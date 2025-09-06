module altr.db;

import altr.branch, altr.tree, altr.leaves;
import std.stdio;
import d2sqlite3;
import std.file : exists, mkdirRecurse;
import std.path : dirName;

class AltrDatabase {
    private Database db;
    private string dbPath;
	private bool isOpen = false;
    
    this(string path = "altr.db") {
        this.dbPath = path;
        
        // Create directory if it doesn't exist
        // string dir = dirName(path);
        // if (!exists(dir)) {
        //     mkdirRecurse(dir);
        // }
        
        // Open/create database
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
    
    // Create a new tree with initial branch
    void createTree(string name, string link, string branchName, string target, int priority) {
        db.begin();
        try {
            // Insert tree
            auto stmt = db.prepare("INSERT INTO trees (name, link, selected_branch, manual) VALUES (?, ?, ?, 0)");
            stmt.bind(1, name);
            stmt.bind(2, link);
            stmt.bind(3, branchName);
            stmt.execute();
            
            // Insert initial branch
            auto branchStmt = db.prepare("INSERT INTO branches (tree_name, name, target, priority, active) VALUES (?, ?, ?, ?, 1)");
            branchStmt.bind(1, name);
            branchStmt.bind(2, branchName);
            branchStmt.bind(3, target);
            branchStmt.bind(4, priority);
            branchStmt.execute();
            
            db.commit();
            writeln("Created tree '", name, "' with branch '", branchName, "'");
        } catch (Exception e) {
            db.rollback();
            throw e;
        }
    }
    
    // Add a branch to existing tree
    void addBranch(string treeName, string branchName, string target, int priority) {
        auto stmt = db.prepare("INSERT INTO branches (tree_name, name, target, priority, active) VALUES (?, ?, ?, ?, 0)");
        stmt.bind(1, treeName);
        stmt.bind(2, branchName);
        stmt.bind(3, target);
        stmt.bind(4, priority);
        stmt.execute();
        
        // Update selection if this branch has higher priority and tree is in auto mode
        updateAutoSelection(treeName);
        
        writeln("Added branch '", branchName, "' to tree '", treeName, "'");
    }
    
    // Add leaves to a branch
    void addLeaves(string treeName, string branchName, string[string] leaves) {
        // Get branch ID
        auto branchStmt = db.prepare("SELECT id FROM branches WHERE tree_name = ? AND name = ?");
        branchStmt.bind(1, treeName);
        branchStmt.bind(2, branchName);
        auto results = branchStmt.execute();
        
        if (results.empty()) {
            throw new Exception("Branch not found: " ~ branchName);
        }
        
        int branchId = results.front().peek!int(0);
        
        // Insert leaves
        auto leafStmt = db.prepare("INSERT OR REPLACE INTO leaves (branch_id, link_path, target_path) VALUES (?, ?, ?)");
        foreach (linkPath, targetPath; leaves) {
            leafStmt.bind(1, branchId);
            leafStmt.bind(2, linkPath);
            leafStmt.bind(3, targetPath);
            leafStmt.execute();
            leafStmt.reset();
        }
        
        writeln("Added ", leaves.length, " leaves to branch '", branchName, "'");
    }
    
    // Get tree information
    Tree getTree(string name) {
        Tree tree;
        
        // Get tree info
        auto treeStmt = db.prepare("SELECT name, link, selected_branch, manual FROM trees WHERE name = ?");
        treeStmt.bind(1, name);
        auto treeResults = treeStmt.execute();
        
        if (treeResults.empty()) {
            throw new Exception("Tree not found: " ~ name);
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
                throw new Exception("Branch '" ~ branchName ~ "' not found in tree '" ~ treeName ~ "'");
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
            writeln("Selected branch '", branchName, "' for tree '", treeName, "' (manual mode)");
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
