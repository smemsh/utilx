#!/usr/bin/env bash
#
# bright
#   changes the backlight brightness, give N where N is:
#     up                +(max/10)
#     down              -(max/10)
#     max               (max)
#     1-10              (max/10) * N
#     11-100            (max/100) * N
#     100 < N < max/10  invalid
#     max/10 < N < max  (1/max) * N
#
# scott@smemsh.net
# https://smemsh.net/src/utilx/
# https://spdx.org/licenses/GPL-2.0
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
brightmax=$(<$ctlmax)
brightnow=$(<$ctlnow)

adjust=$((brightmax / 10))
if ! ((adjust))
then echo "adjustment via brightmax will fail"; false; exit; fi

bright ()
{
	if (($# == 0)); then
		nowpercent=$(bc -ql <<< "scale=2;(97/100)*100")
		nowpercent=${nowpercent%.*}
		echo $nowpercent%

	elif (($# != 1)); then
		echo "only 0 or 1 arg supported"; false

	elif [[ $1 == 'up' ]]; then
		new=$(($brightnow + adjust))
		if ((new > brightmax)); then new=$brightmax; fi
		echo $new > $ctlfile

	elif [[ $1 == 'down' ]]; then
		new=$(($brightnow - adjust))
		if ((new < 0)); then new=0; fi
		echo $new > $ctlfile

	elif [[ $1 == 'max' ]]; then
		echo $brightmax > $ctlfile

	elif [[ $1 =~ [^[:digit:]] ]]; then
		echo "digits only please"; false

	elif (($1 <= 10)); then
		echo $(($1 * adjust)) > $ctlfile

	elif (($1 <= 100)); then
		echo $(($1 * (adjust / 10))) > $ctlfile

	elif (($1 < adjust)); then
		echo "must give at least 10% if using absolute brightness"

	elif (($1 < brightmax)); then
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
