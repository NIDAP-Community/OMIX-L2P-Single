# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX L2P Single](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Single)
- **Canonical path:** `modules/OMIX-L2P-Single/`
- **Canonical module version:** `3.1.0`
- **Canonical interface version:** `1`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`eee4433cd74d0ce9bd1daba1571ca6312cba7ea2`](https://github.com/NIDAP-Community/OMIX/commit/eee4433cd74d0ce9bd1daba1571ca6312cba7ea2)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Single/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | SHA-256 | Purpose |
| --- | --- | --- | --- |
| `R/L2P_Analysis.R` | `code/functions/L2P_Analysis.R` | `c963f5c4168f7bb425d14b4ea0a00270bcff0818ee5b1e7d341b4209bff385bf` | Single-comparison L2P implementation. |

The listed export was verified byte-for-byte against the canonical source
reference above. The canonical `schemas/interface.yml` reviewed for the App
Panel and adapter contract has SHA-256
`ffbbb20d3cfa384a4b1c09610110520e1d8b62ed55d0046c251156edcdb98628`.

## Platform translations

- Canonical `deg_table` is exposed directly as the optional Code Ocean file
  selector `deg_table`. When blank, `code/adapter_io.R` searches only the
  attached `/data/deg_table` mount. It accepts one unambiguous supported DEG
  table, or an exact `diff_<comparison>.csv` for a single comparison; multiple
  candidates are an error rather than an implicit first-file choice.
- Canonical internal `output_dir` is platform-managed as `/results` and is not
  exposed in the App Panel.
- The App Panel and adapter CLI default `species` to `Mouse` because the
  attached mouse demonstration dataset is the deployment's default input. The
  canonical portable CLI retains its `Human` default.
- All other 38 public or advanced controls retain their canonical names,
  types, choices, order, and defaults. There are no deprecated public controls
  or scientific aliases.

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — baseline tag not yet established. |
| Adapter release tag | Pending. |
| Platform release | Pending validation record. |
| Runtime tag | `codeocean/omix-r-pathway:r4.4.3-bioconductor3.20-v1` (from `.codeocean/environment.json`). |
| Runtime digest | Pending — no immutable digest has been validated or recorded. |
| Named-parameter platform run | Pending — GitHub/local checks are not Code Ocean validation. |
| Syncweaver lock | Pending — no generated `.syncweaver-lock.json` is recorded. |

See the [OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md). The source commit, adapter tag, platform release, and runtime identity are separate records.

## Adapter-only support code

`code/adapter_io.R` resolves Code Ocean inputs and the optional legacy
MOSuite `moo-diff.rds` workflow handoff. It is platform support code and is not
part of the canonical `R/` export.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next canonical version and immutable source reference here, and then re-export the listed
file without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
