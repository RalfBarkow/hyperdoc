;;;; Inspector views of the upstream assessment, and the chain of one change as a Topicmap workspace:
;;;;   Upstream Commit -> Changed Definition -> Current Definition -> ASDF Owner -> Impact -> Decision -> Required Migration -> Verification
;;;; Every link carries the epistemic status of what supports it. The views offer no control: reading an assessment changes nothing.

(in-package #:dreyeck/inspector/upstream-assessment)

(defun claim-status-label (status)
  (ecase status
    (:source-observed "observed in the source")
    (:mechanically-derived "mechanically derived")
    (:design-inference "design inference")
    (:working-hypothesis "working hypothesis")))

(defun short-sha (sha) (and sha (subseq sha 0 (min 9 (length sha)))))

(defparameter +upstream-web-url+ "https://codeberg.org/khinsen/hyperdoc/commit/")

(defmethod v:text-representation ((run ua:intake-run))
  (format nil "Upstream intake: ~(~A~), ~D commit~:P" (ua:intake-run-status run) (length (ua:intake-run-commits run))))
(defmethod v:text-representation ((assessment ua:commit-assessment))
  (let ((evidence (ua:commit-assessment-evidence assessment)))
    (format nil "Upstream commit ~A: ~A" (short-sha (ua:commit-evidence-sha evidence)) (or (ua:commit-evidence-subject evidence) "no evidence"))))
(defmethod v:text-representation ((change ua:change-assessment))
  (let ((c (ua:change-assessment-change change)))
    (format nil "~(~A~) ~A" (ua:definition-change-kind c) (ua:definition-change-key c))))
(defmethod v:text-representation ((decision ua:decision))
  (format nil "~(~A~) (~(~A~))" (ua:decision-kind decision) (ua:decision-status decision)))
(defmethod v:text-representation ((claim ua:claim)) (format nil "~A: ~A" (claim-status-label (ua:claim-status claim)) (ua:claim-text claim)))

(defun system-ref (name)
  "An Inspector reference to the ASDF system NAME when this image defines it, else its name as code."
  (let ((system (ignore-errors (asdf:find-system name nil))))
    (if system (v:html (v:object-ref system :display name)) (v:html (:code (v:esc name))))))

(defun render-claims (claims)
  (v:html
    (:ul :class "assessment-claims"
      (dolist (claim claims)
        (v:html (:li (:strong (v:esc (claim-status-label (ua:claim-status claim)))) ": " (v:esc (ua:claim-text claim))
                     (when (ua:claim-basis claim) (v:html " " (:small (v:esc (format nil "(~{~A~^; ~})" (ua:claim-basis claim))))))))))))

(defun fact-row (label value) (v:html (:tr (:th :style "text-align:left;vertical-align:top;" (v:esc label)) (:td (v:esc (princ-to-string value))))))

;;; The run

(v:defview intake-run-view (run ua:intake-run)
  (v:html-view :title "Upstream intake run" :priority 1
    (let ((observation (ua:intake-run-observation run)))
      (v:html
        (:h2 "Upstream intake")
        (:table :class "inspector-table"
          (fact-row "Last examined (recorded by a person)" (or (short-sha (ua:intake-run-last-examined run)) "none"))
          (fact-row "Observed upstream tip" (if observation (format nil "~A = ~A" (ua:upstream-observation-ref observation) (or (short-sha (ua:upstream-observation-tip observation)) "not found")) "no upstream repository given"))
          (fact-row "Status" (string-downcase (symbol-name (ua:intake-run-status run)))))
        (:p "Observation does not integrate: it fetches nothing, loads no library source and records no decision.")
        (:h3 "Commits to assess, oldest first")
        (:table :class "inspector-table"
          (:tr (:th "Commit") (:th "Evidence") (:th "Fork Git") (:th "Source adoption") (:th "Changes"))
          (dolist (assessment (ua:intake-run-commits run))
            (let ((evidence (ua:commit-assessment-evidence assessment)) (integration (ua:commit-assessment-integration assessment)))
              (v:html (:tr (:td (v:object-ref assessment :display (short-sha (ua:commit-evidence-sha evidence))) " " (v:esc (or (ua:commit-evidence-subject evidence) "")))
                           (:td (v:esc (string-downcase (symbol-name (ua:commit-evidence-availability evidence)))))
                           (:td (v:esc (string-downcase (princ-to-string (getf integration :classification)))))
                           (:td (v:esc (string-downcase (symbol-name (ua:commit-assessment-source-adoption assessment)))))
                           (:td (v:esc (princ-to-string (length (ua:commit-assessment-changes assessment))))))))))))))

;;; One commit

(v:defview commit-assessment-view (assessment ua:commit-assessment)
  (v:html-view :title "Upstream commit" :priority 1
    (let* ((evidence (ua:commit-assessment-evidence assessment)) (integration (ua:commit-assessment-integration assessment)) (sha (ua:commit-evidence-sha evidence)))
      (v:html
        (:h2 (v:esc (format nil "~A ~A" (short-sha sha) (or (ua:commit-evidence-subject evidence) "(no evidence)"))))
        (:table :class "inspector-table"
          (fact-row "Commit" sha) (fact-row "Authored" (or (ua:commit-evidence-authored-at evidence) "unknown"))
          (fact-row "Parents" (format nil "~{~A~^ ~}" (mapcar #'short-sha (ua:commit-evidence-parents evidence))))
          (fact-row "Upstream page" (concatenate 'string +upstream-web-url+ sha))
          (fact-row "Evidence" (format nil "~(~A~)" (ua:commit-evidence-availability evidence)))
          (fact-row "Objects in the fork's Git" (getf integration :object-present-p))
          (fact-row "Ancestor of the fork's HEAD" (getf integration :ancestor-of-head-p))
          (fact-row "Classification by the fork's Git" (string-downcase (princ-to-string (getf integration :classification))))
          (fact-row "Source adoption" (string-downcase (symbol-name (ua:commit-assessment-source-adoption assessment)))))
        (:p "Git ancestry and source adoption are different relations: a commit's definitions can stand in the fork's source while the commit is in no history of the fork, and the reverse.")
        (render-claims (ua:commit-assessment-notes assessment))
        (:h3 "Changed definitions")
        (if (ua:commit-assessment-changes assessment)
            (v:html
              (:table :class "inspector-table"
                (:tr (:th "Change") (:th "Path") (:th "In the fork") (:th "Owner now") (:th "Proposal") (:th "Recorded"))
                (dolist (change (ua:commit-assessment-changes assessment))
                  (let ((c (ua:change-assessment-change change)))
                    (v:html (:tr (:td (v:object-ref change :display (format nil "~(~A~) ~A" (ua:definition-change-kind c) (ua:definition-change-key c))))
                                 (:td (:code (v:esc (ua:definition-change-path c))))
                                 (:td (v:esc (string-downcase (symbol-name (ua:fork-situation-relation (ua:change-assessment-situation change))))))
                                 (:td (v:esc (format nil "~{~A~^, ~}" (ua:change-assessment-owners change))))
                                 (:td (v:object-ref (ua:change-assessment-proposal change) :display (v:text-representation (ua:change-assessment-proposal change))))
                                 (:td (if (ua:change-assessment-recorded change)
                                          (dolist (d (ua:change-assessment-recorded change)) (v:html (v:object-ref d :display (v:text-representation d)) " "))
                                          (v:html "none"))))))))) 
            (v:html (:p "No Lisp or ASDF definition changed.")))))))

;;; One changed definition

(defun fragment-pre (tree) (v:html (:pre (v:esc (ua:tree-text tree)))))

(v:defview change-assessment-view (change ua:change-assessment)
  (v:html-view :title "Change in the fork" :priority 1
    (let* ((c (ua:change-assessment-change change)) (s (ua:change-assessment-situation change)) (o (ua:change-assessment-ownership change))
           (i (ua:change-assessment-impact change)) (before (ua:definition-change-before c)) (after (ua:definition-change-after c)))
      (v:html
        (:h2 (v:esc (v:text-representation change)))
        (:p (:code (v:esc (ua:definition-change-path c))))
        (:h3 "1. What upstream changed")
        (dolist (pair (ua:definition-change-fragments c))
          (v:html (:p "Before:") (fragment-pre (car pair)) (:p "After:") (fragment-pre (cdr pair))))
        (when (ua:definition-change-handlers c)
          (v:html
            (:p "Handler forms of the definition, in order (derived from the syntax of the two texts):")
            (:table :class "inspector-table"
              (:tr (:th "#") (:th "Protects calls to") (:th "Clause types after") (:th "Changed"))
              (dolist (h (ua:definition-change-handlers c))
                (let ((shown (or (getf h :after) (getf h :before))))
                  (v:html (:tr (:td (v:esc (princ-to-string (getf h :index))))
                               (:td (v:esc (format nil "~{~A~^, ~}" (getf shown :protected-calls))))
                               (:td (v:esc (format nil "~{~A~^, ~}" (getf shown :clauses))))
                               (:td (:strong (v:esc (if (getf h :changed-p) "yes" "no")))))))))))
        (:h3 "2. Where it stands in the fork now")
        (:p (v:esc (format nil "Relation: ~(~A~)." (ua:fork-situation-relation s))))
        (:ul (dolist (l (ua:fork-situation-locations s)) (v:html (:li (:code (v:esc (format nil "~A  ~A" (first l) (second l))))))))
        (dolist (f (ua:fork-situation-fragments s))
          (v:html (:p (v:esc (format nil "The changed part is ~(~A~)~@[ in ~{~A~^, ~}~]." (getf f :status) (mapcar #'second (getf f :elsewhere)))))))
        (render-claims (ua:fork-situation-claims s))
        (:h3 "3. ASDF owner now, and who should own it")
        (:p "Now: " (dolist (name (ua:change-assessment-owners change)) (v:html (system-ref name) " ")))
        (:p (v:esc (format nil "Category: ~(~A~)." (getf o :category))) " Should own: "
            (let ((should (getf o :should-own))) (dolist (name (if (listp should) should (list should))) (v:html (system-ref (princ-to-string name)) " "))))
        (render-claims (list (getf o :claim)))
        (:h3 "4. What may be affected")
        (:p (v:esc (format nil "~D systems own or depend on it; ~D of them are tests." (length (ua:impact-systems i)) (length (ua:impact-tests i)))))
        (:p "Tests: " (dolist (name (ua:impact-tests i)) (v:html (system-ref name) " ")))
        (:p (v:esc "Definitions that mention the name: ") (dolist (m (ua:impact-callers i)) (v:html (:code (v:esc (format nil "~A ~A" (first m) (second m)))) (:br))))
        (:p (v:esc (format nil "HyperDoc pages that mention it: ~{~A~^, ~}." (ua:impact-pages i))))
        (:p (v:esc (format nil "Contract files that name it: ~:[none~;~:*~{~A~^, ~}~]." (mapcar #'first (ua:impact-contracts i)))))
        (render-claims (ua:impact-claims i))
        (:h3 "5. Decision")
        (:p (v:esc "Proposed by rule: ") (v:object-ref (ua:change-assessment-proposal change) :display (v:text-representation (ua:change-assessment-proposal change))))
        (:p (v:esc "Recorded: ") (if (ua:change-assessment-recorded change)
                                     (dolist (d (ua:change-assessment-recorded change)) (v:html (v:object-ref d :display (v:text-representation d)) " "))
                                     (v:html "none")))
        (:p (v:object-ref (change-chain-workspace change) :display "The chain as a Topicmap"))
        (when (and before after) (v:html (:h3 "Source (before / after)") (:pre (v:esc (ua:source-definition-text before))) (:pre (v:esc (ua:source-definition-text after)))))))))

;;; A decision

(v:defview decision-view (decision ua:decision)
  (v:html-view :title "Decision" :priority 1
    (v:html
      (:h2 (v:esc (v:text-representation decision)))
      (:table :class "inspector-table"
        (fact-row "Commit" (ua:decision-commit decision)) (fact-row "Subject" (ua:decision-subject decision))
        (fact-row "Kind" (string-downcase (symbol-name (ua:decision-kind decision)))) (fact-row "Status" (string-downcase (symbol-name (ua:decision-status decision))))
        (fact-row "Proposed by" (ua:decision-proposed-by decision)))
      (:p "A decision is not its execution: a proposal changes nothing, and only a person accepts it.")
      (:h3 "Rationale") (:p (v:esc (ua:decision-rationale decision)))
      (:h3 "Evidence") (render-claims (ua:decision-evidence decision))
      (:h3 "Required migration") (:p (v:esc (or (ua:decision-required-migration decision) "none")))
      (:h3 "Verification") (:ul (dolist (item (ua:decision-verification decision)) (v:html (:li (v:esc item))))))))

(v:defview claim-view (claim ua:claim)
  (v:html-view :title "Claim" :priority 1 (v:html (:h2 (v:esc (claim-status-label (ua:claim-status claim)))) (:p (v:esc (ua:claim-text claim))) (render-claims (list claim)))))

;;; The chain as a Topicmap workspace

(defstruct chain-step id label object)

(defun chain-steps (change)
  "The eight steps for one changed definition, each with the object the Inspector opens for it."
  (let* ((c (ua:change-assessment-change change)) (d (or (first (ua:change-assessment-recorded change)) (ua:change-assessment-proposal change)))
         (owners (ua:change-assessment-owners change)) (s (ua:change-assessment-situation change)))
    (list (make-chain-step :id "chain:commit" :label "Upstream commit" :object (or (ua:change-assessment-commit change) change))
          (make-chain-step :id "chain:definition" :label (format nil "Changed definition ~A" (ua:definition-change-key c)) :object c)
          (make-chain-step :id "chain:current" :label (format nil "Current definition: ~(~A~)" (ua:fork-situation-relation s)) :object s)
          (make-chain-step :id "chain:owner" :label (format nil "ASDF owner ~{~A~^, ~}" owners)
                           :object (or (some (lambda (n) (ignore-errors (asdf:find-system n nil))) owners) (ua:make-claim (format nil "ASDF owner: ~{~A~^, ~}" owners) :mechanically-derived (list "ASDF definitions"))))
          (make-chain-step :id "chain:impact" :label (format nil "Impact: ~D systems" (length (ua:impact-systems (ua:change-assessment-impact change)))) :object (ua:change-assessment-impact change))
          (make-chain-step :id "chain:decision" :label (format nil "Decision: ~(~A~)" (ua:decision-kind d)) :object d)
          (make-chain-step :id "chain:migration" :label "Required migration"
                           :object (ua:make-claim (or (ua:decision-required-migration d) "none recorded") :design-inference (list "the decision")))
          (make-chain-step :id "chain:verification" :label "Verification"
                           :object (ua:make-claim (format nil "~{~A~^; ~}" (or (ua:decision-verification d) '("none recorded"))) :design-inference (list "the decision"))))))

(defun change-chain-workspace (change)
  "A Topicmap workspace for the chain of CHANGE. The links are named for what supports them, with the existing epistemic statuses."
  (let* ((steps (chain-steps change))
         (topics (loop for step in steps for index from 0
                       collect (tm:make-topicmap-topic :id (chain-step-id step) :type :upstream-assessment-step :label (chain-step-label step) :object (chain-step-object step)
                                                       :view-properties (list :x (+ 100 (* 190 (mod index 4))) :y (+ 110 (* 150 (floor index 4))) :visible t))))
         (links '((:source-observed "The commit's own text, from Git objects or recorded evidence.")
                  (:mechanically-derived "Digests of canonical source trees, compared.")
                  (:mechanically-derived "The ASDF definitions list the file; no component was loaded.")
                  (:mechanically-derived "Search over the fork's source and the ASDF DEPENDS-ON lists.")
                  (:design-inference "A decision weighs the impact; a proposal is not an execution.")
                  (:design-inference "The decision names what must be migrated.")
                  (:design-inference "The decision names how the migration is verified.")))
         (associations (loop for (from to) on steps for (status warrant) in links while to
                             collect (tm:make-topicmap-association :id (format nil "~A->~A" (chain-step-id from) (chain-step-id to)) :type :supports
                                                                   :from (chain-step-id from) :to (chain-step-id to)
                                                                   :properties (list :presentation :relation :epistemic-status status :warrant warrant))))
         (projection (tm:make-topicmap-projection :source change :topics topics :associations associations)))
    (tm:make-topicmap-workspace projection "chain:definition")))
