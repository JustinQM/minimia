#!/bin/bash

printf "miniMIA Install Scipt V0.1.0\n\n"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

source ./phase0.sh

source ./phase1.sh
