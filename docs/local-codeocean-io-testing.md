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

When this directory is mounted at `/data/deg_table`, the adapter sees, for
example, `/data/deg_table/<workflow-result-id>/DEG_Analysis.csv`. The explicit
mount matches both the App Panel declaration and normal Code Ocean attachment
behavior.

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
| `data/debug/codeocean-workflow/` | `/data/deg_table` | Downstream workflow results |
| `results/debug-codeocean-workflow/` | `/results` | Local test outputs |

No `--deg_table` argument is supplied, so `code/main.R` follows its
mount-scoped discovery path. For one comparison, an exact
`diff_<comparison>.csv` is deterministic. Otherwise the adapter requires one
recognized DEG result or one supported data file beneath `/data/deg_table`;
multiple candidates fail and list their paths. Other CSV files, such as a
package inventory, are not treated as named DEG input. The log should report
the selected workflow file before pathway analysis begins.

Use a comparison that exists in `DEG_Analysis.csv`. To test error handling,
temporarily copy or rename files inside this ignored debug fixture; do not
alter the original archive.

## Run workflow-input checks

The adapter test verifies explicit-file priority, mount-scoped discovery,
exact comparison-file selection, non-DEG artifact exclusion, and clear
ambiguity errors:

```bash
Rscript tests/test-workflow-input.R
```
