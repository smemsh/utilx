#!/usr/bin/env bash
#
# x.sh: x, x2, x3, x4, starts different wms running on x11:
#   x: sdorfehs on :0
#   x2: nested xephyr+jwm
#   x3: nested xephyr+qtile
#   x4: sdorfehs on :3
#
# scott@smemsh.net
# https://github.com/smemsh/utilx/
# https://spdx.org/licenses/GPL-2.0
#
##############################################################################

XRC=~/.xrc

declare -a \
serveropts=(
	-nolisten tcp
	-core
)

# use invocation name to see if base (x) or nested xserver
# todo: this information could come from whether we're already
#   in X based on $DISPLAY
#
set_which_server ()
{
	case $1 in

	(x) ###

	xsrvr=X	# debian 20151011, was migrated to xserver-xorg-legacy
	#xsrvr=/usr/lib/xorg/Xorg.wrap
	#serveropts+=(-dpi 96)	# correct for gateway fpd1760 17" 1280x1024
	serveropts+=(-dpi ${XRC_DPI:-106})	# correct for thinkpad x61s 11.3" 1024x768
	serveropts+=(-keeptty -novtswitch -maxclients 2048)

	srcdp=0
	dstdp=0
	vtnum=${XRC_VT:-2}
	vtarg=vt$vtnum
	wmarg=sdorfehs
	;;

	(x2) ###

	# we use this to run a nested X server
	xsrvr=Xephyr
	serveropts+=(
		-dpi ${XRC_DPI:-106}
		-screen $((${XRC_HRES:-1024} - 6))x$((${XRC_YRES:-768} - 6))
		-no-host-grab
	)
	srcdp=0
	dstdp=1
	wmarg=jwm
	;;

	(x3) ###

	# this is for experimenting with qtile
	xsrvr=Xephyr
	serveropts+=(-dpi ${XRC_DPI:-106} -screen ${XRC_HRES:-1024}x${XRC_YRES:-768})
	srcdp=0
	dstdp=2
	wmarg="$HOME/venv/qtile/bin/qtile"
	;;

	(x4) ###

	xsrvr=X
	serveropts+=(-dpi ${XRC_DPI:-106})
	serveropts+=(-keeptty -novtswitch)

	srcdp=3
	dstdp=3
	vtnum=${XRC_VT:-3}
	vtarg=vt$vtnum
	wmarg=sdorfehs
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
	local logname=${wmarg%% *}; logname=${wmarg##*/}
	daemonize "$wmarg" $logname || exit 20
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
