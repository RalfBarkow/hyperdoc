{ runCommand, python3, source, application }:
runCommand "hyperdoc-dmx-mcp-check" {
  nativeBuildInputs = [ python3 application.runtime ];
} ''
  export CL_SOURCE_REGISTRY="${source}/"
  export ASDF_OUTPUT_TRANSLATIONS="${source}/:$TMPDIR/fasl/"
  export XDG_CACHE_HOME="$TMPDIR/cache"
  mkdir -p "$out"
  if ! ${application}/bin/hyperdoc-dmx-mcp --check > "$TMPDIR/asdf.log" 2>&1; then
    cat "$TMPDIR/asdf.log" >&2
    exit 1
  fi
  python3 ${source}/scripts/test-dmx-mcp-resource-discovery.py \
    --artifacts "$TMPDIR/discovery" > "$out/discovery.log" 2>&1
  python3 ${source}/scripts/test-dmx-mcp-application.py ${application}/bin/hyperdoc-dmx-mcp \
    > "$out/application.log" 2>&1
  cp "$TMPDIR/discovery/results.json" "$out/discovery.json"
  if ! sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
    --script ${source}/scripts/test-dmx-mcp-contracts.lisp > "$TMPDIR/contracts.log" 2>&1; then
    cat "$TMPDIR/contracts.log" >&2
    exit 1
  fi
  python3 - "$TMPDIR" "$out" <<'PY'
import pathlib, sys
for name, prefix in [("contracts.log", "DMX-MCP-CONTRACT "), ("asdf.log", "DMX-MCP-ASDF-CHECK ")]:
    lines = (pathlib.Path(sys.argv[1]) / name).read_text().splitlines()
    (pathlib.Path(sys.argv[2]) / name).write_text("\n".join(line for line in lines if line.startswith(prefix)) + "\n")
PY
''
