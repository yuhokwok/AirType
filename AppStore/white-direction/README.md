# AirType 宣傳素材 · 白底新版

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
