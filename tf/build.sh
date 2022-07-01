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

## setup default TF variables
export TF_INPUT=0
export TF_IN_AUTOMATION=1

. ${BINDIR}/setup.sh


[ -n "${TFMAIN}" ] && GLOBALOPTS="-chdir=${TFMAIN}"

terraform $GLOBALOPTS init || exit 2

case "${TFMODE}" in
  validate)
    terraform $GLOBALOPTS validate || exit 3 ;;
  plan)
    terraform $GLOBALOPTS validate || exit 3
    terraform $GLOBALOPTS plan -out=plan ;;
  apply)
    terraform $GLOBALOPTS apply plan ;;
  *)
    echo "Unknown mode '${TFMODE}'"; exit 11 ;;
esac

