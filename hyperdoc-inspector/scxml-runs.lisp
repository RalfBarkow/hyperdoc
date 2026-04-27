;;;; Inspector views for SCXML repair-protocol dry-runs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(views:defview 👀overview
    (run hyperdoc::page-lookup-topic-repair-scxml-run)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::scxml-run-scxml-path-of run))))))
              (:tr (:td (views:esc "Command"))
                   (:td (:pre
                         (views:esc
                          (format nil "~{~A~^ ~}"
                                  (hyperdoc::scxml-run-command-of run))))))
              (:tr (:td (views:esc "Exit code"))
                   (:td (:tt
                         (views:esc
                          (princ-to-string
                           (hyperdoc::scxml-run-exit-code-of run)))))))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc
             (or (hyperdoc::scxml-run-stdout-of run) "")))
      (when (plusp (length (or (hyperdoc::scxml-run-stderr-of run) "")))
        (views:html
          (:h3 (views:esc "Errors"))
          (:pre (views:esc
                 (hyperdoc::scxml-run-stderr-of run))))))))