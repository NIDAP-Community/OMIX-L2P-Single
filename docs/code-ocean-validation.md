# Code Ocean validation record

This record separates observed platform execution from facts that have not yet
been captured. A successful computation is not, by itself, an adapter release.

## Recorded computation

| Field | Evidence |
| --- | --- |
| Validation date | 2026-09-30 |
| Code Ocean computation | `814293` |
| Adapter commit | `b6683811bbc37140a1f26e89c59c361947a9876c` |
| Canonical module | OMIX L2P Single `3.2.0` at `5caab82a6dc89c20a30f4cf3826618620b1daf0f` |
| Runtime selected in Code Ocean | `OMIX Pathways v2` |
| Observed outcome | The named-parameter computation completed successfully. |

## Evidence classification

This is **partial platform validation**. It confirms that the merged adapter
could execute in Code Ocean with the named runtime. It does not establish the
runtime's immutable digest, a published capsule release, or a complete durable
checklist of output files and scientific assertions.

## Remaining release gates

- Capture the immutable digest for the exact Code Ocean runtime used.
- Record the capsule identifier or URL and any published platform release ID.
- Repeat or inspect the computation and record the effective input, comparison,
  important named parameters, expected output files, and scientific sanity
  checks.
- Have Beacon verify the completed evidence record against the merged adapter.
- Obtain explicit release approval before creating an adapter tag or publishing
  a capsule release.

Until those gates are complete, `OMIX_MODULE_SOURCE.md` must keep the adapter
version, release tag, platform release, and runtime digest as **Pending**.
