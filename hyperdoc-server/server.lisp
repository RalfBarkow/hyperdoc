;;;; Web server for HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/server)

(defun serve-catalog (&key (port 8080))
  (clog:initialize
   #'(lambda (body)
       (clog-moldable-inspector::on-new-inspector body
                                                  :object hyperdoc:*catalog*
                                                  :pane-width 750))
   :port port))
