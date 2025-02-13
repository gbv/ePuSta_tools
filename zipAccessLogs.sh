#!/bin/bash

EPUSTADIR=/mcr/clausthal/epusta

ACCESSLOGDIR=$EPUSTADIR/accesslogs/

gzip $ACCESSLOGDIR/*.log
