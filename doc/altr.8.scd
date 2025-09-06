ALTR(8)

# NAME

*altr* maintain groups(trees) of symlinks(branches) with followers(leaves)

# SYNOPSIS

*altr* [_options_] *--ACTION* [_args_]...++
where *--ACTION* is one of:++
*--create* _name_,_link_,_target-name_,_target-path_,_priority_

# DESCRIPTION
*altr* is a reimplementation of the classic _update-alternatives_ family of
programs. If you are familiar with them, *altr* will come naturally to you.

It is common to have multiple programs that fulfill a similar purpose, such as
Emacs, Vim, Micro and Nano for editing text files. *altr* allows you to create generic
symlinks for these, for example:

/usr/bin/editor -> /usr/bin/emacs: priority *50*++
/usr/bin/editor -> /usr/bin/vim:   priority *40*++
/usr/bin/editor -> /usr/bin/micro: priority *30*++
/usr/bin/editor -> /usr/bin/nano:  priority *20*

In this example, when in _auto_ mode (the default), the editor command will
point to Emacs, since it has the highest priority number.

# SEE ALSO
_ln_(1), _link_(1), _unlink_(1), _readlink_(1), _realpath_(1), _symlink_(7)

# COPYRIGHT
Copyright (C) 2025 Will Reed, Licensed under the GNU GPL version 3 or later.
This is free software: you are free to change and redistribute it. There is NO
WARRANTY, to the extent permitted by law.

# VERSION
*altr* version _0.0.1_

# AUTHOR
Written and maintained by Will Reed <_wreed@disroot.org_>, source code may be
found at _https://github.com/wreedb/altr_.
