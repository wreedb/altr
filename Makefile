.PHONY: all default clean release

DUB ?= dub
BUILDMODE ?= reldeb
DUBC := ${DUB} build
OUTPUTS := altr

altr: source/main.d
	@echo -e "\033[1;32mDUB\033[0m $@"
	@${DUBC} > /dev/null 2>&1

all: ${OUTPUTS}
default: all

release: source/main.d
	@echo -e "\033[1;34mDUB\033[0m: $@ altr"
	@${DUBC} -b $(BUILDMODE) >/dev/null 2>&1


dubclean:
	@${DUB} clean > /dev/null 2>&1
	@${DUB} clean-caches > /dev/null 2>&1
	@echo -e "\033[1;33mCLEAN\033[0m dub"

clean: dubclean
	@rm -f ${OUTPUTS}
	@echo -e "\033[1;33mCLEAN\033[0m ${OUTPUTS}"

