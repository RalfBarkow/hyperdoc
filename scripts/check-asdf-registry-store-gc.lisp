;;;; FAQ asdf-registry-store-gc: what ASDF does when a registered .asd vanishes from the Nix store, read in one process.
;;;; Run by scripts/check-asdf-registry-store-gc.sh; the store path comes from a file, not from the environment.
(require :asdf)

(defun say (fmt &rest args) (apply #'format t fmt args) (terpri) (finish-output))
(defun fail (fmt &rest args) (apply #'say (concatenate 'string "FAIL " fmt) args) (uiop:quit 1))
(defun run (&rest command)
  "Run COMMAND without the image's library path, which the SBCL wrapper sets and which breaks Nix's own binaries."
  (multiple-value-bind (out err code) (uiop:run-program (list* "env" "-u" "LD_LIBRARY_PATH" "-u" "DYLD_LIBRARY_PATH" command) :output :string :error-output :string :ignore-error-status t)
    (values code (string-trim '(#\Newline #\Space) out) (string-trim '(#\Newline #\Space) err))))

(defun vanished-registry-entries ()
  "The diagnosis the FAQ prints for a running image: source-registry entries and registered systems whose .asd is gone."
  (append
   (loop for name being the hash-keys of asdf/source-registry::*source-registry* using (hash-value asd)
         unless (probe-file asd) collect (list :registry name asd))
   (loop for name in (asdf:registered-systems)
         for asd = (asdf:system-source-file (asdf:registered-system name))
         when (and asd (not (probe-file asd))) collect (list :registered name asd))))

(let* ((path-file (uiop:getenv "FAQ_STORE_PATH_FILE"))
       (store (string-trim '(#\Newline) (uiop:read-file-string path-file)))
       (asd (concatenate 'string store "/faq-gc-probe.asd")))
  (say "case=registered SBCL=~A ASDF=~A" (lisp-implementation-version) (asdf:asdf-version))
  ;; Like the Nix wrapper's CL_SOURCE_REGISTRY entry STORE//: a tree, scanned once when ASDF first searches.
  (asdf:initialize-source-registry `(:source-registry (:tree ,(uiop:ensure-directory-pathname store))
                                                      (:directory ,(uiop:ensure-directory-pathname (uiop:getenv "FAQ_USER_DIR")))
                                                      :inherit-configuration))
  (asdf/source-registry:ensure-source-registry)
  (let ((cached (gethash "faq-gc-probe" asdf/source-registry::*source-registry*)))
    (unless (and cached (equal (namestring cached) asd)) (fail "registered: registry entry ~S, expected ~A" cached asd))
    (say "PASS registered: registry maps faq-gc-probe to ~A before the system is loaded" (namestring cached)))

  (say "case=vanished")
  (multiple-value-bind (code out err) (run "nix-store" "--delete" store)
    (declare (ignore out))
    (unless (and (zerop code) (not (probe-file asd))) (fail "vanished: nix-store --delete exit ~D: ~A" code err)))
  ;; As in the operator's image: a system outside the store depends on the vanished one.
  (let ((condition (nth-value 1 (ignore-errors (asdf:load-system "faq-gc-user")))))
    (unless (and condition (typep condition 'asdf:load-system-definition-error)
                 (search "file does not exist" (princ-to-string condition))
                 (search asd (princ-to-string condition)))
      (fail "vanished: expected LOAD-SYSTEM-DEFINITION-ERROR for ~A, got ~S" asd condition))
    (say "PASS vanished: load-system faq-gc-user signals ~A: ~A"
         (type-of condition) (substitute #\Space #\Newline (princ-to-string condition))))
  (let ((condition (nth-value 1 (ignore-errors (asdf:find-system "faq-gc-probe")))))
    (say "observed: find-system faq-gc-probe directly signals ~A: ~A" (type-of condition) condition))

  (say "case=diagnose")
  (let ((entries (vanished-registry-entries)))
    (unless (find "faq-gc-probe" entries :key #'second :test #'equal) (fail "diagnose: entries ~S" entries))
    (say "PASS diagnose: ~D vanished entr~:@P, including ~S" (length entries) (find "faq-gc-probe" entries :key #'second :test #'equal)))

  (say "case=restored")
  ;; The same directory added again yields the same content-addressed path; the registry entry needs no change.
  (multiple-value-bind (code out err) (run "nix" "--extra-experimental-features" "nix-command" "store" "add-path"
                                           "--name" (subseq store (1+ (position #\- store)))
                                           (uiop:getenv "FAQ_FIXTURE_DIR"))
    (unless (and (zerop code) (equal out store)) (fail "restored: add-path exit ~D gave ~S (~A), expected ~A" code out err store)))
  (progn
    (asdf:load-system "faq-gc-user")
    (unless (equal 42 (uiop:symbol-call :cl-user :faq-gc-answer)) (fail "restored: answer"))
    (say "PASS restored: same path ~A; load-system faq-gc-user succeeds in the same process, without restarting it; answer=42" store)))
