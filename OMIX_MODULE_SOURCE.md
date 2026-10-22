# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX L2P Single](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Single)
- **Canonical path:** `modules/OMIX-L2P-Single/`
- **Canonical module version:** `3.2.0`
- **Canonical interface version:** `1`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`5caab82a6dc89c20a30f4cf3826618620b1daf0f`](https://github.com/NIDAP-Community/OMIX/commit/5caab82a6dc89c20a30f4cf3826618620b1daf0f)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Single/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | SHA-256 | Purpose |
| --- | --- | --- | --- |
| `R/L2P_Analysis.R` | `code/functions/L2P_Analysis.R` | `f24c57751dcbda394cdf222bdf46892b6f463f98fb678d07234e921fa0c02054` | Single-comparison L2P implementation. |

The listed export was verified byte-for-byte against the canonical source
reference above. The canonical `schemas/interface.yml` reviewed for the App
Panel and adapter contract has SHA-256
`ff40848d376cdf9b5bb406a478a689b7398387752e8f0e2efbfb1595f4f2a1e0`.

## Platform translations

- Canonical `deg_table` is exposed directly as the optional Code Ocean file
  selector `deg_table`. When blank, `code/adapter_io.R` searches only the
  attached `/data/deg_table` mount. It accepts one unambiguous supported DEG
  table, or an exact `diff_<comparison>.csv` for a single comparison; multiple
  candidates are an error rather than an implicit first-file choice.
- When the optional `deg_table` mount is empty, the adapter additionally
  recognizes exactly one `Limma_Analysis.csv` in the generic `/data` bundle
  supplied by a direct OMIX Limma workflow-result edge. This is a Code Ocean
  path translation, not a canonical input-contract change; other generic CSV
  files remain ineligible.
- Canonical internal `output_dir` is platform-managed as `/results` and is not
  exposed in the App Panel.
- The App Panel presets `comparison` to `B-A` for the attached mouse
  demonstration table and leaves `comparisons` blank. The adapter CLI retains
  the canonical blank defaults, so another table may infer a comparison only
  when exactly one complete prefix exists for the configured suffixes.
- The App Panel and adapter CLI default `species` to `Mouse` because the
  attached mouse demonstration dataset is the deployment's default input. The
  canonical portable CLI retains its `Human` default.
- Per-comparison workflow tables may translate configured prefixed column
  names to their generic narrow equivalents (for example, `B-A_pval` to
  `pval`) only when no complete prefixed comparison is present. Wide-table
  selection and exact-column precedence remain canonical.
- Every public or advanced control is exposed. Other than the documented
  `comparison` and `species` demonstration presets, controls retain their
  canonical names, types, choices, order, and defaults.

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — baseline tag not yet established. |
| Adapter release tag | Pending. |
| Platform release | Pending validation record. |
| Runtime tag | `codeocean/omix-r-pathway:r4.4.3-bioconductor3.20-v2` (from `.codeocean/environment.json`). |
| Runtime digest | Pending — no immutable digest has been validated or recorded. |
| Named-parameter platform run | Code Ocean computation `814293` completed successfully on 2026-09-30 against merged adapter commit `b6683811bbc37140a1f26e89c59c361947a9876c` using `OMIX Pathways v2`. The immutable runtime digest, platform release identifier, and durable output checklist remain pending. |
| Syncweaver lock | Pending — no generated `.syncweaver-lock.json` is recorded. |

See the [Code Ocean validation record](docs/code-ocean-validation.md) and the
[OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md).
The completed computation is partial platform evidence, not a release: the
source commit, adapter tag, platform release, and immutable runtime identity
remain separate records.

## Adapter-only support code

`code/adapter_io.R` resolves Code Ocean inputs, the direct Limma-result
handoff, and the optional legacy MOSuite `moo-diff.rds` workflow handoff. It
is platform support code and is not part of the canonical `R/` export.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next canonical version and immutable source reference here, and then re-export the listed
file without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
