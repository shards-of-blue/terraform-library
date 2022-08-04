#
## Common terraform setup tasks
#

## look for various variations of an environment variable
envenv() {
  local varname="${1}"
  local default="${2}"
  local v=$( eval echo \$${varname}_${TENANTKEY^^} )
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
## setup terraform azure backend configuration
## Get data from env variables, if present. Otherwise extract from
## global platform configuration, if appropriate.
#
aztf_backend_conf() {

  ST_SUBSCRIPTION_ID=$( envenv ST_SUBSCRIPTION_ID )
  [ -z "${ST_SUBSCRIPTION_ID}" ] && ST_SUBSCRIPTION_ID=$(yq '.az_infra_provisioning_subscription_id' < conf/$TENANTKEY.yaml)

  ST_RESGROUP_NAME=$( envenv ST_RESGROUP_NAME )
  [ -z "${ST_RESGROUP_NAME}" ] && ST_RESGROUP_NAME=$(yq '.az_infra_provisioning_resource_group' < conf/$TENANTKEY.yaml)

  ST_ACCOUNT_NAME=$( envenv ST_ACCOUNT_NAME )
  [ -z "${ST_ACCOUNT_NAME}" ] && ST_ACCOUNT_NAME=$(yq '.az_infra_provisioning_storage_account' < conf/$TENANTKEY.yaml)

  ## container name component defaults to LZ name
  ST_CONTAINER_NAME=$( envenv ST_CONTAINER_NAME )
  if [ -z "${ST_CONTAINER_NAME}" ]; then
    echo "variable ST_CONTAINER_NAME is not set"
    return 1
  fi

  ## key prefix component defaults to LZ name
  ST_KEY_PREFIX=$( envenv ST_KEY_PREFIX )
  [ -z "${ST_KEY_PREFIX}" ] && ST_KEY_PREFIX=0

  echo " --setup: constructing azurerm backend configuration file"

  cat > "${TFMAIN}/backend.conf" << EOT
subscription_id      = "${ST_SUBSCRIPTION_ID}"
resource_group_name  = "${ST_RESGROUP_NAME}"
storage_account_name = "${ST_ACCOUNT_NAME}"
container_name       = "${ST_CONTAINER_NAME}"
key                  = "${TFMAIN}/${ST_KEY_PREFIX}-terraform.tfstate"
use_azuread_auth     = true
EOT
  export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config backend.conf"
}

#
## Arrange for git clones from terraform to pick up an access token
#
ghtf_token_setup() {
  [ -z "${GITHUB_WORKSPACE}" ] && return
  [ -z "${GITHUB_ORG_CLONETOKEN}" ] && return
  echo " --setup: setup github token to clone other repos in the organization"
  git config --global url."https://${GITHUB_ORG_CLONETOKEN}@github.com".insteadOf https://github.com
}


#
## record base directory of this build
## (note: default on assumption this script lives in "lib/tf")
#
[ -z "${BASEDIR}" ] && BASEDIR=$GITHUB_WORKSPACE
[ -z "${BASEDIR}" ] && BASEDIR=$BITBUCKET_CLONE_DIR
[ -z "${BASEDIR}" ] && BASEDIR="$(realpath ${BINDIR}/../..)"

[ -z "${TFMAIN}" -a -d tfmain ] && TFMAIN=tfmain
[ -z "${TFMAIN}" ] && TFMAIN=.


if [ -n "${BITBUCKET_STEP_OIDC_TOKEN}" ]; then
  ## check if we have OIDC tokens (doesn't work properly yet in bitbucket)
  echo "BITBUCKET_STEP_OIDC_TOKEN: ${BITBUCKET_STEP_OIDC_TOKEN}"
  export ARM_OIDC_REQUEST_TOKEN=${BITBUCKET_STEP_OIDC_TOKEN}
fi

## set 'tenant' parameter which, by convention, is required in many roots
export TF_VAR_tenant=${TENANTKEY}

## look for env-specific terraform variable files
FN="${TFMAIN}/${TENANTKEY}.tfvars"
if [ -f "$FN" ]; then
    export TF_CLI_ARGS_plan="${TF_CLI_ARGS_plan} -var-file=${FN}"
fi

## collect any repo-defined settings
[ -f ./.pipeline.vars ] && . ./.pipeline.vars
[ -f ./tfsettings ] && . ./tfsettings
[ -f "${TFMAIN}/tfsettings" ] && . "${TFMAIN}/tfsettings"

aztf_backend_conf || exit 10

ghtf_token_setup

#
## check for tenant-specific versions of AZURE_* credential variables
#

if [ -n "${AZCLILOGIN}" ]; then
  ## use a regular user account
  AZURE_CLI_SUBSCRIPTION_ID=$( envenv AZURE_CLI_SUBSCRIPTION_ID )
  AZURE_CLI_CLIENT_ID=$( envenv AZURE_CLI_CLIENT_ID )
  AZURE_CLI_CLIENT_SECRET=$( envenv AZURE_CLI_CLIENT_SECRET )
  AZURE_CLI_TENANT_ID=$( envenv AZURE_CLI_TENANT_ID )

  az login --allow-no-subscriptions --username "$AZURE_CLI_CLIENT_ID" --password "$AZURE_CLI_CLIENT_SECRET" --tenant "$AZURE_CLI_TENANT_ID" >/dev/null || {

    echo "AZ login failed"
    exit 2
  }

  ## unset any ARM_ variables to avoid upsetting terraform
  unset ARM_SUBSCRIPTION_ID
  unset ARM_CLIENT_ID
  unset ARM_CLIENT_SECRET

else
  export ARM_SUBSCRIPTION_ID=$( envenv AZURE_SUBSCRIPTION_ID )
  export ARM_CLIENT_ID=$( envenv AZURE_CLIENT_ID )
  export ARM_CLIENT_SECRET=$( envenv AZURE_CLIENT_SECRET )
  export ARM_TENANT_ID=$( envenv AZURE_TENANT_ID )
fi
