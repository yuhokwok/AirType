# AirType landing page

A buildless Traditional Chinese product page using the same typography, spacing, navigation, download buttons, section layouts and dialog treatment as invivo's CInput site, with a blue-violet AirType accent palette.

## Preview

```sh
python3 -m http.server 8768 --directory website/dist
```

Open http://localhost:8768/. The interactive hero is an in-page demonstration, with no connection to an AirType keyboard and no persistence. Setup, FAQ and privacy explanations use native keyboard-accessible dialogs. No external scripts, analytics or cookies are added.

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
