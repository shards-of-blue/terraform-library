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

## get bitbucket access token
get_bbtoken()
{

  ## try environment variables set by pipeline
  K="${PL_OAUTH_CLIENT_ID}"
  S="${PL_OAUTH_CLIENT_SECRET}"

  if [ -z "${K}" -o -z "${S}" ]; then
    ## then try pulling credentials from a local file
    if [ -f "${BASEDIR}/.oidckeys" ]; then
      . "${BASEDIR}/.oidckeys"
      K="${PL_OAUTH_CLIENT_ID}"
      S="${PL_OAUTH_CLIENT_SECRET}"
      if [ -z "${K}" -o -z "${S}" ]; then
        K="${OAUTH_CLIENT_ID}"
        S="${OAUTH_CLIENT_SECRET}"
      fi
    fi
  fi

  if [ -z "${K}" -o -z "${S}" ]; then
    echo "No bitbucket credentials available"
    return 1
  fi

  ## call bitbocket.org's OAUTH2 endpoint and extract the token from json-formatted output
  export BITBUCKET_OAUTH_TOKEN=$( curl -s -X POST -u "${K}:${S}" -d 'grant_type=client_credentials' "https://bitbucket.org/site/oauth2/access_token" | jq -r '.access_token' )
}

pull_subrepo()
{
  local folder="${1}"
  local reponame="${2}"
  local workspace="${3}"
  local branch="${4}"

  [ -n "${BITBUCKET_OAUTH_TOKEN}" ] || {
    echo "pull_subrepo(${workspace}): no token";
    return;
  }

  [ -d "${folder}" ] || mkdir "${folder}"
  URL=https://x-token-auth:${BITBUCKET_OAUTH_TOKEN}@bitbucket.org/${workspace}/${reponame}.git

  [ -n "${branch}" ] && B="-b ${branch}"
  ( cd ${folder} && git submodule add $B ${URL} . )
  #git archive --format=tar --remote=${URL} | ( cd ${folder} && tar xvf - )
}

#
## record base directory of this build
## (note: default on assumption this script lives in "lib/tf")
#
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
use_azuread_auth     = true
EOT


## pull library and configuration
##get_bbtoken()
##pull_subrepo lib azure-library shades-of-blue release-v1
##pull_subrepo conf azure-global-configuration shades-of-blue
#
