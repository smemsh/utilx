#!/bin/bash
#
# rparrange.sh: rpleft, rpright, rprenumber
#   rearrange ratpoison window offsets (incr, decr, make sequential)
#
# desc
#   - intended to be bound to ratpoison keys using definekey ... exec
#   - rprenumber: rearrange ratpoison window numbers sequentially
#   - rpleft: decrement current window's position on window list
#   - rpright: increment current window's position on window list
#
# scott@smemsh.net
# https://github.com/smemsh/utilx/
# https://spdx.org/licenses/GPL-2.0
#
##############################################################################

which=$(basename $0)

rp="ratpoison -c"

# the ratpoison window numbers are not changed when
# intermediary windows die, so they end up with gaps in
# them; establish a mapping between a contiguous sequence
# and the actual ratpoison numbers
#
numbers=($(
	$rp windows |
	awk '{print $3}'
))
nwin=${#numbers[@]}
firstwin=${numbers[0]}
lastwin=${numbers[nwin-1]}

# we need to know which particular mapping represents the
# current window
#
current=$(
	$rp windows |
	grep ^\\\* | awk '{print $3}'
)

# switch about our invocation name from the argument vector
#
case $which in
(rprenumber)
	for ((i = 0; i < $nwin; i++)); do
		old=${numbers[i]}
		target=$i
	done;;

(rpleft)
	if ((current == firstwin)); then
		target=$lastwin
	else
		change=-1
	fi;;

(rpright)
	if ((current == lastwin)); then
		target=$firstwin
	else
		change=1
	fi;;
esac

# if it wasn't either the first or the last, then we need
# further calculation to determine which one to swap with
#
if ! [[ "$target" ]]; then
	for ((i = 0; i < $nwin; i++)); do
		((${numbers[i]} == current)) && break
	done
	target=${numbers[i+change]}
fi

# do the actual swap
#
$rp "number $target $old"
