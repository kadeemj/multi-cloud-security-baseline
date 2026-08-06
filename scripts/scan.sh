#!/usr/bin/env bash
# Checkov wrapper — the single source of truth for scan flags. Called
# locally and from .github/workflows/security-baseline.yml, so CI and local
# runs can never drift apart.
#
# Usage: scripts/scan.sh <aws|gcp> <baseline|insecure> [--sarif <output-dir>]
set -euo pipefail

CLOUD="${1:-}"
MODE="${2:-}"

if [[ "$CLOUD" != "aws" && "$CLOUD" != "gcp" ]]; then
  echo "Usage: $0 <aws|gcp> <baseline|insecure> [--sarif <output-dir>]" >&2
  exit 1
fi
if [[ "$MODE" != "baseline" && "$MODE" != "insecure" ]]; then
  echo "Usage: $0 <aws|gcp> <baseline|insecure> [--sarif <output-dir>]" >&2
  exit 1
fi
shift 2

SARIF_DIR=""
if [[ "${1:-}" == "--sarif" ]]; then
  SARIF_DIR="${2:?--sarif requires an output directory}"
  shift 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ "$MODE" == "baseline" ]]; then
  DIRS=("modules/${CLOUD}-iam-baseline" "modules/${CLOUD}-logging-baseline" "modules/${CLOUD}-encryption-baseline" "live/${CLOUD}")
  CONFIG=".checkov.yaml"
else
  DIRS=("examples/insecure/${CLOUD}")
  CONFIG=".checkov-insecure.yaml"
fi

DIR_ARGS=()
for d in "${DIRS[@]}"; do
  DIR_ARGS+=(-d "$d")
done

OUTPUT_ARGS=(--output cli)
if [[ -n "$SARIF_DIR" ]]; then
  mkdir -p "$SARIF_DIR"
  # With multiple -o formats, --output-file-path takes exact per-format file
  # paths (positionally matched, comma-separated) — NOT a directory. Passing
  # a bare directory here silently breaks (IsADirectoryError), confirmed
  # empirically against checkov 3.3.9.
  OUTPUT_ARGS=(--output cli --output sarif --output json --output-file-path "console,${SARIF_DIR}/results_sarif.sarif,${SARIF_DIR}/results_json.json")
fi

echo "==> checkov: cloud=${CLOUD} mode=${MODE} dirs=${DIRS[*]}"
START=$(date +%s)

set +e
checkov "${DIR_ARGS[@]}" --framework terraform --config-file "$CONFIG" "${OUTPUT_ARGS[@]}"
STATUS=$?
set -e

END=$(date +%s)
echo "==> checkov ${CLOUD}/${MODE} finished in $((END - START))s (exit ${STATUS})"
exit "$STATUS"
