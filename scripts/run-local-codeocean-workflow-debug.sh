#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  cat >&2 <<'USAGE'
Usage: scripts/run-local-codeocean-workflow-debug.sh <image> <comparison> [additional main.R arguments]

Mounts data/debug/codeocean-workflow as /data/deg_table, matching the declared
Code Ocean input mount. The image must contain the runtime dependencies
required by this capsule.
USAGE
  exit 2
fi

image="$1"
comparison="$2"
shift 2

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$repo_root/data/debug/codeocean-workflow"
results_root="$repo_root/results/debug-codeocean-workflow"

if [[ ! -d "$fixture_root" ]]; then
  echo "Missing fixture directory: $fixture_root" >&2
  echo "See docs/local-codeocean-io-testing.md to create it." >&2
  exit 2
fi

mkdir -p "$results_root"

docker run --rm \
  -v "$repo_root/code:/code:ro" \
  -v "$fixture_root:/data/deg_table:ro" \
  -v "$results_root:/results" \
  --entrypoint bash \
  "$image" \
  /code/run --comparison "$comparison" "$@"
