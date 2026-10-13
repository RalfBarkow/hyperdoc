# Bounded Solo definition extraction

This tool parses the unchanged, retained Solo `client/dialog/index.html` from
`https://github.com/WardCunningham/wiki-plugin-solo`, commit
`17915844349bada64c901bd5ea73472702c446f9`. It never evaluates the extracted
JavaScript or loads its imports. Only `composite`, `composite/merge`, and
`composite/merge/mergeprops` are exported.

## Offline dependency

`vendor/acorn-8.16.0/acorn.mjs` is an unmodified copy of the locally installed
Acorn 8.16.0 distribution, with its package metadata and MIT license.
`vendor/acorn-lock.json` pins all three files by SHA-256. No npm installation,
network request, Nix pin change or runtime parser dependency is needed.
The local Wiki lockfile did not pin this top-level 8.16.0 installation (it
records a nested 8.15.0). No npm tarball integrity or Acorn Git revision is
claimed. The committed bytes and digest are this extraction's dependency authority.
Node 20+ is required for authoring; verified with Node 24.19.0.

From the repository root:

```sh
node tools/how-trails-definitions/extract.mjs --check
node tools/how-trails-definitions/test.mjs
# Deliberate regeneration, followed by diff review:
node tools/how-trails-definitions/extract.mjs
```

The full Solo SHA-256 is checked before selecting the known fifth script
(zero-based ordinal 4), at lines 32–584. This is a bounded selector for one
immutable file, not a general HTML extraction algorithm. Acorn parses its
module body with `ecmaVersion: 2022`. Generated JSON has no timestamps or
machine paths and must be byte-identical on repeat extraction.

Offsets: AST spans are script-relative UTF-16 code units, end exclusive.
File-relative UTF-16 and UTF-8 byte offsets are both recorded. Lines are
one-based in the original HTML; columns are zero-based UTF-16. The script
has its own body digest. Full definition text excludes surrounding whitespace.

## Inspector contract

The Lisp loader verifies the generated artifact's digest, source authority,
source bytes, script bounds, definition hierarchy, line/column coordinates,
UTF-16 spans, and exact UTF-8 slices before creating objects. Changes to the
extraction must update the reviewed artifact digest in `javascript-definitions.lisp`.
No parser, Node process or JavaScript evaluation runs in the Inspector.

Identity is repository + full commit OID + Git pathname + script ordinal +
AST start/end. Names and scope paths describe the definitions; they are not
sufficient identity. Objects reuse the existing Git revision/file objects.
Ward's original source-range object remains separate from the complete definition.
Only `composite` links the retained execution record as its witness. Nested
functions explicitly do not claim isolated test coverage.

The existing Lisp reading suite and `scripts/test-how-trails-source-navigation.mjs`
exercise these objects, rejected identities/spans, and the fresh browser journey.
No source Wiki JSON, Solo source, execution record or original range is rewritten.

A future JavaScript Functions HyperBook still needs decisions about general HTML
script discovery, anonymous/assigned functions, scope and module resolution,
parser upgrades, indexing and cross-revision identity. This bounded example does
not establish those contracts or runtime function identities.
