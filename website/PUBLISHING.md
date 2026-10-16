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
