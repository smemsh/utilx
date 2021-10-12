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

if ! for dir in /sys/class/backlight/{acpi_video0,intel_backlight}
do test -d $dir && break; done
then echo "only support acpi, intel sysfiles" >&2; false; exit
fi

ctldir=$dir
ctlfile=$ctldir/brightness
ctlnow=$ctldir/actual_brightness
ctlmax=$ctldir/max_brightness
brightnow=$(<$ctlnow)

adjust=$((brightnow / 10))
((adjust == 0)) && adjust=1

bright ()
{
	if (($# == 0)); then
		echo $brightnow%

	elif (($# != 1)); then
		echo "only 0 or 1 arg supported"; false

	elif [[ $1 == 'up' ]]; then
		echo $(($brightnow + adjust)) > $ctlfile

	elif [[ $1 == 'down' ]]; then
		echo $(($brightnow - adjust)) > $ctlfile

	elif [[ $1 == 'max' ]]; then
		echo $(< $ctlmax) > $ctlfile

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
