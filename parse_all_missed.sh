#!/bin/bash

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTDIR/config"
source ~/.profile

for filename in "$ACCESSLOGDIR"/*; do
    if [ -f "$filename" ]; then
        if [[ "$filename" == *.gz ]]; then
            basename="$(basename "$filename" .log.gz)"
        elif [[ "$filename" == *.log ]]; then
            basename="$(basename "$filename" .log)"
        else
            echo "Error: Wrong filename pattern - skip processing."
            continue
        fi
        destfile="$basename.epusta.log"
        destfile2="$basename.epusta.log.gz"
        if [ ! -f "$EPUSTALOGDIR/$destfile" ] && [ ! -f "$EPUSTALOGDIR/$destfile2" ]; then
            echo "Processing: $filename -> $destfile"
            if [[ "$filename" == *.gz ]]; then
                zcat "$filename" | log2epusta.php | addIdentifierMIR.php | filter.php > "$EPUSTALOGDIR/$destfile"
            else
                cat "$filename" | log2epusta.php | addIdentifierMIR.php | filter.php > "$EPUSTALOGDIR/$destfile"
            fi
        else
            echo "$filename already parsed."
        fi
    fi
done
