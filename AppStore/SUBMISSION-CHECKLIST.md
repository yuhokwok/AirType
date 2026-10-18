# AirType 上架交付與待填資料

Images refreshed: 2026-10-18 (Asia/Hong_Kong)

## 已準備

- 繁體中文、英文名稱、副標題、宣傳文字、完整說明、關鍵字、更新內容，各欄獨立 TXT，可直接貼入 App Store Connect。
- 每語言 iPhone 5 張 1206 × 2622、iPad 5 張 2064 × 2752；合共 20 張 RGB PNG，無透明背景。
- 原始 iPhone 17 Pro Max、iPad Pro 13-inch (M5) Simulator 畫面及真實 Web Access 瀏覽器畫面；中英文示例文字已透過瀏覽器送達兩個裝置的 App 內鍵盤預覽。
- 紫色宣傳排版 HTML、輸出程式、檔案 manifest、尺寸與文字欄位驗證報告。
- 1024 品牌圖、深色品牌預覽、社交宣傳素材；App Store 正式 icon 由專案 AirType.icon 隨 build 提交。icons 目錄為品牌參考圖，並非從最新 .icon 編譯產物抽取的最終商店 icon。
- 英文 App Review notes，列出完整取用、本地網絡、同一 Wi-Fi、配對及 IP fallback 步驟。

## 提交前需要完成的外部資料

- Support URL：需提供已公開且有聯絡方法的真實支援頁。現有聯絡電郵：info@invivointeractive.com（來自專案網站，請確認仍有效）。
- Privacy Policy URL：需獨立、公開可存取的私隱政策頁。現有網站只有私隱對話框；不把未部署的網址當成可提交連結。附 PRIVACY-POLICY-DRAFT.md，確認後可發布。
- Marketing URL：填入已部署 AirType 官網的實際網址。
- Copyright：建議 2026 invivo interactive limited；請按實際權利人核實。
- App Review 聯絡人姓名、電話、電郵；最終版本號與 build、定價及銷售地區。
- App Privacy、年齡分級、內容權利、加密／出口合規及 Accessibility 資料：按最終 binary 和實際測試在 Connect 填寫，不能單憑素材代填。原生加密實作仍在原始碼／build 內，不可只因 UI 隱藏便假設沒有加密。
- 更新內容是按目前程式功能撰寫的候選文案；如為首次發佈可略過，如更新既有商店版本，提交前與上一個正式版本比較。

## 驗證範圍

- 本次使用現有程式建立 Simulator build 成功；未更改 App 程式碼或原有未提交變更。
- 截圖為目前程式的開發用鍵盤預覽及正式設定介面，沒有冒充第三方 App 或已完成實機測試。繁中與英文組均以對應語言啟動 App，網頁語言由裝置端提供；已重拍 1.1 卡片式設定頁（含教學入口、連線名稱及私隱摺疊設定）及深色鍵盤。
- 實體 iPhone/iPad 的簽署、完整取用／本地網絡權限，以及第三方 App 內接收仍需上架前驗收。
- 本次未上傳、未提交 App Store Connect；無製作可選 App Preview 影片、App 內活動圖或 Apple 邀請制 featuring artwork，因現時未提供該活動／邀請的版型與要求。

## Apple 規格來源（2026-10-17 查閱）

- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/

本素材使用 Apple 列出的 iPhone Dynamic Island 中屏幕與 iPad 13 吋有效尺寸。每組 5 張；App Store 每組可使用 1–10 張截圖。Metadata 程式檢查名稱與副標題 30 字、宣傳文字 170 字、說明與更新 4000 字；關鍵字採更保守的 UTF-8 100 bytes 上限。
