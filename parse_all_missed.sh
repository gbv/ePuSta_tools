#!/bin/bash

source .config

source ~/.profile

for filename in $ACCESSLOGDIR/*; do
    if [ -f $filename ]; then
        #basename="$(basename $filename .log)";
        #destfile=$basename.epusta.log
        if [ ${filename: -3} == ".gz" ]; then
            basename="$(basename $filename .log.gz)";
            filename2=${filename: 0 : -3};
        elif [ ${filename: -4} == ".log" ]; then
            basename="$(basename $filename .log)";
            filename2=$filename;
        else
            echo "Error: Wrong Filenamepatern - skip processing."
        fi
        destfile=$basename.epusta.log;
        destfile2=$basename.epusta.log.gz;
        if [ ! -f "$EPUSTALOGDIR/$destfile" ] && [ ! -f "$EPUSTALOGDIR/$destfile2" ]; then
            echo "Processing: $filename -> $destfile"
            if [ -f "$EPUSTALOGDIR/$destfile2" ]; then rm $EPUSTALOGDIR/$destfile2; fi 
            if [ ${filename: -3} == ".gz" ]; then gzip -d $filename; fi
            cat $filename2 | log2epusta.php | addIdentifierMIR.php | filter.php > $EPUSTALOGDIR/$destfile
            if [ ${filename: -3} == ".gz" ]; then gzip $filename2; fi
        else
            echo "$filename allready parsed."
        fi
    fi
done

