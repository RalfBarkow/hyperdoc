;;;; Re-run PR #32's read-only Critic/Judgement reading test (no engine, no new Critique). PR_TREE = extraction of e1ab2f5.
(require :asdf)
(asdf:load-asd (merge-pathnames "dreyeck.asd" (uiop:ensure-directory-pathname (uiop:getenv "PR_TREE"))))
(asdf:test-system "dreyeck/work/fedwiki-link-resolution/critic")
(format t "~&CRITIC-READER-DONE~%")
