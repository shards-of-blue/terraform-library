#!/bin/sh

BINDIR=$(dirname $0)

# setup default tenant
TENANTKEY=${DEFAULT_TENANTKEY:-live}

## parse arguments
while [ $# -gt 0 ]; do
  case $1 in
    -v) verbose=1; shift;;
    -tenantkey) TENANTKEY="$2"; shift 2;;
    -main) TFMAIN="$2"; shift 2;;
    -mode) TFMODE="$2"; shift 2;;
    -storekey) ST_KEY_PREFIX="$2"; shift 2;;
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


## setup default TF variables
export TF_INPUT=0
export TF_IN_AUTOMATION=1

. ${BINDIR}/setup.sh


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

