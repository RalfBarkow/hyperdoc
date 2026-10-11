(in-package :hyperbook/fedwiki/tests)

(defun dialog-large-page (fixture-file)
  "Trusted generated 1500-entry input supplied by the offline driver only."
  (let ((page (topics-page :context))
        (fixture (with-open-file (in fixture-file) (shasht:read-json in))))
    (assert (equal "Generated trusted 1500-entry test fixture; not observed production data"
                   (gethash "kind" fixture)))
    (dolist (site (cons (fw::origin-of page) (fw::context-of page)))
      (let ((record (find (fw::domain-name-of site) (gethash "sites" fixture)
                          :key (lambda (r) (gethash "domain" r)) :test #'equal)))
        (assert record)
        (fw::fetch-sitemap site :json-fetcher
          (lambda (url) (declare (ignore url)) (gethash "sitemap" record)))))
    page))

(defun check-dialog-contract ()
  (let* ((page (topics-page))
         (item (find :mech (fw::story-of page) :key #'fw::item-type-of))
         (fw::*mech-plugin-host-url* "https://mech.dreyeck.ch/assets/hyperdoc-mech/")
         (view (story-view page)) (html (v:view-html view)))
    (assert (equal "3a62aa636c883134" (fw::id-of item)))
    (assert (search (format nil "CLICK~% POPUP state") (fw::text-of item)))
    (assert (search "No Code item has run" html))
    (assert (member item (mapcar #'cdr (v:view-references view)) :test #'eq)))
  (format t "~&FEDWIKI-MECH-DIALOG-PASS: original item and explicit-initiation Story boundary retained.~%"))

(defun serve-dialog-browser-witness (port host-url stop-file fixture-file)
  "Fresh Inspector; original page plus explicit trusted generated large input."
  (setf fw::*mech-plugin-host-url* host-url)
  (clog:initialize (lambda (body) (declare (ignore body))) :port port :host "127.0.0.1")
  (dolist (entry (list (cons "/ready" (topics-page))
                       (cons "/large" (dialog-large-page fixture-file))))
    (let ((page (cdr entry)))
      (clog:set-on-new-window
       (lambda (body)
         (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
         (let ((inspector (clog-moldable-inspector::create-inspector body :pane-width "700px" :playground? nil)))
           (clog-moldable-inspector::create-pane inspector page :select "Story")))
       :path (car entry))))
  (format t "~&MECH-DIALOG-BROWSER-READY ~D~%" port)
  (finish-output)
  (unwind-protect (loop repeat 2400 until (probe-file stop-file) do (sleep 0.1))
    (clog:shutdown)))
