;;;; FAQ check: asdf-fasl-nix-store
;;;; Would ASDF have to write a compiled file into /nix/store for this source?
;;;; Run in a fresh process only; it ends the process (never load it into a working image).
;;;;
;;;;   sbcl --noinform --non-interactive --no-userinit --load check-asdf-fasl-destination.lisp
;;;;
;;;; Source to check (first match wins):
;;;;   FAQ_SYSTEM=<name> [FAQ_COMPONENT=<name>]  a file of that system (default: its first file)
;;;;   FAQ_PROBE_SOURCE=<path>                    any source path
;;;;   otherwise                                  a made-up store path outside every packaged library
;;;; FAQ_CHECK_READ_ONLY=1 creates nothing; then creatability is reported as not checked.
;;;;
;;;; Exit 0  no write into the store is needed: the destination is outside the store
;;;;         (and can be created), or it is in the store and the compiled file is already there.
;;;; Exit 1  the destination is in the store and the compiled file is missing.
;;;; Exit 2  the destination is outside the store but cannot be created.
;;;; Exit 3  the named system or component was not found.
;;;; Exit 0 with a store destination still means: any recompilation of that file will fail.
(require :asdf)
(defun faq-report (key value) (format t "~&~A ~A~%" key value))
(let* ((system-name (uiop:getenv "FAQ_SYSTEM"))
       (read-only (equal (uiop:getenv "FAQ_CHECK_READ_ONLY") "1"))
       (system (and system-name (asdf:find-system system-name nil)))
       (component (and system
                       (let ((name (uiop:getenv "FAQ_COMPONENT")))
                         (if name
                             (asdf:find-component system name)
                             (find-if (lambda (c) (typep c 'asdf:cl-source-file))
                                      (asdf:component-children system))))))
       (source (cond (system-name (and component (asdf:component-pathname component)))
                     (t (pathname (or (uiop:getenv "FAQ_PROBE_SOURCE")
                                      "/nix/store/00000000000000000000000000000000-faq-probe/package.lisp")))))
       (fasl (cond (component (first (asdf:output-files (asdf:make-operation 'asdf:compile-op) component)))
                   (source (compile-file-pathname (asdf:apply-output-translations source))))))
  (faq-report "lisp" (format nil "~A ~A" (lisp-implementation-type) (lisp-implementation-version)))
  (faq-report "asdf" (asdf:asdf-version))
  (faq-report "env-ASDF_OUTPUT_TRANSLATIONS"
              (let ((v (uiop:getenv "ASDF_OUTPUT_TRANSLATIONS")))
                (if v (format nil "set, ~D characters" (length v)) "unset")))
  (when system-name (faq-report "system" (format nil "~A ~:[not-found~;found~]" system-name system)))
  (unless source
    (format t "FAIL not-found: system or component not found.~%")
    (uiop:quit 3))
  (faq-report "source" (format nil "~A ~:[absent~;present~]" source (probe-file source)))
  (faq-report "fasl-destination" fasl)
  (cond ((uiop:string-prefix-p "/nix/store/" (namestring fasl))
         (cond ((probe-file fasl)
                (format t "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.~%")
                (uiop:quit 0))
               (t
                (format t "FAIL store-destination: ASDF would have to write into the store.~%")
                (uiop:quit 1))))
        (read-only
         (format t "PASS read-only: destination is outside the store; creatability not checked.~%")
         (uiop:quit 0))
        ((handler-case (progn (ensure-directories-exist fasl) t) (error () nil))
         (format t "PASS: destination is outside the store and can be created.~%")
         (uiop:quit 0))
        (t
         (format t "FAIL not-creatable: ~A cannot be created (check HOME or XDG_CACHE_HOME).~%"
                 (uiop:pathname-directory-pathname fasl))
         (uiop:quit 2))))
