# Whisper-large-v3-turbo (CoreML, via WhisperKit)

**Status: DROPPED from M1 scope (2026-05-19).** This document is kept as reference for the conditional post-MVP "Whisper open-form-STT quality experiment" milestone in [`SousChefApp-v2/docs/milestone-plan.md`](https://github.com/YuliangZhou7/SousChef-v2/blob/main/docs/milestone-plan.md). The experiment runs only if dogfooding shows the M1-chosen engine (iOS 26 `SpeechAnalyzer` or `SFSpeechRecognizer`, locked by Q3) misses cooking-Q&A WER targets in noisy real-kitchen conditions in a way users notice. If/when that experiment runs, it ships its own asset release (e.g. `v3`), not `v1`.

**Why dropped:** ~1.6 GB asset + ~1.5–2 GB peak resident RAM + a CoreML compile step + an SPM dependency for a runner the cost analysis flagged as a likely loser to iOS 26 `SpeechAnalyzer` (also OS-shipped, zero download). Original "drop Whisper if SpeechAnalyzer is within ~5 WER points on noisy" spike rule is moot — Whisper isn't in the spike anymore.

## Source

- **Upstream model:** [openai/whisper-large-v3-turbo](https://huggingface.co/openai/whisper-large-v3-turbo) — MIT.
- **CoreML packaging:** [argmaxinc/whisperkit-coreml](https://huggingface.co/argmaxinc/whisperkit-coreml) — MIT-licensed CoreML conversions of every Whisper variant.
- **Swift runtime:** [argmaxinc/WhisperKit](https://github.com/argmaxinc/WhisperKit) — Swift Package; depends on the CoreML asset at runtime.
- **App integration (historical):** original M1 plan had task C5 (open-form STT adapter) building this conditionally if Q3 picked Whisper. C5 now wraps the Q3-locked Apple-shipped engine. The "if Whisper wins" branch no longer exists.

## What we mirror

Whisper's CoreML asset is a directory containing several compiled subgraphs (encoder, decoder, vocab, configs). We zip the whole directory and ship as `whisper-large-v3-turbo.mlmodelc.zip` (~1.6 GB), unzipped at install time.

## Size sensitivity

Whisper-large-v3-turbo is the **single largest asset** in the M1 cookable set (per M1_PLAN.md Q1). The whole first-launch payload is ~1.8 GB; without Whisper it drops to ~175 MB. That's the entire point of the Q3 spike — if iOS 26 SpeechAnalyzer can replace it at <5 WER points cost, the user saves ~1.6 GB of download + ~1.5 GB of in-cooking RAM peak.

## Version log

| Date | Upstream URL | SHA-256 | Notes |
|---|---|---|---|
| TBD | (fill in from argmaxinc release page) | (`scripts/hash.sh v1`) | Conditional — only mirrored if Q3 picks Whisper. |

## License

- **Whisper upstream:** MIT (OpenAI).
- **WhisperKit + the CoreML conversion:** MIT (Argmax).

In-app attribution screen carries both notices (M6 polish).

## Refresh trigger

Replace if:

- argmaxinc/whisperkit-coreml ships a Whisper-large-v4 (or future "turbo" variant) with materially better latency / WER on noisy audio.
- Re-running the M1 eval shows the current asset version misses the Q3 thresholds.

Don't refresh just to track upstream changes — the M1 install base on the previous app version still points at the prior asset; the rule is **new release tag, not silent overwrite**.
