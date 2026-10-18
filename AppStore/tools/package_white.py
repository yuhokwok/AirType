from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json
import shutil

base = Path(__file__).resolve().parents[1]
root = base / 'white-direction'
output = base.parent / 'output'
manifest = json.loads((root / 'manifest.json').read_text())
assert len(manifest) == 30 and all(m['passed'] and not m['hasAlpha'] and m['colourSpace'] == 'srgb' for m in manifest)
expected = {'iphone': (1206, 2622, 10), 'ipad': (2064, 2752, 10),
            'header': (3840, 1646, 2), 'search-results': (3840, 2560, 2),
            'social-square': (1080, 1080, 2), 'social-story': (1080, 1920, 2),
            'social-landscape': (1200, 630, 2)}
for placement, (width, height, count) in expected.items():
    entries = [m for m in manifest if m['placement'] == placement]
    assert len(entries) == count
    assert all((m['width'], m['height']) == (width, height) for m in entries)
    assert all((root / m['file']).is_file() for m in entries)

shutil.copytree(base / 'metadata', root / 'metadata', dirs_exist_ok=True)
shutil.copy2(base / 'LISTING-COPY.md', root / 'LISTING-COPY.md')
shutil.copy2(base / 'fonts' / 'OFL.txt', root / 'FONT-LICENSE.txt')
(root / 'brand').mkdir(exist_ok=True)
shutil.copy2(base / 'icons' / 'airtype-brand-1024.png', root / 'brand' / 'airtype-brand-1024.png')
(root / 'README.md').write_text('''# AirType 宣傳素材 · 白底新版

2026-10-18 · 繁體中文及英文 · 共 30 張宣傳圖。

沿用用戶提供的既有視覺方向：白底、青綠標題、淡紫裝置線框、底部六色色帶。產品畫面來自現有新版 AirType Simulator 與 Web Access 截圖；參考圖中的舊介面只作視覺方向，沒有用作產品畫面。

| 資料夾／用途 | 尺寸 | 數量 |
| --- | --- | --- |
| screenshots/*/iphone · Dynamic Island 中屏幕 | 1206 × 2622 | 10 |
| screenshots/*/ipad · iPad 13 吋 | 2064 × 2752 | 10 |
| creative/*header* · iPhone／iPad 共用 Header | 3840 × 1646 | 2 |
| creative/*search-results* · Search Results | 3840 × 2560 | 2 |
| promo/*square* · 社交方圖 | 1080 × 1080 | 2 |
| promo/*story* · 社交直圖 | 1080 × 1920 | 2 |
| promo/*landscape* · 社交橫圖 | 1200 × 630 | 2 |

所有正式圖片都是無 alpha 的 sRGB PNG。iPhone／iPad 圖請放在 App Screenshots；本包沒有 App Preview 影片。社交尺寸是沿用的宣傳格式，不是 Apple 上架尺寸要求。

Header 的文字、品牌、手機及瀏覽器外框均在 Apple 模板中央安全區 x=1097、y=493、1646 × 661 px 內。色帶屬可被裁切的背景。Search Results 按用戶要求採較大構圖，不限制在模板中央安全區內。

先開啟 index.html 檢視。previews/ 是縮圖與 Header 中央裁切檢查圖，不可代替正式圖上傳。sources/ 內的 HTML 內嵌字型與產品截圖，可編輯及按原尺寸重新渲染。manifest.json 記錄逐圖尺寸、色彩與主要內容邊界。brand/ 是沿用品牌標誌；metadata/ 與 LISTING-COPY.md 是現有中英文上架文案。

## 官方規格（2026-10-18 核對）

- Screenshot: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Header／Search Results: https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/
- Template: https://developer.apple.com/app-store/asset-best-practices/

## 已完成檢查

- [x] 30 張中英文正式圖片已輸出。
- [x] 官方 screenshot／creative 圖尺寸及無透明度已核對。
- [x] 所有主要內容在畫布內，沒有被底部色帶遮擋。
- [x] Header 主要內容在中央安全區內。
- [x] 總覽、社交圖、Search Results 與 Header 中央裁切已作視覺覆核。
- [x] ZIP 可讀取、逐檔內容及 SHA-256 校驗。

本次只交付本地圖片與文案，未上傳或送審。Header 的最終裝置裁切仍以 App Store Connect Preview 為準。
''')
files = sorted(p for p in root.rglob('*') if p.is_file() and p.name != 'SHA256SUMS.txt')
(root / 'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + str(p.relative_to(root)) + '\n' for p in files))
files.append(root / 'SHA256SUMS.txt')

def pack(name, payload):
    checksum = ''.join(hashlib.sha256(data).hexdigest() + '  ' + name + '\n' for name, data in sorted(payload.items()))
    if 'SHA256SUMS.txt' not in payload:
        payload['SHA256SUMS.txt'] = checksum.encode()
    dest = output / name
    with ZipFile(dest, 'w', ZIP_DEFLATED, compresslevel=1) as z:
        for filename, data in sorted(payload.items()):
            z.writestr(filename, data)
    with ZipFile(dest) as z:
        assert z.testzip() is None
        for filename, data in payload.items():
            assert z.read(filename) == data
    return {'archive': str(dest), 'bytes': dest.stat().st_size, 'verified': True}

archives = [pack('AirType-All-Marketing-White-2026-10-18.zip', {str(p.relative_to(root)): p.read_bytes() for p in files})]
for label, placements in [('iPhone-1206x2622', ['iphone']), ('iPad-2064x2752', ['ipad']), ('Header-Search', ['header', 'search-results'])]:
    items = [m for m in manifest if m['placement'] in placements]
    payload = {m['file']: (root / m['file']).read_bytes() for m in items}
    payload['README.md'] = (root / 'README.md').read_bytes()
    payload['manifest.json'] = (json.dumps(items, indent=2) + '\n').encode()
    archives.append(pack(f'AirType-{label}-White-2026-10-18.zip', payload))
(output / 'AirType-White-Package-Validation.json').write_text(json.dumps({'images': 30, 'archives': archives}, indent=2) + '\n')
print(json.dumps({'images': 30, 'archives': archives}, indent=2))
