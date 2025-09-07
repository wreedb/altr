.PHONY: all default clean release sqlite dsqlite depclean distclean

DC ?= ldmd2
CC ?= gcc
AR ?= ar
CFLAGS ?= -O2 -pipe
OUTPUTS := altr
SQLITEFLAGS := -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS5 -DSQLITE_SECURE_DELETE
SQLITE_LIB  ?= deps/sqlite.a
SQLITE_OBJ  := deps/sqlite.o
DSQLITE     := deps/d2sqlite/source
DSQLITEDIR  := deps/d2sqlite/source/d2sqlite3
DSQLITE_A   := deps/dsqlite.a
DSQLITE_SOURCES := $(DSQLITEDIR)/database.d \
				   $(DSQLITEDIR)/internal/memory.d \
				   $(DSQLITEDIR)/internal/util.d \
				   $(DSQLITEDIR)/library.d \
				   $(DSQLITEDIR)/package.d \
				   $(DSQLITEDIR)/results.d \
				   $(DSQLITEDIR)/sqlite3.d \
				   $(DSQLITEDIR)/statement.d

ALTR_SOURCES := source/altr/branch.d source/altr/tree.d source/altr/leaves.d source/main.d


all: altr
default: all

deps/sqlite.o: deps/sqlite.c
	@echo -e "(\033[1;34mCC\033[0m) $@"
	@$(CC) $(CFLAGS) $(SQLITEFLAGS) -c $^ -o $@

$(SQLITE_LIB): deps/sqlite.o
	@echo -e "(\033[1;34mAR\033[0m) $@"
	@$(AR) rcs $@ $^

sqlite: $(SQLITE_LIB)

$(DSQLITE_A): $(DSQLITE_SOURCES)
	@echo -e "(\033[1;32mDC\033[0m) $@"
	@$(DC) -release -inline -O -w -version=Have_d2sqlite3 -I$(DSQLITE) $^ -lib -vcolumns -of$@

dsqlite: $(DSQLITE_A)

altr: $(ALTR_SOURCES) $(SQLITE_LIB) $(DSQLITE_A)
	@echo -e "(\033[1;32mDC\033[0m) $@"
	@$(DC) -od./source -i -I./source -I./deps/d2sqlite/source -release -inline $^ -of$@

clean:
	@rm -f ${OUTPUTS} source/*.o
	@echo -e "(\033[1;33mCLEAN\033[0m) ${OUTPUTS}"

depclean:
	@rm -f ${SQLITE_LIB} ${SQLITE_OBJ} ${DSQLITE_A}
	@echo -e "(\033[1;33mCLEAN\033[0m) ${SQLITE_LIB} ${SQLITE_OBJ} ${DSQLITE_A}"

distclean: clean depclean
