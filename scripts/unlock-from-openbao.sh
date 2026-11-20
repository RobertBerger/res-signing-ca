#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CA_CERT="${BASE_DIR}/openbao/ca-chain.pem"
BAO_URL="https://192.168.42.182:8443"
SECRET_API_PATH="v1/secret/data/yocto/git-crypt/res-signing-ca"


echo "Unseal OpenBao"
echo "e.g from a Webbrowser: ${BAO_URL}"
echo "3 unseal keys"
echo "then login with the root token"
echo "Press <ENTER> to continue"
read r

printf "Enter OpenBao Token: "
stty -echo
read -r BAO_TOKEN
stty echo
printf "\n"

cd "${BASE_DIR}"
curl --fail --silent --show-error \
     --cacert "${CA_CERT}" \
     --header "X-Vault-Token: ${BAO_TOKEN}" \
     "${BAO_URL}/${SECRET_API_PATH}" \
  | jq -r '.data.data.key_b64' \
  | base64 -d \
  | git-crypt unlock -

echo "Unlocked ${BASE_DIR} successfully."
