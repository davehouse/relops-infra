#!/usr/bin/env bash

hostname_prefix="t-linux64-ms-"
workerType="gecko-t-linux-talos"

for c in {1..14}; do
    dc=$(( c / 8 + 1 ))
    nstart=$(( (c - 1) * 45 ))
    if (( dc > 1 )); then
        # The last chassis in mdc1 has only 30 cartridges installed
        # but we continued numbering from 300
        nstart=$(( nstart - 15 ))
        # Do not touch the last chassis mdc2. It is for testing.
        if (( c == 14 )); then
            continue
        fi
    fi
    #echo $dc": "$c" "$nstart >&2
    # For linux, we are using the first 15 on each chassis.
    for i in {1..15}; do
        I=$(( nstart + i ))
        if ! (( c % 7 )) && (( i > 10 )); then
            break
        fi
        hostname=${hostname_prefix}$(printf "%03g" "${I}")".test.releng.mdc${dc}.mozilla.com"
        echo $hostname
    done
done
