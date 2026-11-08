;;;; Isolated fixture run; no productive Wiki or server is started.
(require :asdf)
(asdf:load-asd (merge-pathnames "../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:test-system "dreyeck/work/fedwiki-local-only/tests")
