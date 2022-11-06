#
## Common terraform setup tasks
#

## look for various variations of an environment variable
envenv() {
  local varname="${1}"
  local default="${2}"
  local v=$( eval echo \$${varname}_${TENANTKEY^^})
  if [ -n "${v}" ]; then echo $v; return; fi
  v=$( eval echo \$${varname} )
  if [ -n "${v}" ]; then echo $v; return; fi
  echo $default
}

## record environment variable definition to artifact file
expenv() {
  local varname="${1}"
  local value="${2}"
  echo export ${varname}=\"${value}\" >> ${ENV_ARTIFACT_FNAME}
}


env_init() {
  ## re-init environment setting artifact file
  ENV_ARTIFACT_FNAME="${1}"
  > ${ENV_ARTIFACT_FNAME}

  ## setup default TF variables
  expenv TF_INPUT 0
  expenv TF_IN_AUTOMATION 1

  #
  ## record base directory of this build
  ## (note: default on assumption this script lives in "lib/tf")
  #
  [ -z "${BASEDIR}" ] && BASEDIR=$GITHUB_WORKSPACE
  [ -z "${BASEDIR}" ] && BASEDIR=$BITBUCKET_CLONE_DIR
  [ -z "${BASEDIR}" ] && BASEDIR="$(realpath ${BINDIR}/../..)"

  [ -z "${TFMAIN}" -a -d tfmain ] && TFMAIN=tfmain
  [ -z "${TFMAIN}" ] && TFMAIN=.

  expenv TFMAIN ${TFMAIN}

  ## set 'tenant' parameter which, by convention, is required in many roots
  expenv TF_VAR_tenant ${TENANTKEY}

  ## look for env-specific terraform variable files
  FN="${TFMAIN}/${TENANTKEY}.tfvars"
  if [ -f "$FN" ]; then
    expenv TF_CLI_ARGS_plan "${TF_CLI_ARGS_plan} -var-file=${FN}"
  fi
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
  expenv BITBUCKET_OAUTH_TOKEN="$( curl -s -X POST -u "${K}:${S}" -d 'grant_type=client_credentials' 'https://bitbucket.org/site/oauth2/access_token' | jq -r '.access_token' )"
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

  local fname="${1}"
  local CONFDIR="${2:-../conf}"

  ST_TENANT_ID=$( envenv ST_TENANT_ID )
  [ -z "${ST_TENANT_ID}" ] && ST_TENANT_ID=$(yq '.az_infra_provisioning_tenant_id' < ${CONFDIR}/$TENANTKEY.yaml)

  ST_SUBSCRIPTION_ID=$( envenv ST_SUBSCRIPTION_ID )
  [ -z "${ST_SUBSCRIPTION_ID}" ] && ST_SUBSCRIPTION_ID=$(yq '.az_infra_provisioning_subscription_id' < ${CONFDIR}/$TENANTKEY.yaml)

  ST_RESGROUP_NAME=$( envenv ST_RESGROUP_NAME )
  [ -z "${ST_RESGROUP_NAME}" ] && ST_RESGROUP_NAME=$(yq '.az_infra_provisioning_resource_group' < ${CONFDIR}/$TENANTKEY.yaml)

  ST_ACCOUNT_NAME=$( envenv ST_ACCOUNT_NAME )
  [ -z "${ST_ACCOUNT_NAME}" ] && ST_ACCOUNT_NAME=$(yq '.az_infra_provisioning_storage_account' < ${CONFDIR}/$TENANTKEY.yaml)

  ## container name component defaults to LZ name
  ST_CONTAINER_NAME=$( envenv ST_CONTAINER_NAME )
  if [ -z "${ST_CONTAINER_NAME}" ]; then
    echo "variable ST_CONTAINER_NAME is not set"
    return 1
  fi

  ## key prefix component defaults to LZ name
  ST_KEY_PREFIX=$( envenv ST_KEY_PREFIX )
  [ -z "${ST_KEY_PREFIX}" ] && ST_KEY_PREFIX=0

  if [ -n "${OIDCLOGIN}" ]; then
    _AUTH='use_oidc = true'
  else
    _AUTH='use_azuread_auth = true'
  fi
  #if [ -n "${USEARMVARS}" ]; then
  #  ## Add client_id
  #  _CLIENT_ID="client_id = \"$( envenv AZURE_CLIENT_ID )\""
  #fi

  echo " --setup: constructing azurerm backend configuration file"

  cat > "${fname}" << EOT
tenant_id            = "${ST_TENANT_ID}"
subscription_id      = "${ST_SUBSCRIPTION_ID}"
resource_group_name  = "${ST_RESGROUP_NAME}"
storage_account_name = "${ST_ACCOUNT_NAME}"
container_name       = "${ST_CONTAINER_NAME}"
key                  = "${TFMAIN}/${ST_KEY_PREFIX}-terraform.tfstate"
client_id            = "$( envenv AZURE_CLIENT_ID )"
$_AUTH
EOT
  export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config backend.conf"

  ## show backend conf
  echo '-----Backend conf:'
  cat "${fname}"
  echo '-----'
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


get_oidc_env() {
  if [ -n "${BITBUCKET_STEP_OIDC_TOKEN}" ]; then
    ## check if we have OIDC tokens (doesn't work properly yet in bitbucket)
    expenv _OIDC_REQUEST_TOKEN ${BITBUCKET_STEP_OIDC_TOKEN}
  fi
  if [ -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" ]; then
    expenv _OIDC_REQUEST_TOKEN $ACTIONS_ID_TOKEN_REQUEST_TOKEN
    expenv _OIDC_REQUEST_URL $ACTIONS_ID_TOKEN_REQUEST_URL
  fi
}

prep_azcreds()
{
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
    az account show

  else
    if [ -n "${USEARMVARS}" ]; then
      ## pass ARM credentials in TF environment variables
      expenv TF_VAR_subscription_id $( envenv AZURE_SUBSCRIPTION_ID )
      expenv TF_VAR_client_id $( envenv AZURE_CLIENT_ID )
      expenv TF_VAR_tenant_id $( envenv AZURE_TENANT_ID )
      if [ -z "${OIDCLOGIN}" ]; then
        expenv TF_VAR_client_secret $( envenv AZURE_CLIENT_SECRET )
        expenv TF_VAR_use_oidc false
      else
        unset TF_VAR_client_secret
        get_oidc_env
        expenv TF_VAR_oidc_request_token $_OIDC_REQUEST_TOKEN
        expenv TF_VAR_oidc_request_url $_OIDC_REQUEST_URL
        expenv TF_VAR_use_oidc true

      fi
    else
      ## pass ARM credentials in generic environment variables
      expenv ARM_SUBSCRIPTION_ID $( envenv AZURE_SUBSCRIPTION_ID )
      expenv ARM_CLIENT_ID $( envenv AZURE_CLIENT_ID )
      expenv ARM_TENANT_ID $( envenv AZURE_TENANT_ID )
      if [ -z "${OIDCLOGIN}" ]; then
        expenv ARM_CLIENT_SECRET $( envenv AZURE_CLIENT_SECRET )
        expenv ARM_USE_OIDC false
      else
        unset ARM_CLIENT_SECRET
        get_oidc_env
        expenv ARM_OIDC_REQUEST_TOKEN $_OIDC_REQUEST_TOKEN
        expenv ARM_OIDC_REQUEST_URL $_OIDC_REQUEST_URL
        expenv ARM_USE_OIDC true

      fi
    fi
  fi
}
