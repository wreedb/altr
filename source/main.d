module main;
import std.getopt, std.stdio, std.conv;
import altr.tree, altr.branch, altr.leaves, altr.db;

static string altrDir = "/etc/altr";
static string stateDir = "/var/lib/altr";

bool optHelp = false;
bool optVersion = false;
bool optListTrees = false;
string[] optCreateTree;
string[] optAddBranch;
string optShowTree;
string[] optSelectBranch;


string programVersion = "0.0.1";

void showVersion(string vers) {
	writefln("altr version %s", vers);
}

void usage() {
	writeln("USAGE: altr [options...]");
	writeln("  -h,--help         display this help information");
	writeln("  -V,--version      display program version");
	writeln("  -c,--create       create a new tree with initial branch");
	writeln("  syntax: --create <tree name>,<link path>,<branch name>,<branch target>,<branch priority>");
	writeln("  -S,--select       select a trees' branch manually");
	writeln("  syntax: --select <tree name>,<branch name>");
	writeln("  -A,--add-branch   add new branch to a tree");
	writeln("  syntax: --add-branch <tree name>,<branch name>,<target>,<priority>");
	writeln("  -l,--list         show brief listing of trees");
	writeln("  -s,--show <tree>  show detailed listing of tree <tree>");
}

int main(string[] args) {
	auto db = new AltrDatabase("altr.db");
	scope(exit) db.close();
	arraySep = ",";
	
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
		"select|S", &optSelectBranch);

	if (optHelp) { usage(); return 0; }
	if (optVersion) { showVersion(programVersion); return 0; }
	
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

	}
	
	if (optShowTree) {
		Tree t = db.getTree(optShowTree);
		printTree(&t);
	}

	if (optListTrees) {
		foreach (tree; db.listTrees()) {
			Tree t = db.getTree(tree);
			shortPrintTree(&t);
		}
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
			
	}

	if (optAddBranch) {
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

	}
	
	return 0;
}
