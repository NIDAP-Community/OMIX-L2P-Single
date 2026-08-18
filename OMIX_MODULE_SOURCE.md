# OMIX module source

This repository is the Code Ocean deployment adapter for the canonical OMIX
module:

`NIDAP-Community/OMIX/modules/OMIX-L2P-Single`

The canonical module owns the reusable R implementation, platform-neutral CLI,
tests, and interface schema. This repository owns Code Ocean-specific files:
App Panel metadata, workflow and `/data` input discovery, `/results` output
handling, and the capsule environment.

Author scientific changes in the OMIX monorepo first, then export the released
module implementation into this capsule repository. If a change starts in the
Code Ocean capsule, test it there, backport the underlying scientific change to
the OMIX module, and then re-export it here.
