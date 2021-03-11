#!/bin/bash

folder=$1
a="$(lsof +d "${folder}")"

if [[ "${#a}" -gt 0 ]] 
then
    echo "${folder} IN used"
else
    echo "${folder} NOT in used"
fi
