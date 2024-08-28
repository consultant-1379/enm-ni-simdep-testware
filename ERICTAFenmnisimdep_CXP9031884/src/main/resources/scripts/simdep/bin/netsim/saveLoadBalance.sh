#!/bin/sh

MML="save_MML.mml"
cat >> ${MML} << ABC
.select configuration
.config save
ABC

/netsim/inst/netsim_shell < ${MML}
