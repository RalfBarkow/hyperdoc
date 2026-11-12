;;;; One criticism of a text page, as records: a paragraph of "The Fischer
;;;; Critic as an Environment" beside the claim records it restates.
;;;;
;;;; The paragraph says no Fischer paper has been read here and that all but
;;;; one Fischer claim report :NONE-OBSERVED. The claim records in
;;;; lisp-critic-reading.lisp say otherwise. Both texts are identified in one
;;;; recorded source state, and the same kinds of record are kept as for the
;;;; federated context (lisp-critic-federated-context.lisp):
;;;;
;;;;   observation      recorded at a named source state, with how it was
;;;;                    made; and observed again now by OBSERVE-NOW
;;;;   reading          what the paragraph is taken to assert: Claude's
;;;;                    interpretation
;;;;   discrepancy      derived by comparing that reading with the records
;;;;   judgement        Claude's: the paragraph and the records disagree. Its
;;;;                    :BASIS names recorded observations, in the form
;;;;                    RESOLVE-JUDGEMENT-BASIS of the federated context
;;;;                    resolves. It does not say which of the two is wrong.
;;;;   recommendation   a proposed text. Not evidence, and not applied: this
;;;;                    file edits no page.
;;;;
;;;; No critic rule ran for any of this. There is no Evaluation Record and no
;;;; Critique among these records, and none of them is an acceptance decision.

(defpackage #:dreyeck/lisp-critic/text-criticism
  (:use #:cl)
  (:local-nicknames (#:passage #:dreyeck/lisp-critic/text-passage))
  (:export #:+state+ #:recorded-source-state #:passage-reading
           #:recorded-observations #:recorded-observation
           #:judgement #:recommendation
           #:observe-now #:image-agreement))

(in-package #:dreyeck/lisp-critic/text-criticism)

(defparameter +state+ "596344ae95d746f436705808462259371f5a593c"
  "The commit at which the two texts were read and their identities recorded.")

(defparameter +page-path+ "dreyeck/pages/lisp-critic/The Fischer Critic as an Environment.html")
(defparameter +claims-path+ "dreyeck/src/lisp-critic-reading.lisp")

(defparameter +passage-target+
  "dreyeck/pages/lisp-critic/The Fischer Critic as an Environment.html, characters 4160-4629"
  "What names the paragraph as a judgement's target.")

(defparameter +claims-target+
  "dreyeck/src/lisp-critic-reading.lisp, (DEFUN HISTORICAL-CLAIMS)"
  "What names the claim records as a judgement's target.")

(defparameter +provenance+
  '(:kind :claude-code-session :observer "Claude Code" :observation-time "2026-11-12T14:00:00Z")
  "Who recorded the observations, and when.")

(defparameter +critic-provenance+
  '(:kind :llm-critic :critic "Claude Code" :recorded-at "2026-11-12T14:00:00Z"
    :scope (:target-commit "596344ae95d746f436705808462259371f5a593c"))
  "Who made the reading, the judgement and the recommendation.")

(defun recorded-source-state ()
  "The two texts as commit +STATE+ holds them: path, SHA-256 of the octets and
Git blob id of each, and the paragraph's place and text in the page. Recorded
once, from the Git objects of that commit; reading it runs no Git."
  (copy-tree
   `(:state ,+state+
     :files ((:role :page :path ,+page-path+
              :sha256 "78cd0198be60447c4d0627d5aab7d4d7b5964cf3e090ca6d6d7cbc78c611b923"
              :git-blob "9311795202ace004dddf364a7f369acd1c572975")
             (:role :claims-source :path ,+claims-path+
              :sha256 "28f50b15f7a807b10e72958ea13d364af82641d687a9c55728b538c746702f12"
              :git-blob "53b57d14242add6ad5d77e79ec9f18db1ed9ce38"))
     :passage (:range (4160 . 4629)
               :text "Neither Fischer paper has been read here. Only the first claim on this page
is currently carried by something observed — a secondary research note in
the local wiki, which mentions the rules, the user model, the knowledge
browser, the visualization support and learning on demand. Every other
Fischer claim cites a paper and reports
<code>:OBSERVED-EVIDENCE-KIND :NONE-OBSERVED</code>: the sentence names
where it should be checked, and nothing here has checked it yet.")
     :recording (:method "git rev-parse and git show of the two paths at the commit; SHA-256 of the octets; the paragraph located in the decoded page text."
                 :provenance ,+provenance+))))

(defun passage-reading ()
  "What the paragraph is taken to assert about the claim records, as three
countable assertions. An interpretation: whoever reads the paragraph
differently has a different reading, and the discrepancies follow the reading."
  (copy-tree
   `(:kind :passage-reading :target ,+passage-target+
     :assertions
     ((:id :no-paper-read
       :statement "No claim that cites a primary paper is carried by a primary paper read here."
       :expects (:count :observed-evidence-kind :primary-paper 0))
      (:id :first-claim-carried-by-a-secondary-note
       :statement "The first claim that cites a primary paper is carried by a secondary research note."
       :expects (:first :observed-evidence-kind :secondary-research-note))
      (:id :every-other-claim-none-observed
       :statement "Every other claim that cites a primary paper reports :NONE-OBSERVED."
       :expects (:rest :observed-evidence-kind :none-observed)))
     :provenance ,+critic-provenance+
     :evidence-status :interpreted)))

(defun recorded-observations ()
  "What was observed of the two texts at +STATE+. Kept as recorded then; each
says how it was made. OBSERVE-NOW observes again and derives nothing from these."
  (copy-tree
   `((:kind :recorded-observation :id :passage :state ,+state+
      :question "What does the page say, in its paragraph on what has been read, about the Fischer claims?"
      :targets (,+passage-target+)
      :result (:occurrences 1 :range (4160 . 4629))
      :method "The page's blob at the commit, decoded as UTF-8; the paragraph's text found once, at these characters."
      :provenance ,+provenance+
      :evidence-status :observed)
     (:kind :recorded-observation :id :claims :state ,+state+
      :question "What do the records give as the observed evidence of each claim that cites a primary paper?"
      :targets (,+claims-target+)
      :result (:claims-citing-a-primary-paper 10
               :by-observed-evidence-kind ((:primary-paper . 5) (:none-observed . 5))
               :first-claim (:subject :fischer-1987 :id :critic-capability
                             :observed-evidence-kind :primary-paper))
      :method "The quoted table in the definition of HISTORICAL-CLAIMS, read from the blob's text at the commit; the definition was not evaluated and the system was not loaded."
      :provenance ,+provenance+
      :evidence-status :observed))))

(defun recorded-observation (id)
  (or (find id (recorded-observations) :key (lambda (observation) (getf observation :id)))
      (error "No observation ~S was recorded at ~A." id +state+)))

(defun judgement ()
  "Claude's judgement about the two recorded observations. It rests on them and
on the reading of the paragraph; it is not an observation and not a Critique."
  (copy-tree
   `(:kind :judgement :label "T1" :principle :prose-restates-records
     :statement "The paragraph and the claim records disagree about what has been read: the paragraph says no Fischer paper has been read and all but one Fischer claim report :NONE-OBSERVED, while five of the ten claims that cite a primary paper record a primary paper as observed evidence, the first among them. Which of the two is wrong is not settled by this: the records may be ahead of the paragraph, or wrong themselves."
     :targets (,+passage-target+ ,+claims-target+)
     :basis ((:state ,+state+ :observation :passage)
             (:state ,+state+ :observation :claims))
     :reading :passage-reading
     :provenance ,+critic-provenance+
     :evidence-status :interpreted)))

(defun recommendation ()
  "Claude's recommendation, with what OBSERVE-NOW is predicted to find once it
is made. Not evidence: it declares no evidence status. Not applied: the page
is as it was, and whether a prediction held is a later observation."
  (copy-tree
   `(:kind :text-correction-proposal :label "T1" :addresses ("T1")
     :recommendation "Do not restate in prose what the claim records count. Replace the paragraph by a sentence that points at the records, so the page cannot fall behind them again."
     :replacement-text "Which Fischer claims are carried by a passage read here, and which only cite a paper, is recorded claim by claim and can be inspected above. This page does not restate the counts."
     :predictions ((:probe observe-now :passage-status :absent :discrepancies :not-determined))
     :applied-p nil
     :provenance ,+critic-provenance+)))

(defun %repository-root ()
  (asdf:system-source-directory "dreyeck"))

(defun observe-now (&key (root (%repository-root)) octets)
  "The two texts as they read now under ROOT, against the recorded source
state, and the discrepancies between the reading and the records — or
:NOT-DETERMINED when the texts are not the recorded ones. Reads two files
and may ask Git one question about each; loads and evaluates nothing."
  (passage:criticise-passage (recorded-source-state) (passage-reading) :root root :octets octets))

(defun image-agreement (&key (root (%repository-root)))
  "Whether the claim table this image has loaded is the one the source text
declares. :READING-SYSTEM-NOT-LOADED where the reading system is not in the
image: nothing is loaded to find out."
  (let* ((package (find-package "DREYECK/LISP-CRITIC/READING"))
         (symbol (and package (find-symbol "HISTORICAL-CLAIMS" package))))
    (if (not (and symbol (fboundp symbol)))
        (list :kind :image-agreement :status :reading-system-not-loaded)
        (let* ((pathname (merge-pathnames +claims-path+ root))
               (text (and (uiop:file-exists-p pathname)
                          (ignore-errors (uiop:read-file-string pathname :external-format :utf-8))))
               (table (and text (passage:read-claim-table text))))
          (list :kind :image-agreement
                :status (cond ((null table) :source-table-unreadable)
                              ((equal table (funcall symbol)) :image-agrees-with-source)
                              (t :image-differs-from-source)))))))
