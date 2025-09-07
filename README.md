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
the `DC` environment variable, though there may be differences in the 
command line flag syntax.

```sh
git clone https://github.com/wreedb/altr; cd altr
git submodule update --init
make
```

By default, the SQLite 3.50.4 amalgamation vendored with the project is built as 
a static library. However it is also possible to build using your system SQLite 
library if desired, though you are on your own with that. To dynamically link 
against your systems' copy:
```
make SQLITE_LIB="-L -lsqlite3"
```
