#!/usr/bin/env sh

while read line; do
    if grep -q "PASSWORD" <<< $line; then
        read user password <<< $(sed "s/PASSWORD \(\w\+\) = \(\w\+\)/\1 \2/" <<< $line)
        echo ${password} > .passwords/${user}
    fi
done
