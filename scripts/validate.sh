#!/usr/bin/env bash
# terraform init/validate/plan wrapper — the single source of truth for how
# each cloud's root module is exercised credential-free. Called locally and
# from .github/workflows/security-baseline.yml.
#
# Usage: scripts/validate.sh <aws|gcp>
set -euo pipefail

CLOUD="${1:-}"
if [[ "$CLOUD" != "aws" && "$CLOUD" != "gcp" ]]; then
  echo "Usage: $0 <aws|gcp>" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$REPO_ROOT/live/$CLOUD"

if [[ "$CLOUD" == "aws" ]]; then
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
  export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
else
  if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
    export GOOGLE_APPLICATION_CREDENTIALS="$TMP_DIR/fake-gcp-credentials.json"
    bash "$REPO_ROOT/scripts/gen-fake-gcp-creds.sh" "$GOOGLE_APPLICATION_CREDENTIALS"
  fi
fi

cd "$ROOT_DIR"
START=$(date +%s)

echo "==> terraform init ($CLOUD)"
terraform init -backend=false -input=false

echo "==> terraform validate ($CLOUD)"
terraform validate

echo "==> terraform plan ($CLOUD)"
# -lock=false: this always uses local state for the credential-free
# validation path (never a shared remote backend), and local state locking
# additionally can't work at all on a network-mounted filesystem (flock()
# isn't supported over SMB/NFS). A real apply follows live/<cloud>/README.md
# instead, typically against a remote backend with proper locking.
terraform plan -input=false -lock=false -var-file=ci.tfvars

END=$(date +%s)
echo "==> terraform ($CLOUD) finished in $((END - START))s"
