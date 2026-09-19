;;;; Contracts for the Lisp Critic genealogy reading.
;;;;
;;;; The reading claims three different kinds of access to three different
;;;; stations. These tests hold it to that: a documented station must stay
;;;; documented, and an executable one must actually execute.

(defpackage #:dreyeck/lisp-critic/reading/tests
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/lisp-critic/reading)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:views #:html-inspector-views))
  (:export #:run-tests #:run-current-tests))

(in-package #:dreyeck/lisp-critic/reading/tests)

(defparameter +pages+
  '("Reading the Lisp Critic Genealogy"
    "The Fischer Critic as an Environment"
    "Reading Riesbeck's Lisp Critic"
    "From Riesbeck Run to HyperDoc Critique"
    "Anatomy of a Critique"))

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun page-of (title)
  (hyperbook:find-page reading:*lisp-critic-reading* title :signal-error? t))

(defun page-elements (page tag)
  (plump:get-elements-by-tag-name (hyperdoc::dom-of page) tag))

(defun page-package (page)
  (let* ((tags (plump:get-elements-by-tag-name
                (plump:parse (hyperdoc:file-of page)) "in-package"))
         (name (and (= 1 (length tags))
                    (string-trim '(#\Space #\Tab #\Newline #\Return)
                                 (plump:text (first tags))))))
    (check name "Page ~S does not declare exactly one IN-PACKAGE."
           (hyperbook:id-of page))
    (or (find-package (string-upcase name))
        (error "Page ~S names missing package ~S."
               (hyperbook:id-of page) name))))

(defun element-texts (page tag)
  (mapcar (lambda (element)
            (string-trim '(#\Space #\Tab #\Newline #\Return)
                         (plump:text element)))
          (page-elements page tag)))

(defun page-expressions (page)
  (loop for element in (page-elements page "a")
        for expression = (plump:attribute element "expr")
        when expression collect expression))

(defun page-links (page)
  (loop for element in (page-elements page "a")
        for target = (plump:attribute element "page")
        when target collect target))

;;
;; 2. Every intended page is present in the book
;;

(defun check-pages-present ()
  (check (= (length +pages+)
            (hash-table-count (hyperdoc:pages-of reading:*lisp-critic-reading*)))
         "The reading book holds ~D pages instead of ~D."
         (hash-table-count (hyperdoc:pages-of reading:*lisp-critic-reading*))
         (length +pages+))
  (dolist (title +pages+)
    (check (page-of title) "Reading page ~S is missing." title))
  (check (string= "Reading the Lisp Critic Genealogy"
                  (hyperbook:main-page-id-of reading:*lisp-critic-reading*))
         "Unexpected main page ~S."
         (hyperbook:main-page-id-of reading:*lisp-critic-reading*))
  t)

;;
;; 8. Native navigation: the entry page reaches all the others, and every
;;    other page returns to it.
;;

(defun check-navigation ()
  (let ((entry (page-links (page-of "Reading the Lisp Critic Genealogy"))))
    (dolist (title (rest +pages+))
      (check (member title entry :test #'string=)
             "The entry page does not link to ~S." title)))
  (dolist (title (rest +pages+))
    (check (member "Reading the Lisp Critic Genealogy"
                   (page-links (page-of title)) :test #'string=)
           "Page ~S has no link back to the entry page." title))
  t)

;;
;; 3. + 4. Transclusions resolve, and every addressed example runs
;;

(defun check-transclusions-and-examples ()
  (dolist (title +pages+)
    (let* ((page (page-of title))
           (*package* (page-package page)))
      ;; Every <source-of-function> must name something defined.
      (dolist (name (element-texts page "source-of-function"))
        (multiple-value-bind (symbol position) (read-from-string name)
          (check (= position (length name))
                 "Page ~S: source reference ~S has trailing syntax."
                 title name)
          (check (fboundp symbol)
                 "Page ~S transcludes undefined ~S." title symbol)))
      ;; Every <view-transclusion> must evaluate to a renderable view.
      (dolist (expression (element-texts page "view-transclusion"))
        (let ((value (hyperdoc::parse-and-eval expression)))
          (check (not (typep value 'condition))
                 "Page ~S: transclusion ~S produced ~A."
                 title expression value)
          (check (plusp (length (views:view-html value)))
                 "Page ~S: transclusion ~S rendered nothing."
                 title expression)))
      ;; Every addressed example must run and report its evidence status.
      (dolist (expression (page-expressions page))
        (let ((value (hyperdoc::parse-and-eval expression)))
          (check (not (typep value 'condition))
                 "Page ~S: example ~S produced ~A." title expression value)
          (check (getf value :evidence-status)
                 "Page ~S: example ~S returned no evidence status."
                 title expression)))))
  t)

;;
;; The genealogy must keep the two lines apart
;;

(defun check-genealogy-separation ()
  (let* ((stations (reading:lisp-critic-genealogy))
         (fischer (reading:lisp-critic-station :fischer-lisp-critic))
         (riesbeck (reading:lisp-critic-station :riesbeck-lisp-critic)))
    (check (eq :documented (getf fischer :evidence-status))
           "Fischer's station claims ~S rather than :DOCUMENTED."
           (getf fischer :evidence-status))
    (check (null (getf fischer :executable-here))
           "Fischer's station claims to be executable here.")
    (check (eq :executable (getf riesbeck :evidence-status))
           "Riesbeck's station claims ~S rather than :EXECUTABLE."
           (getf riesbeck :evidence-status))
    ;; The relation across the two lines must remain a resemblance.
    (check (eq :conceptual-resemblance (getf riesbeck :relation-to-predecessor))
           "Riesbeck's station claims ~S to its predecessor."
           (getf riesbeck :relation-to-predecessor))
    ;; No station anywhere may claim descent.
    (dolist (station stations)
      (dolist (key '(:relation-to-predecessor :relation-to-successor))
        (check (not (eq :descends-from (getf station key)))
               "Station ~S claims descent, which no local evidence supports."
               (getf station :station))))
    ;; The unevidenced claims must stay listed rather than quietly adopted.
    (let ((claims (reading::fischer-claims-without-local-evidence)))
      (check claims "The unevidenced Fischer claims disappeared.")
      (dolist (claim claims)
        (check (eq :none (getf claim :local-evidence))
               "Claim ~S is no longer marked as unevidenced."
               (getf claim :claim)))))
  t)

;;
;; 5. 6. 7. The three outcomes, against the real engine
;;

(defun check-outcomes ()
  (let ((match (reading:critic-match-example))
        (non-match (reading:critic-non-match-example))
        (failure (reading:critic-failure-example)))
    ;; 5. A match still yields a Critique.
    (let ((record (getf match :record)))
      (check (eq :completed (er:evaluation-status-of record))
             "The match case failed: ~A" (er:evaluation-failure-of record))
      (check (= 1 (length (er:evaluation-result-of record)))
             "The match case produced ~D critiques instead of one."
             (length (er:evaluation-result-of record)))
      (check (typep (first (er:evaluation-result-of record)) 'critic:critique)
             "The match case produced something other than a Critique.")
      (check (eq :evaluation-record-and-critique
                 (getf (getf match :summary) :outcome))
             "The match case reports outcome ~S."
             (getf (getf match :summary) :outcome)))
    ;; 6. A non-match yields no Critique, but still a record.
    (let ((record (getf non-match :record)))
      (check (eq :completed (er:evaluation-status-of record))
             "The non-match case did not complete.")
      (check (null (er:evaluation-result-of record))
             "The non-match case produced a critique.")
      (check (eq :evaluation-record-only
                 (getf (getf non-match :summary) :outcome))
             "The non-match case reports outcome ~S."
             (getf (getf non-match :summary) :outcome)))
    ;; 7. A failure stays a record and keeps its condition.
    (let ((record (getf failure :record)))
      (check (eq :failed (er:evaluation-status-of record))
             "The failure case did not fail.")
      (check (er:evaluation-failure-of record)
             "The failure case discarded its condition.")
      (check (null (er:evaluation-result-of record))
             "The failure case produced a critique.")
      (check (eq :evaluation-record-with-condition
                 (getf (getf failure :summary) :outcome))
             "The failure case reports outcome ~S."
             (getf (getf failure :summary) :outcome))))
  t)

;;
;; The engine source the reading transcludes must really be the vendored one
;;

(defun check-source-backing ()
  (let* ((anatomy (reading:critique-anatomy-example))
         (pathname (getf (getf anatomy :source-provenance) :pathname)))
    ;; Missing external sources must fail this proof, never skip it.
    (check (probe-file pathname)
           "The rule's recorded source file is absent: ~A" pathname)
    (check (search "lisp-rules" (namestring pathname))
           "The rule does not come from the vendored rule file: ~A" pathname)
    ;; The recommendation must come from the engine, not from the page.
    (check (search "CADR" (getf anatomy :explanation))
           "The explanation no longer carries the engine's recommendation."))
  (let ((station (reading:riesbeck-source-station-example)))
    (check (getf station :present-p) "The local source station is absent.")
    (dolist (file (getf station :vendored-files))
      (check (getf file :present-p)
             "Vendored engine file ~A is absent." (getf file :name))))
  t)

(defun run-current-tests ()
  (hyperdoc::ensure-pages-loaded reading:*lisp-critic-reading*)
  (check-pages-present)
  (check-navigation)
  (check-genealogy-separation)
  (check-outcomes)
  (check-source-backing)
  (check-transclusions-and-examples)
  (format t "~&LISP-CRITIC-READING-PASS: five pages, two lines kept apart, ~
three outcomes, source-backed transclusion.~%")
  t)

(defun run-tests ()
  (run-current-tests)
  (format t "~&CURRENT-IMAGE-READING-PASS~%")
  (uiop:run-program
   (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
         "--eval" "(require :asdf)"
         "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
         "--eval" "(asdf:load-system \"dreyeck/lisp-critic/reading/tests\")"
         "--eval" "(dreyeck/lisp-critic/reading/tests:run-current-tests)")
   :output *standard-output* :error-output *error-output*)
  (format t "~&FRESH-PROCESS-READING-PASS~%")
  t)
