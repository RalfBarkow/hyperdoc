;;;; Utility functions
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

(defun fetch-json (url)
  "Load JSON data from URL and return it as Lisp data structures."
  (format t "Fetching JSON from ~A~%" url)
  (let ((stream (drakma:http-request url :method :get :want-stream t)))
    (setf (flexi-streams:flexi-stream-external-format stream) :utf-8)
    (shasht:read-json stream)))

(defun fetch-page-json (wiki-domain slug)
  "Load JSON data for the page defined by SLUG from the Wiki site at
WIKI-DOMAIN, and return it as Lisp data structures."
  (let ((url (wiki-url wiki-domain (str:concat "/" slug ".json"))))
    (fetch-json url)))

(defun fetch-page-html (wiki-domain slug)
  "Load the rendered HTML for the page defined by SLUG from the
Wiki site at WIKI-DOMAIN."
  (let ((url (wiki-url wiki-domain (str:concat "/" slug ".html"))))
    (drakma:http-request url :method :get)))

(defun wiki-url (domain-name local-url)
  "Construct a URL from a DOMAIN-NAME and a LOCAL-URL."
  (assert (str:starts-with? "/" local-url))
  (assert (not (str:ends-with? "/" domain-name)))
  (format nil "http://~A~A" domain-name local-url))

(defun wiki-date-to-timestamp (date)
  "Convert DATE, the number of milliseconds since 1971-01-01, to
a local-time:timestamp. Allow DATE to be NIL, returning NIL."
  (and date
       (local-time:unix-to-timestamp (round (/ date 1000)))))

