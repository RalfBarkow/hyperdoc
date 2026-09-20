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
           #:lisp-critic-genealogy-projection
           #:lisp-critic-genealogy-discourse
           #:lisp-critic-discourse-example
           #:current-critique-example
           #:genealogy-stations-example
           #:genealogy-in-this-runtime
           #:engine-available-p
           #:lisp-critic-station
           #:evidence-ladder-example
           #:lisp-critic-genealogy-example
           #:historical-claims
           #:claims-about
           #:source-passages
           #:source-passage-for
           #:claim-for-source-passage
           #:claims-for-source-passage
           #:passage-covers-p
           #:resolve-executability
           #:evidence-adequate-for-p
           #:claim-carried-p
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
;;   SUBJECT               what the claim is about
;;   CLAIM-TYPE            what kind of thing is being claimed
;;   ASSERTION             the sentence itself
;;   CITED-SOURCE-KIND     what source is supposed to carry it
;;   LOCATOR               where that source is, to re-check it
;;   LOCATOR-OBSERVED-P    whether that exact source was read here
;;   OBSERVED-EVIDENCE-KIND what actually carries it in this workspace
;;   OBSERVED-LOCATOR      where that observed evidence is
;;   WITNESS               who stands behind the cited source
;;   SOURCE-OBSERVED-P     whether the artifact described is present
;;   EXECUTABLE-HERE-P     whether that artifact can run in this runtime
;;
;; Citing a source is not reading it. A claim may name a paper as the thing
;; that should settle it while nothing in this workspace has yet settled
;; anything: then OBSERVED-EVIDENCE-KIND is :NONE-OBSERVED and the claim is
;; shown as uncarried rather than as proven. Promoting it is the job of a
;; later slice that actually reads the paper.
;;
;; The three access questions stay independent. Riesbeck's engine is source
;; observed and still not executable on a server without the station.
;;

(defparameter +evidence-adequacy+
  '((:capability     :primary-paper :secondary-research-note :source-file)
    (:contribution   :primary-paper)
    (:environment    :primary-paper)
    (:identity       :primary-paper :secondary-research-note :source-file
                     :readme)
    (:descent        :source-file :readme)
    (:provenance-gap :absence-of-reference))
  "Which kind of observed evidence can carry which kind of claim.

Evidence has no standing on its own: a source file settles what a program
does and says nothing about whether a 1987 system had a user model, and a
paper about that system settles nothing about who edited a file in 2003.
Strength is a relation between evidence and claim, so it is written down as
one.

:ABSENCE-OF-REFERENCE deliberately carries only :PROVENANCE-GAP. Finding no
attribution in a file is a fact about the search, not about descent: it
neither establishes a lineage nor rules one out, and letting it settle
:DESCENT either way would be an argument from silence.")

(defun evidence-adequate-for-p (evidence-kind claim-type)
  (let ((row (assoc claim-type +evidence-adequacy+)))
    (and row (member evidence-kind (rest row)) t)))

(defun claim-carried-p (claim)
  "Whether something actually read here carries this claim right now.

A claim whose OBSERVED-EVIDENCE-KIND is :NONE-OBSERVED is not carried. It
still names the source that should carry it, so a later slice can read that
source and promote it."
  (let ((observed (getf claim :observed-evidence-kind)))
    (and (not (eq :none-observed observed))
         (evidence-adequate-for-p observed (getf claim :claim-type)))))

(defun historical-claims ()
  "Every historical sentence this reading shows, with its provenance.

Claims carried only by conversation are not listed here; they are listed
as absent by FISCHER-CLAIMS-WITHOUT-LOCAL-EVIDENCE."
  (copy-tree
   '(;; The Fischer line. The papers are the sources these claims cite.
     ;; Neither paper has been read in this workspace, so only the first
     ;; claim is currently carried by something actually observed here.
     (:subject :fischer-1987
      :claim-type :capability
      :assertion
      "LISP-CRITIC was an integrated environment: rules, a rule interpreter, a user model, explanation with a knowledge browser and visualization support, and learning on demand."
      :cited-source-kind :primary-paper
      :locator "Fischer 1987, A Critic for LISP, IJCAI-87, pp. 177-184"
      :locator-observed-p nil
      :observed-evidence-kind :secondary-research-note
      :observed-locator "~/.wiki/wiki.ralfbarkow.ch/pages/a-critic-for-lisp"
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :fischer-1987
      :id :boecker-contribution
      :claim-type :contribution
      :assertion
      "Boecker developed many of the original ideas, the original set of rules and the rule interpreter. He is credited as a contributor, not as a co-author."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378, Acknowledgments"
      :locator-observed-p t
      :observed-evidence-kind :primary-paper
      :observed-locator "Fischer & Mastaglio 1991, Acknowledgments"
      :witness (:author-self-report :acknowledgement)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :fischer-1987
      :claim-type :contribution
      :assertion
      "Morel implemented the explanation capabilities; Burns implemented the statistical analysis."
      :cited-source-kind :primary-paper
      :locator "Fischer 1987, A Critic for LISP, IJCAI-87, acknowledgements"
      :locator-observed-p nil
      :observed-evidence-kind :none-observed
      :observed-locator nil
      :witness (:author-self-report :acknowledgement)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-version-1
      :id :version-1-contribution
      :claim-type :contribution
      :assertion
      "Morel, Burns, and Cormack contributed to version 1 of LISP-CRITIC."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, A conceptual framework for knowledge-based critic systems, Decision Support Systems 7(4), 355-378, Acknowledgments"
      :locator-observed-p t
      :observed-evidence-kind :primary-paper
      :observed-locator "Fischer & Mastaglio 1991, Acknowledgments"
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-version-2
      :id :version-2-contribution
      :claim-type :contribution
      :assertion "Rieman, Johl, and Lynn worked on version 2 of LISP-CRITIC."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378, Acknowledgments"
      :locator-observed-p t
      :observed-evidence-kind :primary-paper
      :observed-locator "Fischer & Mastaglio 1991, Acknowledgments"
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-version-2
      :claim-type :environment
      :assertion
      "Version 2 ran on a Symbolics 3600 under Genera, with the knowledge base updated to Common Lisp."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :observed-evidence-kind :none-observed
      :observed-locator nil
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-later
      :claim-type :environment
      :assertion
      "The conceptual knowledge structure was object-oriented, implemented with the Common Lisp Object System."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :observed-evidence-kind :none-observed
      :observed-locator nil
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-later
      :claim-type :capability
      :assertion
      "The refined user model drew on code analysis, explanation requests, and proposals the programmer had rejected."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :observed-evidence-kind :none-observed
      :observed-locator nil
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :lisp-critic-zmacs
      :claim-type :capability
      :assertion
      "The ZMACS-based version offered an interaction cycle of accept, reject, or request explanation."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378"
      :locator-observed-p nil
      :observed-evidence-kind :none-observed
      :observed-locator nil
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     (:subject :critiquing-paradigm
      :claim-type :identity
      :assertion
      "The work was generalised from one Lisp critic into a conceptual framework for knowledge-based critic systems."
      :cited-source-kind :primary-paper
      :locator
      "Fischer & Mastaglio 1991, Decision Support Systems 7(4), 355-378, title and framing"
      :locator-observed-p nil
      :observed-evidence-kind :none-observed
      :observed-locator nil
      :witness (:author-self-report :peer-reviewed-publication)
      :source-observed-p nil
      :executable-here-p nil)

     ;; The Riesbeck line. Here the cited source and the observed evidence
     ;; are the same file, because the file is in the workspace.
     (:subject :riesbeck-engine
      :claim-type :identity
      :assertion
      "The engine carries a dated update history running from 1997 to 2003, each entry initialled CKR."
      :cited-source-kind :source-file
      :locator "vendor/lisp-critic/lisp-critic.lisp, update-history header"
      :locator-observed-p t
      :observed-evidence-kind :source-file
      :observed-locator "vendor/lisp-critic/lisp-critic.lisp"
      :witness (:author-self-report)
      :source-observed-p t
      :executable-here-p :runtime-dependent)

     (:subject :riesbeck-2003-change
      :claim-type :descent
      :assertion
      "DEFINE-LISP-PATTERN and DEFINE-RESPONSE were merged on 1/3/03."
      :cited-source-kind :source-file
      :locator "vendor/lisp-critic/lisp-critic.lisp, update-history header"
      :locator-observed-p t
      :observed-evidence-kind :source-file
      :observed-locator "vendor/lisp-critic/lisp-critic.lisp"
      :witness (:author-self-report)
      :source-observed-p t
      :executable-here-p :runtime-dependent)

     (:subject :beane-2004-adaptation
      :claim-type :descent
      :assertion
      "On 2004-05-06 require/provide statements were removed, cs235 package references were replaced by lisp-critic-user, and an ASDF defsystem file was added."
      :cited-source-kind :readme
      :locator "vendor/lisp-critic/README"
      :locator-observed-p t
      :observed-evidence-kind :readme
      :observed-locator "vendor/lisp-critic/README"
      :witness (:adapter-self-report)
      :source-observed-p t
      :executable-here-p :runtime-dependent)

     ;; A fact about a search, not a verdict on lineage. It records that no
     ;; attribution was found; it neither establishes descent nor rules it
     ;; out, which is why its claim-type is :PROVENANCE-GAP.
     (:subject :fischer-to-riesbeck
      :claim-type :provenance-gap
      :assertion
      "No attribution or reference to Fischer, Boecker, Colorado or a critiquing paradigm was found in the inspected vendor source. No source-provenance link has been observed in either direction."
      :cited-source-kind :source-file
      :locator "vendor/lisp-critic/, full-text search"
      :locator-observed-p t
      :observed-evidence-kind :absence-of-reference
      :observed-locator "vendor/lisp-critic/"
      :witness (:local-observation)
      :source-observed-p t
      :executable-here-p :runtime-dependent))))

;;
;; Two complementary projections of the same material.
;;
;; The genealogy shows objects and their lineage. The discourse shows the
;; questions the comparison raises. Both are ordinary Topicmap projections,
;; so they get the existing native view, navigation and legend, and neither
;; needs a graph engine of its own.
;;
;; A topic carries the real plist as its OBJECT, so following a station in
;; the Topicmap reaches the same data the claim views already render.
;;

(defun claims-about-subjects (&rest subjects)
  (remove-if-not (lambda (claim) (member (getf claim :subject) subjects))
                 (historical-claims)))

(defun genealogy-station-topic (key x y)
  (let ((station (lisp-critic-station key)))
    (dreyeck/topicmap:make-topicmap-topic
     :id (string-downcase (symbol-name key))
     :type :station
     :label (getf station :name)
     :object station
     :view-properties (list :x x :y y :visible t :pinned nil))))

(defun genealogy-stage-topic (id label subjects x y)
  "A documented stage of the research line, carrying the claims about it.

These stages are not separate stations: nothing in this workspace holds an
artifact for them. Their object is the set of claims that mention them, so
following one reaches the evidence rather than an invented record."
  (dreyeck/topicmap:make-topicmap-topic
   :id id :type :documented-stage :label label
   :object (list :kind :documented-stage :label label
                 :subjects subjects
                 :claims (apply #'claims-about-subjects subjects))
   :view-properties (list :x x :y y :visible t :pinned nil)))

(defun lisp-critic-genealogy-projection ()
  "The two histories, side by side, with no edge between them.

The left column is documented research; the right column is code that is
present here. The only cross-column association is a conceptual comparison,
and it is typed as such so it cannot be read as lineage."
  (let ((topics
          (list (genealogy-station-topic :fischer-lisp-critic 120 80)
                (genealogy-stage-topic
                 "documented-later-versions" "documented later versions"
                 '(:lisp-critic-version-1 :lisp-critic-version-2
                   :lisp-critic-later :lisp-critic-zmacs)
                 120 240)
                (genealogy-stage-topic
                 "critiquing-paradigm" "broader critiquing paradigm"
                 '(:critiquing-paradigm) 120 400)
                (genealogy-station-topic :riesbeck-lisp-critic 620 80)
                (genealogy-station-topic :beane-asdf-adaptation 620 220)
                (genealogy-station-topic :a-critic-for-lisp-station 620 360)
                (genealogy-station-topic :dreyeck-lisp-critic 620 500)))
        (associations
          (list
           ;; Research line: documented succession only.
           (dreyeck/topicmap:make-topicmap-association
            :id "research-1" :type :documented-successor
            :from "fischer-lisp-critic" :to "documented-later-versions")
           (dreyeck/topicmap:make-topicmap-association
            :id "research-2" :type :documented-successor
            :from "documented-later-versions" :to "critiquing-paradigm")
           ;; Code line: what the source itself records.
           (dreyeck/topicmap:make-topicmap-association
            :id "code-1" :type :port/adaptation
            :from "riesbeck-lisp-critic" :to "beane-asdf-adaptation")
           (dreyeck/topicmap:make-topicmap-association
            :id "code-2" :type :local-extraction
            :from "beane-asdf-adaptation" :to "a-critic-for-lisp-station")
           (dreyeck/topicmap:make-topicmap-association
            :id "code-3" :type :hyperdoc-projection
            :from "a-critic-for-lisp-station" :to "dreyeck-lisp-critic")
           ;; The one edge across the columns. Not a genealogy edge.
           (dreyeck/topicmap:make-topicmap-association
            :id "comparison" :type :conceptual-comparison
            :from "fischer-lisp-critic" :to "riesbeck-lisp-critic"
            :properties '(:note "compared, not descended; no source lineage established")))))
    (dreyeck/topicmap:make-topicmap-projection
     :source :lisp-critic-genealogy
     :topics topics :associations associations
     :view-properties '(:width 1000 :height 620))))

;;
;; The discourse: only the questions the comparison actually raises.
;;

(defun discourse-claim-object (statement support related)
  (list :kind :discourse-claim :statement statement :support support
        :related-claims (apply #'claims-about-subjects related)))

(defun lisp-critic-genealogy-discourse ()
  "The few questions this comparison raises, with their claims and support.

Deliberately small. The full provenance record stays in the claim views;
this projection carries only what a reader would actually ask."
  (flet ((question (id label x y)
           (dreyeck/topicmap:make-topicmap-topic
            :id id :type :question :label label
            :object (list :kind :discourse-question :question label)
            :view-properties (list :x x :y y :visible t :pinned nil)))
         (claim (id label object x y)
           (dreyeck/topicmap:make-topicmap-topic
            :id id :type :claim :label label :object object
            :view-properties (list :x x :y y :visible t :pinned nil)))
         (source (id label x y)
           (dreyeck/topicmap:make-topicmap-topic
            :id id :type :source :label label
            :object (list :kind :discourse-source :source label)
            :view-properties (list :x x :y y :visible t :pinned nil))))
    (dreyeck/topicmap:make-topicmap-projection
     :source :lisp-critic-discourse
     :topics
     (list
      (question "q-linter" "Was Fischer's Lisp Critic essentially a linter?"
                80 80)
      (claim "c-linter" "No: an integrated environment"
             (discourse-claim-object
              "No. It was described as an integrated environment for criticism, explanation, learning and user modelling."
              "Fischer 1987" '(:fischer-1987))
             480 80)
      (source "s-linter" "Fischer 1987" 880 80)

      (question "q-descent" "Does Riesbeck's lisp-critic descend from Fischer's?"
                80 240)
      (claim "c-descent" "No source lineage has been established"
             (discourse-claim-object
              "No source lineage has been established, in either direction."
              "No provenance statement observed in the inspected code line."
              '(:fischer-to-riesbeck))
             480 240)
      (source "s-descent" "Inspected vendor source: no attribution found"
              880 240)

      (question "q-hyperdoc" "What does HyperDoc add?" 80 400)
      (claim "c-hyperdoc" "It separates execution from critique"
             (discourse-claim-object
              "It separates a critic execution from the resulting Critique and makes both inspectable."
              "Current repository implementation and tests."
              '(:riesbeck-engine))
             480 400)
      (source "s-hyperdoc" "Repository implementation and tests" 880 400))
     :associations
     (list
      (dreyeck/topicmap:make-topicmap-association
       :id "a-linter" :type :answered-by :from "q-linter" :to "c-linter")
      (dreyeck/topicmap:make-topicmap-association
       :id "s-linter-edge" :type :supported-by
       :from "c-linter" :to "s-linter")
      (dreyeck/topicmap:make-topicmap-association
       :id "a-descent" :type :answered-by :from "q-descent" :to "c-descent")
      (dreyeck/topicmap:make-topicmap-association
       :id "s-descent-edge" :type :supported-by
       :from "c-descent" :to "s-descent")
      (dreyeck/topicmap:make-topicmap-association
       :id "a-hyperdoc" :type :answered-by
       :from "q-hyperdoc" :to "c-hyperdoc")
      (dreyeck/topicmap:make-topicmap-association
       :id "s-hyperdoc-edge" :type :supported-by
       :from "c-hyperdoc" :to "s-hyperdoc"))
     :view-properties '(:width 1200 :height 520))))

;;
;; From a claim to the passage that is supposed to support it.
;;
;; A locator says where a statement should be checked. That is not yet
;; useful: the reader still has to leave the reading to check it. A passage
;; record carries the wording itself, so the claim can be compared against
;; it — and, as the first one here shows, corrected against it.
;;
;; Deliberately not a citation model. One passage, for one claim, keyed by
;; the claim it supports. The next one is added when a reader needs it.
;;

(defun source-passages ()
  "Passages recorded for individual claims.

PASSAGE-OBSERVED-P is the same question the claims already ask of their
locators: was this text read in this workspace? For the entry below it now
was — the paper was placed in the workspace and its acknowledgments read —
so the claims this passage covers are promoted with it.

Reading it immediately earned its keep: two claims were worded more
strongly than the paper. The paper says Morel, Burns and Cormack
\"contributed to\" version 1 and that Rieman, Johl and Lynn \"worked on\"
version 2; both had been recorded as \"credited to\"."
  (copy-tree
   '((:kind :source-passage
      :id :mastaglio-1991-acknowledgments
      :supports-claims (:version-1-contribution :version-2-contribution
                        :boecker-contribution)
      :source "Fischer & Mastaglio 1991"
      :title "A conceptual framework for knowledge-based critic systems"
      :bibliographic "Decision Support Systems 7(4), 355-378"
      :location "Acknowledgments"
      :supports
      "Morel, Burns, and Cormack contributed to version 1 of LISP-CRITIC."
      :passage
      "The authors would like to thank especially: Heinz-Dieter Boecker, who developed many of the original ideas, the original set of rules and the rule interpreter; Andreas Lemke developed FRAMER; Helga Nieper-Lemke developed KAESTLE; Christopher Morel, Bart Burns, and Catherine Cormack contributed to version 1 of LISP-CRITIC; Anders Morch developed JANUS; John Rieman, Paul Johl, and Patrick Lynn worked on version 2 of LISP-CRITIC; Hal Eden and Brent Reeves for recent work on LISP-CRITIC."
      :passage-observed-p t
      :passage-origin :read-in-this-workspace
      :read-from "Zotero storage M9DJBUDF, PDF text layer"
      :transcription-note
      "Transcribed from the PDF text layer. Obvious OCR damage repaired: the layer reads \"Bart Bums\" for Bart Burns and sets stray full stops after Boecker and Johl."))))

(defun passage-covers-p (passage claim)
  "Whether PASSAGE is the recorded wording behind CLAIM.

One passage can settle several claims — the acknowledgments below name
three contributors in one sentence — so coverage is listed per claim id.
Keying on subject and claim-type instead would be too coarse: two
different claims about Fischer 1987 are both contributions, and only one
of them is in this passage."
  (and (getf claim :id)
       (member (getf claim :id) (getf passage :supports-claims))
       t))

(defun source-passage-for (claim)
  "The passage recorded for CLAIM, if one exists."
  (find-if (lambda (passage) (passage-covers-p passage claim))
           (source-passages)))

(defun claims-for-source-passage (passage)
  "Every claim this passage settles, for navigation back."
  (remove-if-not (lambda (claim) (passage-covers-p passage claim))
                 (historical-claims)))

(defun claim-for-source-passage (passage)
  "The claim a passage was primarily recorded for."
  (first (claims-for-source-passage passage)))

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
  "Inspect the Lisp Critic genealogy."
  (lisp-critic-genealogy-projection))

(hyperdoc:defexample lisp-critic-discourse-example
  "Explore the questions and claims around the genealogy."
  (lisp-critic-genealogy-discourse))

(hyperdoc:defexample current-critique-example
  "Inspect one current HyperDoc Critique."
  (critic:car-cdr-critique-example))

(hyperdoc:defexample genealogy-stations-example
  "The station records behind the genealogy, with their evidence status.

Secondary to the genealogy view: this is the data, not the reading."
  (list :kind :genealogy
        :engine-available-p (engine-available-p)
        :stations (genealogy-in-this-runtime)
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
                                 :cited-source-kind
                                 (getf claim :cited-source-kind)
                                 :observed-evidence-kind
                                 (getf claim :observed-evidence-kind)
                                 :carried-p (claim-carried-p claim)))
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
