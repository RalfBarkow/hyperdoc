# HyperDoc Makefile.
#
# Simple use:
#   make
#   make run
#   make stop
#
# This builds:
#   1. HyperDoc SBCL server executable
#   2. native CLOG Frame executable via Nix
#   3. launcher script
#
# This Makefile uses real tab-indented recipes. Do not replace tabs.

.DEFAULT_GOAL := all

.PHONY: all explain-build run stop status clean rebuild help \
	build-standalone build-clog-frame build-runner \
	repomix repomix-help repomix-clean repomix-all \
	repomix-core repomix-dock repomix-validation repomix-fedwiki \
	repomix-dmx repomix-deployment repomix-dm6 repomix-zotero \
	repomix-full

SBCL ?= sbcl
LISP ?= nix develop -c $(SBCL)

BUNDLE_DIR ?= bundle-deploy
SERVER_DIR ?= $(BUNDLE_DIR)/hyperdoc-standalone
FRAME_DIR ?= $(BUNDLE_DIR)/hyperdoc-frame

SERVER_EXE ?= $(SERVER_DIR)/hyperdoc
FRAME_EXE ?= $(FRAME_DIR)/clogframe
RUNNER ?= $(FRAME_DIR)/run-hyperdoc-frame

PID_FILE ?= $(FRAME_DIR)/hyperdoc-server.pid
PORT_FILE ?= $(FRAME_DIR)/hyperdoc-server.port
LOG_FILE ?= $(FRAME_DIR)/hyperdoc-server.log

HYPERDOC_SYSTEM ?= :hyperdoc/server

CLOGFRAME_NIX ?= nix/clogframe.nix
CLOGFRAME_RESULT ?= result-clogframe

REPOMIX_PACK = core
PACK = $(REPOMIX_PACK)
REPOMIX_FOCUSED_PACKS = core dock validation fedwiki dmx deployment dm6 zotero

all: explain-build $(SERVER_EXE) $(FRAME_EXE) $(RUNNER)
	@echo
	@echo "Built:"
	@echo "  $(SERVER_EXE)"
	@echo "  $(FRAME_EXE)"
	@echo "  $(RUNNER)"
	@echo
	@echo "Run with:"
	@echo "  make run"

explain-build:
	@echo "make builds a standalone HyperDoc CLOG Frame bundle:"
	@echo "  1. HyperDoc SBCL server executable"
	@echo "  2. native CLOG Frame executable via Nix"
	@echo "  3. launcher script"
	@echo
	@echo "Other useful goals:"
	@echo "  make run           launch CLOG Frame"
	@echo "  make stop          stop background HyperDoc server"
	@echo "  make status        show server status"
	@echo "  make repomix-full  build full Repomix pack"
	@echo

$(SERVER_EXE): Makefile tools/save-hyperdoc-standalone.lisp
	@echo "==> Building HyperDoc server executable"
	rm -f result result-clogframe
	mkdir -p "$(dir $(SERVER_EXE))"
	$(LISP) --no-userinit --no-sysinit --non-interactive \
		--eval '(defparameter cl-user::*hyperdoc-root* #P"$(CURDIR)/")' \
		--eval '(defparameter cl-user::*hyperdoc-output* #P"$(abspath $(SERVER_EXE))")' \
		--eval '(defparameter cl-user::*hyperdoc-system* $(HYPERDOC_SYSTEM))' \
		--load tools/save-hyperdoc-standalone.lisp
	@echo "==> Built $(SERVER_EXE)"

$(FRAME_EXE): $(CLOGFRAME_NIX)
	@echo "==> Building CLOG Frame via Nix"
	mkdir -p "$(dir $(FRAME_EXE))"
	nix build --impure \
		--expr 'let flake = builtins.getFlake "git+file://$(CURDIR)"; pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; }; in pkgs.callPackage ./$(CLOGFRAME_NIX) { }' \
		--out-link "$(CLOGFRAME_RESULT)"
	test -x "$(CLOGFRAME_RESULT)/bin/clogframe"
	install -m 0755 "$(CLOGFRAME_RESULT)/bin/clogframe" "$(FRAME_EXE)"
	@echo "==> Built $(FRAME_EXE)"

$(RUNNER): Makefile tools/run-hyperdoc-frame.sh $(SERVER_EXE) $(FRAME_EXE)
	@echo "==> Installing runner"
	mkdir -p "$(dir $(RUNNER))"
	install -m 0755 tools/run-hyperdoc-frame.sh "$(RUNNER)"
	@echo "==> Built $(RUNNER)"

run: all
	"$(RUNNER)"

stop:
	@if [ -f "$(PID_FILE)" ]; then \
		pid="$$(cat "$(PID_FILE)")"; \
		if kill -0 "$$pid" 2>/dev/null; then \
			echo "Stopping HyperDoc server $$pid"; \
			kill "$$pid" 2>/dev/null || true; \
		else \
			echo "No running server for stale PID $$pid"; \
		fi; \
	else \
		echo "No PID file."; \
	fi
	rm -f "$(PID_FILE)" "$(PORT_FILE)"

status:
	@if [ -f "$(PID_FILE)" ] && kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
		echo "running"; \
		echo "pid:  $$(cat "$(PID_FILE)")"; \
		echo "port: $$(cat "$(PORT_FILE)" 2>/dev/null || echo unknown)"; \
		echo "log:  $(LOG_FILE)"; \
	else \
		echo "not running"; \
	fi

clean:
	-$(MAKE) stop
	rm -rf "$(SERVER_DIR)" "$(FRAME_DIR)" "$(CLOGFRAME_RESULT)" result
	rm -rf .cache/clog

rebuild: clean all

build-standalone: $(SERVER_EXE)
build-clog-frame: $(FRAME_EXE)
build-runner: $(RUNNER)

help:
	@echo "Standalone CLOG Frame:"
	@echo "  make        build standalone CLOG Frame bundle"
	@echo "  make run    launch it"
	@echo "  make stop   stop background HyperDoc server"
	@echo "  make status show server status"
	@echo "  make clean  remove generated bundle"
	@echo
	@echo "Repomix:"
	@echo "  make repomix"
	@echo "  make repomix PACK=dock"
	@echo "  make repomix-full"
	@echo "  make repomix-core"
	@echo "  make repomix-all"
	@echo "  make repomix-clean"

repomix:
	@echo "==> Repomix: generating $(PACK) pack"
	tools/repomix-pack.sh $(PACK)

repomix-core:
	@echo "==> Repomix: generating core pack"
	tools/repomix-pack.sh core

repomix-dock:
	@echo "==> Repomix: generating dock pack"
	tools/repomix-pack.sh dock

repomix-validation:
	@echo "==> Repomix: generating validation pack"
	tools/repomix-pack.sh validation

repomix-fedwiki:
	@echo "==> Repomix: generating fedwiki pack"
	tools/repomix-pack.sh fedwiki

repomix-dmx:
	@echo "==> Repomix: generating dmx pack"
	tools/repomix-pack.sh dmx

repomix-deployment:
	@echo "==> Repomix: generating deployment pack"
	tools/repomix-pack.sh deployment

repomix-dm6:
	@echo "==> Repomix: generating dm6 pack"
	tools/repomix-pack.sh dm6

repomix-zotero:
	@echo "==> Repomix: generating zotero pack"
	tools/repomix-pack.sh zotero

repomix-full:
	@echo "==> Repomix: generating full repository pack"
	tools/repomix-pack.sh full

repomix-all:
	@echo "==> Repomix: generating focused packs: $(REPOMIX_FOCUSED_PACKS)"
	for pack in $(REPOMIX_FOCUSED_PACKS); do \
		tools/repomix-pack.sh "$$pack"; \
	done

repomix-clean:
	@echo "==> Repomix: removing generated outputs"
	rm -f repomix-output-hyperdoc*.md repomix-output-hyperdoc*.xml

repomix-help:
	@echo "Repomix targets:"
	@echo "  make repomix"
	@echo "  make repomix PACK=dock"
	@echo "  make repomix-core"
	@echo "  make repomix-dock"
	@echo "  make repomix-validation"
	@echo "  make repomix-fedwiki"
	@echo "  make repomix-dmx"
	@echo "  make repomix-deployment"
	@echo "  make repomix-dm6"
	@echo "  make repomix-zotero"
	@echo "  make repomix-all"
	@echo "  make repomix-full"
	@echo "  make repomix-clean"
