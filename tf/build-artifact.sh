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
    -storekey) ST_KEY_PREFIX="$2"; shift 2;;
    -storecontainer) ST_CONTAINER_NAME="$2"; shift 2;;
    -usearmvars) USEARMVARS="1"; shift;;
    -artifactdir) ARTIFACTDIR="$2"; shift 2;;
    -azconfdir) AZCONFDIR="$2"; shift 2;;
    -*) echo "Unknown option $1"; shift;;
     *) break;;
  esac
done

. ${BINDIR}/setup.sh

[ -d "${ARTIFACTDIR}" ] || exit 5

env_init "${ARTIFACTDIR}/runtime.env"

aztf_backend_conf "${ARTIFACTDIR}/backend.conf" "${AZCONFDIR}" || exit 6

