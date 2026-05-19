# Asset Attribution

Per-asset upstream sources + licenses. Update every time an asset is
refreshed or added. See `upstream/<asset>.md` for the deep-dive per
asset.

## v1 (current)

| Asset | Upstream | License | Notes |
|---|---|---|---|
| `hey-chef.onnx` | [openwakeword.com/library](https://openwakeword.com/library) — "Hey Chef" community model | Apache 2.0 (openWakeWord convention; verify per model page) | Compatible with the `livekit-wakeword` Swift runtime (livekit-wakeword inherits openWakeWord's mel + Google speech embedding pipeline). If only `.tflite` is published, convert via `tf2onnx`. |
| `kokoro-82m.mlmodelc.zip` | [FluidInference/FluidAudio](https://github.com/FluidInference/FluidAudio) Kokoro-82M CoreML release | Apache 2.0 (FluidAudio) + Apache 2.0 (Kokoro upstream) | Bundled as a zipped CoreML asset; the app unzips into `Application Support/SousChef/voice-assets/v1/`. |
| `whisper-large-v3-turbo.mlmodelc.zip` | [argmaxinc/whisperkit-coreml](https://huggingface.co/argmaxinc/whisperkit-coreml) | MIT (WhisperKit) + MIT (Whisper-large-v3-turbo upstream) | **Conditional asset** — included only if the M1 STT spike (M1_PLAN.md Q3) picks WhisperKit over iOS 26 `SpeechAnalyzer`. |
| `speaker-verifier-placeholder.bin` | n/a — M1 stub | n/a | Placeholder; not shipped. Real FluidAudio speaker embedding lands in a post-M1 personalization milestone. |

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
