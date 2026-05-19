# SousChef-assets

Mirror + release host for the on-device voice model assets shipped by
the [SousChef](https://github.com/YuliangZhou7/SousChef-v2) cooking app.

The app downloads these assets on first launch (per
[M1_PLAN.md Q1 / Q8](https://github.com/YuliangZhou7/SousChef-v2/blob/main/docs/tasks/M1_PLAN.md)).
We mirror upstream model files into our own tagged GitHub releases so:

- The app fetches from a stable URL we control (upstreams move files).
- Versioning is explicit per app release (atomic v1 → v2 swap with
  rollback at runtime).
- No infra cost (GitHub Releases hosts the binaries; this repo holds
  only scripts + per-asset attribution).

**Asset binaries are NOT committed to this repo.** They live in
GitHub Releases. This repo holds:

- Per-asset upstream documentation + licenses (`upstream/`).
- Mirror / hash / publish scripts (`scripts/`).
- The release-manifest definitions (`manifests/`).

## Repo layout

```
SousChef-assets/
├── README.md                # this file
├── LICENSE                  # MIT (scripts only; assets keep upstream licenses)
├── ATTRIBUTION.md           # per-asset license summary
├── .gitignore
├── manifests/
│   └── v1.json              # what ships in release v1: upstream URL +
│                            #   expected SHA-256 + destination filename
├── scripts/
│   ├── mirror.sh            # download upstream → staging/
│   ├── hash.sh              # SHA-256 every file in staging/
│   ├── publish.sh           # gh release upload from staging/ → tagged release
│   ├── app-manifest.sh      # emit the in-app asset-manifest.json (URLs + hashes)
│   └── lib/                 # shared bash helpers
├── upstream/                # one .md per asset documenting source +
│   │                        #   license + last-refresh date
│   ├── hey-chef.md
│   ├── kokoro.md
│   ├── whisper-large-v3-turbo.md
│   └── speaker-verifier.md  # not used in M1 (stub), placeholder
└── staging/                 # gitignored; downloaded artifacts land here
```

## Workflow (per release)

The full end-to-end is in [`docs/workflow.md`](docs/workflow.md). Summary:

1. Edit `manifests/vN.json` with upstream URLs.
2. `scripts/mirror.sh vN` — downloads every URL into `staging/vN/`.
3. `scripts/hash.sh vN` — computes SHA-256 for every file, writes into
   `manifests/vN.json` (the `sha256` field).
4. `scripts/publish.sh vN` — `gh release create vN` and uploads every
   file. Idempotent (re-running adds missing files; doesn't reset).
5. `scripts/app-manifest.sh vN` — emits the JSON that ships inside the
   SousChef app at `App/Resources/asset-manifest.json`. Copy the
   output into the app repo.

After the in-app manifest is updated and the app rebuilt, fresh installs
fetch from the v`N` release URLs.

## Asset URLs

Stable downloads land at:

```
https://github.com/YuliangZhou7/SousChef-assets/releases/download/v1/<filename>
```

Public-readable, no auth, no rate-limit concerns for normal usage.

## Versioning

- Release tag = `v1`, `v2`, ... matching the in-app manifest version.
- Bumping `v1 → v2` is purely additive: new release uploaded; old
  release retained for users still on the previous app build.
- Rollback: if `v2` is bad, point the in-app manifest back at `v1` and
  ship an app update. The runtime atomic-swap (per Q8) handles the
  client-side fallback automatically the first time it sees a failed
  validation.

## License

- Scripts and documentation in this repo: MIT (see `LICENSE`).
- Asset binaries hosted in GitHub Releases: each asset retains its
  original upstream license. See `ATTRIBUTION.md`.
