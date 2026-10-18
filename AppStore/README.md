# AirType App Store 素材包

最新設計：**白底、青綠標題、六色色帶版**在 [white-direction/index.html](white-direction/index.html)。請以該目錄的 30 張新版圖片及 `AirType-All-Marketing-White-2026-10-18.zip` 為準；下列舊紫色素材保留作歷史版本。

圖片更新日期：2026-10-18（香港時間）。

先開啟 `index.html` 預覽全部截圖，再按 `SUBMISSION-CHECKLIST.md` 填入正式連結及審核聯絡資料。

## 圖片

| 路徑 | 數量 | 尺寸與用途 |
| --- | --- | --- |
| screenshots/zh-Hant/iphone | 5 | 1206 × 2622；繁中 iPhone Dynamic Island 中屏幕 |
| screenshots/zh-Hant/ipad | 5 | 2064 × 2752；繁中 iPad 13 吋 |
| screenshots/en-US/iphone | 5 | 1206 × 2622；英文 iPhone Dynamic Island 中屏幕 |
| screenshots/en-US/ipad | 5 | 2064 × 2752；英文 iPad 13 吋 |
| promo | 6 | 兩語言各 1080 × 1080、1080 × 1920、1200 × 630；社交／官網宣傳 |
| icons | 2 | 1024 品牌原圖及深色品牌預覽；正式商店 icon 以專案 AirType.icon 隨 build 提交 |
| sources | — | 原始 Simulator、瀏覽器截圖及可重用 HTML 版面 |

上架截圖次序：電腦輸入 → 六位碼配對 → 中英文與 Emoji → 本機 QWERTY → 設定教學。

`overview-zh-Hant.png`、`overview-en-US.png` 是縮圖總覽，不能代替各張正式截圖上傳。所有 screenshot 檔案已檢查尺寸、RGB 色彩與無 alpha。

## 文案

`metadata/zh-Hant/`、`metadata/en-US/` 每欄一份 TXT：

- name：名稱
- subtitle：副標題
- promotional_text：宣傳文字
- description：完整說明
- keywords：關鍵字
- whats_new：更新內容候選稿

`metadata/metadata.json` 包含兩語言全部欄位；`metadata/validation.json` 是長度檢查結果。所有文案只描述目前公開 Web 功能，未宣傳隱藏的藍牙或原生 Mac 連線。

另附 `REVIEW-NOTES.txt`、`PRIVACY-POLICY-DRAFT.md` 及 `SUBMISSION-CHECKLIST.md`。私隱政策尚待營運者確認與公開發布。

## 重建

需要 Node.js、Playwright（含 Chromium）、sharp，以及 Python 3。程式相對路徑從工具檔位置解析；請在專案根目錄執行：

```sh
python3 AppStore/tools/write-metadata.py
node AppStore/tools/render.cjs
node AppStore/tools/finish.cjs
python3 AppStore/tools/package.py
```

若套件不在專案 node_modules，先將 `NODE_PATH` 設為你的套件目錄。本次使用 Codex bundled runtime 的 playwright 與 sharp。

`sources/zh-Hant/` 與 `sources/en-US/` 分別存放對應語言的實際畫面。`capture-states.py <locale>` 擷取本機 QWERTY、卡片式設定頁及配對畫面；深色鍵盤以實際 UI 的 Dark／深色控制切換後擷取。

`capture-portal.cjs <locale> <iphone|ipad> <port> <code> <simulator-id>` 使用當下鍵盤顯示的 port 與配對碼，實際連接、傳送示例文字、擷取瀏覽器及已連線的裝置畫面。配對資訊隨連線失效；不是固定測試帳戶。每組另有 capture.json 記錄。

## 證據及限制

來源是目前原始碼成功建出的 Simulator App；示例文字透過真正的本地 Web Access 配對與 Send 功能，送達 iPhone/iPad 的 App 內鍵盤預覽。繁中組使用真實繁中 App、鍵盤及網頁介面，英文組使用英文介面。本次按最新卡片式設定頁重新擷取，第四張改用實際深色鍵盤。`fonts/` 附排版字型及其 OFL 授權。正式 build 及第三方 App 內的實機驗收另列於上架清單。未上傳或送審。


## iPhone medium-display export — 2026-10-18

Current iPhone PNGs are rendered at 1206 × 2622 for the “iPhone with Dynamic Island (medium display)” App Screenshots slot. The HTML artwork is rendered uniformly at the new scale; the existing PNGs are not stretched or cropped. iPad exports remain 2064 × 2752.

The separate App Previews slot accepts video; this package contains static PNG screenshots, not preview videos. The 886 × 1920 resolution shown by Connect is for portrait App Preview video.

To refresh only the iPhone exports and overview:

```sh
node AppStore/tools/render.cjs --iphone-only
node AppStore/tools/finish.cjs --iphone-only
python3 AppStore/tools/package_iphone.py
```

The dedicated iPhone upload ZIP contains five screenshots per language plus validation and upload notes. Previous large-display archives remain in output for reference.
