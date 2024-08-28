#!/bin/bash

fileName="simdep.tar.gz"

echo "..upload $fileName starting"

cd ../..;  touch $fileName
( rm -v $fileName ) || { printf 'File does not exist or is not a regular file: %s\n' "$fileName" >&2; exit 1; }

( tar -cvzf $fileName simdep ) || { printf 'File does not exist or is not a regular file: %s\n' "$fileName" >&2; exit 1; }

( /usr/bin/curl -u simadmin:simadmin -T $fileName ftp://ftp.athtem.eei.ericsson.se/TEP/qfatonu/download/ ) \
  ||  { printf 'File does not exist or is not a regular file: %s\n' "$fileName" >&2; exit 1; }
#echo "dolarQM=$?"

echo "..upload $fileName ended!"
