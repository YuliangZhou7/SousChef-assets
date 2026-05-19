# Asset-host workflow

End-to-end recipe for shipping a new version of the voice assets.

## Prerequisites

- macOS or Linux shell.
- `gh` CLI authenticated against the GitHub account that owns
  `YuliangZhou7/SousChef-assets` (`gh auth status`).
- `curl`, `python3` (system), one of `sha256sum` / `shasum`.
- For `.tflite → .onnx` conversions (Hey Chef): `pip install tf2onnx tensorflow`.

## End-to-end: shipping v1 (initial release)

```
SousChef-assets/                       SousChefApp-v2/
  ├── manifests/v1.json   ◄── ① edit
  │       │
  │       │ ② mirror.sh v1
  │       ▼
  ├── staging/v1/
  │       │
  │       │ ③ hash.sh v1
  │       ▼
  │   (manifest.sha256 fields populated)
  │       │
  │       │ ④ publish.sh v1
  │       ▼
  │   github.com/.../SousChef-assets/releases/tag/v1
  │       │
  │       │ ⑤ app-manifest.sh v1
  │       ▼
                       App/Resources/asset-manifest.json   ◄── ⑥ copy & commit
                                  │
                                  │ ⑦ app rebuilds; first launch
                                  ▼ fetches from release URLs
```

### Step-by-step

**① Edit `manifests/v1.json`.** Fill in each asset's `upstream_url`. Leave `sha256` / `size_bytes` as `"TBD"` — they'll be populated by step ③.

**② Mirror.** Downloads every upstream URL into `staging/v1/`:
```bash
scripts/mirror.sh v1
```
Idempotent. Files already downloaded with a matching SHA-256 are skipped. If a URL is still `"TBD"`, the script logs and continues — useful when you're iterating one asset at a time.

**③ Hash.** Computes SHA-256 + byte size for every staged file, writes back into the manifest:
```bash
scripts/hash.sh v1
```
After this step, every shipping asset's manifest entry has real numbers.

**④ Publish.** Creates the GitHub release (if absent) and uploads every staged file that's not already attached:
```bash
scripts/publish.sh v1
```
Idempotent. Re-runs upload only the missing files. Release notes are placeholder; edit in the GitHub UI afterwards if you want.

**⑤ Emit the in-app manifest.** Pipes the trimmed version into stdout — redirect to the SousChef app's resource file:
```bash
scripts/app-manifest.sh v1 \
  > ../SousChefApp-v2/App/Resources/asset-manifest.json
```
This is the file the app reads at first launch to know what to download.

**⑥ Commit + ship the app.** In the `SousChefApp-v2` repo:
```bash
cd ../SousChefApp-v2
git add App/Resources/asset-manifest.json
git commit -m "[M1] D2: ship asset-manifest.json pointing at v1 release"
git push
```

**⑦ Fresh installs of the new app build now fetch from the v1 release URLs.**

## Refresh recipe (v1 → v2)

Same loop but to a new tag:

```bash
cp manifests/v1.json manifests/v2.json
# Edit v2.json — update versions / URLs / drop or add assets.
scripts/mirror.sh v2
scripts/hash.sh v2
scripts/publish.sh v2
scripts/app-manifest.sh v2 \
  > ../SousChefApp-v2/App/Resources/asset-manifest.json
```

Don't delete the `v1` release — installed app versions still depend on those URLs. New version → new tag.

## Conditional asset: Whisper

Whisper-large-v3-turbo is in the v1 manifest with `"required_if": "stt_engine == 'whisper'"`. Until the M1 STT spike (Q3) concludes:

- Leave its `upstream_url` as `"TBD"` in `manifests/v1.json` if iOS 26 SpeechAnalyzer wins.
- Fill it in and complete steps ②–⑤ if Whisper wins.

`scripts/mirror.sh` skips `"TBD"` entries silently. `scripts/app-manifest.sh` skips assets with `"TBD"` sha256 from the emitted in-app manifest, so the app never tries to download a Whisper asset that wasn't published.

## Publish-eligibility (license-restricted assets)

Each asset in a manifest carries a `publish_eligible` boolean (defaults to `true` if omitted). When `false`:

- `scripts/publish.sh` skips the asset — it's not uploaded to the GitHub release.
- `scripts/app-manifest.sh` drops the asset from the in-app manifest — fresh installs don't try to fetch from a non-existent release URL.
- The file still lives in local `staging/<version>/` so the developer can build the app against it for dogfooding.

**v1 example:** the openwakeword.com community "Hey Chef" model is `publish_eligible: false` because per the site's terms (reviewed 2026-05-19) community models can't be redistributed in a public release. The developer's local M1 build uses the community model from `staging/v1/hey-chef.onnx` directly (bundled into the dev build, not fetched at runtime). The first **public** release (v2) ships a custom-trained Hey Chef classifier with `publish_eligible: true`.

This is the safety rail: a license-restricted asset can never accidentally leak into a public release just because someone forgot to comment it out.

## What doesn't go through this flow

- Recording corpora (wake-word, command, Q&A, MOS) — those live in the app repo at `Packages/*/Tests/Fixtures/`, tracked with Git LFS (per M1_PLAN.md Q12).
- The "Hey Chef" classifier when we train a custom one (post-M1 wake-word milestone) — it follows the same flow, just with a self-built `.onnx` placed in `staging/v2/`.
