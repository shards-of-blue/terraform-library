#
## Common terraform setup tasks
#

#test
ST_RESGROUP_NAME="INFRA-Provisioning"
ST_CONTAINER_NAME="tfstate"
ST_ACCOUNT_NAME_test="prov4f8aT01"
ST_ACCOUNT_NAME_staging="prov4f8aT11"
ST_ACCOUNT_NAME_production="prov4f8aT21"
#testend

## record base directory of this build
BASEDIR=$BITBUCKET_CLONE_DIR
[ -z "${BASEDIR}" ] && BASEDIR="$(realpath ${BINDIR}/../..)"

[ -n "$TFDIR" -a -d "$TFDIR" ] || { echo "setup: TFDIR '$TFDIR' does not exist"; exit 11; }

## environment default (probably not very useful)
[ -z "$ENV" ] && ENV=$BITBUCKET_DEPLOYMENT_ENVIRONMENT

## check if we have OIDC tokens (doesn't work properly yet in bitbucket)
#echo "BITBUCKET_STEP_OIDC_TOKEN: ${BITBUCKET_STEP_OIDC_TOKEN}"
#export ARM_OIDC_REQUEST_TOKEN=${BITBUCKET_STEP_OIDC_TOKEN}

## Setup stuff based on deployment environment, if present
[ -z "${BITBUCKET_DEPLOYMENT_ENVIRONMENT}" ] && return


FN="${TFDIR}/${BITBUCKET_DEPLOYMENT_ENVIRONMENT}.tfvars"
if [ -f "$FN" ]; then
    VARFILEARG="-var-file=${FN}"
    echo VARFILEARG=${VARFILEARG}
fi

## look for various variations of an environment variable
envenv() {
  local varname="${1}"
  local default="${2}"
  local v=$( eval echo \$${varname}_${ENV} )
  if [ -n "${v}" ]; then echo $v; return; fi
  v=$( eval echo \$${varname} )
  if [ -n "${v}" ]; then echo $v; return; fi
  echo $default
}

## check if there env-specific versions of the ARM_* variables
ARM_SUBSCRIPTION_ID=$( envenv ARM_SUBSCRIPTION_ID )
ARM_CLIENT_ID=$( envenv ARM_CLIENT_ID )
ARM_CLIENT_SECRET=$( envenv ARM_CLIENT_SECRET )

ST_SUBSCRIPTION_ID=$( envenv ST_SUBSCRIPTION_ID )
ST_RESGROUP_NAME=$( envenv ST_ACCOUNT_NAME )
ST_ACCOUNT_NAME=$( envenv ST_ACCOUNT_NAME )
ST_CONTAINER_NAME=$( envenv ST_CONTAINER_NAME )

## setup terraform backend configuration
TF_BACKEND_CONF="${TFDIR}/backend.conf"
cat > $TF_BACKEND_CONF << EOT
subscription_id      = "${ST_SUBSCRIPTION_ID}"
resource_group_name  = "${ST_RESGROUP_NAME}"
storage_account_name = "${ST_ACCOUNT_NAME}"
container_name       = "${ST_CONTAINER_NAME}"
key                  = "${BITBUCKET_DEPLOYMENT_ENVIRONMENT}.terraform.tfstate"
EOT

