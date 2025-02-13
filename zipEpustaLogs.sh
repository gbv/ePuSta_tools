#!/bin/bash

EPUSTADIR=/mcr/clausthal/epusta

EPUSTALOGDIR=$EPUSTADIR/epustalogs/

gzip $EPUSTALOGDIR/*.log
