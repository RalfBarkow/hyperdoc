;;;; A Critic run, written down so it can be read where it cannot be run.
;;
;; Three different things carry the same finding, and they are not the
;; same object:
;;
;;     the run record        a live CLOS graph, made by running the critic
;;     the snapshot          inert data, JSON, no Lisp in it
;;     the presentation      a CLOS graph rebuilt from the snapshot
;;
;; The middle one exists so that a runtime which may not run the engine
;; can still show what the engine said. It is a projection of the record
;; for transport and display, not a second record model.
;;
;; Two properties make it work, and both were learned by measuring. The
;; rule name and the match pattern come out of the engine's own packages
;; — LISP-CRITIC-USER, EXTEND-MATCH — which do not exist where the
;; engine was never loaded, so they are written as text and stay text.
;; And the format is JSON rather than Lisp forms, so reading a snapshot
;; cannot intern a symbol or create a package at all.

(in-package #:dreyeck/lisp-critic)

(defparameter +critic-snapshot-version+ 1
  "The version of the snapshot contract, written into every snapshot.")

(defun %snapshot-text (object)
  "Render OBJECT as text, because it may name something not present here."
  (and object (princ-to-string object)))

(defun %snapshot-artifact (pathname)
  "What can be said about the engine's source file without running it.

A path and a byte size. Not a digest: nothing in this repository hashes
content, and a snapshot should not be the reason to add a cryptography
dependency. Not a write date either — a timestamp is not an identity,
it is a coincidence that two files can share and one file can change
without."
  (when pathname
    (let ((truename (ignore-errors (probe-file pathname))))
      (list (cons "path" (namestring pathname))
            (cons "byte-size"
                  (or (and truename
                           (ignore-errors
                            (with-open-file (stream truename
                                                    :element-type '(unsigned-byte 8))
                              (file-length stream))))
                      :null))
            (cons "digest" :null)))))

(defun critic-run-snapshot (target)
  "Project TARGET's first run into inert data.

Everything here is a string, a number, a boolean, null, a list or a
map. Nothing in it is a Lisp object that has to be read back as one."
  (let* ((record (first (target-runs-of target)))
         (rule (and record (rule-of record)))
         (source (and rule (rule-source-of rule)))
         (station (getf source :station)))
    (unless record
      (error "This target carries no run to write down."))
    (list
     (cons "snapshot-version" +critic-snapshot-version+)
     (cons "evaluation"
           (list (cons "identity" (lisp-critic-run-record-id-of record))
                 (cons "status" (%snapshot-text
                                 (lisp-critic-run-record-status record)))
                 (cons "started-at" (lisp-critic-run-record-started-at-of record))
                 (cons "finished-at" (lisp-critic-run-record-finished-at-of record))
                 (cons "input" (%snapshot-text (target-form-of target)))
                 (cons "invocation"
                       (%snapshot-text
                        (lisp-critic-run-record-invocation-form-of record)))
                 ;; A vector, not a list: with alists written as
                 ;; objects, a list of plain strings would be mistaken
                 ;; for one. Sequences say so by being vectors.
                 (cons "notes" (coerce (mapcar #'%snapshot-text
                                               (lisp-critic-run-record-notes-of
                                                record))
                                       'vector))
                 (cons "raw-output" (lisp-critic-run-record-raw-output record))
                 (cons "error-output"
                       (lisp-critic-run-record-error-output-of record))
                 (cons "condition"
                       (or (%snapshot-text
                            (lisp-critic-run-record-condition-summary-of record))
                           :null))))
     (cons "rule"
           (list (cons "name" (%snapshot-text (rule-name-of rule)))
                 (cons "pattern" (%snapshot-text (rule-pattern-of rule)))
                 (cons "response" (coerce (mapcar #'%snapshot-text
                                                  (rule-response-of rule))
                                          'vector))
                 (cons "system" (or (getf source :system) :null))))
     (cons "artifact" (or (%snapshot-artifact (getf source :pathname)) :null))
     (cons "provenance"
           (list (cons "engine"
                       (or (and station
                                (%snapshot-text
                                 (getf (lisp-critic-source-station-provenance-of
                                        station)
                                       :engine)))
                           :null))
                 (cons "source-binding"
                       (or (and station
                                (lisp-critic-source-station-id-of station))
                           :null))))
     ;; Only what the running image can actually answer about itself. No
     ;; commit: a run cannot determine one without guessing at a working
     ;; directory it was never told about.
     (cons "runtime"
           (list (cons "implementation" (lisp-implementation-type))
                 (cons "version" (lisp-implementation-version))
                 (cons "written-at" (get-universal-time))))
     (cons "critiques"
           (coerce
            (mapcar (lambda (critique)
                         (list (cons "explanation"
                                     (critique-explanation-of critique))
                               (cons "evidence"
                                     (%snapshot-text
                                      (critique-evidence-of critique)))))
                    (critiques-of record))
            'vector)))))

(defun write-critic-run-snapshot (target stream)
  "Write TARGET's run to STREAM as JSON.

SHASHT decides between array and object by a special variable rather
than an argument, so the binding is here and not at every call site."
  (let ((shasht:*write-alist-as-object* t))
    (shasht:write-json (critic-run-snapshot target) stream)))

(defun critic-run-snapshot-string (target)
  (with-output-to-string (stream) (write-critic-run-snapshot target stream)))

(defun %snapshot-value (map key &optional default)
  (let ((entry (gethash key map)))
    (if (or (null entry) (eq entry :null)) default entry)))

(defun %snapshot-list (value)
  (cond ((null value) nil)
        ((vectorp value) (coerce value 'list))
        (t value)))

(defun read-critic-run-snapshot (stream)
  "Read a snapshot from STREAM as data.

JSON, so this creates no package and interns no symbol, whatever the
engine called its rules."
  (shasht:read-json stream))

(defun reconstitute-critic-run (snapshot)
  "Rebuild the objects the existing views read, from inert data.

Builds nothing that runs: no system is found, no wrapper is loaded, no
engine is reached, no rule is applied. The result carries the finding
of a run that happened elsewhere, and says as much in its contract."
  (let* ((version (%snapshot-value snapshot "snapshot-version"))
         (evaluation (%snapshot-value snapshot "evaluation"))
         (rule-data (%snapshot-value snapshot "rule"))
         (provenance (%snapshot-value snapshot "provenance"))
         (artifact (%snapshot-value snapshot "artifact")))
    (unless (eql version +critic-snapshot-version+)
      (error "Unsupported Critic snapshot version ~S; this reads version ~S."
             version +critic-snapshot-version+))
    (let* ((target (make-instance 'critic-target
                     :form (%snapshot-value evaluation "input")))
           (contract (make-instance 'lisp-critic-contract
                       :id "reconstituted-critic-run"
                       :title "A Critic run recorded elsewhere"
                       :source-station nil
                       :input-policy '(:form :not-evaluated)
                       :invocation-policy '(:read-from-snapshot)
                       :output-policy '(:structured-findings)
                       :availability-policy '(:no-engine-required)
                       :failure-policy '(:record-condition)
                       :review-contract-role :critique))
           (record (make-instance 'critic-rule-run-record
                     :id (%snapshot-value evaluation "identity")
                     :contract contract
                     :target target
                     :target-paths nil
                     :status (%snapshot-value evaluation "status")
                     :started-at (%snapshot-value evaluation "started-at")
                     :finished-at (%snapshot-value evaluation "finished-at")
                     :raw-output (%snapshot-value evaluation "raw-output" "")
                     :error-output (%snapshot-value evaluation "error-output" "")
                     :condition-summary (%snapshot-value evaluation "condition")
                     :invocation-form (%snapshot-value evaluation "invocation")
                     :notes (%snapshot-list
                             (%snapshot-value evaluation "notes"))))
           (rule (make-instance 'critic-rule
                   :name (%snapshot-value rule-data "name")
                   :pattern (%snapshot-value rule-data "pattern")
                   :response (%snapshot-list
                              (%snapshot-value rule-data "response"))
                   :source (list :system (%snapshot-value rule-data "system")
                                 :pathname (and artifact
                                                (%snapshot-value artifact "path"))
                                 :engine (and provenance
                                              (%snapshot-value provenance "engine"))
                                 :source-binding
                                 (and provenance
                                      (%snapshot-value provenance
                                                       "source-binding"))))))
      (setf (rule-of record) rule)
      (dolist (critique-data (reverse (%snapshot-list
                                       (%snapshot-value snapshot "critiques"))))
        (let ((critique (make-instance 'critique
                          :rule rule :target target :record record
                          :evidence (%snapshot-value critique-data "evidence")
                          :explanation (%snapshot-value critique-data
                                                        "explanation"))))
          (push critique (critiques-of record))
          (push critique (critiques-of rule))))
      (push record (target-runs-of target))
      target)))
