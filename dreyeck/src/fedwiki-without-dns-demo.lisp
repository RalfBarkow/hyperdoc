;;;; Catalog demonstration of docs/fedwiki-without-dns/README.md. Read-only: it shows a committed experiment record and the frozen page.
;;;; It reads two files of this checkout and nothing else: no network, no wiki site, no environment variable, no control that does anything.
;;;; Not a member of dreyeck/catalog. Load it by naming it: HYPERDOC_CATALOG_SYSTEM=dreyeck/fedwiki-without-dns-demo.
(defpackage #:dreyeck/fedwiki-without-dns-demo
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:x #:dreyeck/fedwiki-without-dns)
                    (#:v #:html-inspector-views))
  (:export #:render-demo #:*frozen-site-root* #:current-record #:record-pathname #:frozen-site-root #:stored-page-observation #:stored-page-digest-current-p
           #:warrant-label))
(in-package #:dreyeck/fedwiki-without-dns-demo)

(defun record-pathname ()
  (asdf:system-relative-pathname "dreyeck/fedwiki-without-dns-demo" "docs/fedwiki-without-dns/experiment-record.lisp-data"))

(defvar *frozen-site-root* nil "Rebinding it points the demo at another copy of the frozen site (a test does, to show a changed file is noticed).")

(defun frozen-site-root ()
  (or *frozen-site-root*
      (asdf:system-relative-pathname "dreyeck/fedwiki-without-dns-demo" "tests/fedwiki-without-dns/frozen-site/")))

(defun current-record (&optional (pathname (record-pathname)))
  "The committed experiment record, read now; NIL and the reason as a second value when it cannot be read."
  (handler-case (x:read-record pathname)
    (error (condition) (values nil (princ-to-string condition)))))

(defun stored-page-observation (record)
  "The frozen page file as it is now (its digest and JSON), read from this checkout."
  (lp:observe-local-fedwiki-page-source (frozen-site-root) (x:record-slug record)))

(defun stored-page-digest-current-p (record)
  "Derived: whether the frozen page file still has the digest the experiment recorded."
  (equal (x:record-fixture-sha256 record) (lp:page-source-sha256 (stored-page-observation record))))

;;; Words

(defun warrant-label (warrant)
  (ecase warrant (:observed "observed") (:derived "derived") (:inferred "inferred") (:hypothesized "hypothesized")))

(defun %time (universal-time)
  (multiple-value-bind (second minute hour day month year) (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" year month day hour minute second)))

(defun %short (digest) (if digest (format nil "~A…" (subseq digest 0 (min 12 (length digest)))) "none"))

(defun %access-text (observation)
  (ecase (x:observation-access observation)
    (:ordinary-resolution "ordinary resolution")
    (:explicit-endpoint "given endpoint")))

(defun %dns-text (observation)
  (let ((dns (x:observation-dns observation)))
    (ecase (getf dns :outcome)
      (:resolved (format nil "resolved to ~{~A~^, ~}" (getf dns :addresses)))
      (:failed (format nil "failed: ~A" (getf dns :condition))))))

(defun %connection-text (observation)
  (let ((connection (x:observation-connection observation)) (status (getf (x:observation-http observation) :status)))
    (ecase (getf connection :outcome)
      (:connected (format nil "connected, HTTP ~A" status))
      (:failed (format nil "no connection (~(~A~)): ~A" (getf connection :stage) (getf connection :condition))))))

(defun %origin-text (observation)
  (let ((origin (x:observation-endpoint-origin observation)))
    (cond ((null origin) "none")
          ((eq :earlier-resolution (first origin)) (format nil "the address that the resolution in observation ~A gave" (second origin)))
          (t (format nil "declared: ~A" (second origin))))))

(defun %verdict-text (verdict)
  (ecase verdict
    (:read-identical "read; the same page")
    (:read-different "read; other content")
    (:page-absent "answered; no page")
    (:not-json "answered; not JSON")
    (:resolution-failed "name resolution failed")
    (:unreachable "unreachable")
    (:failed "failed")))

(defun %content-text (observation)
  (let ((content (x:observation-content observation)))
    (if content
        (format nil "~(~A~)~@[, ~D story items~]~@[, ~D journal entries~]" (getf content :relation) (getf content :story-items) (getf content :journal-entries))
        "no page read")))

;;; The views of the record

(defun %condition-short (name) (subseq name (1+ (or (position #\: name :from-end t) -1))))

(defun %path-short (observation)
  (let ((origin (x:observation-endpoint-origin observation)))
    (if (x:observation-endpoint observation)
        (format nil "endpoint ~A (~A)" (x:observation-endpoint observation)
                (if (eq :earlier-resolution (first origin)) (format nil "from ~A" (second origin)) "declared"))
        "ordinary resolution")))

(defun %dns-short (observation)
  (let ((dns (x:observation-dns observation)))
    (if (eq :resolved (getf dns :outcome))
        (format nil "resolved ~{~A~^, ~}" (getf dns :addresses))
        (format nil "failed: ~A" (%condition-short (getf dns :condition))))))

(defun %connection-short (observation)
  (let ((connection (x:observation-connection observation)))
    (if (eq :connected (getf connection :outcome))
        (format nil "HTTP ~A" (getf (x:observation-http observation) :status))
        (format nil "none: ~(~A~)" (getf connection :stage)))))

(defun render-observation-table (record)
  "The access paths side by side, narrow enough for an Inspector pane. Full wording is in each observation's own view and in the claims."
  (let ((observations (x:record-observations record)))
    (v:html
      (:table :class "inspector-table without-dns-comparison"
        (:tr (:th "Id") (:th "Outcome") (:th "Path") (:th "DNS then") (:th "Connection"))
        (dolist (observation observations)
          (v:html
            (:tr :class (format nil "without-dns-observation role-~(~A~)" (x:observation-role observation))
                 (:td (v:object-ref observation :display (x:observation-id observation)))
                 (:td (:strong (v:esc (%verdict-text (x:observation-verdict observation)))) (:br)
                      (:small (v:esc (format nil "~(~A~)" (or (getf (x:observation-content observation) :relation) "no page read"))) " "
                              (:code (v:esc (%short (x:observation-json-sha256 observation))))))
                 (:td (v:esc (%path-short observation)))
                 (:td (v:esc (%dns-short observation)))
                 (:td (v:esc (%connection-short observation)))))))
      (:p :class "without-dns-tls"
          (v:esc (let ((statuses (remove-duplicates (mapcar (lambda (o) (getf (x:observation-tls o) :status)) observations))))
                   (if (equal statuses '(:not-performed))
                       (format nil "TLS check: not-performed in all ~D observations (HTTP): no authenticated site identity." (length observations))
                       (format nil "TLS check: ~(~{~A~^, ~}~) (see each observation)." statuses)))))
      (:p :class "without-dns-origins"
          "Endpoint mappings: "
          (v:esc (format nil "~{~A~^; ~}"
                         (loop for o in observations when (x:observation-endpoint-origin o)
                               collect (format nil "~A: ~A" (x:observation-id o) (%origin-text o)))))))))

(defun render-claims (claims)
  (v:html
    (:ul :class "without-dns-claims"
      (dolist (claim claims)
        (v:html (:li (:strong (v:esc (warrant-label (x:claim-warrant claim)))) ": " (v:esc (x:claim-statement claim))
                     (when (x:claim-basis claim)
                       (v:html " " (:small (v:esc (format nil "(rests on ~{~A~^, ~})" (x:claim-basis claim))))))))))))

(v:defview comparison-view (record x:experiment-record)
  (v:html-view :title "Comparison of the access paths" :priority 1
    (v:html
      (:h2 "One page, read by name and then through a given address")
      (:p "Site " (:code (v:esc (x:record-site record))) ", page " (:code (v:esc (x:record-slug record)))
          ". Failure condition: " (v:esc (x:record-dns-failure record)) ".")
      (:p "Stored page file SHA-256 " (:code (v:esc (x:record-fixture-sha256 record))) " (" (v:esc (format nil "~D" (x:record-fixture-octets record)))
          " octets). Recorded " (v:esc (%time (x:record-recorded-at record))) ".")
      (render-observation-table record)
      (:h3 "What was observed, derived, inferred and only hypothesized")
      (render-claims (x:derive-findings record))
      (:h3 "What this record does not show")
      (:ul (dolist (limit (x:record-limits record)) (v:html (:li (v:esc limit))))))))

(v:defview claims-by-warrant-view (record x:experiment-record)
  (v:html-view :title "Claims by warrant" :priority 2
    (v:html
      (:h2 "Observed, derived, inferred, hypothesized")
      (dolist (warrant x:+warrants+)
        (v:html
          (:h3 (v:esc (string-capitalize (warrant-label warrant))))
          (let ((claims (remove warrant (x:derive-findings record) :key #'x:claim-warrant :test-not #'eq)))
            (if claims
                (render-claims claims)
                (v:html (:p "none")))))))))

(v:defview setup-view (record x:experiment-record)
  (v:html-view :title "Setup" :priority 3
    (v:html
      (:h2 "How the observations were made")
      (:table :class "inspector-table"
        (loop for (key value) on (x:record-environment record) by #'cddr
              do (v:html (:tr (:th (v:esc (string-downcase (symbol-name key)))) (:td (v:esc value)))))))))

(v:defview record-data-view (record x:experiment-record)
  (v:html-view :title "Record as data" :priority 4
    (v:html
      (:h2 "The record as it is stored")
      (:p "Plain data: keywords, strings, integers and lists. Reading it evaluates nothing.")
      (:pre :class "without-dns-record-data"
            (v:esc (let ((*print-pretty* t) (*print-right-margin* 120) (*package* (find-package :cl-user)))
                     (prin1-to-string (x:record-form record))))))))

(defun render-field-table (observation)
  (v:html
    (:table :class "inspector-table"
      (:tr (:th "Field") (:th "Value") (:th "Warrant"))
      (flet ((row (name value warrant)
               (v:html (:tr (:th (v:esc name)) (:td (v:esc value)) (:td (v:esc (warrant-label warrant)))))))
        (row "Site (as named)" (x:observation-site observation) :observed)
        (row "Page slug" (x:observation-slug observation) :observed)
        (row "URL requested" (x:observation-url observation) :observed)
        (row "Access" (%access-text observation) :observed)
        (row "Endpoint used" (or (x:observation-endpoint observation) "none") :observed)
        (row "Origin of the endpoint mapping" (%origin-text observation)
             (if (eq :earlier-resolution (first (x:observation-endpoint-origin observation))) :derived :observed))
        (row "DNS result" (%dns-text observation) :observed)
        (row "Connection and HTTP" (%connection-text observation) :observed)
        (row "TLS check" (format nil "~(~A~): ~A" (getf (x:observation-tls observation) :status) (getf (x:observation-tls observation) :reason)) :observed)
        (row "JSON SHA-256 of the served octets" (or (x:observation-json-sha256 observation) "none") :observed)
        (row "Octets" (format nil "~A" (or (x:observation-octet-count observation) "none")) :observed)
        (row "Content against the stored page" (%content-text observation) :derived)
        (row "Outcome" (%verdict-text (x:observation-verdict observation)) :derived)
        (row "Observed at" (%time (x:observation-observed-at observation)) :observed)))))

(v:defview observation-view (observation x:access-observation)
  (v:html-view :title "Observation" :priority 1
    (v:html
      (:h2 (v:esc (format nil "Observation ~A: ~A" (x:observation-id observation) (%access-text observation))))
      (when (getf (x:observation-connection observation) :message)
        (v:html (:p "Condition: " (:code (v:esc (getf (x:observation-connection observation) :message))))))
      (render-field-table observation))))

(v:defview claim-view (claim x:claim)
  (v:html-view :title "Claim" :priority 1
    (v:html
      (:h2 (v:esc (warrant-label (x:claim-warrant claim))))
      (:p (v:esc (x:claim-statement claim)))
      (:p "Rests on: " (v:esc (format nil "~{~A~^, ~}" (x:claim-basis claim)))))))

;;; The page's generated part

(defun render-stored-page (record)
  (let* ((source (stored-page-observation record))
         (wiki (lp:make-local-fedwiki (frozen-site-root) (concatenate 'string "fedwiki:" (x:record-site record))))
         (page (lp:make-local-fedwiki-page (frozen-site-root) wiki (x:record-slug record))))
    (v:html
      (:h2 "The page that is read")
      (:p "Site " (:code (v:esc (x:record-site record))) ", slug " (:code (v:esc (x:record-slug record)))
          ". The frozen file in this checkout has SHA-256 " (:code (v:esc (lp:page-source-sha256 source)))
          (v:esc (if (equal (lp:page-source-sha256 source) (x:record-fixture-sha256 record))
                     " — the digest the experiment recorded (derived)."
                     " — NOT the digest the experiment recorded: this file is not the page that was read.")))
      (:h3 (v:esc (hyperbook:title-of page)))
      (loop for item across (hyperbook/fedwiki::story-of page)
            do (hyperbook/fedwiki::render-story-item (hyperbook/fedwiki::item-type-of item) item page)))))

(defun render-demo (&optional (pathname (record-pathname)))
  "The page's generated part. It never signals: a record that cannot be read is reported instead. It offers no control."
  (multiple-value-bind (record problem) (current-record pathname)
    (if (null record)
        (v:html (:p :class "without-dns-unavailable" "The experiment record could not be read: " (v:esc problem)))
        (v:html
          (render-stored-page record)
          (:h2 "The experiment, in one table")
          (render-observation-table record)
          (:p "Open the record in the Inspector: " (v:object-ref record :display "Experiment record" :select "Comparison of the access paths"))
          (let ((ordinary (x:find-observation record "B")) (given (x:find-observation record "C")))
            (when (and ordinary given)
              (v:html (:p "Compare the two paths: observation "
                          (v:object-ref ordinary :display "B (ordinary, DNS failing)")
                          " and observation "
                          (v:object-ref given :display "C (given endpoint, DNS still failing)") "."))))))))

(hyperdoc:defhyperdoc *demo*
  :id "dreyeck/fedwiki-without-dns-demo"
  :title "Reading a Wiki Page Without DNS"
  :asdf-system-name "dreyeck/fedwiki-without-dns-demo"
  :subdirectory "dreyeck/pages/fedwiki-without-dns-demo"
  :main-page-id "Reading One Wiki Page Without DNS")
