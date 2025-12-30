
#!/usr/bin/env bash
set -euo pipefail

# --- Configuration (keep identical to the main script) ---
BASE_DOMAIN="appsec.rocks"
NAME_PREFIX="web"
OUTDIR="out"
DAYS=7                       # certificate validity
CURVE="prime256v1"           # ECC P-256
COUNTRY="DE"
ORG="AppSec Rocks (Test)"
OU="Automation"

# --- Input validation ---
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <index>"
  exit 1
fi
i="$1"
if ! [[ "$i" =~ ^[0-9]+$ ]]; then
  echo "Index must be a positive integer; got: $i"
  exit 1
fi

mkdir -p "$OUTDIR"

num=$(printf "%04d" "${i}")
host="${NAME_PREFIX}${num}.${BASE_DOMAIN}"

key_path="${OUTDIR}/${host}.key"
crt_path="${OUTDIR}/${host}.crt"
cfg_path="${OUTDIR}/${host}.openssl.cnf"

# Per-host OpenSSL config (SAN + subject). Written atomically per job.
cat > "${cfg_path}" <<EOF
[ req ]
default_md              = sha256
prompt                  = no
distinguished_name      = dn
x509_extensions         = v3_req

[ dn ]
C  = ${COUNTRY}
O  = ${ORG}
OU = ${OU}
CN = ${host}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${host}
EOF

# Generate EC private key (P-256)
openssl ecparam -name "${CURVE}" -genkey -noout -out "${key_path}"

# Create self-signed cert with 7-day validity and unique serial
openssl req -new -key "${key_path}" -config "${cfg_path}" \
| openssl x509 -req -days "${DAYS}" -extfile "${cfg_path}" -extensions v3_req \
    -signkey "${key_path}" -sha256 -set_serial "${i}" -out "${crt_path}"

echo "✔ ${host} -> ${key_path}, ${crt_path}"
