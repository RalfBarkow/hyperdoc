;;;; A Critic evaluation of a DEFEXAMPLE, recorded where the engine may run
;;;; and read where it may not.
;;;;
;;;; The 2004 Riesbeck/Beane engine is not a dependency of this repository.
;;;; It is loaded from a source station, as code that arrived with a page,
;;;; and a served runtime does not run such code. So the engine runs in a
;;;; trusted development runtime, and what it said there is written down:
;;;; which example it judged, as an exact source occurrence; which rule; the
;;;; Evaluation Record and its Critiques, which are the engine's own output;
;;;; what each one matched, and where in the example; and which engine,
;;;; down to the digests of its files.
;;;;
;;;; Reading a record here builds nothing that runs. It is JSON, so reading
;;;; it interns no symbol. The example is observed again in this runtime's
;;;; own source, to say whether the record is still about it, and the
;;;; match is located there, to say whether it is code or quoted data.
;;;;
;;;; A recorded evaluation is not a live one, and it is not a description
;;;; written by hand: every recommendation here is text the engine produced.

(defpackage #:dreyeck/lisp-critic/recorded
  (:use #:cl)
  (:local-nicknames (#:critic #:dreyeck/lisp-critic)
                    (#:ex #:dreyeck/lisp-critic/examples)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:hv #:html-inspector-views/standard)
                    (#:views #:html-inspector-views))
  (:export #:recorded-example-evaluation
           #:recorded-identity-of
           #:current-occurrence-of
           #:occurrence-status-of
           #:recorded-target-of
           #:recorded-record-of
           #:recorded-matches-of
           #:recorded-engine-of
           #:recorded-context-of
           #:read-example-evaluation
           #:record-example-evaluation
           #:record-demonstration-evaluations
           #:+recorded-cases+
           #:setf-push-recorded-example
           #:x-plus-1-recorded-example))

(in-package #:dreyeck/lisp-critic/recorded)

(defparameter +example-evaluation-version+ 1
  "The version of this record's contract, written into every record.")

(defparameter +engine-edition+
  "Zach Beane's ASDF-loadable archive of Chris Riesbeck's Lisp Critic, dated 2004-05-06 (https://xach.com/lisp/lisp-critic.tar.gz), with the one local change its source station's PATCH-NOTES.md records: VAR-PREFIX in extend-match.lisp is a DEFPARAMETER."
  "Which engine, as its source station documents it. The digests recorded
beside it make the claim checkable against the files that ran.")

(defparameter +engine-files+
  '("README" "lisp-critic.asd" "tables.lisp" "write-wrap.lisp" "extend-match.lisp"
    "lisp-critic.lisp" "lisp-rules.lisp")
  "The vendored engine's files, whose digests identify the edition.")

(defparameter +recording-context+
  "A trusted development runtime, in which the 2004 engine's source station was reachable and running page-attached code was permitted."
  "Where a record is made, which is never where it is read.")

(defparameter +recorded-cases+
  '(("setf-push-reading-plan.json" "READING-PLAN" "SETF-PUSH")
    ("x-plus-1-reading-outstanding-changes.json" "READING-OUTSTANDING-CHANGES" "X-PLUS-1"))
  "The recorded evaluations Reading the Lisp Critic shows: record file,
example on the Executable workflow reading code page, and rule.")

;;;; Identities

(defun %text-digest (string)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets string :external-format :utf-8))))

(defun %file-digest (pathname)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 pathname)))

(defun %key-text (key)
  "KEY as text, printed in the package its name is read in."
  (let ((*package* (symbol-package (second key))))
    (prin1-to-string key)))

(defun %occurrence-identity (occurrence)
  "What names OCCURRENCE exactly, as data: its code page, form key, range,
text, and the digest of the whole source snapshot it was observed in."
  (let* ((page (r:occurrence-page occurrence))
         (source (r:occurrence-source occurrence))
         (range (r:occurrence-range occurrence)))
    (list (cons "hyperdoc" (hyperbook:id-of (hyperbook:hyperbook-of page)))
          (cons "code-file" (file-namestring (hyperdoc::source-code-pathname page)))
          (cons "form-key" (%key-text (r:occurrence-form-key occurrence)))
          (cons "range" (vector (car range) (cdr range)))
          (cons "text" (subseq source (car range) (cdr range)))
          (cons "source-sha256" (%text-digest source)))))

(defun %engine-identity ()
  "The engine the run used: its edition as documented, and the digests of
the files that were loaded. NIL digests if no engine was loaded."
  (let ((directory (ignore-errors (asdf:system-source-directory "lisp-critic"))))
    (list (cons "edition" +engine-edition+)
          (cons "files"
                (coerce (loop for name in +engine-files+
                              for path = (and directory (merge-pathnames name directory))
                              collect (list (cons "file" name)
                                            (cons "sha256" (or (and path (probe-file path) (%file-digest path))
                                                               :null))))
                        'vector)))))

(defun %path-to (part form)
  "The element indices from FORM down to the first subform EQUAL to PART,
searching as the engine does: a form before its elements, earlier elements
first. A second value says whether one was found."
  (labels ((walk (here path)
             (when (equal part here)
               (return-from %path-to (values (reverse path) t)))
             (when (consp here)
               (loop for tail on here
                     for index from 0
                     while (consp tail)
                     do (walk (car tail) (cons index path))))))
    (walk form nil)
    (values nil nil)))

(defun %quoted-along-p (form path)
  "Whether a QUOTE form encloses the subform PATH leads to in FORM."
  (let ((here form))
    (dolist (index path nil)
      (when (and (consp here) (eq 'quote (first here)))
        (return t))
      (setf here (nth index here)))))

(defun %subform (form path)
  (let ((here form))
    (dolist (index path here)
      (setf here (nth index here)))))

;;;; Recording, where the engine may run

(defun %match (critique form package)
  (let ((code (uiop:symbol-call :lisp-critic "CRITIQUE-CODE" (critic:critique-evidence-of critique))))
    (multiple-value-bind (path found) (%path-to code form)
      (list (cons "matched" (let ((*package* package)) (prin1-to-string code)))
            (cons "path" (if found (coerce path 'vector) :null))))))

(defun record-example-evaluation (occurrence rule-name contract)
  "Apply RULE-NAME, with the engine CONTRACT reaches, to the DEFEXAMPLE at
OCCURRENCE, and return what happened as inert data. Runs the engine; for a
runtime that may, never where the record is read. A run that fails is
recorded as failed."
  (let* ((target (ex:critic-target-for-example occurrence))
         (record (critic:run-critic-rule contract rule-name target))
         (form (critic:target-form-of target))
         (package (symbol-package (second (r:occurrence-form-key occurrence)))))
    (list (cons "example-evaluation-version" +example-evaluation-version+)
          (cons "occurrence" (%occurrence-identity occurrence))
          (cons "run" (critic:critic-run-snapshot target))
          (cons "matches" (coerce (mapcar (lambda (critique) (%match critique form package))
                                          (critic:critiques-of record))
                                  'vector))
          (cons "engine" (%engine-identity))
          (cons "recording" (list (cons "context" +recording-context+)
                                  (cons "recorded-at" (get-universal-time)))))))

(defun %recording-contract ()
  (make-instance 'critic:lisp-critic-contract
                 :id "recorded-example-evaluation" :title "One real Critic rule on a DEFEXAMPLE, for the record"
                 :source-station (critic:make-critic-source-station)
                 :input-policy '(:form :not-evaluated) :invocation-policy '(:apply-one-rule)
                 :output-policy '(:structured-findings :raw-output-preserved)
                 :availability-policy '(:local-source-required)
                 :failure-policy '(:record-condition) :review-contract-role :critique))

(defun %workflow-example (name)
  "The DEFEXAMPLE NAME on the Executable workflow reading code page, observed now."
  (let ((page (%code-page "dreyeck/workflow/reading" "workflow-reading.lisp")))
    (or (and page (find name (r:page-example-occurrences page)
                        :key (lambda (occurrence) (symbol-name (second (r:occurrence-form-key occurrence))))
                        :test #'string=))
        (error "Executable workflow reading declares no example ~A." name))))

(defun record-demonstration-evaluations (directory)
  "Record each of +RECORDED-CASES+ into DIRECTORY, one JSON file per case.
Refuses to write a run that did not complete with a finding: the page shows
what the engine said, and a record that it said nothing would be another
page."
  (loop for (file example rule) in +recorded-cases+
        for data = (record-example-evaluation (%workflow-example example) rule (%recording-contract))
        for run = (cdr (assoc "run" data :test #'string=))
        for status = (cdr (assoc "status" (cdr (assoc "evaluation" run :test #'string=)) :test #'string=))
        do (unless (and (equal "COMPLETED" status) (plusp (length (cdr (assoc "matches" data :test #'string=)))))
             (error "~A on ~A did not complete with a finding (~A); nothing written." rule example status))
           (with-open-file (stream (merge-pathnames file (uiop:ensure-directory-pathname directory))
                                   :direction :output :if-exists :supersede :external-format :utf-8)
             (let ((shasht:*write-alist-as-object* t)
                   (shasht:*write-indent-string* "  "))
               (shasht:write-json data stream))
             (terpri stream))
        collect file))

;;;; Reading, where it may not

(defclass recorded-example-evaluation ()
  ((identity :initarg :identity :reader recorded-identity-of)
   (occurrence :initarg :occurrence :reader current-occurrence-of)
   (status :initarg :status :reader occurrence-status-of)
   (target :initarg :target :reader recorded-target-of)
   (matches :initarg :matches :reader recorded-matches-of)
   (engine :initarg :engine :reader recorded-engine-of)
   (context :initarg :context :reader recorded-context-of))
  (:documentation "One recorded Critic evaluation of a DEFEXAMPLE. IDENTITY
is the source occurrence the record names; OCCURRENCE is that example as
this runtime observes it now, if it still declares it, and STATUS says how
the two relate. TARGET carries the recorded Evaluation Record and its
Critiques; each of MATCHES pairs a Critique with what it matched and
whether that is quoted data. ENGINE and CONTEXT say what ran, and where."))

(defmethod print-object ((evaluation recorded-example-evaluation) stream)
  (print-unreadable-object (evaluation stream :type t)
    (format stream "~A ~A" (gethash "form-key" (recorded-identity-of evaluation))
            (occurrence-status-of evaluation))))

(defun recorded-record-of (evaluation)
  "The recorded Evaluation Record."
  (first (critic:target-runs-of (recorded-target-of evaluation))))

(defun %code-page (hyperdoc-id code-file)
  (let ((book (hyperbook:find-hyperbook hyperdoc-id :signal-error? nil)))
    (and book
         (find code-file (coerce (hyperdoc::code-pages-of book) 'list)
               :key (lambda (page) (file-namestring (hyperdoc::source-code-pathname page)))
               :test #'string=))))

(defun %observe-now (identity)
  "The example IDENTITY names, as this runtime's source declares it now, and
how it relates to the recorded one."
  (let ((page (%code-page (gethash "hyperdoc" identity) (gethash "code-file" identity))))
    (if (null page)
        (values nil :page-absent)
        (let ((found (find (gethash "form-key" identity) (r:page-example-occurrences page)
                           :key (lambda (occurrence) (%key-text (r:occurrence-form-key occurrence)))
                           :test #'string=)))
          (cond ((null found) (values nil :example-absent))
                ((and (string= (gethash "source-sha256" identity) (%text-digest (r:occurrence-source found)))
                      (equal (coerce (gethash "range" identity) 'list)
                             (let ((range (r:occurrence-range found))) (list (car range) (cdr range)))))
                 (values found :recorded-snapshot))
                ((string= (gethash "text" identity)
                          (let ((range (r:occurrence-range found)))
                            (subseq (r:occurrence-source found) (car range) (cdr range))))
                 (values found :example-unchanged))
                (t (values found :example-changed)))))))

(defun %read-match (critique match occurrence status)
  (let* ((path (let ((value (gethash "path" match))) (if (vectorp value) (coerce value 'list) :absent)))
         (form (and (member status '(:recorded-snapshot :example-unchanged)) (listp path)
                    (hv:s-exp (r:resolve-occurrence occurrence)))))
    (list :critique critique
          :matched (gethash "matched" match)
          :path path
          :quoted-p (if form (%quoted-along-p form path) :unknown)
          :located-p (and form
                          (string= (gethash "matched" match)
                                   (let ((*package* (symbol-package (second (r:occurrence-form-key occurrence)))))
                                     (prin1-to-string (%subform form path))))))))

(defun read-example-evaluation (pathname)
  "The recorded evaluation at PATHNAME, as objects to read. Loads no engine,
runs no rule, interns no symbol from the record."
  (let* ((data (with-open-file (stream pathname :external-format :utf-8)
                 (critic:read-critic-run-snapshot stream)))
         (version (gethash "example-evaluation-version" data)))
    (unless (eql version +example-evaluation-version+)
      (error "Unsupported example evaluation version ~S; this reads version ~S."
             version +example-evaluation-version+))
    (let* ((identity (gethash "occurrence" data))
           (target (critic:reconstitute-critic-run (gethash "run" data)))
           (critiques (critic:critiques-of (first (critic:target-runs-of target)))))
      (multiple-value-bind (occurrence status) (%observe-now identity)
        (make-instance 'recorded-example-evaluation
                       :identity identity :occurrence occurrence :status status :target target
                       :matches (mapcar (lambda (critique match) (%read-match critique match occurrence status))
                                        critiques (coerce (gethash "matches" data) 'list))
                       :engine (gethash "engine" data)
                       :context (gethash "recording" data))))))

(defun %status-text (status)
  (ecase status
    (:recorded-snapshot "the page's source is the snapshot the record was made on")
    (:example-unchanged "the page's source has changed since, but this example reads exactly as recorded")
    (:example-changed "this example has changed since: the record is about an earlier text")
    (:example-absent "the page no longer declares this example")
    (:page-absent "this runtime has no such code page")))

(defun %where-text (quoted-p)
  (case quoted-p
    ((t) "inside a QUOTE: what matched is quoted data in the example, not code the example evaluates where it stands")
    ((nil) "in the example's code")
    (t "not determined: the example's text here is not the recorded one")))

(views:defview recorded-evaluation-view (evaluation recorded-example-evaluation)
  (views:html-view :title "Recorded evaluation" :priority 1
    (let* ((identity (recorded-identity-of evaluation))
           (occurrence (current-occurrence-of evaluation))
           (record (recorded-record-of evaluation))
           (rule (critic:rule-of record))
           (engine (recorded-engine-of evaluation))
           (context (recorded-context-of evaluation)))
      (views:html
        (:p (:b "Recorded evaluation. ")
            (views:esc "Produced with the 2004 Riesbeck/Beane Lisp Critic in a trusted development runtime; this runtime does not execute that engine."))
        (:table :class "inspector-table"
          (:tr (:td "Source occurrence")
               (:td (if occurrence
                        (views:object-ref occurrence :display (gethash "form-key" identity))
                        (views:esc (gethash "form-key" identity)))
                    (views:esc (format nil " -- ~A" (%status-text (occurrence-status-of evaluation))))))
          (:tr (:td "Recorded on")
               (:td (views:esc (format nil "~A, ~A, characters ~A, source sha256 ~A"
                                       (gethash "hyperdoc" identity) (gethash "code-file" identity)
                                       (coerce (gethash "range" identity) 'list)
                                       (gethash "source-sha256" identity)))))
          (:tr (:td "Evaluation Record")
               (:td (views:object-ref record :display (format nil "~A run" (critic:lisp-critic-run-record-status record)))))
          (:tr (:td "Rule") (:td (views:object-ref rule :display (critic:rule-name-of rule)))))
        (:h3 "Critiques")
        (:table :class "inspector-table"
          (dolist (match (recorded-matches-of evaluation))
            (let ((critique (getf match :critique)))
              (views:html
                (:tr (:td "Critique")
                     (:td (views:object-ref critique :display (critic:critique-explanation-of critique))))
                (:tr (:td "Matched") (:td (:tt (views:esc (getf match :matched)))))
                (:tr (:td "Where") (:td (views:esc (%where-text (getf match :quoted-p)))))))))
        (:h3 "Provenance")
        (:table :class "inspector-table"
          (:tr (:td "Engine") (:td (views:esc (gethash "edition" engine))))
          (dolist (file (coerce (gethash "files" engine) 'list))
            (views:html
              (:tr (:td (:tt (views:esc (gethash "file" file))))
                   (:td (:tt (views:esc (princ-to-string (gethash "sha256" file))))))))
          (:tr (:td "Recorded in") (:td (views:esc (gethash "context" context))))
          (:tr (:td "Recorded at")
               (:td (views:esc (multiple-value-bind (s m h day month year)
                                   (decode-universal-time (gethash "recorded-at" context) 0)
                                 (declare (ignore s m h))
                                 (format nil "~D-~2,'0D-~2,'0D (UTC)" year month day))))))))))

;;;; The recorded cases Reading the Lisp Critic shows

(defun %recorded (file)
  (read-example-evaluation
   (asdf:system-relative-pathname "dreyeck" (concatenate 'string "dreyeck/pages/lisp-critic/evaluations/" file))))

(hyperdoc:defexample setf-push-recorded-example
  "SETF-PUSH on READING-PLAN, as the 2004 engine judged it: a recommendation
worth taking. Read from its record; nothing runs."
  (%recorded "setf-push-reading-plan.json"))

(hyperdoc:defexample x-plus-1-recorded-example
  "X-PLUS-1 on READING-OUTSTANDING-CHANGES, as the 2004 engine judged it: a
match inside quoted data. Read from its record; nothing runs."
  (%recorded "x-plus-1-reading-outstanding-changes.json"))
