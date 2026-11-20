;;;; Restore probe for FAQ asdf-fasl-nix-store: where would ASDF put salza2's package.fasl
;;;; with the wrapper's configuration, after an override that ignores it, after
;;;; (asdf:initialize-output-translations) and after (asdf:initialize-output-translations nil)?
;;;; It computes destinations only: no system is loaded, nothing is compiled or written.
;;;;
;;;;   sbcl --noinform --non-interactive --no-userinit --load restore-probe.lisp
(require :asdf)
(let ((source (asdf:component-pathname (asdf:find-component (asdf:find-system "salza2") "package"))))
  (flet ((show-destination (point)
           (format t "~&RESTORE~C~A~C~A~%" #\Tab point #\Tab
                   (namestring (compile-file-pathname (asdf:apply-output-translations source))))))
    (show-destination "wrapper")
    (asdf:initialize-output-translations
     '(:output-translations :ignore-inherited-configuration :enable-user-cache))
    (show-destination "override")
    (asdf:initialize-output-translations)
    (show-destination "without-argument")
    (asdf:initialize-output-translations nil)
    (show-destination "with-nil")))
