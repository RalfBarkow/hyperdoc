;;;; PR #33's own, unchanged test suite (dreyeck/work/defederation-planning/tests), including the SHOP3 singleton warning.
;;;; Independent review of PR #33 at 7bc2fced4e970e813d870307162ec349380ca0aa (docs/defederation-consolidation/review/README.md).
;;;; From the repository root, with the project's ASDF registry (SBCL 2.4.10, SHOP3 ce53f9b, e.g. in `nix develop`):
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/own-suite.lisp
(require :asdf)
(asdf:load-asd (merge-pathnames "../../../../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:test-system "dreyeck/work/defederation-planning")
