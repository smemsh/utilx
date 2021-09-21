#!/usr/bin/env python3
"""
 rparrange.py: rpleft, rpright, rprenumber, rpafter
   rearrange ratpoison windows (incr, decr, make sequential, insert new)

   - rpleft: decrement current window's position, rotate to bottom if first
   - rpright: increment current window's position, rotate to top if last
   - rpafter: run arg1 with exec, ensuring win number one after current window
   - rprenumber: rearrange ratpoison window numbers sequentially starting at 0
"""

__url__     = 'http://smemsh.net/src/utilpy/'
__author__  = 'Scott Mcdermott <scott@smemsh.net>'
__license__ = 'GPL-2.0'

from sys import argv, stdin, stdout, stderr, exit

from re import match
from fcntl import flock, LOCK_EX
from signal import signal, alarm, SIGALRM, SIG_IGN
from select import select
from random import getrandbits
from subprocess import check_output

from os.path import basename, dirname, expanduser
from os import (
    environ,
    open as osopen, read, write, close,
    O_RDWR,
    EX_OK as EXIT_SUCCESS,
    EX_SOFTWARE as EXIT_FAILURE,
)

###

windows = []
revwins = []
curwin = 0
curidx = 0

RANDBITS = 128
RANDHEXLEN = RANDBITS // 4

FDTIMEOUT = 5

RPWMDIR = expanduser("~/var/rpwm")
TRIGFILE = f"{RPWMDIR}/rpwm.fifo"
LOCKFILE = f"{RPWMDIR}/rpwm.lock"
lockfile = None

###

def err(*args, **kwargs):
    print(*args, file=stderr, **kwargs)

def bomb(*args):
    err(*args)
    exit(EXIT_FAILURE)

def dprint(*args):
    if not debug: return
    err('debug:', *args)

###

def rp(cmd):

    dprint(f"rp '{cmd}'")
    return check_output(['ratpoison', '-c', cmd], text=True)


def acquire_lock():

    global lockfile

    if invname == 'rptrigger':
        return # called by self, avoid deadlock

    def lock_timeout_handler():
        bomb("could not acquire lock")

    lockfile = open(LOCKFILE, 'a')
    signal(SIGALRM, lock_timeout_handler)
    alarm(5)
    flock(lockfile, LOCK_EX)
    signal(SIGALRM, SIG_IGN)


def release_lock():

    if invname == 'rptrigger':
        return # called by self, avoid deadlock
    lockfile.close()


def get_current_window():
    #
    # TODO: when none exist already, this will fail, ie to spawn the first
    # window.  we work around this by spawning a window during wm init, but we
    # could handle this case by doing it here
    #
    return int(match(r'\(\d+,\s+\d+\)\s+(\d+)', rp('info')).group(1))

###

def rpleft(count=1):

    global curwin

    for i in range(count):
        if curwin == windows[0]:
            target = windows[-1] + 1
        else:
            target = windows[curidx - 1]

        cmd = f"number {target}"
        rp(cmd)
        print(cmd)

        if i < count:
            windows.insert(0, windows.pop())
            curwin = get_current_window()


def rpright():

    if curwin == windows[-1]:
        rpleft(len(windows) - 1)
    else:
        target = windows[curidx + 1]
        cmd = f"number {target}"
        rp(cmd)
        print(cmd)


def rprenumber():

    for i in range(len(windows)):
        if windows[i] == i: continue
        else: rp(f"number {i} {windows[i]}")


# used internally to synchronize new window spawn for rpafter
def rptrigger():

    if len(args) != 1 or len(args[0]) != RANDHEXLEN:
        bomb("rptrigger: usage: rptrigger <{RANDHEXLEN}-char-string>")

    fd = osopen(TRIGFILE, O_RDWR)
    _, ready, _ = select([], [fd], [], FDTIMEOUT)
    if not ready:
        bomb("no reader available by the timeout")
    write(fd, args[0].encode())
    close(fd)


def rpafter():

    target = curwin + 1

    try: command = args[0]
    except IndexError: bomb("rpafter: usage: rpafter <command>")

    # new windows are spawned async, so we have to wait on it being
    # actually mapped before proceeding, otherwise we'll race with it.
    # so we add a hook that writes a fixed-length random string to a
    # named pipe, spawn the window, and wait until we get string back
    #
    trigger = "{:032x}".format(getrandbits(RANDBITS))
    winhook = f"newwindow exec {dirname(__file__)}/rptrigger {trigger}"
    try:
        rp(f"addhook {winhook}")
        rp(f"exec {command}")
        fd = osopen(TRIGFILE, O_RDWR) # if not rw, blocks until writer opens
        ready, _, _ = select([fd], [], [], FDTIMEOUT)
        if not ready:
            bomb("no trigger received in time")
        trigchars = read(fd, RANDHEXLEN).decode()
        close(fd)
        if (trigchars != trigger or len(trigchars) != RANDHEXLEN):
            bomb("trigger received but not the right one")
    finally:
        rp(f"remhook {winhook}")

    newcur = get_current_window()

    dprint(f"curwin: {curwin}")
    dprint(f"newcur: {newcur}")

    if newcur == target:
        dprint("new at target already")
        return

    if target not in revwins:
        dprint("target is not occupied")
        rp(f"number {target}")
        return

    dprint("target already occupied")

    # temporarily move the new window beyond the end, so we don't have
    # to consider it when shifting windows right to make room for it.
    # we leave one free slot after the last one, in case they're all
    # contiguous and we have to shift all the way through to last one
    #
    rp(f"number {windows[len(windows) - 1] + 2}")

    # find the first window (after the original current one at start)
    # that has the number after it free.  we only need to shift right up
    # until this one.  it might be the last one if they're all
    # contiguous and no holes can be found
    #
    for i in range(curidx, len(windows) - 1):
        if windows[i] + 1 not in revwins:
            break
    shiftuntil = i
    dprint(f"shiftuntil {shiftuntil}")

    # shift everyone after the original current window to the right by
    # one, up until one that doesn't have a slot occupied after it
    #
    for i in range(shiftuntil, curwin, -1):
        rp(f"number {windows[i] + 1} {windows[i]}")

    # move the new window to the previously occupied target now that it
    # was shifted away and there's room
    #
    rp(f"number {target}")

    # TODO should we renumber or make the windows contiguous while we
    # shift? for now we're just incrementing their existing sequence
    # numbers by one, which will leave the same holes


###

def main():

    global windows, revwins, curwin, curidx

    if debug: breakpoint()

    acquire_lock()

    windows = [int(x) for x in rp('windows %n').splitlines()]
    revwins = {windows[i]:i for i in range(len(windows))}
    curwin = get_current_window()
    curidx = revwins[curwin]

    try: subprogram = globals()[invname]
    except (KeyError, TypeError):
        bomb(f"unimplemented command '{invname}'")

    ret = subprogram()
    release_lock()
    return ret

###

if __name__ == "__main__":

    from sys import version_info as pyv
    if pyv.major < 3 or pyv.major == 3 and pyv.minor < 9:
        bomb("minimum python 3.9")

    invname = basename(argv[0])
    args = argv[1:]

    try:
        from bdb import BdbQuit
        if bool(environ['DEBUG']):
            from pprint import pprint as pp
            debug = True
            err('debug-mode-enabled')
        else:
            raise KeyError

    except KeyError:
        debug = False

    try: main()
    except BdbQuit: bomb("debug-stop")
