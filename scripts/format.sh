#!/bin/bash

MB=1024
GB=1048576

UNFORMATTED=$1

if (( $UNFORMATTED % $GB == 0 )); then
    FORMATTED=$(( UNFORMATTED / GB ))"GB"
elif (( $UNFORMATTED % $MB == 0 )); then
    FORMATTED=$(( UNFORMATTED / MB ))"MB"
else
    FORMATTED=$UNFORMATTED"kB"
fi

echo $FORMATTED

