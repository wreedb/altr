<!--
SPDX-License-Identifier: GPL-3.0-or-later
Author: Will Reed <wreed@disroot.org>
Project: https://github.com/wreedb/altr
-->

altr
====

**altr** is a reimplementation of the classic `update-alternatives` 
family of tools. Its' purpose is to manage groups of symbolic links. 

---
I began using `alternatives` from [fedora-sysv/chkconfig](https://github.com/fedora-sysv/chkconfig), 
but I wanted to have a bit more control over the way it worked, and for it 
to be a more generic distribution-agnostic tool.

---
### Features
- SQLite backend
- Simpler sematics (tree, branch, leaf)
- Distribution agnostic

---
### Building
You will need a [D](https://dlang.org) compiler, such as:
- [ldmd2](https://github.com/ldc-developers/ldc)
- [dmd](https://github.com/dlang/dmd)
- [gdmd](https://github.com/d-programming-gdc/gdmd)

By default, the makefile uses `ldmd2`, which can be overridden with 
the `DMD` environment variable, though there may be differences in the 
command line flag syntax.

```sh
git clone https://github.com/wreedb/altr
cd altr
ninja
# if you wish to install, (as root if needed):
ninja install
# you may do a 'staged' install with
DESTDIR=/path/to/stage/dir ninja install
# the default installation paths fall under /usr, however you may
# augment this behavior with:
PREFIX=/usr/local ninja install
```
