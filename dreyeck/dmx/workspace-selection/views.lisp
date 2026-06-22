;;;; Optional inspector entrypoint for the live workspace-selection result.

(in-package #:dreyeck.dmx.workspace-selection)

(defun inspect-dmx-sqlite-workspace-selection ()
  "Run the live selection and inspect it when CLOG Moldable Inspector is loaded."
  (let ((result (select-dmx-sqlite-workspace-with-shop3)))
    (let* ((package (find-package "CLOG-MOLDABLE-INSPECTOR"))
           (inspector (and package (find-symbol "CLOG-INSPECT" package))))
      (when (and inspector (fboundp inspector))
        (handler-case
            (funcall (symbol-function inspector) :object result)
          (condition (condition)
            (format *error-output*
                    "~&CLOG workspace-selection inspection failed: ~A~%"
                    condition)))))
    result))
