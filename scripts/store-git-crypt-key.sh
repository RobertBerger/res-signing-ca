#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

KEY_FILE="${1:-${BASE_DIR}/../res-signing-ca.git-crypt.key}"
CA_CERT="${BASE_DIR}/openbao/ca-chain.pem"
BAO_URL="https://192.168.42.182:8443"
SECRET_API_PATH="v1/secret/data/yocto/git-crypt/res-signing-ca"


echo "Unseal OpenBao"
echo "e.g from a Webbrowser: ${BAO_URL}"
echo "3 unseal keys"
echo "then login with the root token"
echo "then Secrets Engines -> Enable new engine -> KV -> Path: secret, Version: 2"
echo "Press <ENTER> to continue"
read r


if [ ! -f "${KEY_FILE}" ]; then
    echo "ERROR: Key file not found: ${KEY_FILE}" >&2
    exit 1
fi

if [ ! -f "${CA_CERT}" ]; then
    echo "ERROR: CA chain not found: ${CA_CERT}" >&2
    exit 1
fi

printf "Enter OpenBao Token: "
stty -echo
read -r BAO_TOKEN
stty echo
printf "\n"

if [ -z "${BAO_TOKEN}" ]; then
    echo "ERROR: Empty token provided." >&2
    exit 1
fi

KEY_B64=$(base64 -w0 "${KEY_FILE}")

echo "Uploading git-crypt key to ${BAO_URL}/${SECRET_API_PATH}..."
curl --fail --silent --show-error \
     --cacert "${CA_CERT}" \
     --header "X-Vault-Token: ${BAO_TOKEN}" \
     --header "Content-Type: application/json" \
     --request POST \
     --data "{\"data\": {\"key_b64\": \"${KEY_B64}\"}}" \
     "${BAO_URL}/${SECRET_API_PATH}" >/dev/null

echo "Verifying roundtrip read from OpenBao..."
FETCHED_B64=$(curl --fail --silent --show-error \
     --cacert "${CA_CERT}" \
     --header "X-Vault-Token: ${BAO_TOKEN}" \
     "${BAO_URL}/${SECRET_API_PATH}" | jq -r '.data.data.key_b64')

if [ "${KEY_B64}" != "${FETCHED_B64}" ]; then
    echo "ERROR: Verification mismatch! Keeping local key file ${KEY_FILE}." >&2
    exit 1
fi

echo "Verified match! Removing local key file ${KEY_FILE}..."
rm -f "${KEY_FILE}"
echo "Done."

