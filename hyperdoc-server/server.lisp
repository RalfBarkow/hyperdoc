;;;; Web server for HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/server)

(defun serve-catalog (&key (port 8080) (development nil))
  (setf hyperdoc:*development-features* development)
  (clog-moldable-inspector:clog-serve-inspector hyperdoc:*catalog*
                                                :pane-width "700px"
                                                :port port))
