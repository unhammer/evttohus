#!/bin/bash

# Run several anymalign's in parallel, then merge the results. Kill
# the script when you think you've got good enough alignments.

# Creates temporary files called tmp.alignments.[0-9]*

set -e -u

tmp=$(mktemp -d -t evttohus.XXXXXXXXXX)
mkfifo "${tmp}"/stop_aligning

cat >&2 <<EOF

When you think you've got good enough alignments, open another
terminal and do:

    echo > "${tmp}/stop_aligning"

EOF

declare -i cpus=1
if type nproc &>/dev/null; then
    cpus=$(nproc)
elif sysctlcpus=$(sysctl -n hw.ncpu 2>/dev/null) && [[ -n $sysctlcpus ]]; then
    cpus=$(sysctl -n hw.ncpu)
fi

declare -a procs
declare -i i=0

echo "Starting ${cpus} anymalign processes ..." >&2
while (( i++ < cpus )); do
    python2 anymalign/anymalign.py "$@" > tmp.alignments.$i &
    procs[$i]=$!
done

exit_and_merge () {
    local -i i=0
    while (( i++ < cpus )); do
        # Important: send INT (Ctrl+C), so the script gets a chance to
        # clean up
        echo "Interrupting ${procs[$i]}" >&2
        kill -s INT ${procs[$i]}
    done
    wait
    python2 anymalign/anymalign.py -m tmp.alignments.*
    rm -rf "${tmp}"
}

trap exit_and_merge INT TERM

read < "${tmp}"/stop_aligning
exit_and_merge
