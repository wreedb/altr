<!--
SPDX-License-Identifier: GPL-3.0-or-later
Author: Will Reed <wreed@disroot.org>
Project: https://github.com/wreedb/altr
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-09-14

### Added
- build.ninja: switching to ninja from make
- .env: contains variable for development/iteration

### Changed
- deps/d2sqlite: change submodule path to deps/dsqlite
- deps/sqlite.c: gzipped to deps/sqlite.c.gz, build handles decompression

### Removed
- Makefile: switched to build.ninja
- doc/Makefile: unnecessary, build.ninja rule can handle

## [Unreleased] - 2025-09-08

### Added
- source/altr/symlinks.d: handling links

## [Unreleased] - 2025-09-07

### Changed
- Makefile: add install/uninstall rules

### Added
- source/altr/header.d: global project definitions
- config.mk: split variables from main makefile
- doc/Makefile: sphinx makefile
- doc/source: sphinx source files
- doc/source/altr.rst: sphinx manpage

### Removed
- doc/altr.8.scd: switching to sphinx

## [Unreleased] - 2025-09-06

### Changed
- Makefile: change SQLITE_A -> SQLITE_LIB
- README.md: fix formatting issue

### Added
- deps/d2sqlite: submodule for sqlite bindings
- deps/sqlite.c: SQLite amalgamation for static linking
- LICENSE.md: GPL-3.0-or-later
- doc/altr.8.scd: scdoc manual page
- CHANGELOG.md: this file
- source/*: D source files
