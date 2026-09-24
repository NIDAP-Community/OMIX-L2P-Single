# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX L2P Single](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Single)
- **Canonical path:** `modules/OMIX-L2P-Single/`
- **Canonical module version:** `3.1.0`
- **Canonical interface version:** `1`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`b65eeb3c231eb9dfbdbc09326ab03c23bbe84c8f`](https://github.com/NIDAP-Community/OMIX/commit/b65eeb3c231eb9dfbdbc09326ab03c23bbe84c8f)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Single/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | Purpose |
| --- | --- | --- |
| `R/L2P_Analysis.R` | `code/functions/L2P_Analysis.R` | Single-comparison L2P implementation. |

The listed export was verified byte-for-byte against the canonical source
reference above.

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — baseline tag not yet established. |
| Adapter release tag | Pending. |
| Platform release | Pending validation record. |
| Runtime identity | Not yet recorded as an immutable image digest or lockfile reference. |

See the [OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md). The source commit, adapter tag, platform release, and runtime identity are separate records.

## Adapter-only support code

`code/functions/workflow_input.R` resolves platform workflow inputs. It is
adapter support code, not an exported scientific function.

## Intentional adapter presets

- The App Panel defaults `species` to `Mouse` because the attached
  demonstration DEG dataset is mouse. The portable canonical module retains
  its platform-neutral `Human` default.
- `deg_file` selects Code Ocean attachment modes and output paths are fixed
  under `/results`; neither is part of the canonical scientific interface.
- All other scientific and visualization defaults exposed by the panel match
  the adapter CLI and the recorded canonical module.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next canonical version and immutable source reference here, and then re-export the listed
file without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
