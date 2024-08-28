#!/bin/sh

rm -rf `find /netsim/inst/cbrs/ -type f -mtime +0 -printf '%p\n' | grep cbrstxexpiretime`