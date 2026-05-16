;;;; Public entry points for DM6 page-local topicmap seeds.
;;;;
;;;; The concrete generator lives in hyperdoc/explorer because it works with
;;;; loaded page DOMs and inspector views. These narrow entry points keep page
;;;; expressions fboundp when only the core HyperDoc system is loaded.

(in-package :hyperdoc)

(defun dm6-inline-proof-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/DM6 AppEmbed HyperDoc Inline Proof.html"))

(defun dm6-page-topicmap-seed-report (&rest args &key &allow-other-keys)
  (let ((fallback (symbol-function 'dm6-page-topicmap-seed-report)))
    (asdf:load-system :hyperdoc/explorer)
    (let ((implementation (symbol-function 'dm6-page-topicmap-seed-report)))
      (when (eq implementation fallback)
        (error "hyperdoc/explorer did not install dm6-page-topicmap-seed-report."))
      (apply implementation args))))
