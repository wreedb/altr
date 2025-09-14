// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Will Reed <wreed@disroot.org>
// Project: https://github.com/wreedb/altr

module altr.db;

import altr.header;
import altr.tree;
import altr.branch;
import altr.leaves;

import d2sqlite3;

import std.stdio;
import std.file : exists, mkdirRecurse;
import std.path : dirName;

class AltrDatabase {
    private Database db;
    private string dbPath;
	private bool isOpen = false;
    
    this(string path) {
        this.dbPath = path;
        
        string dir = dirName(path);
        if (!exists(dir)) {
            mkdirRecurse(dir);
        }
        
        db = Database(path);
		isOpen = true;
        initializeSchema();
    }
    
	void close() {
		if (isOpen) {
			db.close();
		}
	}
    
    private void initializeSchema() {
        // Create tables if they don't exist
        db.execute(`
            CREATE TABLE IF NOT EXISTS trees (
                name TEXT PRIMARY KEY,
                link TEXT NOT NULL,
                selected_branch TEXT,
                manual BOOLEAN DEFAULT 0,
                FOREIGN KEY (selected_branch) REFERENCES branches (name)
            )
        `);
        
        db.execute(`
            CREATE TABLE IF NOT EXISTS branches (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tree_name TEXT NOT NULL,
                name TEXT NOT NULL,
                target TEXT NOT NULL,
                priority INTEGER NOT NULL,
                active BOOLEAN DEFAULT 0,
                FOREIGN KEY (tree_name) REFERENCES trees (name),
                UNIQUE(tree_name, name)
            )
        `);
        
        db.execute(`
            CREATE TABLE IF NOT EXISTS leaves (
                branch_id INTEGER,
                link_path TEXT NOT NULL,
                target_path TEXT NOT NULL,
                PRIMARY KEY (branch_id, link_path),
                FOREIGN KEY (branch_id) REFERENCES branches (id)
            )
        `);
    }
    
	void newCreateTree(Tree tree) {
		db.begin();
		try {
			// tree entry
			auto treeStatement = db.prepare("INSERT INTO trees (name, link, selected_branch, manual) VALUES (?, ?, ?, 0)");
			treeStatement.bind(1, tree.name);
			treeStatement.bind(2, tree.link);
			treeStatement.bind(3, tree.selected.name);
			treeStatement.execute();
		
			// initial branch statement
			auto branchStatement = db.prepare("INSERT INTO branches (tree_name, name, target, priority, active) VALUES (?, ?, ?, ?, 1)");
			branchStatement.bind(1, tree.name);
			branchStatement.bind(2, tree.selected.name);
			branchStatement.bind(3, tree.selected.target);
			branchStatement.bind(4, tree.selected.priority);
			branchStatement.execute();
			
            db.commit();
            writef("[\033[1;32mALTR\033[0m] created tree '%s' with branch '%s'\n", tree.name, tree.selected.name);
        	
		} catch (Exception e) {
            db.rollback();
            throw e;
        }

	}
	
	void newAddBranch(Branch b)
	{
		// initialize branch as inactive
		auto statement = db.prepare("INSERT INTO branches (tree_name, name, target, priority, active) VALUES (?, ?, ?, ?, 0)");
		statement.bind(1, b.tree.name);
		statement.bind(2, b.name);
		statement.bind(3, b.target);
		statement.bind(4, b.priority);
		statement.execute();
		// handle automatically setting active branch based on priority
		updateAutoSelection(b.tree.name);
        writef("[\033[1;32mALTR\033[0m] created branch '%s' on tree '%s'\n", b.name, b.tree.name);
	}
    
	void newAddLeaf(Branch b, string[] leaf)
	{
		auto branchStatement = db.prepare("SELECT id FROM branches WHERE tree_name = ? AND name = ?");
		branchStatement.bind(1, b.tree.name);
		branchStatement.bind(2, b.name);
		auto queryResults = branchStatement.execute();

		if (queryResults.empty())
		{
			throw new Exception("[\033[1;31mALTR\033[0m] branch " ~ b.name ~ " not found.");
		}
		
		int branchId = queryResults.front().peek!int(0);
		auto leafStatement = db.prepare("INSERT OR REPLACE INTO leaves (branch_id, link_path, target_path) VALUES (?, ?, ?)");

		leafStatement.bind(1, branchId);
		leafStatement.bind(2, leaf[0]);
		leafStatement.bind(3, leaf[1]);
		leafStatement.execute();

        writef("[\033[1;32mALTR\033[0m] created leaf '%s -> %s' on '%s'\n", leaf[0], leaf[1], b.name);

	}

    // Add leaf to a branch
    void addLeaf(string treeName, string branchName, string[] leaf) {
        // Get branch ID
        auto branchStmt = db.prepare("SELECT id FROM branches WHERE tree_name = ? AND name = ?");
        branchStmt.bind(1, treeName);
        branchStmt.bind(2, branchName);
        auto results = branchStmt.execute();
        
        if (results.empty()) {
            throw new Exception("\033[1;31maltr\033[0m: branch not found: " ~ branchName);
        }
        
        int branchId = results.front().peek!int(0);
        
        // Insert leaf
        auto leafStmt = db.prepare("INSERT OR REPLACE INTO leaves (branch_id, link_path, target_path) VALUES (?, ?, ?)");
        
		leafStmt.bind(1, branchId);
		leafStmt.bind(2, leaf[0]);
		leafStmt.bind(3, leaf[1]);
		leafStmt.execute();
		
        writef("\033[1;32maltr\033[0m: created leaf '%s -> %s' on '%s'\n", leaf[0], leaf[1], branchName);
    }
 	
	Branch getBranch(string treeName, string name)
	{
		Branch b;
		auto branchStatement = db.prepare("SELECT tree_name, name, target, priority, active FROM branches WHERE tree_name = ? AND name = ?");
		branchStatement.bind(1, treeName);
		branchStatement.bind(2, name);
		auto queryResults = branchStatement.execute();
		if (queryResults.empty())
		{
			throw new Exception("[\033[1;31mALTR\033[0m] branch " ~ name ~ " not found.");
		}
		auto branchRow = queryResults.front();
		Tree t = getTree(treeName);

		b.tree = &t;
		b.name = branchRow.peek!string(1);
		b.target = branchRow.peek!string(2);
		b.priority = branchRow.peek!int(3);
		b.active = branchRow.peek!bool(4);
		return b;
	}

    // Get tree information
    Tree getTree(string name) {
        Tree tree;
        
        // Get tree info
        auto treeStmt = db.prepare("SELECT name, link, selected_branch, manual FROM trees WHERE name = ?");
        treeStmt.bind(1, name);
        auto treeResults = treeStmt.execute();
        
        if (treeResults.empty()) {
            throw new Exception("\033[1;31maltr\033[0m: tree not found " ~ name);
        }
        
        auto treeRow = treeResults.front();
        tree.name = treeRow.peek!string(0);
        tree.link = treeRow.peek!string(1);
        string selectedBranchName = treeRow.peek!string(2);
        tree.manual = treeRow.peek!bool(3);
        
        // Get branches
        auto branchStmt = db.prepare("SELECT id, name, target, priority, active FROM branches WHERE tree_name = ? ORDER BY priority DESC");
        branchStmt.bind(1, name);
        auto branchResults = branchStmt.execute();
        
        foreach (row; branchResults) {
            Branch branch;
            int branchId = row.peek!int(0);
            branch.name = row.peek!string(1);
            branch.target = row.peek!string(2);
            branch.priority = row.peek!int(3);
            branch.active = row.peek!bool(4);
            branch.tree = &tree;  // This is a bit tricky with the current design
            
            // Get leaves for this branch
            auto leafStmt = db.prepare("SELECT link_path, target_path FROM leaves WHERE branch_id = ?");
            leafStmt.bind(1, branchId);
            auto leafResults = leafStmt.execute();
            
            foreach (leafRow; leafResults) {
                string linkPath = leafRow.peek!string(0);
                string targetPath = leafRow.peek!string(1);
                branch.leaves[linkPath] = targetPath;
            }
            
            tree.family[branch.name] = branch;
            
            if (branch.name == selectedBranchName) {
                tree.selected = &tree.family[branch.name];
            }
        }
        
        return tree;
    }
    
	void setAutoMode(string treeName) {
		db.begin();
		try {
			// Verify tree exists
			auto checkStmt = db.prepare("SELECT COUNT(*) FROM trees WHERE name = ?");
			checkStmt.bind(1, treeName);
			auto results = checkStmt.execute();

			if (results.front().peek!int(0) == 0) {
				throw new Exception("\033[1;31maltr\033[0m: tree '" ~ treeName ~ "' not found");
			}

			// Set tree to auto mode
			auto modeStmt = db.prepare("UPDATE trees SET manual = 0 WHERE name = ?");
			modeStmt.bind(1, treeName);
			modeStmt.execute();

			// Force auto selection update (reuse existing logic)
			updateAutoSelection(treeName);

			db.commit();
			writef("\033[1;32maltr\033[0m: set tree '%s' to auto mode\n", treeName);

		} catch (Exception e) {
			db.rollback();
			throw e;
		}
	}

    // Update auto selection based on priority
    private void updateAutoSelection(string treeName) {
        // Check if tree is in manual mode
        auto manualStmt = db.prepare("SELECT manual FROM trees WHERE name = ?");
        manualStmt.bind(1, treeName);
        auto results = manualStmt.execute();
        
        if (!results.empty() && !results.front().peek!bool(0)) {
            // Tree is in auto mode, find highest priority branch
            auto stmt = db.prepare("SELECT name FROM branches WHERE tree_name = ? ORDER BY priority DESC LIMIT 1");
            stmt.bind(1, treeName);
            auto branchResults = stmt.execute();
            
            if (!branchResults.empty()) {
                string highestPriorityBranch = branchResults.front().peek!string(0);
                
                // Update all branches to inactive
                auto deactivateStmt = db.prepare("UPDATE branches SET active = 0 WHERE tree_name = ?");
                deactivateStmt.bind(1, treeName);
                deactivateStmt.execute();
                
                // Activate highest priority branch
                auto activateStmt = db.prepare("UPDATE branches SET active = 1 WHERE tree_name = ? AND name = ?");
                activateStmt.bind(1, treeName);
                activateStmt.bind(2, highestPriorityBranch);
                activateStmt.execute();
                
                // Update tree's selected branch
                auto updateTreeStmt = db.prepare("UPDATE trees SET selected_branch = ? WHERE name = ?");
                updateTreeStmt.bind(1, highestPriorityBranch);
                updateTreeStmt.bind(2, treeName);
                updateTreeStmt.execute();
            }
        }
    }
	
	// Manually select a branch (sets tree to manual mode)
    void selectBranch(string treeName, string branchName) {
        db.begin();
        try {
            // Verify the branch exists
            auto checkStmt = db.prepare("SELECT COUNT(*) FROM branches WHERE tree_name = ? AND name = ?");
            checkStmt.bind(1, treeName);
            checkStmt.bind(2, branchName);
            auto results = checkStmt.execute();
            
            if (results.front().peek!int(0) == 0) {
                throw new Exception("\033[1;31maltr\033[0m: branch '" ~ branchName ~ "' not found in tree '" ~ treeName ~ "'");
            }
            
            // Set all branches in this tree to inactive
            auto deactivateStmt = db.prepare("UPDATE branches SET active = 0 WHERE tree_name = ?");
            deactivateStmt.bind(1, treeName);
            deactivateStmt.execute();
            
            // Activate the selected branch
            auto activateStmt = db.prepare("UPDATE branches SET active = 1 WHERE tree_name = ? AND name = ?");
            activateStmt.bind(1, treeName);
            activateStmt.bind(2, branchName);
            activateStmt.execute();
            
            // Update tree's selected branch and set to manual mode
            auto updateTreeStmt = db.prepare("UPDATE trees SET selected_branch = ?, manual = 1 WHERE name = ?");
            updateTreeStmt.bind(1, branchName);
            updateTreeStmt.bind(2, treeName);
            updateTreeStmt.execute();
            
            db.commit();
			writef("\033[1;32maltr\033[0m: selected '%s' for tree '%s' in manual mode\n", branchName, treeName);
        } catch (Exception e) {
            db.rollback();
            throw e;
        }
    }
    
    // List all trees
    string[] listTrees() {
        string[] trees;
        auto stmt = db.prepare("SELECT name FROM trees ORDER BY name");
        auto results = stmt.execute();
        
        foreach (row; results) {
            trees ~= row.peek!string(0);
        }
        
        return trees;
    }
}
