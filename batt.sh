#!/bin/bash
#
# batt.sh: batt, hibernate, suspend
#   simple power management
#
# desc:
#   - batt: how much battery is left (acpi is useless on X61s)
#   - hibernate: hibernates machine after optionally invoking afk
#   - suspend: suspends machine after optionally invoking afk
#
# scott@smemsh.net
# http://smemsh.net/src/ratutils/
# http://spdx.org/licenses/GPL-2.0
#
##############################################################################

set -e

invname=${0##*/}

###

maybe_go_afk ()
{
	if [[ $(type afk &>/dev/null) ]]
	then read -sn 1 -p "go afk first (y/n/a)? "
	else return; fi

	[[ $REPLY == y ]] && { echo "going afk first"; afk; return 0; }
	[[ $REPLY == n ]] && { echo "not going afk first"; return 0; }
	[[ $REPLY == a ]] && { echo "aborted"; exit 1; }

	echo no such reply
	exit 4
}

display_battery_status ()
{
	# these utils don't seem to work or be available flags
	#acpitool -b
	#acpitool -B

	export BC_ENV_ARGS='-ql'

	cd /sys/class/power_supply/BAT0

	# strangely the filename differs amongst intel boards
	#
	for pfx in energy charge; do test -f ${pfx}_now && break; done
	batt=$(echo "scale = 30; ($(<${pfx}_now)/$(<${pfx}_full)) * 100" | bc)
	batt=${batt%.*}
	[[ $(<status) == Full ]] && batt=100
	echo "$batt%"
}

###

main ()
{
	if ((`id -u` == 0)); then
		echo do not run as root
		exit 1
	fi

	case $invname in

	(hibernate)	which=hibernate;;
	(suspend)	which=suspend;;
	(battery|batt)	display_battery_status;				exit;;
	(*)		echo "$invname: unimplemented"; false;		exit;;

	esac

	maybe_go_afk && echo
	printf "%s""ing..." ${which%e} # hibernateing -> hibernating
	pm-$which
	echo back
}

main "$@"
