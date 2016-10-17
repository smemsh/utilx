#!/usr/bin/env bash
#
# bright
#   changes the backlight brightness, give 1-10 or 11-100
#
# scott@smemsh.net
# http://smemsh.net/src/ratutils/
# http://spdx.org/licenses/GPL-2.0
#
##############################################################################

ctldir=/sys/class/backlight/acpi_video0
ctlfile=$ctldir/brightness
ctlnow=$ctldir/actual_brightness
brightnow=$(<$ctlnow)

bright ()
{
	if (($# == 0)); then
		echo $brightnow%

	elif (($# != 1)); then
		echo only 0 or 1 arg supported; false

	elif [[ $1 == 'up' ]]; then
		echo $(($brightnow + 10)) > $ctlfile

	elif [[ $1 == 'down' ]]; then
		echo $(($brightnow - 10)) > $ctlfile

	elif [[ $1 =~ [^[:digit:]] ]]; then
		echo "digits only please"; false

	elif (($1 <= 10)); then
		echo $(($1 * 10)) > $ctlfile

	elif (($1 <= 100)); then
		echo $1 > $ctlfile

	else
		echo "unknown invocation"; false
	fi
}

# for acpid invocation, see /etc/acpi
brightup () { bright up; }
brightdown () { bright down; }

main () { ${0##*/} "$@"; }
main "$@"
