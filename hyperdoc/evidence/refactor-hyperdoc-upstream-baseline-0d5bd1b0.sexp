(:refactor-hyperdoc-upstream-baseline
 (:upstream
  (:repo "https://codeberg.org/khinsen/hyperdoc.git"
   :remote-used "khinsen"
   :commit "0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc"
   :short-commit "0d5bd1b0"
   :subject "Render HTML story items"
   :verified t))
 (:local
  (:repo-root "/Users/rgb/workspace/hyperdoc"
   :head "4f0e75af4bc83e2b8baabe62a05af80a67a88d72"
   :head-subject "fix(shop3): narrow provider source registry to avoid Alexandria package conflict"))
 (:commands
  ((:command "git fetch khinsen 0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc"
    :result "FETCH_HEAD updated from https://codeberg.org/khinsen/hyperdoc")
   (:command "git cat-file -t 0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc"
    :result "commit")
   (:command "git show --stat --oneline --decorate --no-renames 0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc"
    :result
    ((:headline "0d5bd1b0 Render HTML story items")
     (:changed-path "hyperbook-fedwiki/story-items.lisp")
     (:insertions 5)
     (:deletions 4)))))
 (:no-branch-mutation
  ((:merge nil)
   (:reset nil)
   (:checkout nil)
   (:remote-switch nil))))
