#!/bin/bash

filename=$1

if [ ! -f $filename ]; then
    echo "File not found!"
    exit
fi

basename="$(basename $filename .log)";
destfile=$filename.tmp
echo "Processing: $filename -> $destfile"
grep -v /servlets/MCRLoginServlet $filename > $destfile
mv $destfile $filename

