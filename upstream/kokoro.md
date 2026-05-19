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
| `kokoro_21_15s_v2.mlmodelc/*` | ~150–200 MB | TTS model with 15 s max-utterance — sufficient for the longest recipe step likely in normal cookbooks. |
| `G2PEncoder.mlmodelc/*` + `G2PDecoder.mlmodelc/*` | ~20–40 MB | English grapheme-to-phoneme conversion. |
| `g2p_vocab.json` + `vocab_index.json` + `us_gold.json` + `us_lexicon_cache.json` | ~20 MB | English phoneme/lexicon data. |
| `config.json` | trivial | FluidAudio runtime configuration. |
| `voices/af_*.json` + `voices/am_*.json` (American) | ~1–3 MB total | Female / male American English voice embeddings. |
| `voices/bf_*.json` + `voices/bm_*.json` (British) | ~1–3 MB total | British English voice embeddings — included as MOS-panel candidates (task E3). |

Skip:

- Multilingual G2P (`MultilingualG2PEncoder.mlmodelc` etc.) — non-English only.
- Smaller 5 s / 10 s TTS variants (`kokoro_21_5s*`, `kokoro_21_10s*`, `kokoro_24_*`) — we always pick the 15 s variant.
- Source `.mlpackage` directories for every model (we only need the compiled `.mlmodelc`).
- `ANE/`, `ANE-zh/` Apple-Neural-Engine-tuned variants and Chinese voices.

Combined this saves ~70 % of the upstream ~6 GB repo.

**Packaging approach — Option A locked (2026-05-19).**

We ship a single `kokoro-82m-en.tar.gz` mirrored to our v1 GitHub release. App unpacks into `Application Support/SousChef/voice-assets/v1/kokoro-82m-en/` on first launch. Atomic versioned install + SHA-256 integrity check (D2) flow exactly like every other asset.

**Why A** over the alternatives that were on the table:

- **vs. Option B (`ModelRegistry.baseURL` override + HF-direct):** keeps a single fetch path (`asset-manifest.json` → our release URL → install). No conditional code for "fallback to HF if our mirror is empty". HF rate-limits and outages are operationally invisible to users.
- **vs. Option C (defer):** M1 needs working TTS on first launch; deferring leaves a dependency for FluidAudio to dial HF directly at runtime, which we'd then need to remove later anyway.

**Build recipe** — automated in `scripts/build-kokoro-tarball.sh`:

```bash
scripts/build-kokoro-tarball.sh v1
# Resolves the HF commit SHA (or KOKORO_REVISION env override),
# huggingface-cli downloads the English subset into
# staging/v1/kokoro-82m-en/, records the commit at
# staging/v1/kokoro-82m-en.commit.txt, then tars to
# staging/v1/kokoro-82m-en.tar.gz.
```

`scripts/mirror.sh` recognises the `local:scripts/build-kokoro-tarball.sh` `upstream_url` sentinel in `manifests/v1.json` and tells the operator to run the build script if the tarball is missing — it never tries to `curl` a multi-file HF repo as if it were one file.

After the tarball lands in `staging/v1/`, the normal `hash.sh → publish.sh → app-manifest.sh` flow applies with no Kokoro-specific branches.

## Voice selection

The M1 MOS panel (task E3) picks two voice IDs from Kokoro's voice set — one mapped to `VoiceID.warmFemale`, one to `VoiceID.warmMale` (per `DECISIONS.md`). The chosen IDs land in:

- `DECISIONS.md` → "Default TTS voices" row.
- The in-app initial Settings defaults.

No mirroring change needed for voice selection — every Kokoro voice is in the same `.mlmodelc/`.

## Version log

| Date | Source | SHA-256 | Notes |
|---|---|---|---|
| TBD | `huggingface.co/FluidInference/kokoro-82m-coreml` @ commit recorded in `staging/v1/kokoro-82m-en.commit.txt` | (`scripts/hash.sh v1`) | Initial M1 mirror, Option A tarball. Built by `scripts/build-kokoro-tarball.sh v1`. The .commit.txt sidecar pins the source revision so future refreshes (v2+) start from a known point. |

## License

- **Kokoro-82M:** Apache 2.0. Retain the NOTICE file when bundling.
- **FluidAudio (the runtime + CoreML packaging):** Apache 2.0.

Both attribution requirements surface in the in-app third-party attributions screen (M6 polish).

## Refresh trigger

Replace if:

- FluidAudio ships a CoreML asset with measurably better latency / MOS.
- Kokoro upstream releases a new model version FluidAudio adopts.
- A specific Kokoro voice the MOS panel selected is removed from a future release.
