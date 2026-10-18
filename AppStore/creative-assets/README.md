# AirType Header 與 Search Results 圖片

製作日期：2026-10-18。沿用紫色 promo 配色、AirType 品牌與真實 Web Access 畫面。

## 上傳用檔案

| 用途 | 繁體中文 | 英文 | 尺寸 |
| --- | --- | --- | --- |
| Header（iPhone／iPad 共用） | upload/airtype-header-zh-Hant-3840x1646.png | upload/airtype-header-en-US-3840x1646.png | 3840 × 1646 |
| Search Results | upload/airtype-search-results-zh-Hant-3840x2560.png | upload/airtype-search-results-en-US-3840x2560.png | 3840 × 2560 |

4 張都是 sRGB PNG，無 alpha／透明背景。上傳時請選 upload/ 內對應用途及語言的檔案。

## 裁切安排

Header 將所有主要文字、品牌及裝置介面集中於中央，外圍只放可被裁走的紫色漸層、圓弧與色帶。上下各約 30%、左右各約 29% 的畫布是非關鍵背景。

安全區數值直接讀取 Apple 官方 Photoshop 模板中的 Art Safe Area 圖層：

- Header：x=1097、y=493，1646 × 661 px。
- Search Results：按最新要求放大內容 1.6 倍，改用整幅 3840 × 2560 px 畫布，不再限制於模板中央安全區。

輸出程式檢查文字區、手機及電腦介面外框：Header 維持模板安全區；Search Results 檢查內容沒有超出整幅畫布。`manifest.json` 記錄每張圖的尺寸、色彩、透明度及元素座標。

`previews/header-crop-check-zh-Hant.png` 及英文版展示原圖、中央 16:9／4:3／1:1、上下裁切及四邊裁切至安全區的壓力測試。綠色虛線只在檢查圖出現，正式上傳圖沒有輔助線。

這些是構圖裁切示意，不是 Apple 各型號裝置的實際裁切座標。上傳後請用 App Store Connect 的 Preview 檢查實際 iPhone／iPad 顯示。

## 版面來源

sources/ 包含 4 份獨立 HTML，內嵌字型與畫面圖片，可保留或調整排版。來源程式在 AirType 專案的 AppStore/tools/creative-assets.cjs；用 Node.js、Playwright／Chromium、sharp 重新輸出。

## Apple 來源（2026-10-18 查閱）

- 尺寸與無 alpha 要求：https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications
- 安全區、設計與預覽指引：https://developer.apple.com/app-store/asset-best-practices/
- Header PSD：https://devimages-cdn.apple.com/design/resources/download/app-store/creative_assets-product_page_header_template-static.psd
- Search Results PSD：https://devimages-cdn.apple.com/design/resources/download/app-store/creative_assets-search_results_template-static.psd

已下載並解析模板圖層座標，結果保存在 reference/apple-template-bounds.json。未將 Apple 模板及其中的示例美術納入素材 ZIP。

本次只產出本地檔案，未上傳或送審。
