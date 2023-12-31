all: build start

build: build-packages netsim

start: start-netsims start-nso start-cli

build-packages:
	@for p in packages/*; do echo "\n#### Building $$p"; make -C $$p/src || exit; done

netsim: build-packages
	@if [ ! -d netsim ]; then                              \
		echo "\n#### Building netsim network";               \
		ncs-netsim                                           \
			create-network packages/origin     2 origin        \
			create-network packages/skylight   2 skylight      \
			create-network packages/subscriber 2 subscriber    \
			create-network packages/edge       2 edge          \
			create-network packages/origin     2 cpe;          \
		ncs-netsim ncs-xml-init > ncs-cdb/netsim-init.xml;   \
	else echo "\n#### Netsim network already created"; fi

start-netsims: netsim
	@echo "\n#### Starting netsim network"
	@ncs-netsim is-alive origin0 | grep "DEVICE origin0 OK"; if [ $$? = 0 ]; then echo "NETSIM network already running"; else ncs-netsim start; fi

start-nso: ncs.conf
	@echo "\n#### Starting NSO"
	@ncs --status > /dev/null 2>&1; if [ $$? = 0 ]; then echo "NSO already running, but if you updated any packages, you need to reload them inside NSO: packages reload"; else ncs -c ncs.conf --with-package-reload; fi
	@./netsim-simulate-jitter.sh dc0 20
	@./netsim-simulate-jitter.sh dc1 25

start-cli:
	@echo "\n#### Entering NSO Command Line Interface as user admin"
	ncs_cli -Cu admin

stop:
	@if [ -d netsim ]; then ncs-netsim stop; echo "NETSIM network stopped"; else echo "NETSIM already stopped"; fi;
	@ncs --status > /dev/null 2>&1; if [ $$? = 0 ]; then ncs --stop; echo "NSO stopped"; else echo "NSO already stopped"; fi

clean: stop
	@for p in packages/*; do echo "\n#### Cleaning $$p"; make -C $$p/src clean; done
	@rm -rf netsim
	@rm ncs-cdb/netsim-init.xml
	@ncs-setup --reset
