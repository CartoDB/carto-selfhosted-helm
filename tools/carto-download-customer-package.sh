#!/bin/bash

##########################################
# Requirements: yq gsutil
##########################################
DEPENDENCIES="yq jq gsutil gcloud"
SELFHOSTED_MODE="k8s"
FILE_DIR=""
CARTO_SERVICE_ACCOUNT_FILE="./carto-service-account.json"
CLIENT_STORAGE_BUCKET=""
CUSTOMER_PACKAGE_NAME_PREFIX="carto-selfhosted-${SELFHOSTED_MODE}-customer-package"
CUSTOMER_PACKAGE_FOLDER="customer-package"
##########################################

function check_deps()
{
  for DEP in ${DEPENDENCIES}; do
    command -v ${DEP} 2&>1 > /dev/null || \
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

   Usage: $PROGNAME --dir dir_path

   optional arguments:
     -h, --help             show this help message and exit
     -d, --dir              folder path where both <carto-values.yaml> and <carto-secrets.yaml> are located
     -s, --selfhosted-mode  selfhosted-mode for the customer package: k8s, or docker

EOF
}


# ==================================================
# Verify input
# ==================================================
PROGNAME=$(basename $0)

# use getopt and store the output into $OPTS
# note the use of -o for the short options, --long for the long name options
# and a : for any option that takes a parameter
OPTS=$(getopt -o "hd:s" --long "help,dir,selfhosted-mode" -n "$PROGNAME" -- "$@")

# Check getopt errors
if [ $? -ne 0 ] ; then
  echo -e "[ERROR]: please check input arguments."
  usage
  exit 1
elif [ $# -lt 2 -o $# -gt 5 ]; then
  usage
  exit 1
fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    -h | --help ) usage; exit; ;;
    -d | --dir) FILE_DIR="$2"; shift 2 ;;
    -s | --selfhosted-mode) SELFHOSTED_MODE="$3"; shift 2 ;;
    -- ) shift ;;
    * ) break ;;
  esac
done

# ==================================================
# main block
# ==================================================

CARTO_VALUES="${FILE_DIR}/carto-values.yaml"
CARTO_SECRETS="${FILE_DIR}/carto-secrets.yaml"
CUSTOMER_PACKAGE_NAME_PREFIX="carto-selfhosted-${SELFHOSTED_MODE}-customer-package"

# Check dependencies
check_deps

# Check that required files exist
check_input_files "${CARTO_VALUES}"
check_input_files "${CARTO_SECRETS}"

# Validate selfhosted mode
if [ "$(echo ${SELFHOSTED_MODE} | egrep "docker|k8s")" == "" ]; then
  echo -e "\n[ERROR]: available selfhosted modes: k8s or docker\n"
  usage
  exit 1
fi

# Get information from YAML files
cat ${CARTO_SECRETS} | \
  yq ".cartoSecrets.defaultGoogleServiceAccount.value" | \
  grep -v "^$" > ${CARTO_SERVICE_ACCOUNT_FILE}
CLIENT_STORAGE_BUCKET=$(cat ${CARTO_VALUES} | yq -r ".appConfigValues.workspaceImportsBucket")
TENANT_ID=$(cat ${CARTO_VALUES} | yq -r ".cartoConfigValues.selfHostedTenantId")
CLIENT_ID=${TENANT_ID/#onp-} # Remove onp- prefix
SELFHOSTED_VERSION_CURRENT=$(cat ${CARTO_VALUES} | yq -r ".cartoConfigValues.customerPackageVersion")

# Get information from JSON service account file
CARTO_SERVICE_ACCOUNT_EMAIL=$(cat ${CARTO_SERVICE_ACCOUNT_FILE} | jq -r ".client_email")
CARTO_GCP_PROJECT=$(cat ${CARTO_SERVICE_ACCOUNT_FILE}| jq -r ".project_id")

# Download the latest customer package
gcloud auth activate-service-account ${CARTO_SERVICE_ACCOUNT_EMAIL} \
  --key-file=${CARTO_SERVICE_ACCOUNT_FILE} \
  --project=${CARTO_GCP_PROJECT}

# Get latest customer package version
CUSTOMER_PACKAGE_FILE_LATEST=$(gsutil ls gs://${CLIENT_STORAGE_BUCKET}/${CUSTOMER_PACKAGE_FOLDER}/${CUSTOMER_PACKAGE_NAME_PREFIX}-${CLIENT_ID}-*-*-*.zip)
SELFHOSTED_VERSION_LATEST=$(echo ${CUSTOMER_PACKAGE_FILE_LATEST} | grep -Eo "[0-9]+-[0-9]+-[0-9]+")

# Download package
gsutil cp \
  gs://${CLIENT_STORAGE_BUCKET}/${CUSTOMER_PACKAGE_FOLDER}/${CUSTOMER_PACKAGE_NAME_PREFIX}-${CLIENT_ID}-${SELFHOSTED_VERSION_LATEST}.zip .

# Print message
echo -e "\n##############################################################"
echo -e "Current selfhosted version in [carto-values.yaml]: ${SELFHOSTED_VERSION_CURRENT}"
echo -e "Latest selfhosted version downloaded: ${SELFHOSTED_VERSION_LATEST}"
echo -e "Downloaded file: $(basename ${CUSTOMER_PACKAGE_FILE_LATEST})"
echo -e "Downloaded from: ${CUSTOMER_PACKAGE_FILE_LATEST}"
echo -e "##############################################################\n"
