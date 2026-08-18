# Local Code Ocean I/O testing

Use this guide to reproduce the mounted layout of a downstream Code Ocean
workflow without copying the data asset into Git.

## Fixture layout

`data/` and `results/` are ignored by Git. Place an extracted upstream-results
download under an opaque workflow identifier, matching the shape seen by a
downstream capsule:

```text
data/debug/codeocean-workflow/
`-- <workflow-result-id>/
    |-- DEG_Analysis.csv
    |-- figures/
    |-- moo/moo-diff.rds
    |-- output
    `-- r-packages.csv
```

When this directory is mounted at `/data`, the adapter sees, for example,
`/data/<workflow-result-id>/DEG_Analysis.csv`. This is intentionally different
from an attached data asset mounted at `/data/deg_table/`.

## Run the Code Ocean adapter locally

Use an image that contains the same R and package dependencies as the capsule:

```bash
scripts/run-local-codeocean-workflow-debug.sh \
  ghcr.io/nidap-community/omix-r-pathway:<tag> \
  '<comparison>'
```

The runner mounts:

| Local path | Container path | Purpose |
| --- | --- | --- |
| `code/` | `/code` | Code Ocean adapter code |
| `data/debug/codeocean-workflow/` | `/data` | Downstream workflow results |
| `results/debug-codeocean-workflow/` | `/results` | Local test outputs |

No `--deg_file` argument is supplied, so `code/main.R` follows its workflow
input path: recursively discover exactly one CSV whose filename matches the
case-insensitive regex `DEG` under `/data`, or—if no such CSV exists—exactly
one `moo-diff.rds` file. Other CSV files, such as a package inventory, are not
treated as DEG input. The log should report the selected workflow file and
inferred DEG columns before pathway analysis begins.

Use a comparison that exists in `DEG_Analysis.csv`. To test error handling,
temporarily copy or rename files inside this ignored debug fixture; do not
alter the original archive.

## Run workflow-input checks

The adapter test verifies that a unique `DEG` CSV is preferred, non-DEG CSV
artifacts are ignored, multiple DEG candidates fail clearly, and a uniquely
named `moo-diff.rds` remains available as a fallback:

```bash
Rscript tests/test-workflow-input.R
```
