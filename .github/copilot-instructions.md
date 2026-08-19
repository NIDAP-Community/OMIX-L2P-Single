# OMIX L2P Single Code Ocean Adapter Instructions

This repository is a Code Ocean deployment adapter for the canonical
[OMIX-L2P-Single module](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Single).
Before editing, read `README.md`, `OMIX_MODULE_SOURCE.md`, and the
[OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md).

- Keep Code Ocean-only behavior here: App Panel metadata, `code/main.R`,
  `code/run`, `/data` discovery, `/results` handling, and `environment/`.
- This is not a directory mirror. Export only released scientific R functions
  from the canonical module into `code/functions/`.
- If a Code Ocean fix changes scientific behavior, reusable interfaces, or
  schemas, test it here, backport it to the canonical module, validate it
  there, then export the released function back here.
- Do not commit generated results, debug data, package inventories, or secrets.
