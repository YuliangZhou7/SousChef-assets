# Hey Chef wake-word classifier

## Source

- **Primary (M1 dogfooding only):** [openwakeword.com/library](https://openwakeword.com/library) — community section. Models on this site are community-trained and submitted; per the site's terms (reviewed 2026-05-19) the community models likely cannot be redistributed in a public app release without retraining. **Treat the community model as dev/dogfood only.**
- **Production (pre-TestFlight):** must be replaced with a **custom-trained classifier** owned by us. Train via [livekit-wakeword's training CLI](https://github.com/livekit/wakeword) (Python pipeline at `External/livekit-wakeword/`) on hand-collected positive samples + the LiveKit / openWakeWord public negative corpora. Both stacks share the same mel + Google speech embedding + openWakeWord embedding front-end, so the resulting ONNX classifier drops in behind `livekit-wakeword`'s Swift runtime with no integration changes.
- **Runtime in app:** [`livekit-wakeword`](https://github.com/livekit/wakeword) Swift adapter (vendored as a git submodule under `External/livekit-wakeword/`).

## Why this works

`livekit-wakeword`'s README explicitly states it is **backward compatible with openWakeWord models**. Both stacks share:

- Mel spectrogram extraction (16 kHz mono, openWakeWord's `melspec_transform`).
- Google `speech_embedding` model (frozen, 96-dim).
- openWakeWord `embedding` model (frozen).
- A `(16, 96)` feature matrix flowing into the classifier head.

The classifier head is the only thing that varies — livekit ships a conv-attention head; openWakeWord uses a flat DNN. The Swift runtime accepts either ONNX head transparently, per livekit-wakeword's `docs/evaluation.md`.

## Format handling

- openwakeword.com/library publishes models as `.tflite` and/or `.onnx`.
- Our Swift runtime needs **ONNX**. If only `.tflite` is published, convert once:
  ```bash
  pip install tf2onnx tensorflow
  python -m tf2onnx.convert \
    --tflite hey-chef.tflite \
    --output hey-chef.onnx \
    --opset 18
  ```
  Document the conversion source `.tflite` SHA-256 here when you do this so a future refresh starts from the same place.

## Version log

| Date | Source | SHA-256 | Notes |
|---|---|---|---|
| 2026-05-19 | openwakeword.com/library community section — manually downloaded by user; specific submission URL not recorded at time of download | (`scripts/hash.sh v1`) | **Dev/dogfood only.** Stays in local `staging/v1/` only; do not publish to a public release. |
| TBD | custom-trained via livekit-wakeword pipeline | (`scripts/hash.sh v2`) | **First production-shippable classifier.** Required before TestFlight (M6). See "Pre-TestFlight retraining" below. |

## License

Community-submitted models from openwakeword.com's library carry license terms that vary per submission. Per the user's read of [openwakeword.com/terms](https://openwakeword.com/terms) on 2026-05-19, the community models cannot be redistributed in a public app release without retraining — they're suitable for the developer's own dogfooding only.

**Implication:** the M1 build that uses the community Hey Chef model runs locally on the developer's iPhone 16 Pro for dogfooding. It does NOT get uploaded to a public GitHub release on `SousChef-assets`, and it does NOT ship to TestFlight or the App Store.

## Pre-TestFlight retraining (mandatory before M6)

Promoted from M1_PLAN.md Q4 "tracked debt" to **hard requirement**. Before any TestFlight build:

1. Collect ~100–500 positive "Hey Chef" samples (developer voice + any willing test panel) across conditions (quiet, range-hood, water, TTS-playing).
2. Train via the `livekit-wakeword` Python pipeline (`External/livekit-wakeword/src/livekit/wakeword/cli.py`); use livekit's pre-built negative corpora (ACAV100M, openWakeWord negatives) plus locally-recorded kitchen distractors.
3. Output: a custom `hey-chef.onnx` we own end-to-end.
4. Mirror via `SousChef-assets/scripts/` to a `v2` release.
5. Update the in-app manifest to point at `v2`.
6. Retire the dev-only community classifier.

The training pipeline takes ~12–24 hours of compute on a GPU machine (or a few days on Apple Silicon). Plan the work into a dedicated pre-TestFlight wake-word milestone slot.

## Refresh trigger

Replace this asset if:

- M0/M1 dogfooding (developer-only) shows the community classifier is unsuitable for everyday cooking — too many false rejects in kitchen noise, or false accepts during normal conversation.
- Pre-TestFlight retraining is initiated (mandatory; see above).
- An openWakeWord library policy change makes redistribution allowable (unlikely; assume the retraining requirement is permanent).
