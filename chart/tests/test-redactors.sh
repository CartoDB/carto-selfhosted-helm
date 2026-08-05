#!/usr/bin/env bash
#
# Verify the chart's support-bundle Redactor scrubs every known credential
# shape from a captured bundle.
#
# This test exists because PR #854 shipped a chart whose `spec.redactors:`
# block inside the SupportBundle CR was silently ignored by Replicated
# Troubleshoot — the fix was to render redactors as a standalone
# `kind: Redactor` document. A regression of that structural shape (or an
# accidental rename of any redactor pattern) would silently leak customer
# credentials in production support bundles. This test catches it.
#
# Strategy:
#   1. helm template the chart and extract the Redactor CR from the
#      rendered support-bundle Secret stringData
#   2. Build a synthetic support-bundle archive that contains files with
#      every known plaintext sentinel shape
#   3. Run `kubectl support-bundle redact` with the extracted Redactor CR
#      against the synthetic bundle
#   4. Grep the redacted bundle for each sentinel — must report zero hits
#
# Prerequisites: helm, kubectl, kubectl-support_bundle krew plugin,
# python3 with PyYAML (for multi-doc YAML parsing).

set -euo pipefail

# Locate the chart relative to this script so the test can run from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$CHART_DIR"

# ---------- Step 1: render the chart and extract the Redactor CR ----------

# helm dep update is intentionally NOT run here — CI does it once upfront so
# the test stays fast. Local users should run it manually if charts/ is stale.
helm template carto . -n test > "$WORK_DIR/rendered.yaml"

python3 - "$WORK_DIR/rendered.yaml" "$WORK_DIR/redactor.yaml" <<'PY'
import sys, yaml
in_path, out_path = sys.argv[1], sys.argv[2]
for d in yaml.safe_load_all(open(in_path)):
    if not d or d.get('kind') != 'Secret':
        continue
    name = d.get('metadata', {}).get('name', '')
    if 'support-bundle' not in name or 'spec' in name:
        continue
    spec_text = d['stringData']['support-bundle-spec']
    # multi-doc YAML: SupportBundle + Redactor
    for sub in yaml.safe_load_all(spec_text):
        if sub and sub.get('kind') == 'Redactor':
            with open(out_path, 'w') as f:
                yaml.dump(sub, f)
            print(f"extracted {len(sub['spec']['redactors'])} redactor rule(s) -> {out_path}")
            sys.exit(0)
print("ERROR: no kind: Redactor document found in support-bundle Secret stringData", file=sys.stderr)
print("This usually means the chart reverted to embedded spec.redactors, which is silently ignored.", file=sys.stderr)
sys.exit(1)
PY

# ---------- Step 2: build a synthetic bundle with every sentinel ----------

# Bundle archives are conventionally a single top-level directory containing
# version.yaml at the root, mirroring what `kubectl support-bundle` produces.
# The redact tool requires this layout.
BUNDLE_ROOT="$WORK_DIR/bundle/fixture"
mkdir -p "$BUNDLE_ROOT/tenant-requirements-check"
mkdir -p "$BUNDLE_ROOT/replicated-sdk/test-ns/replicated-test/"
mkdir -p "$BUNDLE_ROOT/cluster-resources/pods"
cat > "$BUNDLE_ROOT/version.yaml" <<'YAML'
apiVersion: troubleshoot.replicated.com/v1beta2
kind: SupportBundle
spec:
  version: "test-fixture"
YAML

# Synthetic runPod podSpec — the file the redactors target most directly.
# The env-fallback redactor masks EVERY env value in this file (that is its
# job: shapeless secrets like the Azure storage key have no pattern to match),
# so non-sensitive values here are expected to be scrubbed too.
cat > "$BUNDLE_ROOT/tenant-requirements-check/tenant-requirements-check.json" <<'JSON'
{
  "kind": "Pod",
  "spec": {
    "initContainers": [{
      "name": "init",
      "env": [
        {"name": "DEFAULT_SERVICE_ACCOUNT_KEY__FILE_CONTENT", "value": "eyAidHlwZSI6ICJzZXJ2aWNlX2FjY291bnQiLCAicHJvamVjdF9pZCI6ICJ0ZXN0IiwgInByaXZhdGVfa2V5X2lkIjogImFiY2RlZjEyMzQ1NjciLCAicHJpdmF0ZV9rZXkiOiAiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUlFdlFJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLY3dnZ1NqQWdFQUFvSUJBUUM3VkpUVXQ5VXMnICAuLi4iLCAiY2xpZW50X2VtYWlsIjogImZvb0BiYXIuY29tIn0KICAgIA=="},
        {"name": "ROUTER_SSL_CERT_KEY__FILE_CONTENT", "value": "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLU1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQzdWSlRVdDlVc2FsTlBmenZGYUthSlNwNkY5RjJiTVoyZHcwQU1Tcm14NXBNVE5GS2lXalZGd0pZdmZSeXNUWFR1eDVMaHFlV05GbHpzbA=="},
        {"name": "POSTGRES_SSL_CA__FILE_PATH", "value": "/etc/ssl/postgres-ca.crt"}
      ]
    }],
    "containers": [{
      "name": "main",
      "env": [
        {"name": "LAUNCHDARKLY_SDK_KEY", "value": "sdk-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"},
        {"name": "LAUNCHDARKLY_MOBILE_KEY", "value": "mob-12345678-90ab-cdef-1234-567890abcdef"},
        {"name": "WORKSPACE_THUMBNAILS_ACCESSKEYID", "value": "AKIAIOSFODNN7EXAMPLE"},
        {"name": "WORKSPACE_IMPORTS_STORAGE_ACCESSKEY", "value": "vA8/K5m+1i/1K3RwAGaUVump8VMzZMzaX1CquW6gw5iS0DGqFSSyUkG7G+cGB/LFIwjVLEEWLerf+ASt"},
        {"name": "OPENAI_KEY", "value": "sk-svcacct-CHQ3YL4ftN2UH0W8xW9R5Ud4tfJrj4bry1RN7P"},
        {"name": "GEMINI_API_KEY", "value": "AIzaSyDNkcmZZ0ASCW162cXU0bCgf74vZi68opE"},
        {"name": "VITALLY_TOKEN", "value": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"},
        {"name": "VITALLY_TOKEN_B64", "value": "ZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmhkV1FpT2lJeE9EWXpaamc0WmkwM09EYzFMVFExTldVdFlXUTJPUzA0WkdZNU4yUXlNRGN6WlRnaSJ9"},
        {"name": "WORKSPACE_POSTGRES_PORT", "value": "5432"},
        {"name": "LOG_LEVEL", "value": "info"},
        {"name": "NODE_ENV", "value": "production"}
      ]
    }]
  }
}
JSON

# Synthetic Replicated SDK license-info dump — second leak surface.
cat > "$BUNDLE_ROOT/replicated-sdk/test-ns/replicated-test/replicated-license-info-stdout.txt" <<'TXT'
{
  "licenseID": "test-license-id",
  "appSlug": "carto",
  "customerName": "test-customer",
  "entitlements": {
    "cartoPlatformDefaultSA": {"title": "x", "value": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us\n-----END PRIVATE KEY-----", "valueType": "String"},
    "openAiApiKey": {"title": "x", "value": "sk-svcacct-CHQ3YL4ftN2UH0W8xW9R5Ud4tfJrj4bry1RN7P", "valueType": "String"},
    "geminiApiKey": {"title": "x", "value": "AIzaSyDNkcmZZ0ASCW162cXU0bCgf74vZi68opE", "valueType": "String"},
    "vitallyToken": {"title": "x", "value": "ZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmhkV1FpT2lJeE9EWXpaamc0WmkwM09EYzFMVFExTldVdFlXUTJPUzA0WkdZNU4yUXlNRGN6WlRnaSJ9", "valueType": "String"},
    "cartoFeaturesFlagSdkKey": {"title": "x", "value": "sdk-deadbeef-aaaa-bbbb-cccc-dddddddddddd", "valueType": "String"},
    "databaseEncryptionKey": {"title": "x", "value": "mcaI8oSWt9CBZEarrPJXLgKs4D1h7UY1", "valueType": "String"},
    "jwtEncryptionKey": {"title": "x", "value": "2KMJ5T5hUo58O2OB", "valueType": "String"},
    "instanceId": {"title": "x", "value": "YhwtukDuLyfVTmJ6aShFmjpy7hs0KjVk", "valueType": "String"}
  }
}
TXT

# A pod OUTSIDE the env-fallback's fileSelector scope. Its non-sensitive env
# values must survive redaction — this is what proves the env-value wildcard
# stays scoped to the tenant-requirements-check file instead of stripping
# debug data from every pod in the bundle.
cat > "$BUNDLE_ROOT/cluster-resources/pods/other-app-pod.json" <<'JSON'
{
  "kind": "Pod",
  "spec": {
    "containers": [{
      "name": "app",
      "env": [
        {"name": "WORKSPACE_POSTGRES_PORT", "value": "5432"},
        {"name": "LOG_LEVEL", "value": "info"},
        {"name": "NODE_ENV", "value": "production"}
      ]
    }]
  }
}
JSON

# Build the archive — match the convention of a single top-level dir inside.
# COPYFILE_DISABLE=1 stops macOS tar from injecting AppleDouble (._) entries
# that break the Go archive reader troubleshoot uses.
( cd "$WORK_DIR/bundle" && COPYFILE_DISABLE=1 tar -czf "$WORK_DIR/fixture.tar.gz" fixture )

# ---------- Step 3: run redact with the extracted Redactor CR ----------

# kubectl support-bundle redact <redactor-spec> --bundle <input> --output <output>
kubectl support-bundle redact "$WORK_DIR/redactor.yaml" \
  --bundle "$WORK_DIR/fixture.tar.gz" \
  --output "$WORK_DIR/redacted.tar.gz" >/dev/null

mkdir -p "$WORK_DIR/redacted-extracted"
tar -xzf "$WORK_DIR/redacted.tar.gz" -C "$WORK_DIR/redacted-extracted"

# ---------- Step 4: grep for sentinels and report ----------

# Every entry here is a known plaintext credential shape that the redactor
# set MUST scrub. Adding a new credential shape to the platform means adding
# both a redactor rule AND a sentinel here.
SENTINELS=(
  # LD shapes
  'sdk-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
  'sdk-deadbeef-aaaa-bbbb-cccc-dddddddddddd'
  'mob-12345678-90ab-cdef-1234-567890abcdef'
  # AWS
  'AKIAIOSFODNN7EXAMPLE'
  # OpenAI
  'sk-svcacct-CHQ3YL4ftN2UH0W8xW9R5Ud4tfJrj4bry1RN7P'
  # Google API
  'AIzaSyDNkcmZZ0ASCW162cXU0bCgf74vZi68opE'
  # JWT (raw + b64-wrapped)
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
  'ZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5'
  # PEM private key (raw + b64)
  'BEGIN PRIVATE KEY'
  'BEGIN RSA PRIVATE KEY'
  'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVk'
  # GCP SA JSON (b64)
  'eyAidHlwZSI6'
  # Azure storage key — shapeless, only the env-fallback yamlPath rule covers
  # it. This sentinel is what catches a fileSelector glob that silently stops
  # matching the tenant-requirements-check file (troubleshoot `**/` globs
  # require a parent directory, so the root-relative form must stay listed).
  'vA8/K5m+1i/1K3RwAGaUVump8VMzZMzaX1CquW6gw5iS0DGqFSSyUkG7G+cGB/LFIwjVLEEWLerf+ASt'
  # License-entitlement shape-less values
  'mcaI8oSWt9CBZEarrPJXLgKs4D1h7UY1'
  '2KMJ5T5hUo58O2OB'
  'YhwtukDuLyfVTmJ6aShFmjpy7hs0KjVk'
)

LEAKS=0
PASSES=0
for S in "${SENTINELS[@]}"; do
  if grep -rq -- "$S" "$WORK_DIR/redacted-extracted" 2>/dev/null; then
    LEAKS=$((LEAKS + 1))
    echo "LEAK  $S"
    grep -rl -- "$S" "$WORK_DIR/redacted-extracted" | head -2 | sed 's|^|        |'
  else
    PASSES=$((PASSES + 1))
    echo "OK    $S"
  fi
done

# Non-sensitive values in pods OUTSIDE the env-fallback's scope MUST remain
# unredacted — over-redaction breaks debug bundles. Checked only against the
# out-of-scope pod: inside tenant-requirements-check.json the fallback masks
# every env value by design.
PRESERVED_FILE="$WORK_DIR/redacted-extracted/fixture/cluster-resources/pods/other-app-pod.json"
PRESERVED_FOUND=0
PRESERVED_MISSING=0
for V in '5432' 'info' 'production'; do
  if grep -q -- "\"$V\"" "$PRESERVED_FILE" 2>/dev/null; then
    PRESERVED_FOUND=$((PRESERVED_FOUND + 1))
  else
    PRESERVED_MISSING=$((PRESERVED_MISSING + 1))
    echo "OVER-REDACT  non-sensitive value '$V' was scrubbed"
  fi
done

HIDDEN=$(grep -roh '\*\*\*HIDDEN\*\*\*' "$WORK_DIR/redacted-extracted" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "Summary:"
echo "  Sentinels scrubbed:        $PASSES / ${#SENTINELS[@]}"
echo "  Leaks:                     $LEAKS"
echo "  Non-sensitive preserved:   $PRESERVED_FOUND / 3"
echo "  ***HIDDEN*** insertions:   $HIDDEN"

if [ "$LEAKS" -gt 0 ] || [ "$PRESERVED_MISSING" -gt 0 ]; then
  exit 1
fi

echo "PASS"
