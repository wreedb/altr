.. SPDX-License-Identifier: GPL-3.0-or-later
.. Author: Will Reed <wreed@disroot.org>
.. Project: https://github.com/wreedb/altr

altr - Manage families of symlinks
==================================

SYNOPSIS
--------

:program:`altr` [*options*], *arguments,...*

DESCRIPTION
-----------

:program:`altr` is a tool for managing groups (trees) of symbolic
links. It is a reimplementation of the classic :program:`update-alternatives`
family of tools. It aims to be distribution agnostic and easier to
understand and use.

TERMINOLOGY
-----------

Tree
	These are the top level, they contain *branches* and *leaves*. The
	information attached to a tree is: its' name, the target link it uses,
	the active branch that its' target points to, the mode it's operating
	in (auto/manual) and a list of all of its' registered branches.

Branch
	These are the individual targets that a tree can use to provide its'
	target link. For example, a branch for the a tree *editor* may be
	something like *emacs* (for those of you who are enlightened) or
	*vim* (for those of you who are not). The information attached to
	a branch is: its' name, the name of the tree it belongs to, the target
	path that it provides, its' priority, whether or not it is active,
	and its' *leaves*.

Leaf
	These are somewhat similar to branches, though they function on a more
	limited scope. They are attached to an individual branch, and will only
	be active when their parent branch is active. They *follow* the parent
	so to speak, such that you may have extra associated links attached to
	just one branch.


OPTIONS
-------

.. option:: -c, --create <name>,<link>,<branch>,<target>,<priority>

  Create a new *tree*, requires 5 arguments:
 
  *name*, example: **editor**
 
  *link*, example: **/usr/bin/editor**
 
  *branch*, example: **emacs**
 
  *target*, example: **/usr/bin/emacs**
 
  *priority*, example: **50**

.. option:: -A, --add-branch <tree>,<branch>,<target>,<priority>

  Add a new **branch** to an existing **tree**, requires 4 arguments:

  *tree*, example: **editor**

  *branch*, example: **vim**

  *target*, example: **/usr/bin/vim**

  *priority*, example: **25**

.. option:: -S, --select <tree>,<branch>

  Change the active **branch** from a given **tree**, requires 2 arguments:

  *tree*, example: **editor**
 
  *branch*, example: **nano**

.. option:: -l, --list

  Show a brief listing of all existing **trees**

.. option:: -s, --show <tree>

  Display a given **tree**, along with its' **branches** and **leaves**

.. option:: -h, --help

  Display command line usage information

.. option:: -V, --version

  Display program version information

ENVIRONMENT
-----------

.. envvar:: ALTR_DIR

  If present, its' value will be used to determine the determine the directory
  in which **altr** will store symlink groups. The default is `/etc/altr`

.. envvar:: ALTR_STATE_DIR
  
  If present, its' value will be used to determine the directory containing
  the **altr** database file. The default is `/var/lib/altr`

SEE ALSO
--------

:manpage:`ln(1)`, :manpage:`readlink(1)`, :manpage:`realpath(1)`, :manpage:`symlink(7)`

AUTHOR
------

Written and maintained by Will Reed <wreed@disroot.org>
To report bugs, please visit <https://github.com/wreedb/altr/issues>

VERSION
-------

**altr** version *0.0.1*
