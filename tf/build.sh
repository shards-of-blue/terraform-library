#!/bin/sh

BINDIR=$(dirname $0)

## parse arguments
while [ $# -gt 0 ]; do
  case $1 in
    -v) verbose=1; shift;;
    -env) ENV="$2"; shift 2;;
    -tfdir) TFDIR="$2"; shift 2;;
    -*) echo "Unknown option $1"; shift;;
     *) break;;
  esac
done

[ -n "${TFDIR}" ] || TFDIR=infra

. ${BINDIR}/setup.sh

[ -n "$TF_BACKEND_CONF" ] && BEVAR="-backend-config=${TF_BACKEND_CONF}"

cd $TFDIR
terraform init ${BEVAR} || exit 2
terraform validate || exit 3
terraform plan -out=plan

