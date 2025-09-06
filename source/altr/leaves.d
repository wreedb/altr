module altr.leaves;
import std.stdio, altr.branch, altr.tree;

Branch addLeavesToBranch(Branch branch, string[string] leaves) {
    if (leaves.length > 0) {
        foreach (k, v; leaves) {
            branch.leaves[k] = v;
        }
    }
    return branch;
}
