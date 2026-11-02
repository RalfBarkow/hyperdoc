;;;; What a status that is an USOCKET:NS-UNKNOWN-ERROR does to the view that reports a site's status (SITEMAP-SNAPSHOT of this checkout).
;;;; A handler on the parent class USOCKET:NS-ERROR would store such a status; the SBCL backend of usocket never raises it, so this is a
;;;; property of the handler's reach, not an observed failure. A status of NS-TRY-AGAIN-ERROR is the control.
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(uiop:ensure-directory-pathname (or (uiop:getenv "CHECKOUT") (error "CHECKOUT")))) :inherit-configuration))
(let ((*standard-output* (make-broadcast-stream)) (*error-output* (make-broadcast-stream)))
  (asdf:load-system "clog") (asdf:load-system "hyperbook/fedwiki"))
(dolist (class '(usocket:ns-try-again-error usocket:ns-unknown-error))
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "fedwiki:wiki.test-host.invalid")))
    (setf (hyperbook/fedwiki::status-of wiki) (make-condition class :socket nil :host-or-ip "wiki.test-host.invalid"))
    (format t "~&status ~S -> SITEMAP-SNAPSHOT ~A~%" class
            (handler-case (let ((snapshot (hyperbook/fedwiki::sitemap-snapshot wiki)))
                            (format nil "state=~S message=~S" (gethash "state" snapshot) (gethash "message" snapshot)))
              (error (e) (format nil "SIGNALS ~S" (type-of e)))))))
