;;;; Inspector views of the upstream assessment, and the chain of one change as a Topicmap workspace:
;;;;   Upstream Commit -> Changed Definition -> Current Definition -> ASDF Owner -> Impact -> Decision -> Required Migration -> Verification
;;;; Every link carries the epistemic status of what supports it. The views offer no control: reading an assessment changes nothing.
;;;;
;;;; How the views are set. They are read in two ways. Informing reading is a glance down a pane that may be narrow: one idea per block, headings that
;;;; differ by weight and size, labels in a column of their own, short lines (the measure is limited to about 70 characters), left-aligned and ragged,
;;;; no tables of prose. Consulting reading looks something up and goes on: every definition, system, claim, decision and ownership judgement
;;;; that the text names is an Inspector reference, drawn alike (underlined, in one colour), and no identifier is ever cut off: identifiers wrap
;;;; where they must (OVERFLOW-WRAP) and are never clipped, hidden or put in a nowrap cell.

(in-package #:dreyeck/inspector/upstream-assessment)

(defun claim-status-label (status)
  (ecase status
    (:source-observed "observed in the source")
    (:mechanically-derived "mechanically derived")
    (:design-inference "design inference")
    (:working-hypothesis "working hypothesis")))

(defun short-sha (sha) (and sha (subseq sha 0 (min 9 (length sha)))))

(defparameter +upstream-web-url+ "https://codeberg.org/khinsen/hyperdoc/commit/")

(defparameter +style+
  ".ua{container-type:inline-size;max-width:44rem;line-height:1.5;padding:.25rem .5rem 1.5rem;hyphens:manual}
.ua h2{font-size:1.3em;line-height:1.25;font-weight:600;margin:.2em 0 .6em;overflow-wrap:anywhere}
.ua h3{font-size:1.05em;font-weight:600;margin:1.8em 0 .4em;padding-bottom:.15em;border-bottom:1px solid #cfd4d9}
.ua h4{font-size:1em;font-weight:600;margin:1.1em 0 .25em;overflow-wrap:anywhere}
.ua p{margin:.5em 0;max-width:40rem}
.ua .ua-note{color:#444;font-size:.95em}
.ua dl.ua-facts{display:grid;grid-template-columns:minmax(6rem,10.5rem) minmax(0,1fr);gap:.35rem 1rem;margin:.5em 0}
.ua dl.ua-facts dt{color:#4a4f55;font-size:.88em;font-variant-caps:all-small-caps;letter-spacing:.05em;padding-top:.1em}
.ua dl.ua-facts dd{margin:0;min-width:0}
@container (max-width:32rem){.ua dl.ua-facts{grid-template-columns:minmax(0,1fr)}.ua dl.ua-facts dt{margin-top:.55rem}}
.ua code,.ua .ua-id{font-family:ui-monospace,'DejaVu Sans Mono',Menlo,Consolas,monospace;font-size:.9em;overflow-wrap:anywhere;word-break:normal;white-space:normal}
.ua pre{font-family:ui-monospace,'DejaVu Sans Mono',Menlo,Consolas,monospace;font-size:.88em;line-height:1.4;white-space:pre-wrap;overflow-wrap:anywhere;background:#f5f6f7;border-left:3px solid #b9c0c7;margin:.4em 0;padding:.5rem .75rem}
.ua pre.ua-before{border-left-color:#a33}
.ua pre.ua-after{border-left-color:#287a4b}
.ua .inspector-inspect{color:#0b4f8a;text-decoration:underline;text-decoration-color:#8fb0cc;text-underline-offset:.18em;cursor:pointer;white-space:normal;overflow-wrap:anywhere}
.ua .inspector-inspect:hover{background:#e4edf5}
.ua ul.ua-list{list-style:none;margin:.3em 0;padding:0}
.ua ul.ua-list li{margin:.25em 0;padding-left:1.1em;text-indent:-1.1em}
.ua ul.ua-list li:before{content:'\\2022';display:inline-block;width:1.1em;text-indent:0;color:#8a9199}
.ua .ua-claim{margin:.45em 0;padding:.05em 0 .05em .75rem;border-left:3px solid #b9c0c7;max-width:40rem}
.ua .ua-claim[data-status=source-observed]{border-left-color:#287a4b}
.ua .ua-claim[data-status=mechanically-derived]{border-left-color:#2c5f8a}
.ua .ua-claim[data-status=design-inference]{border-left-color:#946a14}
.ua .ua-claim[data-status=working-hypothesis]{border-left-color:#8a3d3d}
.ua .ua-status{font-size:.85em;font-variant-caps:all-small-caps;letter-spacing:.05em}
.ua .ua-basis{display:block;color:#555;font-size:.85em}
.ua article.ua-change{margin:1rem 0;padding:.4rem .9rem .6rem;border:1px solid #cfd4d9;border-radius:3px}
.ua article.ua-change h4{margin-top:.4em}
.ua .ua-open{border-left:3px solid #946a14;padding-left:.75rem;margin:.5em 0}")

(defmacro fact (label &body body)
  "One labelled fact of a definition list."
  `(progn (v:html (:dt (v:esc ,label))) (v:html (:dd ,@body))))

(defmacro reading (&body body)
  "The body of a view of this reading: its style and one container."
  `(v:html (:style (v:str +style+)) (:div :class "ua" ,@body)))

(defun ref (object label)
  "An Inspector reference to OBJECT, labelled LABEL, drawn as the readings draw every reference. The label may be long: it wraps."
  (v:html (:span :class "ua-id" (v:object-ref object :display label))))

(defun system-ref (name)
  "An Inspector reference to the ASDF system NAME when this image defines it, else its name as code."
  (let ((system (ignore-errors (asdf:find-system name nil))))
    (if system (ref system name) (v:html (:code (v:esc name))))))

(defun system-refs (names)
  (if names
      (v:html (:ul :class "ua-list" (dolist (name names) (v:html (:li (system-ref name))))))
      (v:html (:span :class "ua-note" "no ASDF system lists this file"))))

(defun render-claims (claims)
  (v:html
    (dolist (claim claims)
      (v:html
        (:div :class "ua-claim" :data-status (string-downcase (symbol-name (ua:claim-status claim)))
          (:span :class "ua-status" (v:object-ref claim :display (claim-status-label (ua:claim-status claim))))
          " " (v:esc (ua:claim-text claim))
          (when (ua:claim-basis claim)
            (v:html (:span :class "ua-basis" (v:esc (format nil "Basis: ~{~A~^; ~}" (ua:claim-basis claim)))))))))))

;;; Objects that the assessment is about but that are not structures of its own: a definition seen at a place, and the judgement of its ownership.

(defstruct (located (:constructor %make-located (definition where owners)))
  definition ; a UA:SOURCE-DEFINITION
  where      ; :UPSTREAM-BEFORE, :UPSTREAM-AFTER, :FORK, :FORK-CALLER
  owners)    ; ASDF systems that list the file, for a place in the fork

(defvar *located* (make-hash-table :test 'eq :weakness :key :synchronized t))

(defun located (definition where &optional owners)
  "The one object for DEFINITION seen at WHERE, so that every reference to it in a reading is the same Inspector object."
  (or (cdr (assoc where (gethash definition *located*)))
      (let ((object (%make-located definition where owners)))
        (push (cons where object) (gethash definition *located*))
        object)))

(defun where-label (where)
  (ecase where
    (:upstream-before "upstream, before the commit") (:upstream-after "upstream, after the commit")
    (:fork "this checkout") (:fork-caller "this checkout, mentions the name")))

(defstruct (ownership-judgement (:constructor %make-ownership-judgement (change))) change)

(defvar *judgements* (make-hash-table :test 'eq :weakness :key :synchronized t))

(defun ownership-judgement (change)
  (or (gethash change *judgements*) (setf (gethash change *judgements*) (%make-ownership-judgement change))))

(defun definition-ref (definition where &optional owners)
  (ref (located definition where owners) (ua:source-definition-key definition)))

(defun owners-at (path alist) (cdr (assoc path alist :test #'equal)))

;;; Text representations

(defmethod v:text-representation ((run ua:intake-run))
  (format nil "Upstream intake: ~(~A~), ~D commit~:P" (ua:intake-run-status run) (length (ua:intake-run-commits run))))
(defmethod v:text-representation ((assessment ua:commit-assessment))
  ;; short: the title bar of the Inspector clips what does not fit; the subject is the heading of the view
  (format nil "Upstream commit ~A" (short-sha (ua:commit-evidence-sha (ua:commit-assessment-evidence assessment)))))
(defmethod v:text-representation ((change ua:change-assessment))
  (let ((c (ua:change-assessment-change change)))
    (format nil "~(~A~) ~A" (ua:definition-change-kind c) (ua:definition-change-key c))))
(defmethod v:text-representation ((c ua:definition-change))
  (format nil "Upstream change to ~A" (ua:definition-change-key c)))
(defmethod v:text-representation ((s ua:fork-situation))
  (format nil "In the fork: ~A" (ua:relation-label (ua:fork-situation-relation s))))
(defmethod v:text-representation ((object located))
  (format nil "~A (~A)" (ua:source-definition-key (located-definition object)) (where-label (located-where object))))
(defmethod v:text-representation ((object ownership-judgement))
  (format nil "Ownership of ~A" (ua:definition-change-key (ua:change-assessment-change (ownership-judgement-change object)))))
(defmethod v:text-representation ((decision ua:decision))
  (format nil "~(~A~) (~(~A~))" (ua:decision-kind decision) (ua:decision-status decision)))
(defmethod v:text-representation ((claim ua:claim)) (format nil "~A: ~A" (claim-status-label (ua:claim-status claim)) (ua:claim-text claim)))

;;; The run

(v:defview intake-run-view (run ua:intake-run)
  (v:html-view :title "Upstream intake run" :priority 1
    (let ((observation (ua:intake-run-observation run)))
      (reading
        (:h2 "Upstream intake")
        (:dl :class "ua-facts"
          (fact "Last examined" (v:esc (or (short-sha (ua:intake-run-last-examined run)) "none")) (:span :class "ua-note" " (recorded by a person)"))
          (fact "Observed tip" (v:esc (if observation (format nil "~A = ~A" (ua:upstream-observation-ref observation) (or (short-sha (ua:upstream-observation-tip observation)) "not found")) "no upstream repository given")))
          (fact "Status" (v:esc (string-downcase (symbol-name (ua:intake-run-status run))))))
        (:p :class "ua-note" "Observation does not integrate: it fetches nothing, loads no library source and records no decision.")
        (:h3 "Commits to assess, oldest first")
        (dolist (assessment (ua:intake-run-commits run))
          (let ((evidence (ua:commit-assessment-evidence assessment)) (integration (ua:commit-assessment-integration assessment)))
            (v:html
              (:h4 (v:object-ref assessment :display (format nil "~A ~A" (short-sha (ua:commit-evidence-sha evidence)) (or (ua:commit-evidence-subject evidence) ""))))
              (:dl :class "ua-facts"
                (fact "Evidence" (v:esc (string-downcase (symbol-name (ua:commit-evidence-availability evidence)))))
                (fact "Fork's Git" (v:esc (string-downcase (princ-to-string (getf integration :classification)))))
                (fact "Source adoption" (v:esc (string-downcase (symbol-name (ua:commit-assessment-source-adoption assessment)))))
                (fact "Changed definitions" (v:esc (princ-to-string (length (ua:commit-assessment-changes assessment)))))))))))))

;;; One commit

(defun decision-refs (decisions)
  (if decisions
      (v:html (:ul :class "ua-list" (dolist (d decisions) (v:html (:li (ref d (v:text-representation d)))))))
      (v:html (:span :class "ua-note" "none recorded"))))

(defun fork-definitions-of (change)
  "The definitions of the fork to which CHANGE leads: the ones with its key, or, for a changed part found elsewhere, the ones where that text stands."
  (let* ((s (ua:change-assessment-situation change))
         (elsewhere (remove-duplicates (loop for f in (ua:fork-situation-fragments s) append (getf f :definitions)))))
    (values (ua:fork-situation-definitions s) elsewhere)))

(defun definition-ref-list (definitions owners)
  (v:html
    (:ul :class "ua-list"
      (dolist (d definitions)
        (v:html (:li (definition-ref d :fork (owners-at (ua:source-definition-path d) owners))
                     (:br) (:span :class "ua-note" (:code (v:esc (ua:source-definition-path d))))))))))

(v:defview commit-assessment-view (assessment ua:commit-assessment)
  (v:html-view :title "Upstream commit" :priority 1
    (let* ((evidence (ua:commit-assessment-evidence assessment)) (integration (ua:commit-assessment-integration assessment)) (sha (ua:commit-evidence-sha evidence)))
      (reading
        (:h2 (v:esc (format nil "~A ~A" (short-sha sha) (or (ua:commit-evidence-subject evidence) "(no evidence)"))))
        (:dl :class "ua-facts"
          (fact "Commit" (:code (v:esc sha)))
          (fact "Authored" (v:esc (or (ua:commit-evidence-authored-at evidence) "unknown")))
          (fact "Parent" (:code (v:esc (format nil "~{~A~^ ~}" (mapcar #'short-sha (ua:commit-evidence-parents evidence))))))
          (fact "Upstream page" (:a :href (concatenate 'string +upstream-web-url+ sha) :target "_blank" :class "ua-id" (v:esc (concatenate 'string +upstream-web-url+ sha))))
          (fact "Evidence" (v:esc (format nil "~(~A~)" (ua:commit-evidence-availability evidence))))
          (fact "Objects in the fork's Git" (v:esc (string-downcase (princ-to-string (getf integration :object-present-p)))))
          (fact "Ancestor of the fork's HEAD" (v:esc (string-downcase (princ-to-string (getf integration :ancestor-of-head-p)))))
          (fact "Fork's Git says" (v:esc (string-downcase (princ-to-string (getf integration :classification)))))
          (fact "Source adoption" (v:esc (string-downcase (symbol-name (ua:commit-assessment-source-adoption assessment))))))
        (:p :class "ua-note" "Git ancestry and source adoption are different relations: a commit's definitions can stand in the fork's source while the commit is in no history of the fork, and the reverse.")
        (render-claims (ua:commit-assessment-notes assessment))
        (:h3 (v:esc (format nil "Changed definitions (~D)" (length (ua:commit-assessment-changes assessment)))))
        (if (ua:commit-assessment-changes assessment)
            (dolist (change (ua:commit-assessment-changes assessment))
              (let* ((c (ua:change-assessment-change change)) (s (ua:change-assessment-situation change)))
                (multiple-value-bind (in-fork elsewhere) (fork-definitions-of change)
                  (v:html
                    (:article :class "ua-change"
                      (:h4 (v:object-ref change :display (format nil "~(~A~) ~A" (ua:definition-change-kind c) (ua:definition-change-key c))))
                      (:dl :class "ua-facts"
                        (fact "File" (:code (v:esc (ua:definition-change-path c))))
                        (fact "Upstream change" (ref c (format nil "What ~A changed in ~A" (short-sha sha) (ua:definition-change-key c))))
                        (fact "In the fork" (ref s (ua:relation-label (ua:fork-situation-relation s))))
                        (when in-fork (fact "Same key in the fork" (definition-ref-list in-fork (ua:fork-situation-owners s))))
                        (when (and elsewhere (eq :changed-part-elsewhere (ua:fork-situation-relation s)))
                          (fact "Changed text stands in" (definition-ref-list elsewhere (ua:fork-situation-owners s))))
                        (fact "ASDF system now" (system-refs (ua:change-assessment-owners change)))
                        (fact "Ownership" (ref (ownership-judgement change)
                                               (if (inventory-claim-p (ua:change-assessment-ownership change))
                                                   (format nil "~(~A~), as this checkout's ownership inventory records it" (getf (ua:change-assessment-ownership change) :category))
                                                   (format nil "~(~A~) by the path rule; no decision for this definition" (getf (ua:change-assessment-ownership change) :category)))))
                        (fact "Proposed by rule" (ref (ua:change-assessment-proposal change) (v:text-representation (ua:change-assessment-proposal change))))
                        (fact "Recorded" (decision-refs (ua:change-assessment-recorded change)))))))))
            (v:html (:p "No Lisp or ASDF definition changed.")))))))

;;; One changed definition, in parts that each can be reached on their own

(defun fragment-pre (tree class) (v:html (:pre :class class (v:esc (ua:tree-text tree)))))

(defun render-upstream-change (c)
  (let ((before (ua:definition-change-before c)) (after (ua:definition-change-after c)))
    (v:html
      (:p (:code (v:esc (ua:definition-change-path c))))
      (dolist (pair (ua:definition-change-fragments c))
        (v:html (:p :class "ua-note" "Before (the list as upstream had it):") (fragment-pre (car pair) "ua-before")
                (:p :class "ua-note" "After:") (fragment-pre (cdr pair) "ua-after")))
      (when (ua:definition-change-handlers c)
        (v:html
          (:p "The handler forms of the definition, in order (derived from the syntax of the two texts):")
          (:ul :class "ua-list"
            (dolist (h (ua:definition-change-handlers c))
              (let ((shown (or (getf h :after) (getf h :before))))
                (v:html (:li (:strong (v:esc (format nil "Handler ~D, ~A. " (1+ (getf h :index)) (if (getf h :changed-p) "changed" "unchanged"))))
                             "It protects " (:code (v:esc (format nil "~{~A~^, ~}" (getf shown :protected-calls))))
                             "; its clause types are " (:code (v:esc (format nil "~{~A~^, ~}" (getf shown :clauses)))) ".")))))))
      (when (or before after)
        (v:html (:p "The whole definition: "
                    (when before (v:html (ref (located before :upstream-before) (format nil "~A as upstream had it" (ua:source-definition-key before))) "; "))
                    (when after (v:html (ref (located after :upstream-after) (format nil "~A as upstream has it" (ua:source-definition-key after)))))))))))

(defun fragment-status-sentence (status)
  (ecase status
    (:after-present "The changed text, as upstream has it after the commit, stands in the definition.")
    (:before-present "The changed text, as upstream had it before the commit, stands in the definition.")
    (:before-elsewhere "The changed text stands, as upstream had it before the commit, in")
    (:after-elsewhere "The changed text stands, as upstream has it after the commit, in")
    (:extended-elsewhere "The changed text stands, extended by further types, in")
    (:absent "The changed text stands nowhere in the fork.")))

(defun render-fork-situation (s)
  (v:html
    (:p (:strong (v:esc (ua:relation-label (ua:fork-situation-relation s)))) ".")
    (when (ua:fork-situation-definitions s)
      (v:html (:p "Definitions of the fork with this key:") (definition-ref-list (ua:fork-situation-definitions s) (ua:fork-situation-owners s))))
    (dolist (f (ua:fork-situation-fragments s))
      (v:html (:p (v:esc (fragment-status-sentence (getf f :status))))
              (when (getf f :definitions) (definition-ref-list (getf f :definitions) (ua:fork-situation-owners s)))))
    (render-claims (ua:fork-situation-claims s))
    (dolist (l (ua:fork-situation-counterparts s))
      (v:html (:p :class "ua-note" (v:esc "Possible counterpart (a working hypothesis: it differs in package qualification only, and nothing equates it): ") (:code (v:esc (format nil "~A in ~A" (second l) (first l)))))))
    (:p :class "ua-note" "A match of text is a lead. It does not show that one definition replaces another, or that two definitions behave the same.")))

(defun category-sentence (category)
  (ecase category
    (:upstream-owned "upstream-owned by the path rule: the file is a library path of the upstream contract")
    (:dreyeck-owned "dreyeck-owned by the path rule: the file is not a library path")
    (:reusable-extension "a reusable extension, as the ownership inventory records it")))

(defun inventory-claim-p (ownership)
  "Whether the category comes from an ownership inventory of the checkout (an observation) rather than from the path rule (a derivation)."
  (eq :source-observed (ua:claim-status (getf ownership :claim))))

(defun render-ownership (change)
  (let* ((o (ua:change-assessment-ownership change)) (statements (getf o :statements)) (outside (getf o :outside)) (should (getf o :should-own)))
    (v:html
      (:dl :class "ua-facts"
        (fact "ASDF system now" (system-refs (ua:change-assessment-owners change)))
        (fact "By the path rule" (v:esc (category-sentence (getf o :category))))
        (fact "Which system should own it, by the rule" (system-refs (mapcar #'princ-to-string (if (listp should) should (list should)))))
        (fact "Stated in this checkout" (if statements (v:html (:span :class "ua-note" "see below")) (v:html (:span :class "ua-note" "nothing"))))
        (fact "Proposed elsewhere" (if outside (v:html (:span :class "ua-note" "not in force here; see below")) (v:html (:span :class "ua-note" "nothing recorded"))))
        (fact "Intended owner"
          (cond ((inventory-claim-p o) (v:esc "As the ownership inventory of this checkout records it."))
                ((or statements outside) (v:esc "Not decided for this definition. The path rule is a default, the statement is general, and the proposal is not in force."))
                (t (v:esc "Not recorded.")))))
      (render-claims (list (getf o :claim)))
      (when statements (render-claims statements))
      (when outside (render-claims outside))
      (:p :class "ua-note" "Ownership names who maintains the text and which ASDF system carries it. It is not where the file came from: the fork holds the library and its extensions in one Git repository."))))

(defun render-impact (i)
  (v:html
    (:p (v:esc (format nil "~D systems own or depend on it; ~D of them are tests." (length (ua:impact-systems i)) (length (ua:impact-tests i)))))
    (:h4 "Test systems") (system-refs (ua:impact-tests i))
    (:h4 "Definitions that mention the name")
    (if (ua:impact-callers i)
        (v:html (:ul :class "ua-list"
                  (dolist (m (ua:impact-callers i))
                    (v:html (:li (if (third m) (definition-ref (third m) :fork-caller (owners-at (first m) (ua:impact-caller-owners i))) (v:html (:code (v:esc (second m)))))
                                 (:br) (:span :class "ua-note" (:code (v:esc (first m)))))))))
        (v:html (:p :class "ua-note" "none")))
    (:h4 "HyperDoc pages that mention it")
    (if (ua:impact-pages i)
        (v:html (:ul :class "ua-list" (dolist (p (ua:impact-pages i)) (v:html (:li (:code (v:esc p)))))))
        (v:html (:p :class "ua-note" "none")))
    (:h4 "Contract files that name it")
    (if (ua:impact-contracts i)
        (v:html (:ul :class "ua-list" (dolist (p (ua:impact-contracts i)) (v:html (:li (:code (v:esc (first p))))))))
        (v:html (:p :class "ua-note" "none")))
    (render-claims (ua:impact-claims i))))

(defun render-open-decisions (change)
  "What is still undecided, each with the evidence that the reading has for it."
  (let ((open (remove-if-not (lambda (d) (eq :proposed (ua:decision-status d))) (ua:change-assessment-recorded change)))
        (outside (append (getf (ua:change-assessment-ownership change) :statements) (getf (ua:change-assessment-ownership change) :outside))))
    (v:html
      (:h4 "Open")
      (if (or open outside)
          (v:html
            (dolist (d open)
              (v:html (:div :class "ua-open" (ref d (v:text-representation d)) " is proposed and not accepted. " (:span :class "ua-note" (v:esc (format nil "Evidence: ~D claim~:P." (length (ua:decision-evidence d))))))))
            (when outside
              (v:html (:div :class "ua-open" (ref (ownership-judgement change) "Who owns the fork's text") " is not decided in this checkout. "
                            (:span :class "ua-note" "Evidence: the path rule, a general statement in this checkout, and a proposal in a draft that is not integrated.")))))
          (v:html (:p :class "ua-note" "Nothing is open: every decision here is accepted."))))))

(v:defview definition-change-view (c ua:definition-change)
  (v:html-view :title "Upstream change" :priority 1
    (reading (:h2 (v:esc (v:text-representation c))) (render-upstream-change c))))

(v:defview fork-situation-view (s ua:fork-situation)
  (v:html-view :title "In the fork" :priority 1
    (reading (:h2 "Where the definition stands in the fork") (render-fork-situation s))))

(v:defview ownership-judgement-view (object ownership-judgement)
  (v:html-view :title "Ownership" :priority 1
    (reading (:h2 (v:esc (v:text-representation object))) (render-ownership (ownership-judgement-change object)))))

(v:defview located-view (object located)
  (v:html-view :title "Definition" :priority 1
    (let ((d (located-definition object)))
      (reading
        (:h2 (v:esc (ua:source-definition-key d)))
        (:dl :class "ua-facts"
          (fact "Seen" (v:esc (where-label (located-where object))))
          (fact "Kind" (v:esc (string-downcase (princ-to-string (ua:source-definition-kind d)))))
          (fact "File" (:code (v:esc (ua:source-definition-path d))))
          (when (member (located-where object) '(:fork :fork-caller))
            (fact "ASDF system" (system-refs (located-owners object))))
          (fact "Digest" (:code (v:esc (ua:source-definition-digest d)))))
        (:h3 "Source")
        (:pre (v:esc (ua:source-definition-text d)))))))

(v:defview change-assessment-view (change ua:change-assessment)
  (v:html-view :title "Change in the fork" :priority 1
    (let* ((c (ua:change-assessment-change change)) (s (ua:change-assessment-situation change)) (i (ua:change-assessment-impact change)))
      (reading
        (:h2 (v:esc (v:text-representation change)))
        (:h3 "1. What upstream changed")
        (render-upstream-change c)
        (:h3 "2. Where it stands in the fork now")
        (render-fork-situation s)
        (dolist (key (ua:definition-change-counterparts c))
          (v:html (:p :class "ua-note" (v:esc (format nil "Possible counterpart among upstream's own changes (differs in package qualification only; not equated): ~A" key)))))
        (:h3 "3. ASDF owner now, and who should own it")
        (render-ownership change)
        (:h3 "4. What may be affected")
        (render-impact i)
        (:h3 "5. Decision")
        (:dl :class "ua-facts"
          (fact "Proposed by rule" (ref (ua:change-assessment-proposal change) (v:text-representation (ua:change-assessment-proposal change))))
          (fact "Recorded" (decision-refs (ua:change-assessment-recorded change))))
        (dolist (d (ua:change-assessment-stale change))
          (v:html (:p (:strong "Stale: ") (v:esc (format nil "the decision ~A was taken against another state of the fork than the present one; it stands in the ledger, a new assessment is possible beside it." (ua:decision-id d))))))
        (render-open-decisions change)
        (:p (ref (change-chain-workspace change) "The chain as a Topicmap"))))))

;;; A decision

(v:defview decision-view (decision ua:decision)
  (v:html-view :title "Decision" :priority 1
    (reading
      (:h2 (v:esc (v:text-representation decision)))
      (:dl :class "ua-facts"
        (fact "Commit" (:code (v:esc (ua:decision-commit decision))))
        (fact "Subject" (:code (v:esc (ua:decision-subject decision))))
        (fact "Kind" (v:esc (string-downcase (symbol-name (ua:decision-kind decision)))))
        (fact "Status" (v:esc (string-downcase (symbol-name (ua:decision-status decision)))))
        (fact "Proposed by" (v:esc (ua:decision-proposed-by decision))))
      (:p :class "ua-note" "A decision is not its execution: a proposal changes nothing, and only a person accepts it.")
      (:h3 "Rationale") (:p (v:esc (ua:decision-rationale decision)))
      (:h3 "Evidence") (render-claims (ua:decision-evidence decision))
      (:h3 "Required migration") (:p (v:esc (or (ua:decision-required-migration decision) "none")))
      (:h3 "Verification") (:ul :class "ua-list" (dolist (item (ua:decision-verification decision)) (v:html (:li (v:esc item))))))))

(v:defview claim-view (claim ua:claim)
  (v:html-view :title "Claim" :priority 1
    (reading (:h2 (v:esc (claim-status-label (ua:claim-status claim)))) (render-claims (list claim)))))

;;; The chain as a Topicmap workspace

(defstruct chain-step id label object)

(defun chain-steps (change)
  "The eight steps for one changed definition, each with the object the Inspector opens for it."
  (let* ((c (ua:change-assessment-change change)) (d (or (first (ua:change-assessment-recorded change)) (ua:change-assessment-proposal change)))
         (owners (ua:change-assessment-owners change)) (s (ua:change-assessment-situation change)))
    (list (make-chain-step :id "chain:commit" :label "Upstream commit" :object (or (ua:change-assessment-commit change) change))
          (make-chain-step :id "chain:definition" :label (format nil "Changed definition ~A" (ua:definition-change-key c)) :object c)
          (make-chain-step :id "chain:current" :label (format nil "Current definition: ~A" (ua:relation-label (ua:fork-situation-relation s))) :object s)
          (make-chain-step :id "chain:owner" :label (format nil "ASDF owner ~{~A~^, ~}" owners) :object (ownership-judgement change))
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
