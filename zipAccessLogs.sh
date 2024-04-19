#!/bin/bash

ACCESSLOGDIR=/mcr/clausthal/epusta/accesslogs/

gzip $ACCESSLOGDIR/*.log
