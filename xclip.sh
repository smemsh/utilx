#!/usr/bin/env bash
#
# xclipp, xclips, xclipc
#   originally were shell aliases, but needed in other programs/users
#
# scott@smemsh.net
# https://github.com/smemsh/utilx/
# https://spdx.org/licenses/GPL-2.0
#
declare -A selections=(p primary s secondary c clipboard)
perl -pe 's/[\x20\t]+$//; chomp if eof' \
| xclip -selection ${selections[${0: -1}]} "$@"
