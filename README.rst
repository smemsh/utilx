ratutils
==============================================================================

Collection of some scripts to interact with Ratpoison window
manager.  So far there are:

`wmpersist`_
    Ratpoison (and Chrome) -specific script to preserve browser
    window titles across restarts of browser or ratpoison.  Will
    actually work with any program, but has hardcoded class name
    for chromium at the moment.

`rptmux`_
    Emit ratpoison key mappings off Xorg's Super modifier that
    map to tmux prefix-key command sequences.  Running tmux is
    queried for its bindings, and the mapped commands are then
    re-mapped in Ratpoison, which means no longer are two
    separate keypresses needed.

`rpmeta`_
    Wraps "ratpoison -c meta" to allow sending multiple meta
    keys with a short sleep in between (which should help with
    various terminals... not sure if this is needed in practice)

Also there some more generic utilities for working in xwindows
which we'll store here for now since they're used for pseudo
"desktop environment" type stuff whilst in ratpoison:

:`chkbatt`: increasing screenflashes as battery drains
:`xtty.sh`: switch x11 window by tty or pid
:`tmuxtty.sh`: switch tmux window by tty or pid

____

| scott@smemsh.net
| http://smemsh.net/src/ratutils/
| http://spdx.org/licenses/GPL-2.0
|

status:

- used by author regularly
- some site-local hardcodes remain
- please notify author if using


wmpersist
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The script persists browser window titles across restarts.  Useful for
those who:

- use "ratpoison" window manager
- typically have many browser windows open
- work on them for long sessions (weeks or months)
- like to give them names
- do not like when names disappear upon restart

It allows restarting the browser windows (or Ratpoison), without having
to lose the titles given all the browser windows over time.  This is
very handy for reboots or when applying updates.  Backups of the last
save file are retained each time a new save is done.

Ratpoison does not itself have any persistence mechanism.


usage
------------------------------------------------------------------------------

:"wmpersist save":
    write out chromium window titles to ratpoison winname mappings

:"wmpersist load":
    take existing windows, search for titles in the save file, and
    rename/renumber within ratpoison to match them, once chromium has
    been restarted

Before restarting the browser, and upon adding new windows or making
name changes, run this script (``save``) to dump the mappings.  You
might create a map:

    definekey top M-p verbexec wmpersist save

After browser restart, run script again (``load``) and the titles will
be remapped (along with window numbers and relative sequence).  Of
course, this assumes your browser will remember which windows it had
open (Chrome can be so configured, i.e. *"start where I left off."*)

**Note:** you may have to adjust ``$save_file`` and ``$classname`` if:

- you use a different browser (e.g. Chrome instead of Chromium)
- you want the save files stored elsewhere (default ``~/var/rpwm/``)
- you want to persist something other than Chrome


dependencies
------------------------------------------------------------------------------

The scripts use the following commands:

- ratpoison (query and set window numbers)
- xwininfo (gather all window titles)
- xprop (test for withdrawn windows)
- xlsatoms (debugging)
- lsw (debugging)

Also, the scripts use some routines from my shell script library,
libsh_, but those routines could be added directly to the script.
You'll need to do one of the following:

- install the `shell library`__ and adjust the path herein
- manually add the routines pulled in by `require` and `include`
- reimplement without them (e.g. ``setenv var val`` to ``var=val``)

.. _libsh: http://smemsh.net/src/libsh/

__ libsh_


todo
------------------------------------------------------------------------------

- make $sep pattern same in both rp and xwininfo data gathering
  functions
- ratpoison needs a target arg available for its window name change
  command
- move usage to a constant and emit rather than using comment block to
  document
- use debug routines from libsh rather than ad-hoc inline test-and-print
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


rptmux
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Queries the running tmux (must be run within) for its current
key bindings.  Takes each key binding found in the ``prefix``
keymap (i.e. the ``-T prefix`` binds), and makes a Ratpoison
mapping to emit the tmux prefix followed by that binding, bound
to Super modifier


Example::

    $ tmux list-keys | grep last-window
    bind-key -T prefix l last-window

    $ ratpoison -c 'help top' | grep s-l
    s-l exec rpmeta C-b l

Unfortunately Ratpoison does not allow compound commands in
keymaps, so we must fork out to a script (here we use the
`rpmeta`_ helper also found in these utilities).

All non-prefix maps in tmux are ignored.


rpmeta
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Wrapper allowing several successive calls of the ratpoison
`meta` command, essentially::

    ratpoison -c arg1
    sleep 0.01s
    ratpoison -c arg2
    sleep 0.01s
    ...
    ratpoison -c argN

Note that the sleep only occurs in-between, not at the end.

This command is used by `rptmux`_ to emit the tmux keybindings
it learns about, bound to *Super* key instead of the tmux
prefix.
