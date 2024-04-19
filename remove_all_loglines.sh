#!/bin/bash

EPUSTADIR=/mcr/clausthal/epusta

ACCESSLOGDIR=$EPUSTADIR/accesslogs/
EPUSTALOGDIR=$EPUSTADIR/epustalogs/

for filename in $ACCESSLOGDIR/*.log; do
    basename="$(basename $filename .log)";
    destfile=$filename.tmp
    echo "Processing: $filename -> $destfile"
    grep -v /servlets/MCRLoginServlet $filename > $destfile
    mv $destfile $filename
done

