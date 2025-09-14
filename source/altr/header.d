// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Will Reed <wreed@disroot.org>
// Project: https://github.com/wreedb/altr

module altr.header;
import std.process : environment;

string programVersion = "0.0.1";
string defaultAltrDir = "/etc/altr";
string defaultStateDir = "/var/lib/altr";

string[] readAltrEnv() {
	// check environment for:
	// ALTR_DIR: symlink directory
	// ALTR_STATE_DIR: database directory
	auto altrDir  = environment.get("ALTR_DIR");
	auto stateDir = environment.get("ALTR_STATE_DIR");

	if (altrDir is null) {
		altrDir = defaultAltrDir;
	}
	
	if (stateDir is null) {
		stateDir = defaultStateDir;
	}
	
	return [altrDir, stateDir];

}
