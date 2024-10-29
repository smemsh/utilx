#!/bin/bash
#
# xtty.sh: xttytty, xttypid, xttyx
#   switches x11 window to that of pid or tty $1, or to x11 vt if not in x11
#
# deps:
#   - wmctrl
#
# todo:
#   - we don't seem to switch the rpwm group or properly select window
#
# scott@smemsh.net
# https://github.com/smemsh/utilx/
# http://spdx.org/license/GPL-2.0
#
##############################################################################

bomb () { echo ${FUNCNAME[1]}: ${@}, aborting; exit 1; }

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

#
#   one-arg: all variables of pid $1 in var=val
# multi-arg: only specified env $2..$n of pid $1 in var=val
#
# todo: trailing '=' on variables gets just value (in exe wrapper?)
# todo: envd so we get unexported variables, possibly functions
#
pidenv ()
{
	local pid=$1; shift
	local envfile=/proc/$pid/environ
	local varval var val v

	test -r $envfile || exit 1

	if (($# == 0)); then
		# one arg case
		tr '\0' '\n' < $envfile
	else
		# multi-arg case
		while read -rsd $'\0' varval; do
			var=${varval%=*}; val=${varval#*=}
			for v; do [[ $v == $var ]] && echo "$var=$val"; done
		done < $envfile
	fi
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

	psarg="$1"
	userarg="$2"
	pidarg=`getpid $psarg $userarg`

	display=`pidenv $pidarg DISPLAY`
	idvar=`pidenv $pidarg WINDOWID`
	idnum=${idvar#*=} || bomb "pidenv(): malformed output"
	eval $display wmctrl -ia $idnum || bomb "wmctrl"
}

###

main ()
{
	local invname=$1 userarg=$2; shift
	local invlast3=${invname: -3:3}

	(($# == 1)) ||
		bomb "takes single pid or tty argument"

	if [[ $invname == 'xttyx' ]]; then [[ $DISPLAY ]] || xttyx
	elif [[ $invname =~ ^xtty(tty|pid)$ ]]; then xtty $invlast3 $userarg
	else echo "unimplemented invname '$invname'"; exit 1; fi
}

main ${0##*/} "$@"
