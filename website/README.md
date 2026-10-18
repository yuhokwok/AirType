# AirType landing page

A buildless bilingual Traditional Chinese/English product page using the same typography, spacing, navigation, download buttons, section layouts and dialog treatment as invivo's CInput site, with a blue-violet AirType accent palette.

## Preview

```sh
python3 -m http.server 8768 --directory website/dist
```

Open http://localhost:8768/ for Traditional Chinese or http://localhost:8768/en/ for English. The interactive hero is an in-page demonstration, with no connection to an AirType keyboard and no persistence. Setup, FAQ and privacy explanations use native keyboard-accessible dialogs. No external scripts, analytics or cookies are added.

## Deploy to the company website

```sh
python3 website/package.py
```

Upload the **contents** of `website/dist/` (or extract `airtype-website.zip`) into the server's desired directory, for example `/airtype/`. Assets and links are relative, so the site works at a subdirectory without a build step. This repository does not contain credentials for invivointeractive.com and does not automatically upload to that host.

The separate `.openai/hosting.json` identifies the private Sites preview. Sites publishing uses its own source checkout, outside this app's Git repository. The upload ZIP contains only public page assets, without that manifest or any source-control data.

## Content and artwork

- All App Store buttons point to AirType, product ID `922932291`.
- The icon is the compiled rendering of the current `AirType.icon` asset.
- The dark keyboard image is an actual development-version Simulator capture, labelled accordingly.
- The interactive hero is explicitly labelled an illustration. It does not claim to be a recording of the released App Store version.
- The bundled Noto Sans CJK TC font and its OFL licence are copied from invivo's CInput site source.
- Official company links use `@invivointeractive`.

The App Store listing describes the original release. Setup text accommodates version differences; no unverified minimum OS version, new-release date, ratings, testimonials or service claims are added.


## Privacy policy

The desktop navigation, footer and site privacy dialog link to the complete policy in [Traditional Chinese](dist/privacy/index.html) and [English](dist/privacy/en/index.html). Uploading the package places these at `/airtype/privacy/` and `/airtype/privacy/en/`. Both pages offer language switching without JavaScript. Their layout shares the landing page palette and font.

Content follows the owner's supplied https://www.invivointeractive.com/airtype/privacy/ (retrieved 18 October 2026). The English body preserves all nine sections; Chinese is a translation. The source date (27 September 2014), original privacy contact `info@invivo.me`, and references to the Data Security Statement, support pages and change log are preserved. The supplied source has no actual links for those references, so no destinations are invented. The date displayed is the source policy's update date, not a claim that the policy was revised in 2026.

The existing website-demo privacy dialog describes the local demonstration separately from the full product policy. This task does not revise the 2014 policy's cloud/statistics, sharing, notifications or encryption terms to reflect the current app. In particular, the current same-Wi-Fi Web Access implementation uses unencrypted local HTTP; the source policy's service-encryption wording should be reviewed before publishing an updated current-version policy.


## Homepage languages

The homepage has complete Traditional Chinese and English editions at `/airtype/` and `/airtype/en/`. Both have a visible language switch on desktop and phones. Features, setup steps, FAQ, privacy notices, demo copy/statuses, accessible names and page metadata are localized. Each privacy policy returns to its matching homepage language.

The language is determined by the page URL. No cookies or persistent browser storage are used for language selection. Switching pages resets the illustrative demo, as does a refresh.

The English HTML is generated from the Chinese markup and `locales/en.json`:

```sh
python3 website/build_locales.py
python3 website/package.py
```

The generator rejects missing Chinese-to-English strings rather than silently shipping untranslated copy. Deployed files remain static; no Python or runtime translation service is required. Shared interaction code chooses demo messages from the document language.
