;;;; The project CTM emitter on the proposals, in its own process with Topic Maps 5a4a668
;;; Run from the HyperDoc root, never in the reading's image:
;;;   env XDG_CACHE_HOME=<a fresh directory> TOPIC_MAPS_ROOT=<the clean 5a4a668 clone> \
;;;     sbcl --non-interactive --load scripts/tmdm-model-bootstrap.lisp --load <this file>
;;; It loads dreyeck/work/project, the system of the emitter and the Project Workspace, with the Topic Maps revision that system
;;; is pinned to, and refuses any other. It builds the project model twice: from the four source pages as they are, and with the
;;; text of Implementation Assignments replaced in memory by the page followed by the addition, plus the draft dictionary as a
;;; :proposed-dictionary source. This is the emitter's own way of reading an addition (read-project-sources :texts and :extra).
;;; It writes nothing but its record, evidence/emitter-crosscheck.sexp beside this file.
(asdf:load-system "dreyeck/work/project")
(defpackage #:tmd-crosscheck
  (:use #:cl) (:local-nicknames (#:p #:dreyeck/work/project) (#:plan #:dreyeck/work/ctm-page-authoring)))
(in-package #:tmd-crosscheck)

(defparameter *here* (uiop:pathname-directory-pathname *load-truename*))
(defparameter *root* (asdf:system-source-directory "dreyeck"))
(defparameter +addition+ "implementation-assignments-addition.html")
(defparameter +dictionary+ "topic-maps-deployment-wbs-dictionary.html")
(defparameter +dictionary-path+ "dreyeck/work/topic-maps-deployment-review/proposals/topic-maps-deployment-wbs-dictionary.html")
(defparameter +assignments+
  '("cc-2026-10-26-topic-maps-deployment-design" "cc-2026-10-26-topic-maps-local-packaging"
    "cc-2026-10-27-topic-maps-deployment-review" "cc-2026-10-27-topic-maps-deployment-wbs-proposal"))

(defun sha (octets) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))
(defun sha-file (pathname) (with-open-file (in pathname :element-type '(unsigned-byte 8))
                             (let ((v (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence v in) (sha v))))
(defun sha-text (text) (sha (sb-ext:string-to-octets text :external-format :utf-8)))
(defun text (pathname) (uiop:read-file-string pathname :external-format :utf-8))
(defun git (&rest arguments) (uiop:run-program (list* "git" "-C" (namestring *root*) arguments) :output :string))
(defun tree-state () (list :status (git "status" "--porcelain") :diff-sha256 (sha-text (git "diff" "--binary"))))
(defun source-digests () (mapcar (lambda (i) (list (p:source-path i) (sha-file (merge-pathnames (p:source-path i) *root*))))
                                 (p:sources-items (p:read-project-sources))))
(defun tmd-p (id) (and (stringp id) (uiop:string-prefix-p "tmd" id)))
(defun utc (time) (multiple-value-bind (s mi h d mo y) (decode-universal-time time 0)
                    (format nil "~D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" y mo d h mi s)))

(defun describe-model (model retained)
  (let ((ours (lambda (a) (member (p::assignment-id a) +assignments+ :test #'equal))))
    (list :refused nil
          :proposals (loop for d in (p:model-proposals model) when (tmd-p (p:declaration-id d))
                           collect (list (p:declaration-id d) (p:declaration-kind d) (p:declaration-label d)))
          :declared-tmd (loop for d in (p:model-declarations model)
                              when (and (tmd-p (p:declaration-id d)) (not (p::declaration-proposal-p d))) collect (p:declaration-id d))
          :proposed-statements (loop for s in (p:model-statements model) when (and (p::statement-proposal-p s) (tmd-p (p:statement-from s)))
                                     collect (list (p:statement-from s) (p:statement-relation s) (p:statement-to s)))
          :assignments (loop for a in (p:model-assignments model) when (funcall ours a)
                             collect (list (p::assignment-id a) (p::assignment-title a)
                                           (loop for (field . ref) in (p::assignment-refs a) collect (list field ref))))
          :evidence-entries (loop for e in (p:model-evidence-entries model) when (funcall ours (p::entry-assignment e))
                                  collect (list (p:entry-key e) (if (p::entry-execution-p e) :execution-report :evidence-note)))
          :proposed-entries (loop for (entry . item) in (p:model-proposed-entries model)
                                  when (equal (p:source-path item) +dictionary-path+)
                                    collect (list (plan::entry-element-id entry)
                                                  (mapcar #'plan::control-id (plan::entry-controls entry))))
          :evidence-inputs (loop for (entry . item) in (p:model-proposed-entries model)
                                 when (equal (p:source-path item) +dictionary-path+)
                                   append (loop for c in (plan::entry-controls entry) for test = (plan::control-test c)
                                                when test collect (let ((input (find test (p:model-evidence-inputs model) :key #'p:evidence-path :test #'equal)))
                                                                    (list (plan::control-id c) test (and input (p:evidence-sha256 input))))))
          :gaps (loop for g in (p:model-gaps model) for key = (p::gap-key g)
                      when (or (search "tmd" key) (some (lambda (a) (search a key)) +assignments+))
                        collect (list (p:gap-rule g) key))
          :ctm-sha256 (sha-text (p:model-text model)) :ctm-characters (length (p:model-text model))
          :ctm-lines-naming-tmd (count-if (lambda (line) (search "/tmd" line))
                                          (uiop:split-string (p:model-text model) :separator '(#\Newline)))
          :ctm-equals-retained (string= (p:model-text model) retained))))

(let* ((identity (uiop:symbol-call :dreyeck/work/project :topic-maps-source-identity))
       (retained-path (p:project-ctm-pathname))
       (state-before (tree-state)) (retained-before (sha-file retained-path)) (digests-before (source-digests))
       (retained (text retained-path))
       (page (p::source-text (find :assignments (p:sources-items (p:read-project-sources)) :key #'p::source-role)))
       (addition (text (merge-pathnames +addition+ *here*))) (dictionary (text (merge-pathnames +dictionary+ *here*)))
       (started (get-universal-time)))
  (unless (getf identity :pinned) (error "TOPIC_MAPS_ROOT must be a clean checkout of the pinned revision; it is ~S." identity))
  (let* ((baseline (p:build-project-model (p:read-project-sources)))
         (with-proposals
           (handler-case
               (describe-model
                (p:build-project-model
                 (p:read-project-sources
                  :texts (list (cons :assignments (concatenate 'string page addition)))
                  :extra (list (list :role :deployment-dictionary :book "dreyeck/work/project" :title "Topic Maps Deployment WBS Dictionary"
                                     :kind :proposed-dictionary :path +dictionary-path+ :text dictionary))))
                retained)
             (error (c) (list :refused (princ-to-string c)))))
         (record (list :purpose "The project CTM emitter on the page Implementation Assignments followed by the addition, with the draft dictionary as a proposed dictionary; nothing written but this record."
                       :started-at (utc started) :finished-at (utc (get-universal-time))
                       :lisp (format nil "~A ~A" (lisp-implementation-type) (lisp-implementation-version)) :asdf (asdf:asdf-version)
                       :topic-maps identity :hyperdoc-root (namestring *root*)
                       :inputs (list :addition-sha256 (sha-text addition) :dictionary-sha256 (sha-text dictionary)
                                     :page-sha256 (sha-text page) :retained-ctm-sha256 retained-before)
                       :baseline (list :ctm-equals-retained (string= (p:model-text baseline) retained)
                                       :ctm-sha256 (sha-text (p:model-text baseline)))
                       :with-proposals with-proposals
                       :unchanged (list :tree (equal state-before (tree-state)) :retained-ctm (equal retained-before (sha-file retained-path))
                                        :source-pages (equal digests-before (source-digests)))
                       :tree-diff-sha256 (getf state-before :diff-sha256))))
    (with-open-file (out (ensure-directories-exist (merge-pathnames "evidence/emitter-crosscheck.sexp" *here*))
                         :direction :output :if-exists :supersede :external-format :utf-8)
      (with-standard-io-syntax
        (let ((*print-readably* nil) (*print-right-margin* 140) (*package* (find-package :keyword)))
          (format out ";;; Written by emitter-crosscheck.lisp in its own process with Topic Maps ~A.~%" (getf identity :commit))
          (pprint record out) (terpri out))))
    (format t "~&EMITTER-CROSSCHECK ~:[REFUSED ~A~;READ~*~]: ~D proposals, ~D proposed statements, ~D assignments, ~D evidence entries, ~D draft entries; baseline equals retained: ~A; unchanged: ~S~%"
            (not (getf with-proposals :refused)) (getf with-proposals :refused)
            (length (getf with-proposals :proposals)) (length (getf with-proposals :proposed-statements))
            (length (getf with-proposals :assignments)) (length (getf with-proposals :evidence-entries))
            (length (getf with-proposals :proposed-entries)) (getf (getf record :baseline) :ctm-equals-retained) (getf record :unchanged))))
