#!/bin/bash
#
# xtty.sh: xttytty, xttypid, xttyx
#   switches x11 window to that of pid or tty $1, or to x11 vt if not in x11
#
# deps:
#   - http://smemsh.net/src/libsh/
#   - wmctrl
#
# todo:
#   - we don't seem to switch the rpwm group or properly select window
#
# scott@smemsh.net
# http://smemsh.net/src/ratutils/
# http://spdx.org/license/GPL-2.0
#
##############################################################################

source ~/lib/sh/include

require pidenv
require bomb
require get_invocation_name

###

# - use ps --tty or ps --pid depending on $1 to determine
#   if we are looking for the pid of a tty first, or just
#   using the given pid
# - if tty given, just uses first pid running there, since
#   any should do fine, all the same
# - outputs pid
#
getpid ()
{
	local psarg=$1 userarg=$2

	pidarg=($(ps \
		--$psarg $userarg \
		--format pid= \
		2>/dev/null
	))
	if ! [[ $pidarg ]]; then
		echo "could not find ps:$psarg arg:$userarg"; false; exit; fi

	printf $pidarg
}

###

xttyx ()
{
	local xtty=$(ps -C X -o tty=)
	local xtty=${xtty#tty}

	[[ $xtty ]] || exit 1
	((xtty)) || exit 2
	chvt $xtty || exit 3
}

xtty ()
{
	local idvar idnum display
	local psarg userarg pidarg

	(($# == 1)) ||
		bomb "takes single pid or tty argument"

	psarg="$1"
	userarg="$2"
	pidarg=`getpid $psarg $userarg`

	display=`pidenv $pidarg DISPLAY`
	idvar=`pidenv $pidarg WINDOWID
	idnum=${idvar#*=} || bomb "pidenv(): malformed output"
	eval $display wmctrl -ia $idnum || bomb "wmctrl"
}

###

main ()
{
	local invname=$1 userarg=$2; shift
	local invlast3=${invname: -3:3}

	if [[ $invname == 'xttyx' ]]; then [[ $DISPLAY ]] || xttyx
	elif [[ $invname == xtty(tty|pid) ]]; then xtty $invlast3
	else echo "unimplemented invname '$invname'"; exit 1; fi
}

main `get_invocation_name` "$@"
