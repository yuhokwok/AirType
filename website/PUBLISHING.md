# Publication status

The static landing page is complete, locally checked, and packaged in `airtype-website.zip` (generated with `python3 website/package.py`). Upload the ZIP contents to the desired directory on invivointeractive.com. The company server has not been changed.

The private Sites preview was saved successfully, but its publication and one retry both failed on 16 October 2026 with:

> Please wait and consider throttling your request speed

This is a hosting-service failure, not a page build failure. No live preview URL was returned.

- Site: `appgprj_6ad1e7f8bbf081918d68328302465202`
- Saved version: `appgprj_6ad1e7f8bbf081918d68328302465202~appgver_5cbbb91190cc81918e667126c3079183`
- First deployment: `appgdep_6ad1e976db0c8191b4efe501caf69e35`
- Retry deployment: `appgdep_6ad1e9f68cec8191a28c62de22418f43`
- Saved source commit: `d9b922edbf50da8718971fed923d8f539b137ebb`

The saved version above predates the purple theme update. To publish the current page, reuse the existing Site ID, synchronize the latest source, and save a new version before deployment. Do not create a duplicate Site. The Site remains private.

Validation: local assets and font load; no browser console errors observed; interactive demo transfers typed Unicode into the illustrated phone; native guide, FAQ and privacy dialogs open and close; FAQ details expand; App Store links all target AirType ID 922932291 (HK listing returns HTTP 200); narrow layouts show no horizontal document overflow; JavaScript syntax and the static upload ZIP were checked. The interactive demo does not communicate with the real keyboard.


## Bilingual privacy pages — 18 October 2026

The current upload package includes `privacy/index.html` (Traditional Chinese), `privacy/en/index.html` (English), shared privacy styling and homepage/footer/dialog links. Policy content follows the owner-supplied legacy page and retains its 27 September 2014 update date. This is a translated/reformatted copy, not a revised policy for version 1.1; see the content notes in README.md. The company server has not been updated by this task.


## Privacy page verification — 18 October 2026

Re-fetched the specified live policy (HTTP 200) and matched all 20 English body paragraphs across nine sections. Added a desktop navigation link and canonical URLs for the Chinese/English policy pages. Playwright checks passed at 1440 × 1000 and 390 × 844: homepage/footer entry, bilingual navigation, return-home link, all nine sections, original date, no horizontal overflow, no page errors and no failed local asset responses. Browser plugin was not available; regular Playwright was used. Rebuilt and verified airtype-website.zip. The production server was not changed.


## Complete bilingual homepage — 18 October 2026

Added the static English homepage at `en/index.html`, shared-language demo messages, visible desktop/mobile language links, localized metadata and language alternates, plus English-policy return links to the English homepage. `build_locales.py` and `locales/en.json` maintain English copy from the same Chinese layout.

Playwright passed both languages at 320, 390, 768, 1024 and 1440 px: document language and meaningful page identity, no horizontal overflow, language switching, demo Unicode delivery, Enter/Shift+Enter, guide/FAQ/privacy dialog opening and closing, FAQ expansion, policy navigation and language-matched home return. No page errors or failed local asset responses. Browser plugin was absent; regular Playwright was used. The company server has not been updated; upload the regenerated static ZIP to publish.
