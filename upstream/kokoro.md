# Kokoro-82M TTS (via FluidAudio)

## Source

- **Upstream model:** [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) — 82M-parameter ONNX/CoreML TTS, Apache 2.0.
- **CoreML packaging:** [`FluidInference/kokoro-82m-coreml`](https://huggingface.co/FluidInference/kokoro-82m-coreml) on Hugging Face — multi-file CoreML repo, Apache 2.0. Updated continuously by the FluidInference team.
- **Swift runtime wrapper:** [FluidInference/FluidAudio](https://github.com/FluidInference/FluidAudio) — CoreML + ANE-optimized inference pipeline; downloads from Hugging Face at runtime by default (override via `ModelRegistry.baseURL`).
- **App integration:** the M1 Kokoro TTS adapter (`Packages/VoiceIO/.../KokoroTTSAdapter.swift`, Group C task C7) wraps FluidAudio's API behind the `SpeechSynthesizing` protocol from Group B.

## What we mirror

**`FluidInference/kokoro-82m-coreml` is a multi-file Hugging Face repo, not a single asset.** It contains three TTS model variants (5s / 10s / 15s max-utterance), G2P encoder + decoder pairs (English + multilingual), and supporting vocab/lexicon JSONs (~300–500 MB total).

For SousChef (English-only at M1 per DECISIONS.md), the minimum-viable subset is:

| File | Approx size | Why |
|---|---|---|
| `kokoro_21_15s_v2.mlmodelc` | ~150–200 MB | TTS model with 15 s max-utterance — sufficient for the longest recipe step likely in normal cookbooks. |
| `G2PEncoder.mlmodelc` + `G2PDecoder.mlmodelc` | ~20–40 MB | English grapheme-to-phoneme conversion. |
| `g2p_vocab.json` + `vocab_index.json` + `us_gold.json` + `us_lexicon_cache.json` | ~20 MB | English phoneme/lexicon data. |
| `config.json` | trivial | FluidAudio runtime configuration. |

Skip multilingual G2P (`MultilingualG2PEncoder.mlmodelc` etc.) and the smaller 5 s / 10 s TTS variants — saves ~50 % of the download.

**Packaging approach (pending architecture decision in M1_PLAN.md):**

The asset-host pipeline supports three options for shipping this. Architecture decision (Option A / B / C) is pending; once picked, this section gets a "Decided" line.

- **Option A — Tarball.** Use `huggingface-cli download FluidInference/kokoro-82m-coreml --include="kokoro_21_15s_v2.mlmodelc/*" --include="G2P*.mlmodelc/*" --include="*.json"` to grab the English subset; `tar -czf staging/v1/kokoro-82m-en.tar.gz <files>`. Ship the single tarball; app unpacks into `Application Support/SousChef/voice-assets/v1/kokoro-82m-en/`.
- **Option B — `ModelRegistry.baseURL` override.** Don't mirror anything; FluidAudio default-fetches from Hugging Face on first launch. We expose a setting later that points at our mirror as a safety net if HuggingFace goes down or rate-limits.
- **Option C — Skip from v1.** Defer Kokoro mirroring until a later milestone; M1 ships only Hey Chef (+ conditional Whisper) in our v1 release; FluidAudio fetches Kokoro from HuggingFace.

## Voice selection

The M1 MOS panel (task E3) picks two voice IDs from Kokoro's voice set — one mapped to `VoiceID.warmFemale`, one to `VoiceID.warmMale` (per `DECISIONS.md`). The chosen IDs land in:

- `DECISIONS.md` → "Default TTS voices" row.
- The in-app initial Settings defaults.

No mirroring change needed for voice selection — every Kokoro voice is in the same `.mlmodelc/`.

## Version log

| Date | Source | SHA-256 | Notes |
|---|---|---|---|
| TBD | `huggingface.co/FluidInference/kokoro-82m-coreml` snapshot @ TBD-commit-sha | (`scripts/hash.sh v1`) | Initial M1 mirror. Record the HF commit SHA at download time so future refreshes start from the same point. |

## License

- **Kokoro-82M:** Apache 2.0. Retain the NOTICE file when bundling.
- **FluidAudio (the runtime + CoreML packaging):** Apache 2.0.

Both attribution requirements surface in the in-app third-party attributions screen (M6 polish).

## Refresh trigger

Replace if:

- FluidAudio ships a CoreML asset with measurably better latency / MOS.
- Kokoro upstream releases a new model version FluidAudio adopts.
- A specific Kokoro voice the MOS panel selected is removed from a future release.
