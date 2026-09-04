# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX L2P Single](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Single)
- **Canonical path:** `modules/OMIX-L2P-Single/`
- **Released source reference:** [`2987296a45a2a11e6c4b3454c813a63ae6db6ac0`](https://github.com/NIDAP-Community/OMIX/commit/2987296a45a2a11e6c4b3454c813a63ae6db6ac0)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Single/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | Purpose |
| --- | --- | --- |
| `R/L2P_Analysis.R` | `code/functions/L2P_Analysis.R` | Single-comparison L2P implementation. |

The listed export was verified byte-for-byte against the released source
reference above.

## Adapter-only support code

`code/functions/workflow_input.R` resolves platform workflow inputs. It is
adapter support code, not an exported scientific function.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next released source reference here, and then re-export the listed
file without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
