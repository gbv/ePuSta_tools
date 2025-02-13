#!/bin/bash

source .config

gzip $ACCESSLOGDIR/*.log
