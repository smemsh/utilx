#!/bin/bash
#
# gg.sh: gg, ggw
#   invoke search from command line args using keyboard-friendly browsers
#
# desc:
#   - takes command line args, urlescapes, creates a google search url
#   - brings up text browser with the url based on invocation name:
#   - gg: elinks (curses browser that supports tables)
#   - ggw: vimb (webkit1 browser with keyboard bindings, normal mode)
#
# scott@smemsh.net
# https://github.com/smemsh/utilx/
# https://spdx.org/licenses/GPL-2.0
#
##############################################################################

urlencode ()
{
	local s="$1"

	# todo: surely this is not all of them!
	s=${s// /%20}
	s=${s//\\/%5c}
	s=${s//\`/%60}
	s=${s//\$/%24}
	s=${s//\&/%26}
	s=${s//\"/%22}
	s=${s//\'/%27}
	s=${s//\</%3c}
	s=${s//\>/%3e}

	echo "$s"
}

make_search_url ()
{

	while (($# > 0))
	do
		param="$1"

		# using both a plus and quotes, i.e. +"searchterm"
		# disables as much of word stemming and similar google
		# tricks so we can try to get only what we requested,
		# only if we requested it
		#
		quote='%22'
		minus='%2d'

		# they got rid of plus operator... now quotes on single word
		# perform this function (it's overloaded) but we keep the code
		# here in case some day sanity prevails
		#
		#plus='%2b'
		plus=''

		# pass through capitalized ORs unchanged as google
		# treats them specially
		#
		[[ $param == 'OR' || $invname == 'ww' ]] && unset quote plus
		[[ $param =~ ^- ]] && { plus=$minus; param=${param/-/}; }

		param=`urlencode "$param"`
		search=$search+${plus}${quote}${param}${quote}

		shift
	done

	if [[ $invname == 'ww' ]]
	then sbase="en.wikipedia.org/wiki/Special:Search?search="
	else sbase="www.google.com/search\?hl=all\&${datearg}\&q="
	fi

	search=${search/+/} # ??? why is this here?
}

setgreys ()
{
	# UPDATE need for this workaround turns out to be due to elinks color
	# pallette for 256 colors being darker and elinks had a 16-color config
	# for xterm-256color even though other -256color TERMs used 256 color
	# configs.  so this override not needed -- we just change to 16 color
	# config in elinks -- but we may use it later to remap something else,
	# or for a different reason, so leaving the code intact for now
	#
	return

	# urxvt maps the greys different than xterm and they are very dark
	# which doesn't work well with some applications like elinks.  rather
	# than set the color in those browsers we "whiten" the dark range of
	# grey for rxvt terms, but this is probably best done in urxvt
	# resources actually TODO
	#
	[[ $TERM =~ rxvt ]] || return
	for greycolor in {232..247}
	do
		# https://stackoverflow.com/questions/27159322
		lowestgrey=249
		greynum=$(((lowestgrey - 232) * 10 + 8))
		echo -en "\e]4;$greycolor;#$(
			for ((i = 0; i < 3; i++))
			do printf '%02x' $greynum
			done
		)\e\\"
	done
}

main ()
{
	invname=${0##*/}
	datearg=${invname: -1}
	datearg="tbs=qdr:${datearg:-'a'}"

	case $invname in
	(ggw) defbrowser='vimb' ;;
	(gg) setgreys; defbrowser='elinks' ;;
	(ww) setgreys; defbrowser='elinks' ;;
	(*) echo "unknown invocation name"; false; exit ;;
	esac

	browser=${GGBROWSER:-"$defbrowser"}

	# XXX why? not referenced anywhere
	declare +i URL

	make_search_url "$@"

	eval exec $browser https://$sbase$search
}

main "$@"
