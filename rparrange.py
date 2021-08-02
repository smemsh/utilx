#!/usr/bin/env python3
"""
 rparrange.py: rpleft, rpright, rprenumber
   rearrange ratpoison window offsets (incr, decr, make sequential)

   - intended to be bound to ratpoison keys using definekey ... exec
   - rprenumber: rearrange ratpoison window numbers sequentially
   - rpleft: decrement current window's position on window list
   - rpright: increment current window's position on window list
"""

__url__     = 'http://smemsh.net/src/utilpy/'
__author__  = 'Scott Mcdermott <scott@smemsh.net>'
__license__ = 'GPL-2.0'

from sys import argv, stdin, stdout, stderr, exit
from re import match
from subprocess import check_output

from os.path import basename
from os import (
    environ,
    EX_OK as EXIT_SUCCESS,
    EX_SOFTWARE as EXIT_FAILURE,
)

###

windows = []
revwins = []
curwin = 0
curidx = 0

###

def err(*args, **kwargs):
    print(*args, file=stderr, **kwargs)

def bomb(*args):
    err(*args)
    exit(EXIT_FAILURE)

###

def rp(cmd):
    return check_output(['ratpoison', '-c', cmd], text=True)

###

def rpleft():

    if curwin == windows[0]:
        target = windows[-1] + 1
    else:
        target = windows[curidx - 1]

    rp(f"number {target}")


def rpright():

    if curwin == windows[-1]:
        if windows[0] == 0:
            for i in range(len(windows) - 1, -1, -1):
                print(f"rp number {windows[i]+1} {windows[i]}")
        target = 0
    else:
        target = windows[curidx + 1]

    rp(f"number {target}")

###

def main():

    global windows, revwins, curwin, curidx

    windows = [int(x) for x in rp('windows %n').splitlines()]
    revwins = {windows[i]:i for i in range(len(windows))}
    curwin = int(match(r'\(\d+,\s+\d+\)\s+(\d+)', rp('info')).group(1))
    curidx = revwins[curwin]

    try: subprogram = globals()[invname]
    except (KeyError, TypeError):
        bomb(f"unimplemented command '{invname}'")

    return subprogram()

###

if __name__ == "__main__":

    from sys import version_info as pyv
    if pyv.major < 3 or pyv.major == 3 and pyv.minor < 9:
        bomb("minimum python 3.9")

    invname = basename(argv[0])
    args = argv[1:]

    try:
        if bool(environ['DEBUG']):
            from pprint import pprint as pp
            debug = True
            err('debug-mode-enabled')
        else:
            raise KeyError

    except KeyError:
        debug = False

    if debug: breakpoint()

    main()
