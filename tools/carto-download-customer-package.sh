#!/bin/bash

##########################################
# Requirements: yq jq gsutil gcloud
##########################################
DEPENDENCIES="yq jq gsutil gcloud"
SELFHOSTED_MODE="k8s"
FILE_DIR="."
CARTO_SERVICE_ACCOUNT_FILE="./carto-service-account.json"
CLIENT_STORAGE_BUCKET=""
CUSTOMER_PACKAGE_NAME_PREFIX="carto-selfhosted-${SELFHOSTED_MODE}-customer-package"
CUSTOMER_PACKAGE_FOLDER="customer-package"
##########################################

function check_deps()
{
  for DEP in ${DEPENDENCIES}; do
    # shellcheck disable=SC2261,SC2210
    command -v "${DEP}" 2&>1 > /dev/null || \
      { echo -e "\n[ERROR]: missing dependency <${DEP}>. Please, install it.\n"; exit 1;}
  done
}

function check_input_files()
{
  # =================================
  # $1 -> input file to validate
  # =================================
  if ! [ -e "$1" ]; then
    echo -e "\n[ERROR]: unable to locate <$1>. Please check that the file exists.\n"
    usage
    exit 2
  fi
}

function usage()
{
  cat <<EOF

   Usage: $PROGNAME [-d dir_path] [-s <k8s|docker>]

   optional arguments:
     -d    Folder path where both <carto-values.yaml> and <carto-secrets.yaml> are located (k8s)
           or where both <customer.env> and <key.json> are located (docker). 
           Default is current directory.
     -h    Show this help message and exit
     -s    Selfhosted-mode for the customer package: k8s or docker.
           Default is k8s.

EOF
}

function _error() {
  # ARGV1 = message
  # ARGV2 = desired exit code (default is 1)
  local EXIT_CODE="${2:-1}"
  RED="\033[1;31m"
  YELLOW="\033[1;93m"
  NONE="\033[0m"
  echo -e "❌ ${RED}ERROR ${NONE}[${EXIT_CODE}]: ${YELLOW}${1}${NONE}"
  usage
  exit "${EXIT_CODE}"
}

# ==================================================
# Verify input
# ==================================================
PROGNAME="$(basename "$0")"

# use getopts builtin to store provided options
while getopts d:s:h OPTS ; do
  case "${OPTS}" in
    d) FILE_DIR="${OPTARG%/}" ;;
    s) SELFHOSTED_MODE="${OPTARG}" ;;
    h) usage ; exit ;;
    *) _error "Invalid args provided" 1
  esac
done

# ==================================================
# main block
# ==================================================
# docker
CARTO_ENV="${FILE_DIR}/customer.env"
CARTO_SA="${FILE_DIR}/key.json"
# k8s
CARTO_VALUES="${FILE_DIR}/carto-values.yaml"
CARTO_SECRETS="${FILE_DIR}/carto-secrets.yaml"
# global
CUSTOMER_PACKAGE_NAME_PREFIX="carto-selfhosted-${SELFHOSTED_MODE}-customer-package"

# Check dependencies
check_deps

# Validate selfhosted mode
if [ "$(echo "${SELFHOSTED_MODE}" | grep -E "docker|k8s")" == "" ]; then
  echo -e "\n[ERROR]: available selfhosted modes: k8s or docker\n"
  usage
  exit 1
fi

# Check that required files exist
if [ "${SELFHOSTED_MODE}" = "k8s" ]; then
  check_input_files "${CARTO_VALUES}"
  check_input_files "${CARTO_SECRETS}"
fi
if [ "${SELFHOSTED_MODE}" = "docker" ]; then
  check_input_files "${CARTO_ENV}"
  check_input_files "${CARTO_SA}"
fi

# Get information from YAML files (k8s) or customer.env file (docker)
if [ "${SELFHOSTED_MODE}" = "k8s" ]; then
  yq ".cartoSecrets.defaultGoogleServiceAccount.value" < "${CARTO_SECRETS}" | \
    grep -v "^$" > "${CARTO_SERVICE_ACCOUNT_FILE}"
  CLIENT_STORAGE_BUCKET=$(yq -r ".appConfigValues.workspaceImportsBucket" < "${CARTO_VALUES}")
  TENANT_ID=$(yq -r ".cartoConfigValues.selfHostedTenantId" < "${CARTO_VALUES}")
  CLIENT_ID="${TENANT_ID/#onp-}" # Remove onp- prefix
  SELFHOSTED_VERSION_CURRENT=$(yq -r ".cartoConfigValues.customerPackageVersion" < "${CARTO_VALUES}") 
fi

# shellcheck disable=SC1090
if [ "${SELFHOSTED_MODE}" = "docker" ]; then
  source "${CARTO_ENV}"
  cp "${CARTO_SA}" "${CARTO_SERVICE_ACCOUNT_FILE}"
  CLIENT_STORAGE_BUCKET="${WORKSPACE_IMPORTS_BUCKET}"
  TENANT_ID="${SELFHOSTED_TENANT_ID}"
  CLIENT_ID="${TENANT_ID/#onp-}" # Remove onp- prefix
  SELFHOSTED_VERSION_CURRENT="${CARTO_SELFHOSTED_CUSTOMER_PACKAGE_VERSION}"
fi

# Get information from JSON service account file
CARTO_SERVICE_ACCOUNT_EMAIL=$(jq -r ".client_email" < "${CARTO_SERVICE_ACCOUNT_FILE}")
CARTO_GCP_PROJECT=$(jq -r ".project_id" < "${CARTO_SERVICE_ACCOUNT_FILE}")

# Download the latest customer package
gcloud auth activate-service-account "${CARTO_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${CARTO_SERVICE_ACCOUNT_FILE}" \
  --project="${CARTO_GCP_PROJECT}"

# Get latest customer package version
CUSTOMER_PACKAGE_FILE_LATEST=$(gsutil ls "gs://${CLIENT_STORAGE_BUCKET}/${CUSTOMER_PACKAGE_FOLDER}/${CUSTOMER_PACKAGE_NAME_PREFIX}-${CLIENT_ID}-*-*-*.zip")
SELFHOSTED_VERSION_LATEST=$(echo "${CUSTOMER_PACKAGE_FILE_LATEST}" | grep -Eo "[0-9]+-[0-9]+-[0-9]+")

# Download package
gsutil cp \
  "gs://${CLIENT_STORAGE_BUCKET}/${CUSTOMER_PACKAGE_FOLDER}/${CUSTOMER_PACKAGE_NAME_PREFIX}-${CLIENT_ID}-${SELFHOSTED_VERSION_LATEST}.zip" .

# Print message
echo -e "\n##############################################################"
echo -e "Current selfhosted version in [carto-values.yaml]: ${SELFHOSTED_VERSION_CURRENT}"
echo -e "Latest selfhosted version downloaded: ${SELFHOSTED_VERSION_LATEST}"
echo -e "Downloaded file: $(basename "${CUSTOMER_PACKAGE_FILE_LATEST}")"
echo -e "Downloaded from: ${CUSTOMER_PACKAGE_FILE_LATEST}"
echo -e "##############################################################\n"
