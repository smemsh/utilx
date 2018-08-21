#!/usr/bin/env bash
#
# x.sh: x, x2
#   starts x11 with ratpoison (x) or a nested one with xephyr+jwm (x2)
#
# todo:
#   - if [[ $DISPLAY ]] x2; else x; fi
#   - x3 .. xN
#
# scott@smemsh.net
# http://smemsh.net/src/ratutils/
# http://spdx.org/licenses/GPL-2.0
#
##############################################################################

XRC=~/.xrc

declare -a \
serveropts=(
	-nolisten tcp
)

# use invocation name to see if base (x) or nested xserver
# todo: this information could come from whether we're already
#   in X based on $DISPLAY
#
set_which_server ()
{
	case $1 in

	(x)

	xsrvr=X	# debian 20151011, was migrated to xserver-xorg-legacy
	#xsrvr=/usr/lib/xorg/Xorg.wrap
	#serveropts+=(-dpi 96)	# correct for gateway fpd1760 17" 1280x1024
	serveropts+=(-dpi ${XRC_DPI:-106})	# correct for thinkpad x61s 11.3" 1024x768
	serveropts+=(-keeptty -novtswitch)

	srcdp=0
	dstdp=0
	vtnum=2
	vtarg=vt$vtnum
	wmarg=rpwm
	;;

	(x2)

	# we use this to run a nested X server
	xsrvr=Xephyr
	serveropts+=(-dpi ${XRC_DPI:-106} -screen ${XRC_HRES:-1024}x${XRC_YRES:-768})
	srcdp=0
	dstdp=1
	wmarg=jwm
	;;

	(*)

	echo "bad invocation: '$1'"
	;;

	esac
}

start_xserver ()
{
	color=black

	# runs the X server, which is sometimes nested (x2)
	#
	export DISPLAY=:$srcdp
	if ! daemonize "$xsrvr :$dstdp $vtarg ${serveropts[*]}" $xsrvr
	then exit 10; fi

	# get server up before spawning its window manager
	#
	export DISPLAY=:$dstdp
	for ((i = 0; i < 5; i++)); do
		sleep 0.2; xsetroot -name root && break; echo; done

	# if we failed xsetroot, the server did not finish start
	#
	if (($? > 0)); then exit 15; fi
}

start_window_manager ()
{
	export DISPLAY=:$dstdp
	daemonize $wmarg $wmarg || exit 20
}

main ()
{
	invname=${0##*/}

	test -r $XRC && source $XRC

	set_which_server $invname
	start_xserver
	start_window_manager
}

main "$@"
