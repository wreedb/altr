// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Will Reed <wreed@disroot.org>
// Project: https://github.com/wreedb/altr

module main;

// std imports
import std.conv : to;
import std.format : format;
import std.stdio : writefln, writeln, writef;
import std.getopt;

// local imports
import altr.header;
import altr.symlinks;
import altr.tree;
import altr.branch;
import altr.leaves;
import altr.db;

// getopt option variables
string optShowTree;
string optSetAuto;
string[] optGetBranch;
string[] optCreateTree;
string[] optAddBranch;
string[] optSelectBranch;
string[] optAddLeaf;
bool optListTrees = false;
bool optVersion = false;
bool optHelp = false;

void showVersion(string vers, string[] altrEnv) {
	writefln("altr: version %s", vers);
	writefln("ALTR_DIR: %s", altrEnv[0]);
	writefln("ALTR_STATE_DIR: %s", altrEnv[1]);
}

void usage() {
	writeln("USAGE: altr [options...]");
	writeln("  -c,--create       create a new tree with initial branch");
	writeln("  -S,--select       select a trees' branch manually");
	writeln("  -A,--add-branch   add new branch to a tree");
	writeln("  -l,--list         show a brief listing of trees");
	writeln("  -s,--show <tree>  show detailed listing of tree <tree>");
	writeln("     --add-leaf     add a new leaf to a branch");
	writeln("     --auto         change tree to automatic selection");
	writeln("  -h,--help         display this help information");
	writeln("  -V,--version      display program version");
}

int main(string[] args) {

	auto altrEnv = readAltrEnv();

	string altrDir = altrEnv[0];
	string stateDir = altrEnv[1];

	ensureAltrRootDir(altrDir);

	auto db = new AltrDatabase(format("%s/altr.db", stateDir));
	scope(exit) db.close();

	arraySep = ","; // for multi-argument options
	
	getopt(
		args,
		std.getopt.config.passThrough,
		std.getopt.config.caseSensitive,
		std.getopt.config.bundling,
		"help|h", &optHelp,
		"version|V", &optVersion,
		"create|c", &optCreateTree,
		"show|s", &optShowTree,
		"list|l", &optListTrees,
		"add-branch|A", &optAddBranch,
		"add-leaf", &optAddLeaf,
		"select|S", &optSelectBranch,
		"auto", &optSetAuto,
		"get-branch", &optGetBranch);

	if (optHelp) { usage(); return 0; }
	if (optVersion) { showVersion(programVersion, altrEnv); return 0; }
	
	if (optCreateTree)
	{
		if (optCreateTree.length != 5)
		{
			writeln("\033[1;31merror\033[0m: --create requires arguments: <name>,<link>,<initial branch name>,<initial branch target>,<initial branch priority>");
			writeln("example: altr --create editor,/usr/bin/editor,vim,/usr/bin/vim,50");
			return 1;
		}

		Tree t = createTree(optCreateTree[0], optCreateTree[1], optCreateTree[2], optCreateTree[3], to!int(optCreateTree[4]));
		db.newCreateTree(t);
		return 0;
	}
	
	if (optAddBranch)
	{
		if (optAddBranch.length != 4) {
			writeln("\033[1;31mALTR\033[0m: --add-branch requires arguments: <tree name>,<branch name>,<target>,<priority>");
			writeln("example: altr --add-branch editor,vim,/usr/bin/vim,50");
			return 1;
		}
		
		Tree t = db.getTree(optAddBranch[0]); // get the tree by its' name

		string bName = optAddBranch[1];
		string bTarget = optAddBranch[2];
		int bPriority = to!int(optAddBranch[3]);

		Branch b = createBranch(bName, bTarget, bPriority, &t);
		
		db.newAddBranch(b);
		return 0;

	}
	
	/*
	if (optCreateTree) {
		if (optCreateTree.length != 5) {
			writeln("\033[1;31merror\033[0m: --create requires arguments: <name>,<link>,<initial branch name>,<initial branch target>,<initial branch priority>");
			writeln("example: altr --create editor,/usr/bin/editor,vim,/usr/bin/vim,50");
			return 1;
		}
		string name = optCreateTree[0];
		string link = optCreateTree[1];
		string iName = optCreateTree[2];
		string iTarget = optCreateTree[3];
		int iPriority = to!int(optCreateTree[4]);
		db.createTree(name, link, iName, iTarget, iPriority);
		return 0;
	}*/
	
	if (optShowTree) {
		Tree t = db.getTree(optShowTree);
		printTree(&t);
		return 0;
	}

	if (optListTrees) {
		foreach (tree; db.listTrees()) {
			Tree t = db.getTree(tree);
			shortPrintTree(&t);
		}
		return 0;
	}
	
	if (optSetAuto) {
		
		if (optSetAuto is null) {
			writeln("\033[1;31merror\033[0m: --auto requires an argument <tree name>");
			return 1;
		}
	
		db.setAutoMode(optSetAuto);
		return 0;
	}

	if (optGetBranch)
	{
		if (optGetBranch.length != 2)
		{
			writeln("[\033[1;31mALTR\033[0m] --get-branch requires arguments: <tree>,<branch>");
			writeln("example: altr --get-branch editor,emacs");
			return 1;
		}

		Branch b = db.getBranch(optGetBranch[0], optGetBranch[1]);
		printBranch(&b);
		return 0;
	}

	/*if (optAddLeaf)
	{
		if (optAddLeaf.length != 4)
		{
			writeln("\033[1;31merror\033[0m: --add-leaf requires arguments: <tree>,<branch>,<leaf path>,<target path>");
			writeln("example: altr --add-leaf toolchain,llvm,/usr/bin/c++,/usr/bin/clang++");
			return 1;
		}
		string tName = optAddLeaf[0];
		string bName = optAddLeaf[1];
		return 0;
	}*/
	
	if (optAddLeaf) {
		if (optAddLeaf.length != 4) {
			writeln("\033[1;31merror\033[0m: --add-leaf requires arguments: <tree>,<branch>,<leaf path>,<target path>");
			writeln("example: altr --add-leaf toolchain,llvm,/usr/bin/c++,/usr/bin/clang++");
			return 1;
		}
		string tree   = optAddLeaf[0]; // tree name
		string branch = optAddLeaf[1]; // branch name
		string[2] leaf = [optAddLeaf[2], optAddLeaf[3]];
		db.addLeaf(tree, branch, leaf);
		return 0;
	}

	if (optSelectBranch) {
		if (optSelectBranch.length != 2) {
			writeln("\033[1;31merror\033[0m: --select requires arguments: <tree name>,<branch name>");
			writeln("example: altr --select editor,vim");
			return 1;
		}

		string tname = optSelectBranch[0];
		string bname = optSelectBranch[1];
		db.selectBranch(tname, bname);
		return 0;
	}

	/* if (optAddBranch) {
		if (optAddBranch.length != 4) {
			writeln("\033[1;31merror\033[0m: --add-branch requires arguments: <tree name>,<branch name>,<target>,<priority>");
			writeln("example: altr --add-branch editor,vim,/usr/bin/vim,50");
			return 1;
		}
		
		string tname = optAddBranch[0];
		string bname = optAddBranch[1];
		string target = optAddBranch[2];
		int priority = to!int(optAddBranch[3]);

		db.addBranch(tname, bname, target, priority);
		return 0;
	} */
	
	usage();
	return 1;
}
