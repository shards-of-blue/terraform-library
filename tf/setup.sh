#
## Common terraform setup tasks
#

#test
ST_RESGROUP_NAME="INFRA-Provisioning"
ST_CONTAINER_NAME="tfstate"
ST_SUBSCRIPTION_ID_test="a6bb6a10-0083-4845-bc27-bb762faec360"
ST_SUBSCRIPTION_ID_staging="x"
ST_SUBSCRIPTION_ID_production="x"
ST_ACCOUNT_NAME_test="prov4f8at01"
ST_ACCOUNT_NAME_staging="prov4f8at11"
ST_ACCOUNT_NAME_production="prov4f8at21"
#testend

## record base directory of this build
BASEDIR=$BITBUCKET_CLONE_DIR
[ -z "${BASEDIR}" ] && BASEDIR="$(realpath ${BINDIR}/../..)"

[ -z "${TFMAIN}" -a -d tfmain ] && TFMAIN=tfmain
[ -z "${TFMAIN}" ] && TFMAIN=.


## environment default (probably not very useful)
[ -z "$ENV" ] && ENV=$BITBUCKET_DEPLOYMENT_ENVIRONMENT

## check if we have OIDC tokens (doesn't work properly yet in bitbucket)
#echo "BITBUCKET_STEP_OIDC_TOKEN: ${BITBUCKET_STEP_OIDC_TOKEN}"
#export ARM_OIDC_REQUEST_TOKEN=${BITBUCKET_STEP_OIDC_TOKEN}


## look for env-specific terraform variable files
FN="${TFMAIN}/${ENV}.tfvars"
if [ -f "$FN" ]; then
    export TF_CLI_ARGS_plan="${TF_CLI_ARGS_plan} -var-file=${FN}"
fi

## Setup stuff based on deployment environment, if present
#[ -z "${BITBUCKET_DEPLOYMENT_ENVIRONMENT}" ] && return


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
ST_RESGROUP_NAME=$( envenv ST_RESGROUP_NAME )
ST_ACCOUNT_NAME=$( envenv ST_ACCOUNT_NAME )
ST_CONTAINER_NAME=$( envenv ST_CONTAINER_NAME )

## collect any repo-defined settings
[ -f ./tfsettings ] && . ./tfsettings
[ -f "${TFMAIN}/tfsettings" ] && . "${TFMAIN}/tfsettings"

## setup terraform backend configuration
export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config backend.conf"
cat > "${TFMAIN}/backend.conf" << EOT
subscription_id      = "${ST_SUBSCRIPTION_ID}"
resource_group_name  = "${ST_RESGROUP_NAME}"
storage_account_name = "${ST_ACCOUNT_NAME}"
container_name       = "${ST_CONTAINER_NAME}"
key                  = "${INFRA_IMMUTABLE_ID}-${INFRA_DEPLOY_ID}/${ENV}.terraform.tfstate"
EOT
