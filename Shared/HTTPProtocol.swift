import Foundation

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data

    static func parse(_ data: Data) throws -> HTTPRequest? {
        guard data.count <= 65_536 else { throw ProtocolError.tooLarge }
        guard let range = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        guard let head = String(data: data[..<range.lowerBound], encoding: .utf8) else { throw ProtocolError.invalid }
        let lines = head.components(separatedBy: "\r\n")
        let first = lines[0].split(separator: " ")
        guard first.count == 3, first[2] == "HTTP/1.1" else { throw ProtocolError.invalid }
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { throw ProtocolError.invalid }
            let name = line[..<colon].lowercased()
            guard headers[name] == nil else { throw ProtocolError.invalid }
            headers[name] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        guard headers["transfer-encoding"] == nil else { throw ProtocolError.invalid }
        let length: Int
        if let raw = headers["content-length"] {
            guard let value = Int(raw), value >= 0, value <= 60_000 else { throw ProtocolError.invalid }
            length = value
        } else { length = 0 }
        let start = range.upperBound
        guard data.count - start >= length else { return nil }
        return HTTPRequest(method: String(first[0]), path: String(first[1]), headers: headers,
                           body: Data(data[start..<(start + length)]))
    }
    enum ProtocolError: Error { case invalid, tooLarge }
}

struct RemoteCommand: Codable {
    enum Action: String, Codable { case insert, delete, newline }
    let id: UUID
    let action: Action
    let text: String?
    var isValid: Bool {
        action != .insert || (text != nil && !(text?.isEmpty ?? true) && (text?.utf8.count ?? 0) <= 16_384)
    }
}
