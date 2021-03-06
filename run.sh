#!/bin/sh

set -eu

#set the max memory
BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*${BYTES_PER_MEG}))

DEFAULT_MIN=$((64 * $BYTES_PER_MEG)) #This is a guess
regex='^([[:digit:]]+)([GgMm])?i?$'
num_regex='^[[:digit:]]+'
unit_regex='[GgMm]'

export NODE_OPTIONS=""

if [ 1 -eq $(echo "${OCP_AUTH_PROXY_MEMORY_LIMIT:-}" | grep -Ec $regex) ] ; then
    num=$(echo ${OCP_AUTH_PROXY_MEMORY_LIMIT} | grep -oE $num_regex)
    unit=$(echo ${OCP_AUTH_PROXY_MEMORY_LIMIT} | grep -oE $unit_regex || echo "")

    if [ "$unit" = "G" ] || [ "$unit" = "g" ]; then
        ((num = num * ${BYTES_PER_GIG})) # enables math to work out for odd Gi
    elif [ "$unit" = "M" ]  || [ "$unit" = "m" ]; then
        ((num = num * ${BYTES_PER_MEG})) # enables math to work out for odd Gi
    #else assume bytes
    fi

    if [ $num -lt $DEFAULT_MIN ] ; then
        echo "$num is less than the default $(($DEFAULT_MIN / $BYTES_PER_MEG))m.  Setting to default."
        num=$DEFAULT_MIN
    fi

    export NODE_OPTIONS="--max-old-space-size=$((num / ${BYTES_PER_MEG}))"

else
    echo "Unable to process the OCP_AUTH_PROXY_MEMORY_LIMIT: '${OCP_AUTH_PROXY_MEMORY_LIMIT}'."
    echo "It must be a number, optionally followed by 'G'(Gigabytes) or 'M' (Megabytes), e.g. 64M"
    exit 1
fi

cd ${APP_DIR}
echo "Using NODE_OPTIONS: '$NODE_OPTIONS' Memory setting is in MB"
echo "Running from directory: '$(pwd)'"

exec node ${NODE_OPTIONS} /usr/local/bin/npm start
