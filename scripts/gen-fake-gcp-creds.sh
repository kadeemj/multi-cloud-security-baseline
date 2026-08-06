#!/usr/bin/env bash
# Generates a throwaway, real (syntactically-valid, self-signed) GCP
# service-account key at runtime for credential-free `terraform plan`.
# Never commit the output — even a fake committed PEM block tends to trip
# GitHub secret-scanning / push protection on a public repo.
#
# Usage: scripts/gen-fake-gcp-creds.sh [output-path]
set -euo pipefail

OUT="${1:-/tmp/fake-gcp-credentials.json}"
TMP_KEY="$(mktemp)"
trap 'rm -f "$TMP_KEY"' EXIT

openssl genrsa -out "$TMP_KEY" 2048 2>/dev/null

PRIVATE_KEY_JSON=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    print(json.dumps(f.read()))
" "$TMP_KEY")

cat > "$OUT" <<EOF
{
  "type": "service_account",
  "project_id": "security-baseline-demo-000000",
  "private_key_id": "0000000000000000000000000000000000000000",
  "private_key": ${PRIVATE_KEY_JSON},
  "client_email": "fake@ci-placeholder.iam.gserviceaccount.com",
  "client_id": "000000000000000000000",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/fake%40ci-placeholder.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
EOF

echo "Wrote throwaway fake GCP credentials to $OUT (never commit this file)."
