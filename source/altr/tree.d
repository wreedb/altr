module altr.tree;
import std.stdio, altr.branch, altr.leaves;

struct Tree {
    string name;                // pager
    Branch* selected;           // a branch pointer, denoting the active altr
    Branch[string] family;      // branch list, denoting active/inactive altrs
    string link;                // /usr/bin/pager
    bool manual;                // false uses branch with highest priority
}

Tree createTree(string name, string link, string initBranchName, string initBranchTarget, int initBranchPriority) {
    Tree t;
    Branch initBranch = createInitBranch(initBranchName, initBranchTarget, initBranchPriority);
    initBranch.tree = &t;
    t.name = name;
    t.link = link;
    t.family[initBranch.name] = initBranch;
    t.selected = &t.family[initBranch.name];
    // always initialize to auto mode
    t.manual = false;
    return t;
}

Tree addBranchToTree(Tree tree, Branch branch) {
    tree.family[branch.name] = branch;
    // update tree.selected using priority if in auto mode
    if (!tree.manual) {
        Branch* highestPriorityBranch = null;
        int highestPriority = -1;
        
        foreach (ref b; tree.family) {
            if (b.priority > highestPriority) {
                highestPriority = b.priority;
                highestPriorityBranch = &b;
            }
        }
        
        if (highestPriorityBranch) {
            // Set all branches to inactive first
            foreach (ref b; tree.family) {
                b.active = false;
            }
            // Activate the highest priority branch
            highestPriorityBranch.active = true;
            tree.selected = highestPriorityBranch;
        }
    }
    return tree;
}

void shortPrintTree(Tree* tree) {
	writef("\033[1;32m%s\033[0m: %s, %s\n", tree.name, tree.selected.name, tree.selected.target);
}

void printTree(Tree* tree) {
    writef("---\n");
    writef("\033[1;32mname\033[0m: %s\n", tree.name);
    if (tree.manual) { writef("\033[1;32mmode\033[0m: manual\n"); } else { writef("\033[1;32mmode\033[0m: auto\n"); }
    writef("\033[1;32mselected\033[0m: %s\n", tree.selected.name);
    writef("\033[1;32mlink\033[0m: %s\n", tree.link);
    writef("\033[1;32mfamily\033[0m:\n");
    foreach (member; tree.family) {
        printBranch(&member);
    }
}

Tree manualSetSelectedBranch(Tree t, string branchName) {
    if (branchName in t.family) {
        foreach (ref b; t.family) {
            b.active = false;
        }
        t.selected = &t.family[branchName];
        t.manual = true;
        return t;
    } else {
        return t;
    }
}
