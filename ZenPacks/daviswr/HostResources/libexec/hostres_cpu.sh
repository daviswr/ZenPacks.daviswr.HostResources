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
CPU_COUNT=0
CPU_TOTAL=0
hrProcessorLoad=".1.3.6.1.2.1.25.3.3.1.2"

for PER_CPU in `snmpwalk -On -c${COMMUNITY} ${HOST} ${hrProcessorLoad} \
    2>/dev/null | grep -v No\ Such | awk '{print $4}'`
do
    if [ -n "${PER_CPU}" ]; then
        CPU_COUNT=$((${CPU_COUNT} + 1))
        CPU_TOTAL=$((${CPU_TOTAL} + ${PER_CPU}))
    fi
done

if [ ${CPU_COUNT} -gt 0 ]; then
    CPU_LOAD=$((${CPU_TOTAL} / ${CPU_COUNT}))
    echo "CPU|load=${CPU_LOAD} count=${CPU_COUNT}"
else
    exit 1
fi
