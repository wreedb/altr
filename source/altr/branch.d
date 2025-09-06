module altr.branch;
import std.stdio, altr.tree, altr.leaves;

struct Branch {
    int priority;          // 50
    Tree* tree;            // parent tree pointer, e.g. 'pager'
    string name;           // less
    string target;         // /usr/bin/less
    bool active;           // true when selected, false otherwise
    string[string] leaves; // links that follow this branch
}

Branch createInitBranch(string name, string target, int priority) {
    Branch b;
    b.name = name;
    b.target = target;
    b.priority = priority;
    b.active = true;
    return b;
}

Branch createBranch(string name, string target, int priority, Tree* tree) {
    Branch b;
    b.tree = tree;
    b.name = name;
    b.target = target;
    b.priority = priority;
    b.active = false;
    return b;
}

void printBranch(Branch* branch) {
    writef("  \033[1;34mname\033[0m: %s\n", branch.name);
    writef("  \033[1;34mtarget\033[0m: %s\n", branch.target);
    writef("  \033[1;34mactive\033[0m: %b\n", branch.active);
    writef("  \033[1;34mpriority\033[0m: %d\n", branch.priority);
    if (branch.leaves.length > 0) {
        writef("    \033[1;35mleaves\033[0m:\n");
        foreach (k, v; branch.leaves) {
            writef("    %s -> %s\n", k, v);
        }
    }
}
