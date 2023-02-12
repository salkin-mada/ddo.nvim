#!/bin/sh
DATA=$(curl --silent "https://ordnet.dk/ddo/ordbog?query=$1")
DETECT_NO_RESULT=$(echo "$DATA" | rg "Der er ingen resultater")
if test -z "$DETECT_NO_RESULT"
then
    echo "$DATA" | htmlq -t '#id-boj'
    echo "$DATA" | htmlq -t '#id-ety'
    echo
    echo "Betydning(er)"
    echo "$DATA" | htmlq -t '#content-betydninger'
    echo "$DATA" | htmlq -t '#content-orddannelser'
else
    echo "$1 findes ikke i ordbogen.."
    ALIKES=$(echo "$DATA" | htmlq -t '#more-alike-list-short')
    if test -n "$ALIKES"
    then
        echo "Måske mente du:"
        echo "$ALIKES"
    fi
fi
