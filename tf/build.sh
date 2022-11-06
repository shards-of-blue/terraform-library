#!/bin/sh

BINDIR=$(dirname $0)

# setup default tenant
TENANTKEY=${DEFAULT_TENANTKEY:-live}
AZCONFDIR='../conf'

## parse arguments
while [ $# -gt 0 ]; do
  case $1 in
    -v) verbose=1; shift;;
    -tenantkey) TENANTKEY="$2"; shift 2;;
    -main) TFMAIN="$2"; shift 2;;
    -mode) TFMODE="$2"; shift 2;;
    -storekey) ST_KEY_PREFIX="$2"; shift 2;;
    -storecontainer) ST_CONTAINER_NAME="$2"; shift 2;;
    -azconfdir) AZCONFDIR="$2"; shift 2;;
    -azclilogin) AZCLILOGIN="1"; shift;;
    -azadlogin) AZADLOGIN="1"; shift;;
    -oidclogin) OIDCLOGIN="1"; shift;;
    -usearmvars) USEARMVARS="1"; shift;;
    -*) echo "Unknown option $1"; shift;;
     *) break;;
  esac
done

## default az login is OIDC
[ -z "${AZCLILOGIN}" -a -z "${AZADLOGIN}" -a -z "${OIDCLOGIN}" ] && OIDCLOGIN=1

echo "build: TFMODE=${TFMODE} TFMAIN=${TFMAIN} ST_KEY_PREFIX=${ST_KEY_PREFIX} TENANTKEY=${TENANTKEY} AZCLILOGIN=${AZCLILOGIN}"


. ${BINDIR}/setup.sh

env_init .runtime.env
ghtf_token_setup
prep_azcreds
aztf_backend_conf "${TFMAIN}/backend.conf" "${AZCONFDIR}" || exit 6

source .runtime.env


## collect any repo-defined settings
[ -f ./.pipeline.vars ] && . ./.pipeline.vars
[ -f ./tfsettings ] && . ./tfsettings
[ -f "${TFMAIN}/tfsettings" ] && . "${TFMAIN}/tfsettings"

[ -n "${TFMAIN}" ] && GLOBALOPTS="-chdir=${TFMAIN}"

echo 'build: TF environment:'
env | grep TF_
echo '-----'

terraform $GLOBALOPTS init || exit 2

case "${TFMODE}" in
  validate)
    terraform $GLOBALOPTS validate || exit 3 ;;
  plan)
    terraform $GLOBALOPTS validate || exit 3
    terraform $GLOBALOPTS plan -out=plan ;;
  destroy)
    terraform $GLOBALOPTS plan -out=plan -destroy ;;
  apply)
    terraform $GLOBALOPTS apply plan || exit 4 ;;
  *)
    echo "Unknown mode '${TFMODE}'"; exit 11 ;;
esac

