utilx
==============================================================================

Collection of accumulated utilities for Xorg, and secondarily for a
Ratpoison window manager environment (specifically
https://github.com/jcs/sdorfehs/).

Also there some more generic utilities for working in xwindows which
we'll store here for now since they're used for Xorg.  We group the
Ratpoison-specific and the generic Xorg utilities separately below.

| scott@smemsh.net
| https://github.com/smemsh/utilx/
| https://spdx.org/licenses/GPL-2.0

____

.. contents::

____

Xorg utilities
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These scripts only require X11, or start X (as in ``x.sh`` invocations).


urxvtc
------------------------------------------------------------------------------

Wrapper that starts ``urxvtd`` if not already running, otherwise
connects using the ``urxvtc`` client.


winpid
------------------------------------------------------------------------------

Outputs the supposed pid of the X window with given ID number.
Determines pid by way of the window's ``_NET_WM_PID`` pid, which may or
may not exist.


batt
------------------------------------------------------------------------------

Simple power management stuff (implemented as symlinks to ``batt.sh``):

- *batt:* display how much battery is left
- *battery:* alias for ``batt``
- *suspend:* suspends machine after optionally invoking afk
- *hibernate:* hibernates machine after optionally invoking afk


bright
------------------------------------------------------------------------------

Changes the backlight brightness.  Give args:

================= ===============
up                +(max/10)
down              -(max/10)
max               (max)
1-10              (max/10) * N
11-100            (max/100) * N
100 < N < max/10  invalid
max/10 < N < max  (1/max) * N
================= ===============

Also invocable as ``brightup`` and ``brightdown`` without needing an argument.


gg
------------------------------------------------------------------------------

Invoke search from command line args using keyboard-friendly browsers

Takes command line args, urlescapes, creates a google search url.
Brings up text browser with the url, based on invocation name.

Invocations:

- *gg:* elinks (curses browser that supports tables)
- *ggw:* vimb (webkit1 browser with keyboard bindings, normal mode)
- *ww:* elinks with arg as search for wikipedia


x
------------------------------------------------------------------------------

*x.sh:* x, x2, x3, x4, starts different WMs running on X11:

- **x** sdorfehs on :0
- **x2** nested xephyr+jwm
- **x3** nested xephyr+qtile
- **x4** sdorfehs on :3

This is highly custom and particular to author's setup, but easy enough
to change.  If anyone else actually used this stuff, might parameterize it!


xtty
------------------------------------------------------------------------------

xtty.sh: xttytty, xttypid, xttyx
  switches x11 window to that of pid or tty $1, or to x11 vt if not in x11

deps:

- wmctrl

todo:

- we don't seem to switch the rpwm group or properly select window


rptaskmenu
------------------------------------------------------------------------------

- **rptaskmenu**
- **rptaskallmenu**

Select amongst recent timew/taskw tasks (excluding completed tasks
unless the ``all`` version is used) using a `dmenu` and then "timew
start" it.  See also https://github.com/smemsh/taskwtools/

*Note*: the ``rp`` prefix is used for this command, but it requires only
Xorg and dmenu, and does not actually depend on Ratpoison.

xcount
------------------------------------------------------------------------------

Displays count of active Xorg client connections.

*Note*: server active connection limit seems to be 2 under ostensible
limit set by ``Xserver -maxclients``, and/or method does not account for
all connections


xinvert
------------------------------------------------------------------------------

Inverts all colors anywhere on the xorg screen chosen by ``$DISPLAY``.
Makes sense to bind a WM key to this.


chkbatt
------------------------------------------------------------------------------

Increasing screenflashes as battery drains.  I.e, checks battery,
flashes screen accordingly (hardcoded flash parameters for now).  Run at
intervals, eg out cron.

deps:

- https://github.com/smemsh/utilx/ xflashscreen
- only works in xorg

todo:

- read settings from an rcfile


xflashscreen
------------------------------------------------------------------------------

Flashes xorg screen $1 times for $2 ms.

args:

- $1 inversions (default 4)
- $2 ms to sleep between 2 successive inversions (default 40)

deps:

- https://github.com/smemsh/utilx/ xinvert


ptimer
------------------------------------------------------------------------------

Simple countdown timer, flashes screen at conclusion.

- sleeps arg1 minutes
- prints to stdout each minute
- flashes screen when timer expires


keyinject
------------------------------------------------------------------------------

Inject keys given as args using linux uinput events.

- give keys as sequential arguments at program invocation
- keys to be injected can be X keysym names as in X11/keysymdef.h
- program requires root privileges

    - XXX does not work anyways, change it to use x11, then can use
      maybe to replace some rptmux functionality with something faster?


mousepark
------------------------------------------------------------------------------

Hide/unhide Brave Browser's vertical tab bar by moving mouse to left or
right edge of screen

- restores mouse to previous saved position if statefile exists
- otherwise, saves current position in ~/var/mousepark/position.dat
- then moves mouse to left or right (if ``--right``) edge of screen.
- keeps a statefile, override path with ``--statfile``.

____


Ratpoison utilities
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These scripts will probably only work with Ratpoison or Sdorfehs WMs.
They could probably be adapted to other tiling window managers easily.
If anyone else used these scripts besides me, we could parameterize
them...


rpmeta
------------------------------------------------------------------------------

Wrapper allowing several successive calls of the ratpoison `meta`
command, essentially::

    ratpoison -c arg1
    sleep 0.01s
    ratpoison -c arg2
    sleep 0.01s
    ...
    ratpoison -c argN

Note that the sleep only occurs in-between, not at the end.

This command is used by `rptmux`_ to emit the tmux keybindings it learns
about, bound to *Super* key instead of the tmux prefix.

args:

- any number of ratpoison-format key names to generate

todo:

- fork+exec alone is enough so that sleep isn't actually needed (tested)
- ratpoison 'meta' should just be hacked to take multiple keys


rptmux
------------------------------------------------------------------------------

Adds ratpoison keymaps to generate tmux-bound keypresses off ``Super``
modkey.

Queries the running tmux (must be run within) for its current key
bindings.  Takes each key binding found in the ``prefix`` keymap (i.e.
the ``-T prefix`` binds), and makes a Ratpoison mapping to emit the tmux
prefix followed by that binding, bound to Super modifier


Example::

    $ tmux list-keys | grep last-window
    bind-key -T prefix l last-window

    $ ratpoison -c 'help top' | grep s-l
    s-l exec rpmeta C-b l

Unfortunately Ratpoison does not allow compound commands in
keymaps, so we must fork out to a script (here we use the
`rpmeta`_ helper also found in these utilities).

All non-prefix maps in tmux are ignored.

notes:

- queries running tmux for its keybinds (not needed, see todo)
- generates ratpoison binds off super for the unprefixed tmux key
- emits the keys by executing 'rpmeta' wrapper
- writes the sourceable ratpoison bindings to tmpfile
- invokes ratpoison to source the file, which adds the mappings

todo:

- processes only 'prefix' keymap from tmux, ignores rest
- tmux-2.2: "list-keys and list-commands can be run without starting the
  tmux server" so use that, i.e. no longer need to run within tmux

*Note:* old way we did this was to actually execute the tmux command; we
do not do that anymore because it doesn't know which session to target,
so if we have multiple clients attached to different sessions, only the
first one will get it, which would require that we look up the `terminal
-> pid -> client -> session` mapping, which is more difficult, so we
just emit a keypress instead (much easier) which works with whatever
client we are connected with at present moment

____



wmpersist
------------------------------------------------------------------------------

Persists browser window titles across restarts.  Useful for those who:

- typically have many browser windows open
- work on them for long sessions (weeks or months)
- like to give them names
- do not like when names disappear upon restart
- use "ratpoison" window manager

It allows restarting the browser windows (or Ratpoison), without having
to lose the titles given all the browser windows over time.  This is
very handy for reboots or when applying updates.  Backups of the last
save file are retained each time a new save is done.

Ratpoison does not itself have any persistence mechanism.


usage
..............................................................................

**first arg:** "save" or "load"

:"wmpersist save":
    write out chromium window titles to ratpoison winname mappings

:"wmpersist load":
    take existing windows, search for titles in the save file, and
    rename/renumber within ratpoison to match them, once chromium has
    been restarted

**second arg:** "chrome," "brave" or "nightly" (browser to save/load for).

____

Before restarting the browser, and upon adding new windows or making
name changes, run this script (``save``) to dump the mappings.  You
might create a map::

    definekey top M-p verbexec wmpersist save

After browser restart, run script again (``load``) and the titles will
be remapped (along with window numbers and relative sequence).  Of
course, this assumes your browser will remember which windows it had
open (Chrome can be so configured, i.e. *"start where I left off."*)

**Note:** you may have to adjust ``$save_file`` and ``$classname`` if:

- you use a different browser (e.g. Chrome instead of Chromium)
- you want the save files stored elsewhere (default ``~/var/sdorfehs/``)
- you want to persist something other than Chrome


dependencies
..............................................................................

The scripts use the following commands:

- ``ratpoison`` (query and set window numbers)
- ``xwininfo`` (gather all window titles)
- ``xprop`` (test for withdrawn windows)
- ``xlsatoms`` (debugging)
- ``lsw`` (debugging)


todo
..............................................................................

- make $sep pattern same in both rp and xwininfo data gathering
  functions
- ratpoison needs a target arg available for its window name change
  command
- move usage to a constant and emit rather than using comment block to
  document
- this does not work if one of the tabs is a Chromium bookmark manager,
  unknown reason, have to trace this down UPDATE: it may be because
  Chrome leaves around withdrawn windows seems like for eg bookmarks and
  google contacts pages that have been closed, see window_is_withdrawn()
  test in the code
- make work with other things that just browsers (and other browsers
  than chromium) but this may not work since each app keeps highly
  specific titles
- hack this into ratpoison itself, instead
- or generalize it into a general persistence daemon to be used for a
  management framework
- take class name as command line arg
- support other window managers

____


rptaskline
------------------------------------------------------------------------------

Displays a ratpoison notification line based on output from the given
command, optionally passing some input obtained from a prompted line.

- first, sets up taskw/timew environment variables
- then runs a given command with stifled stdio
- optionally feed a ratpoison-prompted string to the command
- report failure if nonzero exit
- runs a given after-command, output to invoker (ratpoison) for display

args:

- if no args, runs ``taskline`` only, with no ``$1:`` prefixed
- if one arg, runs ``$1``, ``$2`` set to ``taskline``
- if two args, runs ``$1``, ``$2`` set to second arg
- if first arg is ``-p`` or ``--prompt``, reads user input, pass to
  ``$1``

output:

| if success, ratpoison echo ``$1: \`$2\```
| if failure, ratpoison echo ``$1: failed: \`$2\```
| command -> [if different: before-fql -> after-fql]
|            [if different: before-status -> after status]
| taskcont -> noop


rp
------------------------------------------------------------------------------

Gives a command on cli to either Ratpoison or Sdorfehs, depending on
whether ``$SDORFEHS_PID`` is set (so, it can be used for either).

Aggregates all args into a single string and gives them to window
manager as ``-c`` argument.

Basically, a faster way to ``ratpoison -c "this is my command"``.


rptaskdesc
------------------------------------------------------------------------------

Displays the description of the current tracking task (see
https://github.com/smemsh/taskwtools/) as a Ratpoison message.


rptaskhelp
------------------------------------------------------------------------------

Displays the current ratpoison keybinds that seem to relate to
taskwarrior/timewarrior as a Ratpoison help notification window that
seem.  See https://github.com/smemsh/taskwtools/


rparrange
------------------------------------------------------------------------------

Rearrange Ratpoison windows (incr, decr, make sequential, insert new).
These commands are implemented in ``rparrange.py``.

Invocations:

- *rpleft:* decrement current window's position, rotate to bottom if first
- *rpright:* increment current window's position, rotate to top if last
- *rpafter:* run arg1 with exec, ensuring win number one after current window
- *rprenumber:* rearrange ratpoison window numbers sequentially starting at 0
- *rptrigger:* only used internally, but made available as invocation for tests
