;;;; Obtain a list of Wikipedia editions from Wikidata
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

;; This file is *not* loaded as part of the HyperBook interface to Wikipedia.
;; It is meant for occasional updates of the Wikipedia edition list in
;; file wikipedia.lisp.

(defpackage :wikipedia-tools
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>))

(in-package :wikipedia-tools)

(defvar *wikidata-sparql-endpoint*
  "https://query.wikidata.org/bigdata/namespace/wdq/sparql")

(defun wikidata-query (sparql-query)
  (let ((stream (drakma:http-request
                 *wikidata-sparql-endpoint*
                 :method :post
                 :parameters `(("query" . ,sparql-query))
                 :accept "application/sparql-results+json"
                 :want-stream t)))
    (shasht:read-json stream)))

(defun fetch-wikipedia-editions ()
  (let* ((query (format nil "SELECT ?name ?url ~
                               WHERE { ~
                                 ?edition wdt:P31 wd:Q10876391. ~
                                 ?edition wdt:P1448 ?name. ~
                                 ?edition wdt:P856 ?url. ~
                               }"))
         ;; wd:Q10876391 Wikipedia edition
         ;; wdt:P31    instance of
         ;; wdt:P856   Official website
         ;; wdt:P1448  Official name
         (result (wikidata-query query)))
    (->> result
      (gethash "results")
      (gethash "bindings")
      (map 'vector
           #'(lambda (d)
               (let ((name (->> d
                            (gethash "name")
                            (gethash "value")))
                     (url (->> d
                            (gethash "url")
                            (gethash "value"))))
                 (multiple-value-bind
                       (code main-page)
                     (find-code-and-name-of-main-page url)
                   (list code (decode-utf8 name) main-page))))))))

(defun find-code-and-name-of-main-page (url)
  (multiple-value-bind
        (body status headers source-uri stream must-close? reason)
      (drakma:http-request url :method :get)
    (declare (ignorable body status headers source-uri stream must-close? reason ))
    (let ((code (->> source-uri
                  puri:uri-host
                  (str:split ".")
                  first))
          (main-page (->> source-uri
                       puri:uri-path
                       decode-utf8
                       (str:split "/")
                       third)))
      (values code main-page))))

(defun decode-utf8 (s)
  (->> s
    (map 'vector #'char-code)
    trivial-utf-8:utf-8-bytes-to-string))

(defvar *editions* (fetch-wikipedia-editions))

(defun write-edition-list-to-lisp-file ()
  (with-open-file (f "wikipedia-editions.lisp"
                     :direction :output
                     :if-exists :supersede)
    (format f ";; This file has been generated automatically.~%;; Do not edit.~%~%")
    (format f "(in-package :hyperbook/wikipedia)~%~%")
    (format f "(defparameter *editions*~% ~S)" *editions*)))
