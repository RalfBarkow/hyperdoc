# HyperDoc Makefile.
#
# Simple use:
#   make
#   make run
#   make stop
#
# Repomix goals are preserved:
#   make repomix-full
#   make repomix-core
#   make repomix PACK=dock

.RECIPEPREFIX := >
.DEFAULT_GOAL := all

.PHONY: all explain-build run stop status clean rebuild help \
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

CLOG_REPO ?= https://github.com/rabbibotton/clog.git
CLOG_REF ?= main
CLOG_DIR ?= .cache/clog
CLOG_FRAME_DIR ?= $(CLOG_DIR)/clogframe
CLOG_FRAME_CPP ?= $(CLOG_FRAME_DIR)/clogframe.cpp

HYPERDOC_SYSTEM ?= :hyperdoc/server

REPOMIX_PACK = core
PACK = $(REPOMIX_PACK)
REPOMIX_FOCUSED_PACKS = core dock validation fedwiki dmx deployment dm6 zotero

UNAME_S := $(shell uname -s 2>/dev/null || echo unknown)

define RUNNER_SCRIPT
#!/usr/bin/env bash
set -euo pipefail

DIR="$$(cd "$$(dirname "$$0")" && pwd)"
SERVER="$$DIR/../hyperdoc-standalone/hyperdoc"
FRAME="$$DIR/clogframe"

PID_FILE="$$DIR/hyperdoc-server.pid"
PORT_FILE="$$DIR/hyperdoc-server.port"
LOG_FILE="$$DIR/hyperdoc-server.log"

TITLE="$${HYPERDOC_FRAME_TITLE:-HyperDoc}"
WIDTH="$${HYPERDOC_FRAME_WIDTH:-1280}"
HEIGHT="$${HYPERDOC_FRAME_HEIGHT:-900}"
DEVELOPMENT="$${HYPERDOC_DEVELOPMENT:-0}"

free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'
}

alive() {
  test -f "$$PID_FILE" && kill -0 "$$(cat "$$PID_FILE")" 2>/dev/null
}

ready() {
  curl -fsS "http://127.0.0.1:$$1/boot.html" >/dev/null 2>&1
}

if [ ! -x "$$SERVER" ]; then
  echo "Missing server executable: $$SERVER" >&2
  exit 1
fi

if [ ! -x "$$FRAME" ]; then
  echo "Missing CLOG Frame executable: $$FRAME" >&2
  exit 1
fi

if alive && test -f "$$PORT_FILE"; then
  PORT="$$(cat "$$PORT_FILE")"
  if ready "$$PORT"; then
    echo "Reusing running HyperDoc server on port $$PORT"
  else
    echo "Found stale or unresponsive HyperDoc server PID; stopping it."
    old_pid="$$(cat "$$PID_FILE")"
    kill "$$old_pid" 2>/dev/null || true
    rm -f "$$PID_FILE" "$$PORT_FILE"
    PORT="$${HYPERDOC_PORT:-$$(free_port)}"
  fi
else
  PORT="$${HYPERDOC_PORT:-$$(free_port)}"
fi

if ! alive; then
  echo "Starting HyperDoc server on port $$PORT"
  : > "$$LOG_FILE"

  HYPERDOC_PORT="$$PORT" HYPERDOC_DEVELOPMENT="$$DEVELOPMENT" \
    nohup "$$SERVER" >> "$$LOG_FILE" 2>&1 < /dev/null &

  echo "$$!" > "$$PID_FILE"
  echo "$$PORT" > "$$PORT_FILE"
fi

for _ in $$(seq 1 120); do
  if ready "$$PORT"; then
    echo "HyperDoc: http://127.0.0.1:$$PORT/boot.html"
    "$$FRAME" "$$TITLE" "$${PORT}/boot.html" "$$WIDTH" "$$HEIGHT"
    echo
    echo "CLOG Frame closed."
    echo "HyperDoc server is still running on port $$PORT."
    echo "Stop it with: make stop"
    exit 0
  fi
  sleep 0.25
done

echo "Server did not become ready. Log follows:" >&2
tail -n 80 "$$LOG_FILE" >&2 || true
exit 1
endef
export RUNNER_SCRIPT

all: explain-build $(SERVER_EXE) $(FRAME_EXE) $(RUNNER)
> @echo
> @echo "Built:"
> @echo "  $(SERVER_EXE)"
> @echo "  $(FRAME_EXE)"
> @echo "  $(RUNNER)"
> @echo
> @echo "Run with:"
> @echo "  make run"

explain-build:
> @echo "make builds a standalone HyperDoc CLOG Frame bundle:"
> @echo "  1. HyperDoc SBCL server executable"
> @echo "  2. native CLOG Frame executable"
> @echo "  3. launcher script"
> @echo
> @echo "Other useful goals:"
> @echo "  make run           launch CLOG Frame"
> @echo "  make stop          stop background HyperDoc server"
> @echo "  make status        show server status"
> @echo "  make repomix-full  build full Repomix pack"
> @echo

$(SERVER_EXE): Makefile
> @echo "==> Building HyperDoc server executable"
> mkdir -p "$(dir $(SERVER_EXE))"
> $(LISP) --no-userinit --no-sysinit --non-interactive \
>   --eval '(require :asdf)' \
>   --eval '(uiop:chdir #P"$(CURDIR)/")' \
>   --eval '(pushnew (truename #P"$(CURDIR)/") asdf:*central-registry* :test (function equal))' \
>   --eval '(asdf:load-system $(HYPERDOC_SYSTEM))' \
>   --eval '(defun cl-user::truthy (x) (and x (member (string-downcase x) (quote ("1" "true" "yes" "on")) :test (function string=))))' \
>   --eval '(defun cl-user::main () (let* ((port (parse-integer (or (uiop:getenv "HYPERDOC_PORT") "8080") :junk-allowed t)) (dev (cl-user::truthy (uiop:getenv "HYPERDOC_DEVELOPMENT")))) (format t "~&HyperDoc standalone executable~%Port: ~D~%URL: http://127.0.0.1:~D/boot.html~%" port port) (finish-output) (hyperbook/server:serve-catalog :port port :development dev) (loop (sleep 3600))))' \
>   --eval '(sb-ext:save-lisp-and-die #P"$(abspath $(SERVER_EXE))" :toplevel (function cl-user::main) :executable t)'
> @echo "==> Built $(SERVER_EXE)"

$(CLOG_FRAME_CPP):
> @echo "==> Fetching CLOG source"
> mkdir -p "$(dir $(CLOG_DIR))"
> if [ ! -d "$(CLOG_DIR)/.git" ]; then \
>   git clone --depth 1 --branch "$(CLOG_REF)" "$(CLOG_REPO)" "$(CLOG_DIR)"; \
> else \
>   git -C "$(CLOG_DIR)" fetch --depth 1 origin "$(CLOG_REF)"; \
>   git -C "$(CLOG_DIR)" checkout "$(CLOG_REF)"; \
>   git -C "$(CLOG_DIR)" reset --hard "origin/$(CLOG_REF)" || true; \
> fi
> test -f "$(CLOG_FRAME_CPP)"

$(FRAME_EXE): $(CLOG_FRAME_CPP)
> @echo "==> Building CLOG Frame"
> mkdir -p "$(dir $(FRAME_EXE))"
ifeq ($(UNAME_S),Darwin)
> cd "$(CLOG_FRAME_DIR)" && env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" HOME="$$HOME" TMPDIR="$${TMPDIR:-/tmp}" \
>   /usr/bin/xcrun --sdk macosx clang++ clogframe.cpp -std=c++11 -framework WebKit -o clogframe
else ifeq ($(UNAME_S),Linux)
> cd "$(CLOG_FRAME_DIR)" && c++ clogframe.cpp -std=c++11 $$(pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0) -o clogframe
else
> @echo "Unsupported platform: $(UNAME_S)" >&2
> @exit 1
endif
> install -m 0755 "$(CLOG_FRAME_DIR)/clogframe" "$(FRAME_EXE)"
> @echo "==> Built $(FRAME_EXE)"

$(RUNNER): Makefile $(SERVER_EXE) $(FRAME_EXE)
> @echo "==> Writing runner"
> mkdir -p "$(dir $(RUNNER))"
> printf '%s\n' "$$RUNNER_SCRIPT" > "$(RUNNER)"
> chmod +x "$(RUNNER)"
> @echo "==> Built $(RUNNER)"

run: all
> "$(RUNNER)"

stop:
> @if [ -f "$(PID_FILE)" ]; then \
>   pid="$$(cat "$(PID_FILE)")"; \
>   if kill -0 "$$pid" 2>/dev/null; then \
>     echo "Stopping HyperDoc server $$pid"; \
>     kill "$$pid" 2>/dev/null || true; \
>   else \
>     echo "No running server for stale PID $$pid"; \
>   fi; \
> else \
>   echo "No PID file."; \
> fi
> rm -f "$(PID_FILE)" "$(PORT_FILE)"

status:
> @if [ -f "$(PID_FILE)" ] && kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
>   echo "running"; \
>   echo "pid:  $$(cat "$(PID_FILE)")"; \
>   echo "port: $$(cat "$(PORT_FILE)" 2>/dev/null || echo unknown)"; \
>   echo "log:  $(LOG_FILE)"; \
> else \
>   echo "not running"; \
> fi

clean:
> -$(MAKE) stop
> rm -rf "$(SERVER_DIR)" "$(FRAME_DIR)"

rebuild: clean all

help:
> @echo "Standalone CLOG Frame:"
> @echo "  make        build standalone CLOG Frame bundle"
> @echo "  make run    launch it"
> @echo "  make stop   stop background HyperDoc server"
> @echo "  make status show server status"
> @echo "  make clean  remove generated bundle"
> @echo
> @echo "Repomix:"
> @echo "  make repomix"
> @echo "  make repomix PACK=dock"
> @echo "  make repomix-full"
> @echo "  make repomix-core"
> @echo "  make repomix-all"
> @echo "  make repomix-clean"

repomix:
> @echo "==> Repomix: generating $(PACK) pack"
> tools/repomix-pack.sh $(PACK)

repomix-core:
> @echo "==> Repomix: generating core pack"
> tools/repomix-pack.sh core

repomix-dock:
> @echo "==> Repomix: generating dock pack"
> tools/repomix-pack.sh dock

repomix-validation:
> @echo "==> Repomix: generating validation pack"
> tools/repomix-pack.sh validation

repomix-fedwiki:
> @echo "==> Repomix: generating fedwiki pack"
> tools/repomix-pack.sh fedwiki

repomix-dmx:
> @echo "==> Repomix: generating dmx pack"
> tools/repomix-pack.sh dmx

repomix-deployment:
> @echo "==> Repomix: generating deployment pack"
> tools/repomix-pack.sh deployment

repomix-dm6:
> @echo "==> Repomix: generating dm6 pack"
> tools/repomix-pack.sh dm6

repomix-zotero:
> @echo "==> Repomix: generating zotero pack"
> tools/repomix-pack.sh zotero

repomix-full:
> @echo "==> Repomix: generating full repository pack"
> tools/repomix-pack.sh full

repomix-all:
> @echo "==> Repomix: generating focused packs: $(REPOMIX_FOCUSED_PACKS)"
> for pack in $(REPOMIX_FOCUSED_PACKS); do \
>   tools/repomix-pack.sh "$$pack"; \
> done

repomix-clean:
> @echo "==> Repomix: removing generated outputs"
> rm -f repomix-output-hyperdoc*.md repomix-output-hyperdoc*.xml

repomix-help:
> @echo "Repomix targets:"
> @echo "  make repomix"
> @echo "  make repomix PACK=dock"
> @echo "  make repomix-core"
> @echo "  make repomix-dock"
> @echo "  make repomix-validation"
> @echo "  make repomix-fedwiki"
> @echo "  make repomix-dmx"
> @echo "  make repomix-deployment"
> @echo "  make repomix-dm6"
> @echo "  make repomix-zotero"
> @echo "  make repomix-all"
> @echo "  make repomix-full"
> @echo "  make repomix-clean"