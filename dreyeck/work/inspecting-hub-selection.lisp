;;;; Inspecting a Hub Selection
(in-package #:dreyeck/work/hubs)
(hyperdoc:see (hyperdoc:page "What Counts as a Hub?" :hyperbook "dreyeck/work/reading"))
(hyperdoc:see (hyperdoc:page "From Two Hubs to One Trail" :hyperbook "dreyeck/work/reading"))

(defclass hub-selection-evidence () ((record :initarg :record :reader selection-record)))
(defvar *hub-selection* nil)
(hyperdoc:defexample hub-selection
  "Inspect seven executed trusted synthetic cases; this call only reads evidence."
  (or *hub-selection* (setf *hub-selection* (make-instance 'hub-selection-evidence :record (hub-record)))))

(views:defview hub-selection-view (selection hub-selection-evidence)
  (views:html-view :title "Hub selection" :priority -1
    (views:html
      (:h2 "Synthetic hub selection and expansion")
      (:p "Trusted synthetic neighborhood executed by the exact retained Mech walks implementation. No reconstruction of Ward's report. Opening this view reads evidence only.")
      (:p (views:object-ref (selection-record selection) :display "Complete execution record and provenance"))
      (:ul (loop for case across (gethash "cases" (selection-record selection)) do
        (views:html (:li (views:esc (gethash "label" case)) " / "
          (views:object-ref (gethash "neighborhood" case) :display "Input neighborhood") " / "
          (views:object-ref (gethash "ranking" case) :display "Ranking and hits") " / "
          (views:object-ref (gethash "aspects" case) :display "Resulting aspects and graphs")))))
      (:p "In the first case hub has four hits, while its graph root has one incoming relation. Exactly Fifteen contributes a hit but is excluded from fallback parents, which require fewer than ten outgoing links. Reversing the two site-qualified hub records preserves hits and changes the chosen source to Hub B.")
      (:p (views:object-ref (hub-function "hubs") :display "Original hubs" :select "Hub source")
          " / " (views:object-ref (hub-function "blanket") :display "Original blanket" :select "Hub source"))
      (:p (views:object-ref (reading::following-path "scripts/test-mech-hubs-reading.mjs") :display "Repeatable offline witness" :select "Text"))
      (:p (views:object-ref (work:work-page "What Counts as a Hub?") :display "Return to What Counts as a Hub?" :select "Content")))))

(defvar *hub-wiki-pages* (make-hash-table :test #'equal))
(defun hub-wiki-page (site slug title)
  "Use the ordinary site-qualified catalog object; no title-based identity."
  (or (gethash (list site slug) *hub-wiki-pages*)
      (let* ((book (hyperbook:find-hyperbook (concatenate 'string "fedwiki:" site)))
             (page (hyperbook:find-page book slug)))
        (unless page (error "Native Wiki page unavailable: ~A/~A (~A)" site slug title))
        (setf (gethash (list site slug) *hub-wiki-pages*) page))))

(defvar *ward-hub-report* nil)
(defun ward-hub-report ()
  (or *ward-hub-report*
      (setf *ward-hub-report*
        (alexandria:plist-hash-table
         (list "author" "Ward" "transmitted-date" "2026-10-14"
               "publication-date" "not established"
               "provenance" "Ward's message transmitted by the user on 14 October 2026; full wording not independently reconstructed from Wiki JSON."
               "warrant" "author-reported; not independent runtime observation"
               "url" "http://ward.voices.ustawi.wiki/view/welcome-visitors/view/dewey-alexander-trail"
               "verbatim" "Here, while browsing \"hubs\" I selected two that I though would connect. They didn't. So clicked four nodes to make a \"trail\" which will render as its own kind of symbol. This is my first end-to-end run through the new code in Mech and Solo plugins."
               "two-hub-selection" "Ward reports selecting two hubs."
               "expected-connection" "Ward expected a connection."
               "missing-connection" "Ward reports that the selected display did not connect them; exact graph state remains unresolved."
               "four-node-selection" "Ward reports clicking four nodes to make a trail."
               "trail-rendering" "Ward describes a trail that will render as its own kind of symbol and reports his first end-to-end run; independent rendering verification remains absent."
               "runtime-question" "Exact executed Mech/Solo commits are not established; no absence-of-path claim about the entire neighborhood follows.") :test 'equal))))

(defclass hub-reported-claim ()
  ((key :initarg :key :reader report-claim-key)
   (report :initarg :report :reader report-claim-source)))
(defvar *hub-claims* (make-hash-table :test #'equal))
(defun hub-claim (key)
  (or (gethash key *hub-claims*)
      (setf (gethash key *hub-claims*) (make-instance 'hub-reported-claim :key key :report (ward-hub-report)))))
(views:defview hub-claim-view (claim hub-reported-claim)
  (views:html-view :title "Reported claim" :priority -1
    (views:html
      (:h2 (views:esc (report-claim-key claim)))
      (:p (views:esc (gethash (report-claim-key claim) (report-claim-source claim))))
      (:p "Ward's author message was transmitted by the user on 14 October 2026. This is not an independently observed runtime event or established executed revision.")
      (:p (views:object-ref (report-claim-source claim) :display "Author message and provenance"))
      (:p (views:object-ref (work:work-page "From Two Hubs to One Trail") :display "Return to From Two Hubs to One Trail" :select "Content")))))

(defvar *hub-page-capture* nil)
(defun hub-page-capture ()
  (or *hub-page-capture*
      (setf *hub-page-capture* (checked-hub-json
        "dreyeck/work/hubs-evidence/ward.voices.ustawi.wiki--dewey-alexander-trail.json"
        "739ea473cd67f800ee748ab25107d48d53d3cb57cb2224da7ba8cdd7df7289bf"))))

(defun hub-learning-projection ()
  "One learning projection: actual objects, warranted edges, no runtime reconstruction."
  (let* ((first-case (aref (gethash "cases" (hub-record)) 0))
         (ward (hub-wiki-page "ward.voices.ustawi.wiki" "dewey-alexander-trail" "Dewey Alexander Trail"))
         (plan (hub-wiki-page "next.ward.dojo.fed.wiki" "how-trails-travel" "How Trails Travel"))
         (sources (reading::how-trails-sources plan))
         (report (ward-hub-report))
         (topics nil) (edges nil))
    (labels ((topic (id label object)
               (assert object)
               (let ((kind (cond
                             ((member id '("walks" "hubs" "blanket" "solo-sources") :test #'equal) "retained source")
                             ((member id '("neighborhood" "hits" "aspect") :test #'equal) "synthetic execution evidence")
                             ((member id '("report" "two-hubs" "missing" "four-nodes" "trail") :test #'equal) "author report")
                             ((equal id "open") "open question")
                             ((equal id "preservation") "author proposal")
                             ((equal id "capture") "observed page capture")
                             (t "reading / Wiki reference"))))
                 (push (tm:make-topicmap-topic :id id :label label :type :hub-learning :object object
                        :view-properties (list :x (* 280 (mod (length topics) 4)) :y (* 110 (floor (length topics) 4)) :visible t :kind kind)) topics)))
             (edge (from relation to warrant basis)
               (push (tm:make-topicmap-association :id (format nil "hubs:~A:~A:~A" from relation to)
                      :type relation :from from :to to :properties (list :warrant warrant :source basis)) edges)))
      (topic "definition" "Hub definition" (work:work-page "What Counts as a Hub?"))
      (topic "walks" "Mech walks" (hub-function "walks"))
      (topic "hubs" "Mech hubs" (hub-function "hubs"))
      (topic "blanket" "Mech blanket" (hub-function "blanket"))
      (topic "neighborhood" "Synthetic neighborhood" (gethash "neighborhood" first-case))
      (topic "hits" "Ranking / incoming hits" (gethash "ranking" first-case))
      (topic "aspect" "Selected synthetic hub aspect" (aref (gethash "aspects" first-case) 0))
      (topic "ward-page" "Dewey Alexander Trail" ward)
      (topic "report" "Ward's reported experiment" report)
      (dolist (entry '(("two-hubs" "Reported two-hub selection" "two-hub-selection")
                       ("missing" "Reported missing connection" "missing-connection")
                       ("four-nodes" "Reported four-node selection" "four-node-selection")
                       ("trail" "Reported trail rendering" "trail-rendering")
                       ("open" "Open runtime revision question" "runtime-question")))
        (topic (first entry) (second entry) (hub-claim (third entry))))
      (topic "plan" "Ward's How Trails Travel" plan)
      (topic "preservation" "Proposed trail preservation"
        (find "fc195fe5fbc3592f" (hyperbook/fedwiki::story-of plan) :key #'hyperbook/fedwiki::id-of :test #'equal))
      (topic "solo-sources" "Existing Solo source references" sources)
      (topic "capture" "Retained Wiki page (source observation)" (hub-page-capture))
      (edge "definition" :documents "hubs" :derived (hub-function "hubs"))
      (edge "walks" :dispatches "hubs" :source-observed (hub-function "walks"))
      (edge "hubs" :reads "neighborhood" :source-observed (hub-function "hubs"))
      (edge "hubs" :counts "hits" :source-observed (hub-function "hubs"))
      (edge "hubs" :selects "aspect" :derived first-case)
      (edge "blanket" :expands "aspect" :source-observed (hub-function "blanket"))
      (edge "ward-page" :retained-as "capture" :source-observed (hub-page-capture))
      (dolist (id '("two-hubs" "missing" "four-nodes" "trail"))
        (edge "report" :reports id :author-reported report))
      (edge "report" :references "ward-page" :author-reported report)
      (edge "report" :leaves-open "open" :derived report)
      (edge "plan" :proposes "preservation" :author-reported plan)
      (edge "plan" :references "solo-sources" :source-observed plan)
      (tm:make-topicmap-projection :source report :topics (nreverse topics) :associations (nreverse edges)
        :view-properties '(:width 1180 :height 660)))))

(hyperdoc:defexample hub-and-trail-workspace
  "One native Workspace; topic navigation changes Point/History, display has no execution."
  (or *hub-workspace*
      (let* ((projection (hub-learning-projection))
             (workspace (tm:make-topicmap-workspace projection "definition")))
        (setf (slot-value projection 'tm::source) workspace
              *hub-workspace* workspace))))

(defun dewey-trail-page-p (page)
  (and (equal "dewey-alexander-trail" (hyperbook/fedwiki::origin-id-of page))
       (equal "ward.voices.ustawi.wiki" (hyperbook/fedwiki::domain-name-of (hyperbook/fedwiki::origin-of page)))))
(views:defview dewey-trail-reading-view (page hyperbook/fedwiki::fedwiki-page)
  (when (dewey-trail-page-p page)
    (views:html-view :title "Hub and trail reading" :priority 3
      (views:html
        (:h2 "Dewey Alexander Trail — source and reading")
        (:p "This is the original site-qualified Wiki page object. Its ordinary Story/Data views remain available. This view reads documentation and retained source evidence; it executes no Story or Mech program.")
        (:p (:a :href "http://ward.voices.ustawi.wiki/view/welcome-visitors/view/dewey-alexander-trail" "Original Wiki lineup URL"))
        (:p (views:object-ref (hub-page-capture) :display "Retained original page JSON")
            " / " (views:object-ref (ward-hub-report) :display "Ward's report and open runtime questions"))
        (:p (views:object-ref (hub-wiki-page "next.ward.dojo.fed.wiki" "how-trails-travel" "How Trails Travel")
               :select "Plan" :display "Ward's How Trails Travel Plan"))
        (:p (views:object-ref (work:work-page "How Trails Travel") :select "Content" :display "How Trails Travel reading"))
        (:p (views:object-ref (work:work-page "From Two Hubs to One Trail") :select "Content" :display "Return to From Two Hubs to One Trail"))))))

(views:defview hub-code-evidence (page hyperdoc::code-page)
  (when (and (equal "dreyeck/work/reading" (hyperbook:id-of (hyperbook:hyperbook-of page)))
             (member (hyperbook:title-of page) '("Reading Mech Hubs" "Inspecting a Hub Selection") :test #'equal))
    (views:html-view :title "Hub evidence" :priority 2
      (views:html
        (:p "The Source view retains this Code Page's Lisp definitions and DEFEXAMPLE forms. These links open their checked source/evidence objects; they execute no JavaScript.")
        (:ul (dolist (source (hub-sources))
          (views:html (:li (views:object-ref source :display (hub-source-name source) :select "Hub source")))))
        (:p (views:object-ref (hub-selection) :display "Synthetic selection and expansion" :select "Hub selection"))
        (:p (views:object-ref (work:work-page "What Counts as a Hub?") :display "Return to What Counts as a Hub?" :select "Content"))))))
