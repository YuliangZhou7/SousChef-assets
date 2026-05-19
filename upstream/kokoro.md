# Kokoro-82M TTS (via FluidAudio)

## Source

- **Upstream model:** [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) — 82M-parameter ONNX/CoreML TTS, Apache 2.0.
- **Swift runtime wrapper:** [FluidInference/FluidAudio](https://github.com/FluidInference/FluidAudio) — CoreML + ANE-optimized inference pipeline.
- **App integration:** the M1 Kokoro TTS adapter (`Packages/VoiceIO/.../KokoroTTSAdapter.swift`, Group C task C7) wraps FluidAudio's API behind the `SpeechSynthesizing` protocol from Group B.

## What we mirror

We mirror the FluidAudio-provided CoreML asset bundle (`.mlmodelc/`) as a zip. FluidAudio's release artifact contains:

- The compiled CoreML graph (`model.mil`, weights, metadata).
- Voice-embedding manifests for every Kokoro voice the release ships.
- A `voices.json` index FluidAudio reads at load time.

The whole `.mlmodelc/` directory is one logical asset; we ship it as `kokoro-82m.mlmodelc.zip` and unzip at install time on device.

## Voice selection

The M1 MOS panel (task E3) picks two voice IDs from Kokoro's voice set — one mapped to `VoiceID.warmFemale`, one to `VoiceID.warmMale` (per `DECISIONS.md`). The chosen IDs land in:

- `DECISIONS.md` → "Default TTS voices" row.
- The in-app initial Settings defaults.

No mirroring change needed for voice selection — every Kokoro voice is in the same `.mlmodelc/`.

## Version log

| Date | Upstream URL | SHA-256 | Notes |
|---|---|---|---|
| TBD | (fill in from FluidAudio release page) | (`scripts/hash.sh v1`) | Initial M1 mirror. |

## License

- **Kokoro-82M:** Apache 2.0. Retain the NOTICE file when bundling.
- **FluidAudio (the runtime + CoreML packaging):** Apache 2.0.

Both attribution requirements surface in the in-app third-party attributions screen (M6 polish).

## Refresh trigger

Replace if:

- FluidAudio ships a CoreML asset with measurably better latency / MOS.
- Kokoro upstream releases a new model version FluidAudio adopts.
- A specific Kokoro voice the MOS panel selected is removed from a future release.
