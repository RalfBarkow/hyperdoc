(defpackage #:dreyeck/source-snapshot/tests
  (:use #:cl)
  (:local-nicknames (#:s #:dreyeck/source-snapshot) (#:v #:html-inspector-views))
  (:export #:run-tests #:snapshot-root))
(in-package #:dreyeck/source-snapshot/tests)

(defparameter +commit+ "6162ed68c94ea4796b8cf2282edd347d9607b08c")
;; Blob ids read with `git rev-parse 6162ed68:<path>` from the repository, an oracle independent of this verifier (equal at b2eecffa).
(defparameter +oracle-blobs+ '(("examples/project-work.ctm" . "7548c7dd2d3547ea2c7d2dff751c5cc78d0e08dd")
                               ("src/ctm/lexer.lisp" . "2cb1fec9f23a1bbabfeb51d8f003a8da725b1a31")))
(defvar *checks* nil)
(defmacro check (label form)
  `(progn (unless ,form (error "Source snapshot check failed: ~A" ,label)) (push ,label *checks*)))
(defmacro refused (form) `(handler-case (progn ,form nil) (s:snapshot-refused () t)))

(defun snapshot-root ()
  "The /nix/store snapshot under test: ASDF's topic-maps root when that is one, else HYPERDOC_TOPIC_MAPS_SNAPSHOT. No
other source is accepted, so a run without a snapshot fails instead of passing on a checkout."
  (let ((asdf-root (ignore-errors (asdf:system-source-directory "topic-maps")))
        (named (uiop:getenv "HYPERDOC_TOPIC_MAPS_SNAPSHOT")))
    (cond ((and asdf-root (eq :nix-store-snapshot (s:source-kind asdf-root))) asdf-root)
          ((and named (plusp (length named))) (uiop:ensure-directory-pathname named))
          (t (error "No /nix/store Topic Maps snapshot: neither ASDF's topic-maps root nor HYPERDOC_TOPIC_MAPS_SNAPSHOT.")))))

(defun run (&rest arguments) (uiop:run-program arguments :output :string :error-output :string))
(defun native (directory &optional (path "")) (concatenate 'string (string-right-trim "/" (namestring directory)) "/" path))

(defun run-tests ()
  (let* ((*checks* nil) (root (snapshot-root)) (manifest (s:find-snapshot-manifest +commit+))
         (temp (ensure-directories-exist
                (merge-pathnames (format nil "hyperdoc-snapshot-~36R/" (random (expt 36 10) (make-random-state t)))
                                 (uiop:temporary-directory))))
         (copy (merge-pathnames "tree/" temp)))
    (unwind-protect
         (progn
           ;; The store snapshot verifies, and its files hash as Git hashed them.
           (let ((verification (s:verify-store-snapshot root +commit+)))
             (check :store-snapshot-verifies (typep verification 's:snapshot-verification))
             (check :every-step-of-the-chain
                    (equal (s:verification-checks verification)
                           '(:commit-object-hashes-to-commit :commit-names-root-tree :root-listing-hashes-to-root-tree
                             :root-entries-are-the-shipped-entries :shipped-entries-hash-to-the-commit)))
             (check :all-shipped-files-hashed (= 2354 (s:verification-blob-count verification)))
             (check :blobs-equal-git-oracle
                    (every (lambda (pair) (equal (cdr pair) (s:verification-blob-id verification (car pair)))) +oracle-blobs+))
             (check :excluded-not-shipped (and (equal '("reports") (s:manifest-excluded manifest))
                                               (not (probe-file (merge-pathnames "reports/" root)))
                                               (null (s:verification-blob-id verification "reports/README.md"))))
             (let ((file (s:make-snapshot-file verification "examples/project-work.ctm")))
               (check :snapshot-file-reads-the-verified-blob
                      (string= (s:snapshot-file-contents file) (uiop:read-file-string (native root "examples/project-work.ctm"))))
               (check :unshipped-file-refused (refused (s:make-snapshot-file verification "reports/README.md"))))
             (check :views-name-commit-and-exclusion
                    (let ((html (v:view-html (find "Source snapshot" (v:all-views verification) :key #'v:view-title :test #'equal))))
                      (and (search +commit+ html) (search "reports/ (tree 44adbb2c63d01c9a531b78cb04937f05284151de)" html)))))
           (check :store-root-is-store-snapshot (eq :nix-store-snapshot (s:source-kind root)))
           ;; The tree check does not depend on the location; the source policy does.
           (run "cp" "-R" (native root) (native copy))
           (run "chmod" "-R" "u+w" (native copy))
           (check :copy-tree-verifies (typep (s:verify-snapshot-tree copy manifest) 's:snapshot-verification))
           (check :copy-is-not-a-source (and (eq :unverifiable (s:source-kind copy)) (refused (s:verify-store-snapshot copy +commit+))))
           ;; Each change of the tree is refused, and undone before the next.
           (flet ((mutant (label change undo)
                    (unwind-protect (progn (funcall change) (check label (refused (s:verify-snapshot-tree copy manifest))))
                      (funcall undo))
                    (check :copy-restored (typep (s:verify-snapshot-tree copy manifest) 's:snapshot-verification)))
                  (restore (path) (run "rm" "-rf" (native copy path)) (run "cp" "-p" (native root path) (native copy path))
                    (run "chmod" "u+w" (native copy path))))
             (mutant :one-byte-changed
                     (lambda () (with-open-file (out (native copy "src/ctm/lexer.lisp") :direction :output :if-exists :append)
                                  (write-char #\Space out)))
                     (lambda () (restore "src/ctm/lexer.lisp")))
             (mutant :executable-bit-added (lambda () (run "chmod" "u+x" (native copy "topic-maps.asd")))
                     (lambda () (run "chmod" "u-x" (native copy "topic-maps.asd"))))
             (mutant :extra-root-file (lambda () (run "touch" (native copy "extra")))
                     (lambda () (run "rm" (native copy "extra"))))
             (mutant :extra-nested-file (lambda () (run "touch" (native copy "src/extra.lisp")))
                     (lambda () (run "rm" (native copy "src/extra.lisp"))))
             (mutant :missing-file (lambda () (run "rm" (native copy "examples/project-work.lisp")))
                     (lambda () (restore "examples/project-work.lisp")))
             (mutant :excluded-entry-present (lambda () (run "mkdir" (native copy "reports")) (run "touch" (native copy "reports/x")))
                     (lambda () (run "rm" "-rf" (native copy "reports"))))
             (mutant :symlink-for-a-file (lambda () (run "rm" (native copy "LICENSE")) (run "ln" "-s" "README.md" (native copy "LICENSE")))
                     (lambda () (restore "LICENSE")))
             (mutant :git-directory-added (lambda () (run "mkdir" (native copy ".git")) (run "touch" (native copy ".git/HEAD")))
                     (lambda () (run "rm" "-rf" (native copy ".git")))))
           (run "mkdir" (native copy ".git"))
           (check :checkout-is-a-checkout (eq :git-checkout (s:source-kind copy)))
           (run "rm" "-rf" (native copy ".git"))
           ;; A manifest that is not the commit's own objects is refused.
           (flet ((altered (label &rest initargs)
                    (check label (refused (s:verify-snapshot-tree
                                           copy (apply #'make-instance 's:snapshot-manifest
                                                       (append initargs
                                                               (list :pathname nil :commit (s:manifest-commit manifest)
                                                                     :commit-object (s:manifest-commit-object manifest)
                                                                     :root-tree (s:manifest-root-tree manifest)
                                                                     :entries (s:manifest-entries manifest)
                                                                     :excluded (s:manifest-excluded manifest)
                                                                     :nar-hash (s:manifest-nar-hash manifest)))))))))
             (altered :other-commit-id :commit "b9517b977fca2105422892a14b4cf9fe9790bbba")
             (altered :altered-commit-object :commit-object (substitute #\X #\e (s:manifest-commit-object manifest) :count 1 :from-end t))
             (altered :altered-root-entry :entries (substitute-if '("040000" "tree" "0000000000000000000000000000000000000000" "src")
                                                                  (lambda (e) (equal "src" (fourth e))) (s:manifest-entries manifest)))
             (altered :src-excluded-too :excluded '("reports" "src")))
           (check :manifest-for-another-commit-refused (refused (s:find-snapshot-manifest "b9517b977fca2105422892a14b4cf9fe9790bbba")))
           ;; A verified file that changes later is refused when read.
           (let ((file (s:make-snapshot-file (s:verify-snapshot-tree copy manifest) "examples/project-work.ctm")))
             (with-open-file (out (native copy "examples/project-work.ctm") :direction :output :if-exists :append) (write-char #\Space out))
             (check :changed-after-verification-refused-on-read (refused (s:snapshot-file-contents file)))))
      (run "chmod" "-R" "u+w" (native temp))
      (run "rm" "-rf" (native temp)))
    (format t "~&SOURCE-SNAPSHOT-PASS: ~D assertions; ~A verified as Topic Maps ~A without .git; every alteration refused.~%"
            (length *checks*) (namestring root) (subseq +commit+ 0 8))
    t))
