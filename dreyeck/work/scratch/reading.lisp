(in-package #:hyperdoc-scratch)

;; The standalone page uses ordinary fragments and a relative CTM link. A
;; browser inspecting a Lisp object has no file URL for that adjacent CTM.
(defvar *reading-tags* nil)
(plump:define-tag-dispatcher (reading-link *reading-tags*) (name)
  (string-equal name "a"))

(plump:define-tag-printer reading-link (element)
  (when (equal "../scratch.ctm" (plump:attribute element "href"))
    (let ((bytes (alexandria:read-file-into-byte-vector (topic-map-pathname))))
      (html-inspector-views:html
        (:a :download "scratch.ctm"
            :href (concatenate 'string "data:text/plain;base64,"
                               (cl-base64:usb8-array-to-base64-string bytes))
            (html-inspector-views:esc (plump:text element)))))
    t))

(defmethod hyperbook:html-page-assets-of ((book (eql *hyperdoc*)))
  (make-instance 'hyperbook:html-page-assets :inherit (call-next-method)
                 :tag-dispatchers '*reading-tags*))
