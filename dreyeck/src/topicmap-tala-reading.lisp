;;;; Executable TALA reading examples
(IN-PACKAGE :DREYECK/INSPECTOR/TOPICMAP/TALA)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reading TALA as a Layout Layer"))

;; This reading's subject is the real current repository and its
;; CURRENT-HEAD. A runtime loaded from sources that are not a Git checkout,
;; such as a Nix store copy, has no current repository, and the reading
;; says so instead of failing inside Git. Nothing here stands in for the
;; repository: no commit, no repository and no CURRENT-HEAD is claimed,
;; and build provenance is a different statement that this reading does
;; not make.

(defun reading-source-directory ()
  "The directory whose checkout this reading is about: where DREYECK/GIT is
defined, the directory MAKE-CURRENT-GIT-REPOSITORY-CHECKOUT asks Git about."
  (uiop:pathname-directory-pathname
   (asdf:system-source-file (asdf:find-system :dreyeck/git))))

(defun live-git-checkout-absence (directory)
  "NIL when DIRECTORY lies in a live Git checkout, otherwise an observation
that it does not.

Git is asked once, through GIT-RUN-VALUES, where a non-zero exit status is
data rather than an error. Once Git has answered that there is no checkout,
nothing further is asked of it. The observation keeps what Git said, so a
refusal for another reason, such as an unsafe directory, stays visible.
It is not a missing renderer: D2 is reported by TALA-DEPENDENCY-STATUS."
  (let ((arguments '("rev-parse" "--show-toplevel")))
    (multiple-value-bind (stdout stderr exit-code)
        (apply #'dreyeck/git:git-run-values directory arguments)
      (declare (ignore stdout))
      (unless (zerop exit-code)
        (list :kind :no-live-git-checkout
              :examined (namestring directory)
              :git (list :command (cons "git" arguments)
                         :directory (namestring directory)
                         :exit-code exit-code
                         :stderr (dreyeck/git:trim-git-output stderr))
              :requires "A live Git checkout, because this reading's subject is the current repository and its CURRENT-HEAD. This is not the TALA renderer: D2 is reported separately."
              :remedy "Load the reading from a Git checkout, for example with nix develop .#tala in the repository."
              :evidence-status :observed)))))

(defun no-live-git-checkout-p (value)
  (and (consp value) (eq :no-live-git-checkout (getf value :kind))))

(defun reading-live-checkout ()
  "The live checkout this reading is about, or the observation that there is none."
  (or (live-git-checkout-absence (reading-source-directory))
      (dreyeck/git:make-current-git-repository-checkout)))

(HYPERDOC:DEFEXAMPLE READING-WORKSPACE
  (let ((checkout (reading-live-checkout)))
    (if (no-live-git-checkout-p checkout)
        checkout
        (tm::make-topicmap-workspace-for-object checkout))))

(HYPERDOC:DEFEXAMPLE READING-PROJECTION
  (let ((workspace (reading-workspace)))
    (if (no-live-git-checkout-p workspace)
        workspace
        (tm:topicmap-projection-of workspace))))

(HYPERDOC:DEFEXAMPLE READING-TOPIC-IDENTITIES
  (let ((projection (reading-projection)))
    (if (no-live-git-checkout-p projection)
        projection
        (mapcar #'tm:topicmap-topic-id-of
                (tm:topicmap-projection-topics-of projection)))))

(HYPERDOC:DEFEXAMPLE READING-ASSOCIATION-ENDPOINTS
  (let ((projection (reading-projection)))
    (if (no-live-git-checkout-p projection)
        projection
        (mapcar (lambda (association)
                  (list :id (tm:topicmap-association-id-of association)
                        :from (tm:topicmap-association-from-of association)
                        :to (tm:topicmap-association-to-of association)))
                (tm:topicmap-projection-associations-of projection)))))

(HYPERDOC:DEFEXAMPLE READING-LAYOUT-INPUT
  (let ((projection (reading-projection)))
    (if (no-live-git-checkout-p projection)
        projection
        (tala:projection-tala-input projection :seed 44))))

(HYPERDOC:DEFEXAMPLE READING-ID-MAPPING
                     (LET ((INPUT (READING-LAYOUT-INPUT)))
                       (IF (NO-LIVE-GIT-CHECKOUT-P INPUT)
                           INPUT
                          (LIST :TOPICS (TALA:TALA-INPUT-TOPICS INPUT)
                                :ASSOCIATIONS
                                (TALA:TALA-INPUT-ASSOCIATIONS INPUT)
                                :ROUNDTRIPS
                                ;; The key leads back to the Topic by being
                                ;; looked up in the projection that assigned
                                ;; it, not by being decoded. A key is local
                                ;; to this diagram; the Topic is not.
                                (MAPCAR
                                        (LAMBDA (ENTRY)
                                                (LIST (GETF ENTRY :ID)
                                                      (TALA:TALA-INPUT-TOPIC-ID
                                                                                INPUT
                                                                                (GETF
                                                                                      ENTRY
                                                                                      :D2-ID))))
                                        (TALA:TALA-INPUT-TOPICS INPUT))))))

(HYPERDOC:DEFEXAMPLE READING-DEPENDENCY (TALA:TALA-DEPENDENCY-STATUS))

;; The subject comes first: without a current repository there is nothing
;; to lay out, so the renderer is not consulted.
(HYPERDOC:DEFEXAMPLE READING-LAYOUT-RESULT
  (let ((input (reading-layout-input)))
    (if (no-live-git-checkout-p input)
        input
        (let ((dependency (tala:tala-dependency-status)))
          (if (eq :available (getf dependency :status))
              (tala:run-tala input) dependency)))))

(HYPERDOC:DEFEXAMPLE READING-GEOMETRY
  (let ((result (reading-layout-result)))
    (if (typep result 'tala:tala-rendering)
        (tala:tala-rendering-evidence result) result)))

(HYPERDOC:DEFEXAMPLE READING-INVARIANT-REPORT
  (let ((result (reading-comparison)))
    (if (typep result 'tala-comparison) (comparison-invariants result) result)))

(HYPERDOC:DEFEXAMPLE READING-COMPARISON
  (let ((workspace (reading-workspace)))
    (if (no-live-git-checkout-p workspace)
        workspace
        (compare-workspace-layouts workspace :seed 44))))

(HYPERDOC:DEFEXAMPLE READING-SOURCE-WORKSPACE
                     (LET
                          ((PROJECTION
                                       (TM::PROJECT-PAGE-ATTACHED-ASD
                                                                      (ASDF/SYSTEM:SYSTEM-SOURCE-FILE
                                                                                                      (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                               "dreyeck/topicmap/tala"))
                                                                      (MAPCAR
                                                                              (LAMBDA
                                                                                      (NAME)
                                                                                      (CONS
                                                                                            NAME
                                                                                            (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                     NAME)))
                                                                              (QUOTE
                                                                                     ("dreyeck/topicmap/tala"
                                                                                      "dreyeck/inspector/topicmap/tala"
                                                                                      "dreyeck/topicmap/tala/reading"
                                                                                      "dreyeck/topicmap/tala/reading/tests"))))))
                          (TM:MAKE-TOPICMAP-WORKSPACE PROJECTION
                                                      (TM:TOPICMAP-TOPIC-ID-OF
                                                                               (FIRST
                                                                                      (TM:TOPICMAP-PROJECTION-TOPICS-OF
                                                                                                                        PROJECTION))))))

(DREYECK/HYPERDOC:DEFHYPERDOC *TALA-READING* :TITLE
                              "Reading TALA as a Layout Layer" :ID
                              "dreyeck/topicmap/tala/reading" :ASDF-SYSTEM-NAME
                              "dreyeck/topicmap/tala/reading" :SUBDIRECTORY
                              "dreyeck/pages/topicmap-tala" :CODE-SUBDIRECTORY
                              "dreyeck/src" :MAIN-PAGE-ID
                              "Reading TALA as a Layout Layer")

;; The existing source renderer supplies the play thunk. This more-specific
;; presentation adapter leaves other examples and any authority-policy thunk
;; untouched, and binds only these layout examples to the existing TALA probe.
(defmethod html-inspector-views/standard:render-toplevel-cst :around
    ((head (eql 'hyperdoc:defexample)) (cst concrete-syntax-tree:cons-cst) source position)
  (let ((name (concrete-syntax-tree:raw (concrete-syntax-tree:second cst))))
    (if (not (member name '(reading-layout-result reading-geometry
                           reading-invariant-report reading-comparison authored-d2-example)))
        (call-next-method)
        (let ((dependency (tala:tala-dependency-status)))
          (if (not (eq :available (getf dependency :status)))
              (progn
                (views:object-ref dependency :display
                                  (format nil "TALA ~A (inspect capability)"
                                          (string-downcase (symbol-name (getf dependency :status)))))
                ;; DEFEXAMPLE's normal primary rendering is RENDER-CST. Keep
                ;; its persisted source and object references, without play.
                (html-inspector-views/standard::render-cst cst source position))
              (let* ((before (copy-list (views::accumulator-references views::*view-accumulator*)))
                     (end (call-next-method)))
                ;; Preserve the upstream/authority-policy action itself; wrap
                ;; only its evaluation so disappearing/failed tools remain
                ;; inspectable instead of escaping the CLOG event thread.
                (dolist (reference (set-difference
                                    (views::accumulator-references views::*view-accumulator*)
                                    before :test #'eq))
                  (when (typep (cdr reference) 'views:thunk)
                    (let ((original (cdr reference)))
                      (setf (cdr reference)
                            (views:thunk
                              (handler-case
                                  (let ((current (tala:tala-dependency-status)))
                                    (if (eq :available (getf current :status))
                                        (views:eval-thunk original) current))
                                (error (condition) condition)))))))
                end))))))
