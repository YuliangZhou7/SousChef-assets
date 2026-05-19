# Asset Attribution

Per-asset upstream sources + licenses. Update every time an asset is
refreshed or added. See `upstream/<asset>.md` for the deep-dive per
asset.

## v1 (current — dev/dogfood scope only)

**Note:** v1 is the developer-local M1 dogfooding release. The Hey Chef classifier in v1 is the openwakeword.com community model, which per the site's terms cannot be redistributed in a public app release. The first publicly-shippable release will be **v2**, after the custom-trained Hey Chef classifier lands (see `upstream/hey-chef.md` "Pre-TestFlight retraining").

| Asset | Upstream | License | Public-release-eligible? | Notes |
|---|---|---|---|---|
| `hey-chef.onnx` | openwakeword.com/library community section | community submission — restricted per openwakeword.com/terms (reviewed 2026-05-19) | **No.** Dev/dogfood only. | Local-only; not uploaded to a public GitHub release. Must be replaced by a custom-trained classifier before any TestFlight build. |
| `kokoro-82m-en.tar.gz` *(filename pending packaging decision)* | `huggingface.co/FluidInference/kokoro-82m-coreml` — English subset | Apache 2.0 (Kokoro upstream) + Apache 2.0 (FluidInference CoreML packaging) | **Yes.** | Pending architecture decision (Option A tarball vs. B HF-direct vs. C defer); see `upstream/kokoro.md`. |
| `speaker-verifier-placeholder.bin` | n/a — M1 stub | n/a | n/a | Placeholder; not shipped. Real FluidAudio speaker embedding lands in a post-M1 personalization milestone. |

**Removed from v1 on 2026-05-19:** `whisper-large-v3-turbo.mlmodelc.zip` (argmaxinc/whisperkit-coreml, MIT). ~1.6 GB asset + ~1.5–2 GB peak RAM not justified vs. iOS 26 `SpeechAnalyzer` / `SFSpeechRecognizer` (both OS-shipped). Reintroduced only via the conditional post-MVP "Whisper open-form-STT quality experiment" milestone in SousChefApp-v2 — if that ever runs, it ships its own asset version (not v1). See `upstream/whisper-large-v3-turbo.md` for upstream details (kept as reference).

## v2 (planned — first public-release-eligible build)

| Asset | Upstream | License | Notes |
|---|---|---|---|
| `hey-chef.onnx` | Custom-trained by us via livekit-wakeword pipeline on hand-collected positives + LiveKit/openWakeWord public negatives | Owned by us (training data terms permit; document at training time) | Replaces the v1 community classifier. Required before TestFlight. See `upstream/hey-chef.md` "Pre-TestFlight retraining". |

## License compliance reminders

- **Apache 2.0** requires retaining the copyright notice + license text +
  any NOTICE file. Bundle into the app's third-party attributions
  screen (M6 polish — see `DECISIONS.md` deferred operational tasks).
- **MIT** requires retaining the copyright notice + license text. Same
  third-party attributions surface.
- **Kokoro upstream** (the model itself) is Apache 2.0. The voice
  embeddings are part of the Kokoro model bundle. Keep both Kokoro and
  FluidAudio's NOTICE files alongside the in-app attribution screen.

## Asset refresh policy

When upstream ships a new version we want to adopt:

1. Update the relevant `upstream/<asset>.md` with the new version + date.
2. Bump the manifest version (`v1 → v2`); see `manifests/`.
3. Run `scripts/mirror.sh v2` and friends.
4. Update this table.

Don't silently overwrite an existing release tag — users on the old app
build are still depending on those URLs. New version → new tag.
