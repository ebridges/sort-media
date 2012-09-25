#!/bin/bash

dirs=$@
output=/var/local/db/${USER}/incoming.mf


if [ -z "${dirs}" ];
then
    echo "usage: $0 [folders to query]";
    exit
fi

find ${dirs} -iname '*.jpg' -o -iname '*.jpeg' >> ${output}
