# Speaker verifier (placeholder — not shipped in M1)

**Status: NOT SHIPPED in M1.** Speaker verification is deferred to a dedicated post-M1 personalization milestone (per [M1_PLAN.md Q6](https://github.com/YuliangZhou7/SousChef-v2/blob/main/docs/tasks/M1_PLAN.md)). The app ships `AlwaysVerifiedSpeakerVerifier` as a stub — it always returns `.verified` regardless of input. No model asset is loaded or fetched in M1.

This file documents the intended source for when the feature actually lands.

## Intended source

- **FluidAudio's speaker-embedding component** — same package we use for Kokoro (one-dep consolidation, per `DECISIONS.md`).
- Produces a fixed-dimensional voice embedding from a short utterance; cosine-similarity against an enrolled profile yields the verification decision.

## What's deferred

- The actual embedding model asset (estimated ~5 MB; trivial to bundle).
- Enrollment UI in Settings (record N samples, compute centroid, persist).
- Voice-profile storage (Keychain or `Application Support`, encrypted, excluded from iCloud backup).
- Verification pass-through in the wake-word path.
- Multi-speaker eval corpus (EER, impostor false-accept).

The protocol slot (`SpeakerVerifying`) is in place in M1 so the wake-word adapter's `verify(buffer:against:)` call site is wired. When the feature ships, swap `AlwaysVerifiedSpeakerVerifier` for the real implementation; no other code changes.

## Pre-shipping checklist (whenever this lands)

1. Add a `speaker-verifier-vN.mlmodelc.zip` entry to `manifests/vN.json` with the FluidAudio asset URL.
2. Update this file's "Source" section with the actual upstream URL + license.
3. Update `ATTRIBUTION.md` v-row.
4. Bump the in-app manifest version so installed users redownload.
