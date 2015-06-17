#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
src=(     itet      i     og      é      e      et      ek     ol     em     om    ør  ie )
trg=( itiehtta  iddja  åvggå  iedja  iedja  iehtta  iehkka  åvllå  iebma  åvmmå  erra  ij )
pos=(        N      N      N      N      N       N       N      N      N      N     N   N )

loans nob smj "$1"
