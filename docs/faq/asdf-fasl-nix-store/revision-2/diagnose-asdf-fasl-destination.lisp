;;;; FAQ asdf-fasl-nix-store: read-only diagnosis inside a running image (for example the SLY REPL).
;;;; It reads ASDF state and probes files. It compiles nothing, loads no system, searches no
;;;; source registry and creates no file. Reading the form interns its variable names in the
;;;; current package. Calling APPLY-OUTPUT-TRANSLATIONS initializes the translations if this
;;;; image has not done so yet; "translations-initialized" is printed before that happens.
;;;;
;;;;   (load "diagnose-asdf-fasl-destination.lisp")
;;;;
;;;; Change SYSTEM and COMPONENT below for another case; the defaults name the Mac trace's file.
(let* ((system "salza2")
       (component "package")
       (initialized (asdf/output-translations:output-translations-initialized-p))
       (sys (asdf:registered-system system))
       (comp (and sys (asdf:find-component sys component)))
       (src (and comp (asdf:component-pathname comp)))
       (probe #p"/nix/store/00000000000000000000000000000000-faq-probe/package.lisp"))
  (format t "~&lisp ~A ~A~%asdf ~A~%" (lisp-implementation-type) (lisp-implementation-version)
          (asdf:asdf-version))
  (dolist (var '("ASDF_OUTPUT_TRANSLATIONS" "CL_SOURCE_REGISTRY" "XDG_CACHE_HOME" "HOME"))
    (let ((v (uiop:getenv var)))
      (format t "env ~A ~:[unset~;~:*set, ~D characters~]~@[, mentions ~A~]~%"
              var (and v (length v)) (and v (search system v) system))))
  (format t "user-cache ~A~%" asdf:*user-cache*)
  (dolist (p (list (asdf:user-output-translations-pathname)
                   (asdf:user-output-translations-directory-pathname)
                   (asdf:system-output-translations-pathname)
                   (asdf:system-output-translations-directory-pathname)))
    (when p (format t "config ~A ~:[absent~;present~]~%" p (probe-file p))))
  (format t "translations-initialized ~A~%" initialized)
  (format t "store-probe-destination ~A~%" (asdf:apply-output-translations probe))
  (format t "system ~A ~:[not-registered~;registered~]~%" system sys)
  (when sys
    (format t "system-source-file ~A~%" (asdf:system-source-file sys))
    (format t "component ~A ~:[not-found~;found~]~%" component comp))
  (when src
    (let ((fasl (first (asdf:output-files (asdf:make-operation 'asdf:compile-op) comp))))
      (format t "component-source ~A ~:[absent~;present~]~%" src (probe-file src))
      (format t "fasl-destination ~A ~:[absent~;present~]~%" fasl (probe-file fasl))))
  (values))
