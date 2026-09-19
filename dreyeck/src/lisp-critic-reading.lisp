;;;; Reading the Lisp Critic genealogy.
;;;;
;;;; Several different things have been called "Lisp Critic". This reading
;;;; keeps them apart by what can actually be shown here, not by narrative.
;;;;
;;;; Every station carries an evidence status from one ordered vocabulary:
;;;;
;;;;   :ASSERTED-ELSEWHERE  claimed in project conversation; no local artifact
;;;;   :DOCUMENTED          a local document describes it; no source here
;;;;   :SOURCE-OBSERVED     source files are readable in this workspace
;;;;   :EXECUTABLE          the code runs in this image
;;;;
;;;; Relations between stations use only what the evidence supports. There is
;;;; deliberately no DESCENDS-FROM relation: a resemblance of ideas is not a
;;;; demonstrated code lineage, and nothing in this workspace demonstrates one
;;;; between Fischer's LISP-CRITIC and Riesbeck's lisp-critic.

(defpackage #:dreyeck/lisp-critic/reading
  (:use #:cl)
  (:local-nicknames (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record))
  (:export #:*lisp-critic-reading*
           #:lisp-critic-genealogy
           #:genealogy-in-this-runtime
           #:engine-available-p
           #:lisp-critic-station
           #:evidence-ladder-example
           #:lisp-critic-genealogy-example
           #:historical-claims
           #:claims-about
           #:resolve-executability
           #:evidence-adequate-for-p
           #:historical-claims-example
           #:evidence-adequacy-example
           #:fischer-critic-documentation-example
           #:riesbeck-source-station-example
           #:riesbeck-car-cdr-rule-example
           #:ensure-riesbeck-engine-loaded
           #:engine-source-view
           #:critic-match-example
           #:critic-non-match-example
           #:critic-failure-example
           #:critic-outcome-contrast-example
           #:critique-anatomy-example
           #:critic-dimension-comparison-example))

(in-package #:dreyeck/lisp-critic/reading)

(hyperdoc:see
  (hyperdoc:page "Reading the Lisp Critic Genealogy")
  (hyperdoc:page "The Fischer Critic as an Environment")
  (hyperdoc:page "Reading Riesbeck's Lisp Critic")
  (hyperdoc:page "From Riesbeck Run to HyperDoc Critique")
  (hyperdoc:page "Anatomy of a Critique"))

;;
;; Where the local evidence lives
;;

(defparameter +fischer-research-note+
  (merge-pathnames ".wiki/wiki.ralfbarkow.ch/pages/a-critic-for-lisp"
                   (user-homedir-pathname))
  "The local research page that cites Fischer's paper. Not part of this
repository: a workspace artifact, quoted here as documentation only.")

(defun vendored-engine-directory ()
  "The vendored Riesbeck/Beane sources inside the local source station."
  (merge-pathnames
   "vendor/lisp-critic/"
   (uiop:ensure-directory-pathname
    (critic:lisp-critic-source-station-asset-root-of
     (critic:make-critic-source-station)))))

(defun vendored-engine-file (name)
  (let ((pathname (merge-pathnames name (vendored-engine-directory))))
    (and (probe-file pathname) pathname)))

;;
;; The genealogy: stations, each with its own evidence status
;;

(defun lisp-critic-genealogy ()
  "The stations that have been called \"Lisp Critic\", oldest first.

Two separate lines. Nothing here asserts that Riesbeck's code descends from
Fischer's system; the evidence supports a resemblance of purpose, no more."
  (copy-tree
   '((:station :fischer-lisp-critic
      :line :research
      :name "LISP-CRITIC"
      :period "1987"
      :authors ("Gerhard Fischer")
      :language "LISP"
      :runtime "research environment; not identified in local evidence"
      :source-availability :not-present-in-this-workspace
      :provenance
      (:primary "Gerhard Fischer, A Critic for LISP, IJCAI-87"
       :primary-url
       "https://l3d.colorado.edu/wp-content/uploads/2016/04/1987-Critic-for-LISP-IJCAI87.pdf"
       :local-document :fischer-research-note)
      :documented-features
      ("rule-based advice" "user model" "knowledge browser"
       "visualization support" "incremental learning" "learning on demand")
      :documented-scope
      "Improve Lisp programs locally according to a style encoded by rules;
explicitly not a whole-program correctness framework."
      :relation-to-predecessor nil
      :relation-to-successor :conceptual-resemblance
      :executable-here nil
      :evidence-status :documented)

     (:station :riesbeck-lisp-critic
      :line :code
      :name "lisp-critic"
      :period "Northwestern CS 325 course material; archived 2004"
      :authors ("Chris Riesbeck")
      :language "Common Lisp"
      :runtime "runs under SBCL in this image"
      :source-availability :vendored-in-source-station
      :provenance
      (:origin-url
       "http://www.cs.northwestern.edu/academics/courses/325/exercises/critic.html"
       :local-readme "vendor/lisp-critic/README")
      :relation-to-predecessor :conceptual-resemblance
      :relation-to-successor :port/adaptation
      :executable-here t
      :evidence-status :executable)

     (:station :beane-asdf-adaptation
      :line :code
      :name "lisp-critic, ASDF-loadable archive"
      :period "2004-05-06"
      :authors ("Zach Beane")
      :language "Common Lisp"
      :runtime "ASDF system; loaded here on demand"
      :source-availability :vendored-in-source-station
      :provenance
      (:distribution "https://xach.com/lisp/lisp-critic.tar.gz"
       :index "https://xach.com/lisp/"
       :local-readme "vendor/lisp-critic/README")
      :documented-changes
      ("require/provide statements removed"
       "cs235 package references replaced by lisp-critic-user"
       "an ASDF defsystem file added")
      :relation-to-predecessor :port/adaptation
      :relation-to-successor :local-extraction
      :executable-here t
      :evidence-status :executable)

     (:station :a-critic-for-lisp-station
      :line :code
      :name "a-critic-for-lisp"
      :period "2025"
      :authors ("HyperDoc project")
      :language "Common Lisp"
      :runtime "local source station outside this repository"
      :source-availability :present-in-workspace
      :provenance (:wrapper-system "a-critic-for-lisp"
                   :patch-notes "PATCH-NOTES.md")
      :documented-changes
      ("critic-available-p and critique-if-available use (find-package \"LISP-CRITIC-USER\")")
      :relation-to-predecessor :local-extraction
      :relation-to-successor :hyperdoc-projection
      :executable-here t
      :evidence-status :executable)

     (:station :dreyeck-lisp-critic
      :line :code
      :name "dreyeck/lisp-critic"
      :period "current"
      :authors ("HyperDoc project")
      :language "Common Lisp"
      :runtime "this repository"
      :source-availability :in-this-repository
      :provenance (:systems ("dreyeck/lisp-critic"
                             "dreyeck/evaluation-record/lisp-critic"
                             "dreyeck/lisp-critic/critique"
                             "dreyeck/inspector/lisp-critic"))
      :adds ("run record as Evaluation Record"
             "first-class Critique object"
             "Inspector relations between them")
      :relation-to-predecessor :hyperdoc-projection
      :relation-to-successor nil
      :executable-here t
      :evidence-status :executable))))

;;
;; Provenance of statements, which is not the same thing as an Evaluation
;; Record. An Evaluation Record documents one program execution. These
;; records document why a sentence about a Critic system is believed, so
;; they are kept local to this reading rather than derived from that
;; protocol or generalised into a provenance subsystem.
;;
;; A claim carries:
;;
;;   SUBJECT            what the claim is about
;;   CLAIM-TYPE         what kind of thing is being claimed
;;   ASSERTION          the sentence itself
;;   EVIDENCE-KIND      what carries it
;;   WITNESS            who stands behind that evidence
;;   LOCATOR            where to re-check it
;;   LOCATOR-OBSERVED-P whether the cited document is readable here
;;   SOURCE-OBSERVED-P  whether we observe the artifact the claim is about
;;   EXECUTABLE-HERE-P  whether that artifact can run in this runtime
;;
;; The last three are deliberately independent. Riesbeck's engine is source
;; observed and still not executable on a server without the station, and a
;; paper can carry a claim about an artifact nobody here possesses.
;;

(defparameter +evidence-adequacy+
  '((:capability    :primary-paper :source-file)
    (:contribution  :primary-paper)
    (:environment   :primary-paper)
    (:identity      :primary-paper :source-file :readme)
    (:descent       :source-file :readme :absence-of-reference))
  "Which kind of evidence can carry which kind of claim.

Evidence has no standing on its own: a source file settles what a program
does and says nothing about whether a 1987 system had a user model, and a
paper about that system settles nothing about who edited a file in 2003.
Strength is a relation between evidence and claim, so it is written down as
one.")

(defun evidence-adequate-for-p (evidence-kind claim-type)
  (let ((row (assoc claim-type +evidence-adequacy+)))
    (and row (member evidence-kind (rest row)) t)))

(defun historical-claims ()
  "Every historical sentence this reading shows, with its provenance.

Claims carried only by conversation are not listed here; they are listed
as absent by FISCHER-CLAIMS-WITHOUT-LOCAL-EVIDENCE."
  (copy-tree
   '(;; The Fischer line. The papers are the evidence; neither the papers
     ;; nor the systems they describe are present in this workspace.
     (:subject :fischer-1987
      :claim-type :capability
      :assertion
      "LISP-CRITIC was an integrated environment: rules, a rule interpreter, a user model, explanation with a knowledge browser and visualization support, and learning on demand."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator "Fischer 1987, A Critic for LISP, IJCAI-87, pp. 177-184"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :fischer-1987
      :claim-type :contribution
      :assertion
      "Boecker developed the original ideas, the rule set and the rule interpreter. He is credited as a contributor, not as a co-author of the 1987 paper."
      :evidence-kind :primary-paper
      :witness (:author-self-report :acknowledgement)
      :locator "Fischer 1987, A Critic for LISP, IJCAI-87, acknowledgements"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :fischer-1987
      :claim-type :contribution
      :assertion
      "Morel implemented the explanation capabilities; Burns implemented the statistical analysis."
      :evidence-kind :primary-paper
      :witness (:author-self-report :acknowledgement)
      :locator "Fischer 1987, A Critic for LISP, IJCAI-87, acknowledgements"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-version-1
      :claim-type :contribution
      :assertion "Version 1 is credited to Morel, Burns and Cormack."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, A Conceptual Framework for Knowledge-Based Critic Systems, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-version-2
      :claim-type :contribution
      :assertion "Version 2 is credited to Rieman, Johl and Lynn."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-version-2
      :claim-type :environment
      :assertion
      "Version 2 ran on a Symbolics 3600 under Genera, with the knowledge base updated to Common Lisp."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-later
      :claim-type :environment
      :assertion
      "The conceptual knowledge structure was object-oriented, implemented with the Common Lisp Object System."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-later
      :claim-type :capability
      :assertion
      "The refined user model drew on code analysis, explanation requests, and proposals the programmer had rejected."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-zmacs
      :claim-type :capability
      :assertion
      "The ZMACS-based version offered an interaction cycle of accept, reject, or request explanation."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :critiquing-paradigm
      :claim-type :identity
      :assertion
      "The work was generalised from one Lisp critic into a conceptual framework for knowledge-based critic systems."
      :evidence-kind :primary-paper
      :witness (:author-self-report :peer-reviewed-publication)
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378, title and framing"
      :locator-observed-p nil
      :source-observed-p nil
      :executable-here-p nil)

     ;; The Riesbeck line. Here the artifact itself is in the workspace.
     (:subject :riesbeck-engine
      :claim-type :identity
      :assertion
      "The engine carries a dated update history running from 1997 to 2003, each entry initialled CKR."
      :evidence-kind :source-file
      :witness (:author-self-report)
      :locator "vendor/lisp-critic/lisp-critic.lisp, update-history header"
      :locator-observed-p t
      :source-observed-p t
      :executable-here-p :runtime-dependent)

     (:subject :riesbeck-2003-change
      :claim-type :descent
      :assertion
      "DEFINE-LISP-PATTERN and DEFINE-RESPONSE were merged on 1/3/03."
      :evidence-kind :source-file
      :witness (:author-self-report)
      :locator "vendor/lisp-critic/lisp-critic.lisp, update-history header"
      :locator-observed-p t
      :source-observed-p t
      :executable-here-p :runtime-dependent)

     (:subject :beane-2004-adaptation
      :claim-type :descent
      :assertion
      "On 2004-05-06 require/provide statements were removed, cs235 package references were replaced by lisp-critic-user, and an ASDF defsystem file was added."
      :evidence-kind :readme
      :witness (:adapter-self-report)
      :locator "vendor/lisp-critic/README"
      :locator-observed-p t
      :source-observed-p t
      :executable-here-p :runtime-dependent)

     ;; The claim that keeps the two lines apart, carried by an absence.
     (:subject :riesbeck-engine
      :claim-type :descent
      :assertion
      "The vendored engine contains no reference to Fischer, Boecker, Colorado or a critiquing paradigm. Nothing in the source connects it to the research line."
      :evidence-kind :absence-of-reference
      :witness (:local-observation)
      :locator "vendor/lisp-critic/, full-text search"
      :locator-observed-p t
      :source-observed-p t
      :executable-here-p :runtime-dependent))))

(defun resolve-executability (claim)
  "Answer EXECUTABLE-HERE-P for the runtime asking.

A stored :RUNTIME-DEPENDENT is a contract, not an answer."
  (let ((stored (getf claim :executable-here-p)))
    (if (eq :runtime-dependent stored)
        (engine-available-p)
        stored)))

(defun claims-about (subject)
  (remove-if-not (lambda (claim) (eq subject (getf claim :subject)))
                 (historical-claims)))

(defparameter +engine-dependent-stations+
  '(:riesbeck-lisp-critic :beane-asdf-adaptation :a-critic-for-lisp-station)
  "Stations whose code can only run where the source station is mounted.")

(defun genealogy-in-this-runtime ()
  "The genealogy with EXECUTABLE-HERE answered for the runtime asking.

The frozen records describe the stations. Whether their code can run is a
property of the runtime, and a served HyperDoc without the source station
must not inherit a yes that was true only on a development machine."
  (let ((available (engine-available-p)))
    (mapcar (lambda (station)
              (if (member (getf station :station) +engine-dependent-stations+)
                  (let ((copy (copy-list station)))
                    (setf (getf copy :executable-here) available)
                    copy)
                  station))
            (lisp-critic-genealogy))))

(defun lisp-critic-station (key)
  (or (find key (lisp-critic-genealogy)
            :key (lambda (station) (getf station :station)))
      (error "No genealogy station ~S." key)))

;;
;; What is only claimed, and therefore not shown as evidence
;;

(defun fischer-claims-without-local-evidence ()
  "Claims carried in from earlier project conversation that this workspace
does not support. They are listed so they are visibly absent from the
genealogy rather than silently folded into it."
  (copy-tree
   '((:claim :boecker-co-authorship
      :statement "Boecker as a co-author of the 1987 paper."
      :note "His contribution is documented and is recorded as a claim; co-authorship of the paper is a different assertion and is not supported."
      :local-evidence :none)
     (:claim :code-lineage-to-riesbeck
      :statement "Riesbeck's lisp-critic derives from Fischer's LISP-CRITIC."
      :note "The vendored engine's own silence about the research line is recorded as evidence against this, not for it."
      :local-evidence :none))))

;;
;; The evidence ladder, computed rather than asserted
;;

(hyperdoc:defexample evidence-ladder-example
  "Three different things a page can mean by \"here is the Lisp Critic\".

Each rung is checked against the filesystem and the running image, so the
reading cannot quietly promote a documented claim into a demonstrated one."
  (let* ((station (critic:make-critic-source-station))
         (engine (vendored-engine-file "lisp-critic.lisp"))
         (rules (vendored-engine-file "lisp-rules.lisp"))
         ;; Run first: the run is what loads the engine, so asking whether
         ;; the engine is loaded before running would answer about the wrong
         ;; moment.
         (record (first (critic:target-runs-of
                         (critic:car-cdr-critique-example)))))
    (list
     :kind :evidence-ladder
     :documented
     (list :rung-establishes "a local document describes the system"
           :subject :fischer-lisp-critic
           :local-document (namestring +fischer-research-note+)
           :document-present-p (and (probe-file +fischer-research-note+) t)
           :source-in-workspace-p nil)
     :source-observed
     (list :rung-establishes "source files are readable in this workspace"
           :subject :riesbeck-beane-engine
           :station-present-p (critic:lisp-critic-source-station-present-p
                               station)
           :engine-file (and engine (namestring engine))
           :rules-file (and rules (namestring rules)))
     :executable
     (list :rung-establishes "the code runs in this image"
           :subject :dreyeck-lisp-critic
           :engine-package-loaded-p (and (find-package :lisp-critic) t)
           :run-status (er:evaluation-status-of record))
     :evidence-status :observed)))

(hyperdoc:defexample lisp-critic-genealogy-example
  "Every station with its evidence status and its relation to its neighbours.

Read the :RELATION-TO-PREDECESSOR values: between the two lines it is
:CONCEPTUAL-RESEMBLANCE, never a descent claim."
  (list :kind :genealogy
        :engine-available-p (engine-available-p)
        :stations (genealogy-in-this-runtime)
        :lines (flet ((line (key)
                        (remove-if-not (lambda (station)
                                         (eq key (getf station :line)))
                                       (genealogy-in-this-runtime))))
                 (list :research (line :research) :code (line :code)))
        :no-descent-claim-between-lines t
        :evidence-status :observed))

(hyperdoc:defexample historical-claims-example
  "Every historical sentence on these pages, with what carries it.

Read the three independent columns. LOCATOR-OBSERVED-P says whether the
citation can be re-checked in this workspace; SOURCE-OBSERVED-P whether the
artifact being described is here at all; EXECUTABLE-HERE-P whether it can
run. For the Fischer line all three are false, and the claims stand on the
papers alone."
  (list :kind :historical-claims
        :claims (mapcar (lambda (claim)
                          (append (list :executable-here
                                        (resolve-executability claim))
                                  claim))
                        (historical-claims))
        :adequacy +evidence-adequacy+
        :claims-without-local-evidence
        (fischer-claims-without-local-evidence)
        :evidence-status :documented))

(hyperdoc:defexample evidence-adequacy-example
  "Why evidence cannot be ranked once and for all.

A source file settles what a program does; it says nothing about whether a
1987 system had a user model. A paper about that system settles nothing
about who edited a file in 2003. Each row says which evidence can carry
which kind of claim, and every claim on these pages is checked against it."
  (list :kind :evidence-adequacy
        :relation +evidence-adequacy+
        :checked (mapcar (lambda (claim)
                           (list :subject (getf claim :subject)
                                 :claim-type (getf claim :claim-type)
                                 :evidence-kind (getf claim :evidence-kind)
                                 :adequate-p
                                 (evidence-adequate-for-p
                                  (getf claim :evidence-kind)
                                  (getf claim :claim-type))))
                         (historical-claims))
        :evidence-status :interpreted))

(hyperdoc:defexample fischer-critic-documentation-example
  "Fischer's 1987 system as documentation, beside what is not evidenced here.

The station is real and citable. The claims in the second list came from
earlier conversation and have no local artifact, so they stay out of the
genealogy."
  (list :kind :documented-station
        :station (lisp-critic-station :fischer-lisp-critic)
        :local-document (namestring +fischer-research-note+)
        :local-document-present-p (and (probe-file +fischer-research-note+) t)
        :source-in-workspace-p nil
        :executable-here-p nil
        :claims-without-local-evidence (fischer-claims-without-local-evidence)
        :evidence-status :documented))

;;
;; The Riesbeck/Beane source station
;;

(defun engine-available-p ()
  "Whether this runtime can reach the vendored engine at all.

The engine is not an ordinary dependency of this repository. It is loaded
out of a local source station that is deliberately not deployed, so whether
it is reachable is a property of the runtime, not of the reading."
  (and (critic:lisp-critic-source-station-present-p
        (critic:make-critic-source-station))
       t))

(defun runtime-evidence-status ()
  "The strongest status this runtime can honestly claim for the engine.

Where the station is absent — a served HyperDoc, for instance — the engine
is neither source-observed nor executable here, and the reading says so
instead of showing an error where content belongs."
  (if (engine-available-p) :executable :not-available-in-this-runtime))

(defun ensure-riesbeck-engine-loaded ()
  "Load the vendored engine so its own definitions can be transcluded.

Returns a status line either way. Reading pages call this before
transcluding LISP-CRITIC definitions, because a definition can only be
shown once the file defining it has been loaded."
  (handler-case
      (progn
        (unless (find-package :lisp-critic)
          (when (engine-available-p)
            (critic:car-cdr-critique-example)))
        (if (find-package :lisp-critic)
            (format nil "Riesbeck/Beane engine loaded from ~A"
                    (namestring (vendored-engine-directory)))
            (format nil "Riesbeck/Beane engine is not reachable in this ~
runtime. Its source station is a local resource and is not deployed, so the ~
definitions below are shown as unavailable rather than as source.")))
    (error (condition)
      (format nil "Riesbeck/Beane engine is not reachable in this runtime: ~A"
              condition))))

(defun unavailable-definition-view (name)
  "Stand in for a definition this runtime cannot reach.

A served page must not present a failure where it promised source. It
states which definition is missing and why, and keeps the claim it can
still support: the definition exists in the station, wherever that is
mounted."
  (html-inspector-views:html-view :title (format nil "~A (not available here)"
                                                 name)
    (html-inspector-views:html
      (:div
       (:p (html-inspector-views:esc
            (format nil "LISP-CRITIC:~A is defined in the vendored ~
Riesbeck/Beane engine, which this runtime cannot reach." name)))
       (:p (html-inspector-views:esc
            "The engine lives in a local source station that is not part of ~
this repository and is not deployed. Where the station is mounted this ~
definition is source-observed and executable; here it is neither."))))))

(defun engine-source-view (name)
  "Transclude one definition of the vendored engine, by name.

The engine is loaded first, because a definition can only be shown once the
file defining it has been loaded. Macros are resolved through
MACRO-FUNCTION, since a macro name is not a function designator.

When the engine is out of reach this returns an explicit unavailable view
rather than signalling: on a served page the condition would otherwise be
rendered as though it were the content."
  (ensure-riesbeck-engine-loaded)
  (let* ((package (find-package :lisp-critic))
         (symbol (and package (find-symbol (string-upcase name) package)))
         (definition (and symbol
                          (or (macro-function symbol)
                              (and (fboundp symbol) (fdefinition symbol))))))
    (if definition
        (html-inspector-views/standard:source-code-view definition)
        (unavailable-definition-view name))))

(hyperdoc:defexample riesbeck-source-station-example
  "What is actually on disk in the local source station, and its provenance.

Nothing is downloaded. The station is read where it already is."
  (let ((station (critic:make-critic-source-station)))
    (list :kind :source-station
          :present-p (critic:lisp-critic-source-station-present-p station)
          :asset-root (critic:lisp-critic-source-station-asset-root-of station)
          :provenance (critic:lisp-critic-source-station-provenance-of station)
          :wrapper (list :system (critic:lisp-critic-source-station-wrapper-system-of station)
                         :package (critic:lisp-critic-source-station-wrapper-package-of station)
                         :loader (critic:lisp-critic-source-station-wrapper-loader-symbol-of station))
          :upstream (list :system (critic:lisp-critic-source-station-upstream-system-of station)
                          :package (critic:lisp-critic-source-station-upstream-package-of station)
                          :file-entrypoint
                          (critic:lisp-critic-source-station-upstream-file-entrypoint-symbol-of station))
          :vendored-files
          (loop for name in '("lisp-critic.lisp" "lisp-rules.lisp"
                              "extend-match.lisp" "tables.lisp"
                              "write-wrap.lisp" "lisp-critic.asd" "README")
                for pathname = (vendored-engine-file name)
                collect (list :name name :present-p (and pathname t)
                              :pathname (and pathname (namestring pathname))))
          :evidence-status (if (engine-available-p)
                               :source-observed
                               :not-available-in-this-runtime))))

(hyperdoc:defexample riesbeck-car-cdr-rule-example
  "The CAR-CDR rule as the engine holds it, not as prose repeats it.

Pattern and response text come out of the loaded engine, so the page cannot
drift from the rule it describes."
  (let* ((target (critic:car-cdr-critique-example))
         (run (first (critic:target-runs-of target)))
         (rule (critic:rule-of run)))
    (if rule
        (list :kind :engine-rule
              :engine-available-p t
              :rule-name (critic:rule-name-of rule)
              :pattern (critic:rule-pattern-of rule)
              :response (critic:rule-response-of rule)
              :defined-in (getf (critic:rule-source-of rule) :pathname)
              :defining-macro "LISP-CRITIC:DEFINE-LISP-PATTERN"
              :evidence-status :source-observed)
        (list :kind :engine-rule
              :engine-available-p nil
              :defining-macro "LISP-CRITIC:DEFINE-LISP-PATTERN"
              :why (er:evaluation-failure-of run)
              :evidence-status (runtime-evidence-status)))))

;;
;; Three outcomes of one rule application
;;

(defun run-one-rule (rule-name form)
  "Apply one engine rule to FORM and return the run record.

The target program is never evaluated; only the rule is applied to its text."
  (let* ((station (critic:make-critic-source-station))
         (contract (make-instance 'critic:lisp-critic-contract
                     :id "reading-one-rule" :title "Reading: one rule"
                     :source-station station
                     :input-policy '(:form :not-evaluated)
                     :invocation-policy '(:apply-one-rule)
                     :output-policy '(:structured-findings)
                     :availability-policy '(:local-source-required)
                     :failure-policy '(:record-condition)
                     :review-contract-role :critique))
         (target (make-instance 'critic:critic-target :form form)))
    (critic:run-critic-rule contract rule-name target)))

(defun outcome-of (record)
  "Summarise one run record in the three terms the reading distinguishes."
  (list :status (er:evaluation-status-of record)
        :critiques (length (er:evaluation-result-of record))
        :failure (er:evaluation-failure-of record)
        :outcome (cond ((not (eq :completed (er:evaluation-status-of record)))
                        :evaluation-record-with-condition)
                       ((er:evaluation-result-of record)
                        :evaluation-record-and-critique)
                       (t :evaluation-record-only))))

(hyperdoc:defexample critic-match-example
  "A real match: the run record carries a Critique."
  (let ((record (run-one-rule "CAR-CDR" '(car (cdr items)))))
    (list :kind :critic-outcome :case :match
          :form (critic:target-form-of (critic:target-of record))
          :summary (outcome-of record)
          :record record
          :engine-available-p (engine-available-p)
          :evidence-status (runtime-evidence-status))))

(hyperdoc:defexample critic-non-match-example
  "The same rule against the form it recommends: execution succeeds, and
there is nothing to say. An Evaluation Record still exists."
  (let ((record (run-one-rule "CAR-CDR" '(second items))))
    (list :kind :critic-outcome :case :non-match
          :form (critic:target-form-of (critic:target-of record))
          :summary (outcome-of record)
          :record record
          :engine-available-p (engine-available-p)
          :evidence-status (runtime-evidence-status))))

(hyperdoc:defexample critic-failure-example
  "An unavailable rule: the run fails and the record keeps the condition."
  (let ((record (run-one-rule "NO-SUCH-CRITIC-RULE" '(car (cdr items)))))
    (list :kind :critic-outcome :case :failure
          :form (critic:target-form-of (critic:target-of record))
          :summary (outcome-of record)
          :record record
          :engine-available-p (engine-available-p)
          :evidence-status (runtime-evidence-status))))

(hyperdoc:defexample critic-outcome-contrast-example
  "The three outcomes side by side.

An Evaluation Record is produced in all three cases. A Critique is produced
only in the first. That separation is the point of the slice."
  (list :kind :outcome-contrast
        :cases (list (critic-match-example)
                     (critic-non-match-example)
                     (critic-failure-example))
        :invariant "every rule application yields an Evaluation Record"
        :engine-available-p (engine-available-p)
        :evidence-status (runtime-evidence-status)))

;;
;; Anatomy of one critique
;;

(hyperdoc:defexample critique-anatomy-example
  "One Critique read structurally, with every part as a real object.

The same objects carry the Inspector's \"Critic relations\" views, so the
structure shown here is the structure you can navigate."
  (let* ((target (critic:car-cdr-critique-example))
         (record (first (critic:target-runs-of target)))
         (rule (critic:rule-of record))
         (finding (first (critic:critiques-of record))))
    (append
     (list :kind :critique-anatomy
           :engine-available-p (and finding t)
           :target target
           :program-form (critic:target-form-of target)
           :evaluation-record record
           :evaluation-status (er:evaluation-status-of record)
           :inspector-entry-point
           '(dreyeck/lisp-critic:car-cdr-critique-example))
     (if finding
         (list :critic-rule rule
               :critique finding
               :match-evidence (critic:critique-evidence-of finding)
               :explanation (critic:critique-explanation-of finding)
               :source-provenance (critic:rule-source-of rule)
               :evidence-status :executable)
         ;; Without the engine there is a record and a condition, and
         ;; honestly nothing else. The parts are named as absent rather
         ;; than described from memory.
         (list :critic-rule nil :critique nil
               :match-evidence nil :explanation nil :source-provenance nil
               :why (er:evaluation-failure-of record)
               :evidence-status (runtime-evidence-status))))))

;;
;; Comparing the three models of criticism
;;

(hyperdoc:defexample critic-dimension-comparison-example
  "The same questions asked of each station.

This is a distinction aid, not a ranking. Where a cell says :DOCUMENTED the
answer comes from a paper; where it says :SOURCE or :OBJECT it comes from
code that is present here."
  (list :kind :dimension-comparison
        :dimensions
        '((:dimension :rule-representation
           :fischer :documented
           :riesbeck :source
           :hyperdoc :source)
          (:dimension :target
           :fischer :documented
           :riesbeck :source
           :hyperdoc :object-relation)
          (:dimension :invocation
           :fischer :documented
           :riesbeck :executable-example
           :hyperdoc :evaluation-record)
          (:dimension :result
           :fischer "critique / proposed transformation, per paper"
           :riesbeck "critic output"
           :hyperdoc "first-class Critique object")
          (:dimension :explanation
           :fischer "reported by the paper"
           :riesbeck "response template"
           :hyperdoc "explicit relation on the Critique")
          (:dimension :response
           :fischer "accept / reject / explain, per paper"
           :riesbeck :not-evidenced
           :hyperdoc :not-implemented)
          (:dimension :user-model
           :fischer "reported by the paper"
           :riesbeck :not-evidenced
           :hyperdoc :not-implemented)
          (:dimension :provenance
           :fischer :paper
           :riesbeck :source-station
           :hyperdoc :repository))
        :note "A :DOCUMENTED cell and a :SOURCE cell are not the same kind of claim."
        :evidence-status :interpreted))

;;
;; The book
;;

(dreyeck/hyperdoc:defhyperdoc *lisp-critic-reading*
  :id "dreyeck/lisp-critic/reading"
  :title "Reading the Lisp Critic"
  :asdf-system-name "dreyeck/lisp-critic/reading"
  :subdirectory "dreyeck/pages/lisp-critic"
  :main-page-id "Reading the Lisp Critic Genealogy")
