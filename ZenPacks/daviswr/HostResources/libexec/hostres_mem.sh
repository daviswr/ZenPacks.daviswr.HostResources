#!/usr/bin/env bash
set -o errexit
set -o nounset

# Parens splits on $IFS and returns an array
ARGS=(${@});
if [ "${ARGS[$((${#} - 1))]}" == "debug" ]; then
    set -o xtrace
fi

HOST=${1}
COMMUNITY=${2}
TEMP="/tmp"
FILE="${TEMP}/hostres-${HOST}"
PHYS_SIZE=0
PHYS_USED=0
PHYS_FREE=0
SWAP_SIZE=0
SWAP_USED=0
PHYS_FREE=0
hrStorageEntry=".1.3.6.1.2.1.25.2.3.1"
hrStorageDescr=".1.3.6.1.2.1.25.2.3.1.3"
hrStorageAllocationUnits=".1.3.6.1.2.1.25.2.3.1.4"
hrStorageSize=".1.3.6.1.2.1.25.2.3.1.5"
hrStorageUsed=".1.3.6.1.2.1.25.2.3.1.6"

snmpwalk -On -c${COMMUNITY} ${HOST} ${hrStorageEntry} 1> ${FILE} 2>/dev/null

# Indexes will have a trailing space, this is a good thing
# grep exit code is 1 if it doesn't match any lines
PHYS_INDEX=`grep Physical ${FILE} | cut -d\= -f1 | cut -d\. -f 13` || true
REAL_INDEX=`grep Real ${FILE} | cut -d\= -f1 | cut -d\. -f 13` || true
SWAP_INDEX=`grep Swap ${FILE} | cut -d\= -f1| cut -d\. -f 13` || true
VIRT_INDEX=`grep Virtual ${FILE} | cut -d\= -f1| cut -d\. -f 13` || true

# If Real index exists and Physical does not, use Real
if [ -z "${PHYS_INDEX}" -a -n "${REAL_INDEX}" ]; then
    PHYS_INDEX=${REAL_INDEX}
fi

# If Virtual index exists and Swap does not, use Virtual
if [ -z "${SWAP_INDEX}" -a -n "${VIRT_INDEX}" ]; then
    SWAP_INDEX=${VIRT_INDEX}
fi

# Exit if there's nothing for which to grep
if [ -z "${PHYS_INDEX}" -a -z "${SWAP_INDEX}" ]; then
    exit 1
fi

# Physical memory utilization
if [ -n "${PHYS_INDEX}" ]; then
    PHYS_BLOCK=`grep "${hrStorageAllocationUnits}.${PHYS_INDEX}" ${FILE} \
        | awk '{print $4}'` || PHYS_BLOCK=1
    PHYS_SIZE=$((`grep "${hrStorageSize}.${PHYS_INDEX}" ${FILE} \
        | awk '{print $4}'` * ${PHYS_BLOCK})) || PHYS_SIZE=0
    PHYS_USED=$((`grep "${hrStorageUsed}.${PHYS_INDEX}" ${FILE} \
        | awk '{print $4}'` * ${PHYS_BLOCK})) || PHYS_USED=0
    if [ "${PHYS_SIZE}" -gt "${PHYS_USED}" ]; then
        PHYS_FREE=$((${PHYS_SIZE} - ${PHYS_USED}))
    fi
fi

# Swap utilization
if [ -n "${SWAP_INDEX}" ]; then
    SWAP_BLOCK=`grep "${hrStorageAllocationUnits}.${SWAP_INDEX}" ${FILE} \
        | awk '{print $4}'` || SWAP_BLOCK=1
    SWAP_SIZE=$((`grep "${hrStorageSize}.${SWAP_INDEX}" ${FILE} \
        | awk '{print $4}'` * ${SWAP_BLOCK})) || SWAP_SIZE=0
    SWAP_USED=$((`grep "${hrStorageUsed}.${SWAP_INDEX}" ${FILE} \
        | awk '{print $4}'` * ${SWAP_BLOCK})) || SWAP_USED=0
    if [ "${SWAP_SIZE}" -gt "${SWAP_USED}" ]; then
        SWAP_FREE=$((${SWAP_SIZE} - ${SWAP_USED}))
    fi
fi

echo "RAM|physSize=${PHYS_SIZE} physUsed=${PHYS_USED} physFree=${PHYS_FREE}" \
    "swapSize=${SWAP_SIZE} swapUsed=${SWAP_USED} swapFree=${SWAP_FREE}"
