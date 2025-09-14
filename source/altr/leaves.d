// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Will Reed <wreed@disroot.org>
// Project: https://github.com/wreedb/altr

module altr.leaves;

import std.stdio;
import altr.branch;
import altr.tree;

Branch addLeavesToBranch(Branch branch, string[string] leaves) {
    if (leaves.length > 0) {
        foreach (k, v; leaves) {
            branch.leaves[k] = v;
        }
    }
    return branch;
}
