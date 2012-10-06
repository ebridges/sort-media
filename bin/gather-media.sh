#!/bin/bash

user=$1
shift
dirs=$@
output=/var/local/db/${user}/incoming.mf

if [ -z "${dirs}" ];
then
    echo "usage: $0 [folders to query]";
    exit
fi

find ${dirs} -iname '*.jpg' -o -iname '*.jpeg' >> ${output}
