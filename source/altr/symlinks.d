// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Will Reed <wreed@disroot.org>
// Project: https://github.com/wreedb/altr

module altr.symlinks;

import std.file;
import std.path;
import std.string;
import std.stdio;
import std.conv : to;

import altr.header;
import altr.tree;
import altr.branch;
import altr.leaves;
import altr.db;

string ensureAltrRootDir(string path) {
	if (!exists(path)) {
		writef("\033[1;33maltr\033[0m: attempting to create dir '%s'\n", path);
		mkdirRecurse(path);
	}
	return to!string(asNormalizedPath(path));
}

int handleCreateTree(Tree tree, Branch branch) {
	
	return 0;
}


