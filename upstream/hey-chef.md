# Hey Chef wake-word classifier

## Source

- **Primary:** [openwakeword.com/library](https://openwakeword.com/library) — community-trained wake-word models for the [openWakeWord](https://github.com/dscripka/openWakeWord) project.
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

| Date | Source URL | SHA-256 | Notes |
|---|---|---|---|
| TBD | (fill in) | (`scripts/hash.sh v1`) | Initial M1 mirror. |

## License

Open-source community model on the openWakeWord platform. Verify the specific model page on openwakeword.com for the exact license string before shipping (most are Apache 2.0; some community-contributed models may differ).

## Refresh trigger

Replace this asset if:

- Dogfooding shows false-reject rate >5% on the developer's voice in kitchen-noise conditions, **and** the openwakeword.com library has shipped an improved "Hey Chef" variant.
- A custom-trained classifier is produced using `livekit-wakeword`'s training CLI (pre-TestFlight wake-word milestone per M1_PLAN.md Q4 tracked debt).
