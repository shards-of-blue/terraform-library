#!/bin/bash

LOCATION='westeurope'
MODE='deployment'
SCOPE='group'

while [ $# -gt 0 ]; do
  case $1 in
    -v) verbose=1; shift;;
    -p) PARAMETERS="$2"; shift 2;;
    -L) LOCATION="$2"; shift 2;;
    -G) RESGROUP="$2"; shift 2;;
    -B) MODE=build; shift;;
    -S) SCOPE="$2"; shift 2;;
    -*) echo "Unknown option $1"; shift;;
     *) break;;
  esac
done

BINDIR=$(dirname $0)
BASEDIR="$(realpath ${BINDIR}/..)"

TEMPLATE="${BASEDIR}/profile/${1}"
JSONPARMS="/tmp/$(basename ${PARAMETERS}).json"

$BINDIR/yaml2json ${PARAMETERS} > $JSONPARMS

if [[ $MODE == 'build' ]]; then
  az bicep build --file "${TEMPLATE}"
fi

if [[ $MODE == 'deployment' ]]; then
  case $SCOPE in
    group)
      az deployment group create --resource-group ${RESGROUP} --template-file "${TEMPLATE}" --parameters ${JSONPARMS}
      ;;
    sub)
      az deployment sub create -l ${LOCATION} --template-file "${TEMPLATE}" --parameters ${JSONPARMS}
      ;;
    tenant)
      az deployment tenant create -l ${LOCATION} --template-file "${TEMPLATE}" --parameters ${JSONPARMS}
      ;;
    management)
      az deployment management create -l ${LOCATION} --template-file "${TEMPLATE}" --parameters ${JSONPARMS}
      ;;
  esac
fi

