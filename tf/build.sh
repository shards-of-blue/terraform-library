#!/bin/sh

BINDIR=$(dirname $0)

## parse arguments
while [ $# -gt 0 ]; do
  case $1 in
    -v) verbose=1; shift;;
    -env) ENV="$2"; shift 2;;
    -main) TFMAIN="$2"; shift 2;;
    -mode) TFMODE="$2"; shift 2;;
    -*) echo "Unknown option $1"; shift;;
     *) break;;
  esac
done

. ${BINDIR}/setup.sh

[ -n "${TFMAIN}" ] && GLOBALOPTS="-chdir=${TFMAIN}"
[ -n "${TF_BACKEND_CONF}" ] && BEVAR="-backend-config=$(basename ${TF_BACKEND_CONF})"

terraform $GOPTS init ${BEVAR} || exit 2

case "${TFMODE}" in
  validate)
    terraform $GLOBALOPTS validate || exit 3 ;;
  plan)
    env|grep TF
    terraform $GLOBALOPTS validate || exit 3
    terraform $GLOBALOPTS plan -out=plan -input=false ;;
  apply)
    terraform $GLOBALOPTS apply plan -input=false ;;
  *)
    echo "Unknown mode '${TFMODE}'"; exit 11 ;;
esac

