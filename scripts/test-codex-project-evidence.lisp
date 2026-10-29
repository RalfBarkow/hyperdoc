;;;; Focused source regeneration and Project Workspace checks for the Codex report.
;;;; Run in the pinned Lisp runtime from the repository root, with its dependency
;;;; source registry plus this checkout and the verified Topic Maps snapshot.
;;;; Verifies a temporary materialization before replacing the retained CTM/digest.
(require :asdf)
(asdf:load-system "dreyeck/work/project/tests")
(uiop:with-temporary-file (:pathname marker)
  (let ((staged (uiop:ensure-directory-pathname
                 (concatenate 'string (namestring marker) "-ctm/"))))
    (ensure-directories-exist staged)
    (unwind-protect
      (let ((ctm (merge-pathnames "hyperdoc-project.ctm" staged))
        (digest-file (merge-pathnames "hyperdoc-project.ctm.sha256" staged))
        (verified-octets nil))
    (progv (list (find-symbol "+PROJECT-CTM-FILE+" :dreyeck/work/project)
                 (find-symbol "+PROJECT-CTM-DIGEST-FILE+" :dreyeck/work/project))
           (list (namestring ctm) (namestring digest-file))
      (uiop:symbol-call :dreyeck/work/project :write-project-ctm)
      ;; Source, read-back/navigation and acceptance-fixture checks only.
      ;; No broader scope/transition suite or Topic Maps corpus validation.
      (uiop:symbol-call :dreyeck/work/project/tests :run-tests)
      (setf verified-octets (uiop:symbol-call :dreyeck/work/project :%octets ctm)))
    ;; The authored sources must still produce exactly the verified octets.
    (assert (equalp verified-octets
                    (uiop:symbol-call :dreyeck/work/project :%utf8
                                     (uiop:symbol-call :dreyeck/work/project :materialize-project-ctm))))
    (multiple-value-bind (pathname digest)
        (uiop:symbol-call :dreyeck/work/project :write-project-ctm)
      (assert (equalp verified-octets (uiop:symbol-call :dreyeck/work/project :%octets pathname)))
      (format t "~&PROJECT-CTM-MATERIALIZED ~A SHA256 ~A~%" pathname digest)))
      (uiop:delete-directory-tree staged :validate t :if-does-not-exist :ignore))))
(format t "~&CODEX-PROJECT-EVIDENCE-PASS~%")
