;;;; The Lisp Critic on the federated context of Working on HyperDoc: what was
;;;; observed, what Claude judged about it, and what Claude recommended, kept
;;;; as three kinds of record.
;;;;
;;;; An observation comes from executing something against a stated program
;;;; state. The probes below read source and run the reading; they write
;;;; nothing, and each call observes afresh. What was observed at 3e84471c,
;;;; before the reduction was committed as d1849327, a Claude Code session
;;;; observed by other means; it is kept as it was recorded then, with how it
;;;; was made. The forms it names are kept as a source snapshot of that
;;;; commit, read from Git once, when the snapshot was recorded.
;;;;
;;;; A judgement is Claude's interpretation of observations. Its :BASIS ties
;;;; it to them, and RESOLVE-JUDGEMENT-BASIS refuses a basis that names an
;;;; observation not recorded, or a target none of them observed. Its
;;;; :EVIDENCE-STATUS :INTERPRETED is a label; the basis is what holds.
;;;;
;;;; A recommendation proposes a change and predicts what the probes will then
;;;; observe. It is not evidence and declares no evidence status. Whether a
;;;; prediction held is a later observation; nothing here records that.
;;;;
;;;; No critic rule ran for any of this. There is no Evaluation Record and no
;;;; Critique among these records.

(defpackage #:dreyeck/lisp-critic/federated-context
  (:use #:cl)
  (:local-nicknames (#:rec #:dreyeck/lisp-critic/recorded)
                    (#:fc #:dreyeck/work/trails-rendered-reading)
                    (#:tm #:dreyeck/topicmap))
  (:export #:observe-attribution-tests #:observe-links-by-bare-item
           #:observe-event-summary-field #:observe-trail-source-items
           #:f1-discrimination #:prior-observations #:prior-observation
           #:source-snapshot #:recorded-target #:target-now
           #:judgements #:judgement #:resolve-judgement-basis
           #:reduction-proposal #:observed-transition #:record-source-snapshot))

(in-package #:dreyeck/lisp-critic/federated-context)

(defparameter +ward-event+ "2026-10-01T17:18:24.009Z"
  "Ward's Trail relation change, the event at which F1 is observed.")

(defparameter +snapshot-file+
  "dreyeck/pages/lisp-critic/evaluations/federated-context-3e84471c-sources.json"
  "The source snapshot of 3e84471c, in which the recorded observations name their forms.")

;;;; Observing now

(defun %criticised-page ()
  "The code page under criticism, as this runtime has it."
  (or (rec::%code-page "dreyeck/work/reading" "trails-rendered-federated-context.lisp")
      (error "Working on HyperDoc has no federated-context code page.")))

(defun %book-pages ()
  "Every code page of the book the federated context belongs to."
  (coerce (hyperdoc::code-pages-of (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t))
          'list))

(defun %iso-time (universal-time)
  (multiple-value-bind (second minute hour day month year) (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" year month day hour minute second)))

(defun %source-state (page text)
  "Which page, in which state: its book, its file, and the digest of the text read."
  (list :hyperdoc (hyperbook:id-of (hyperbook:hyperbook-of page))
        :code-file (file-namestring (hyperdoc::source-code-pathname page))
        :source-sha256 (rec::%text-digest text)))

(defun %executed (states)
  "Who observed, and when: this runtime, executing a probe against STATES."
  (list :kind :executed-probe
        :runtime (format nil "~A ~A" (lisp-implementation-type) (lisp-implementation-version))
        :observation-time (%iso-time (get-universal-time))
        :sources states))

(defun %observation (probe question targets result states)
  "An executed probe's observation: what it asked, of which forms or subject,
what it found, and against which program state."
  (list :kind :probe-observation :probe probe :question question
        :targets targets :result result
        :provenance (%executed states)
        :evidence-status :observed))

(defun %subforms (form predicate)
  "FORM and the forms within it that PREDICATE holds for."
  (append (and (funcall predicate form) (list form))
          (and (consp form)
               (loop for tail = form then (cdr tail)
                     while (consp tail)
                     append (%subforms (car tail) predicate)))))

(defun %target (form)
  "What names a top-level FORM: its recorded-source identity when the
structural operations own it, otherwise only where it stands."
  (let ((occurrence (getf form :occurrence)))
    (if occurrence
        (alexandria:alist-hash-table (rec::%occurrence-identity occurrence) :test 'equal)
        (list :unkeyed-form-range (getf form :range)))))

(defun %matching (predicate page &optional source)
  "The top-level forms of PAGE that contain a form PREDICATE holds for, and PAGE's state."
  (multiple-value-bind (forms text) (rec:page-forms page source)
    (values (remove-if-not (lambda (form) (%subforms (getf form :form) predicate)) forms)
            (%source-state page text))))

(defun %attribution-test-p (form)
  (and (consp form) (eq 'search (first form))
       (consp (rest form)) (equal "via Thompson" (second form))))

(defun observe-attribution-tests (&optional source)
  "C1a, a proxy: the top-level forms that test text for \"via Thompson\".
It observes where the test occurs. That the occurrences encode one decision
is a judgement, not something this observes. SOURCE replaces the page's text."
  (multiple-value-bind (forms state) (%matching #'%attribution-test-p (%criticised-page) source)
    (%observation 'observe-attribution-tests
                  "Which top-level forms test text for \"via Thompson\"?"
                  (mapcar #'%target forms) (list :count (length forms)) (list state))))

(defun %gethash-path (form)
  "The string keys of a chain of GETHASH forms, outermost first."
  (when (and (consp form) (eq 'gethash (first form)) (stringp (second form)))
    (cons (second form) (%gethash-path (third form)))))

(defun %bare-item-key-p (form)
  "Whether FORM is a function of one argument returning that argument's \"item\"."
  (let ((function (if (and (consp form) (eq 'function (first form))) (second form) form)))
    (and (consp function) (eq 'lambda (first function))
         (consp (second function)) (null (rest (second function)))
         (equal (cddr function) (list (list 'gethash "item" (first (second function))))))))

(defun %links-by-bare-item-p (form)
  "A sequence search through stored \"links\" whose only key is the bare \"item\"."
  (and (consp form)
       (member (first form) '(find find-if position position-if member count remove-if remove-if-not))
       (consp (rest form)) (consp (cddr form))
       (equal "links" (first (%gethash-path (third form))))
       (%bare-item-key-p (getf (cdddr form) :key))))

(defun %stored-collection (path)
  "What the GETHASH chain PATH reaches in a federated context read now."
  (reduce (lambda (table key) (and (hash-table-p table) (gethash key table)))
          (reverse path) :initial-value (fc::context-data (fc:federated-context))))

(defun observe-links-by-bare-item (&optional source)
  "C1b: searches through stored \"links\" keyed by nothing but the bare \"item\"
id, counted when the stored collection holds links from more than one page.
A search within one page's own story or journal is not one of them. SOURCE
replaces the page's text."
  (multiple-value-bind (forms state) (%matching #'%links-by-bare-item-p (%criticised-page) source)
    (let ((operations
            (loop for form in forms
                  append (loop for operation in (%subforms (getf form :form) #'%links-by-bare-item-p)
                               collect (let ((path (%gethash-path (third operation))))
                                         (list :target (%target form) :collection-path path
                                               :pages-in-collection
                                               (remove-duplicates
                                                (map 'list (lambda (link) (gethash "from" link))
                                                     (%stored-collection path))
                                                :test #'equal)))))))
      (%observation 'observe-links-by-bare-item
                    "Which searches through stored links of several pages use the bare item id as their only key?"
                    (mapcar #'%target forms)
                    (list :count (count-if (lambda (operation) (rest (getf operation :pages-in-collection)))
                                           operations)
                          :operations operations)
                    (list state)))))

(defun %summary-accesses (form)
  "How often FORM writes a \"summary\" field, as a CONTEXT-TABLE key or a SETF of
GETHASH, and reads one, as any other GETHASH of it. Two values."
  (let ((writes 0) (reads 0))
    (labels ((summary-p (place)
               (and (consp place) (eq 'gethash (first place)) (equal "summary" (second place))))
             (walk (form)
               (when (consp form)
                 (cond ((eq 'setf (first form))
                        (loop for (place value) on (rest form) by #'cddr
                              do (if (summary-p place) (incf writes) (walk place))
                                 (walk value)))
                       ((eq 'fc::context-table (first form))
                        (loop for (key value) on (rest form) by #'cddr
                              do (if (equal "summary" key) (incf writes) (walk key))
                                 (walk value)))
                       ((summary-p form) (incf reads) (walk (third form)))
                       (t (loop for tail = form then (cdr tail)
                                while (consp tail)
                                do (walk (car tail))))))))
      (walk form)
      (values writes reads))))

(defun observe-event-summary-field (&optional source)
  "C4: the top-level forms of the book's code pages that write or read a
\"summary\" field. SOURCE replaces the federated-context page's text."
  (let ((criticised (%criticised-page)) (writers nil) (readers nil) (states nil))
    (dolist (page (%book-pages))
      (multiple-value-bind (forms text) (rec:page-forms page (and (eq page criticised) source))
        (push (%source-state page text) states)
        (dolist (form forms)
          (multiple-value-bind (writes reads) (%summary-accesses (getf form :form))
            (when (plusp writes) (push (%target form) writers))
            (when (plusp reads) (push (%target form) readers))))))
    (%observation 'observe-event-summary-field
                  "Which forms of the book's code write or read a \"summary\" field?"
                  (append (reverse writers) (reverse readers))
                  (list :writers (length writers) :readers (length readers)
                        :field-present-p (and (or writers readers) t)
                        :writing-forms (reverse writers) :reading-forms (reverse readers))
                  (reverse states))))

(defun %trail-associations (context mode)
  (setf (fc::context-mode context) mode)
  (remove-if-not (lambda (association)
                   (uiop:string-prefix-p "trail:" (tm:topicmap-association-id-of association)))
                 (tm:topicmap-projection-associations-of (fc::context-projection context))))

(defun %declared-trail-item (context relation)
  "An instrument, not a fix: the source item of a Trail RELATION, found in the
one page whose configuration declares that trail item, at the cursor's time."
  (let* ((id (gethash "item" relation))
         (pages (remove-if-not (lambda (page) (find id (gethash "trail-items" page) :test #'equal))
                               (coerce (fc::context-pages context) 'list))))
    (unless (= 1 (length pages))
      (error "Trail item ~A is declared by ~D pages." id (length pages)))
    (gethash id (fc::context-page-story-at
                 (first pages)
                 (gethash "date" (aref (fc:context-events context) (fc::context-cursor context)))))))

(defun observe-trail-source-items (&optional instrument)
  "F1: at Ward's event, how many Trail associations carry their source item,
in Delta and in State. Without INSTRUMENT, the item each association carries,
as the reading resolves it. With INSTRUMENT, a function of a context and a
relation, the item it finds instead. Nothing in the reading is redefined."
  (let ((context (fc:federated-context)) (page (%criticised-page)))
    (multiple-value-bind (forms text) (rec:page-forms page)
      (fc::select-context-event context (position +ward-event+ (fc:context-events context)
                                                  :key (lambda (event) (gethash "at" event))
                                                  :test #'equal))
      (%observation 'observe-trail-source-items
                    "At Ward's 17:18:24.009Z event, do the Trail associations carry their source item?"
                    (list (list :event +ward-event+)
                          (%target (find '(:definition fc::context-relation-item) forms
                                         :key (lambda (form) (getf form :form-key)) :test #'equal)))
                    (list :resolution (if instrument :instrument :reading)
                          :modes (loop for mode in '(:delta :state)
                                       collect (let ((associations (%trail-associations context mode)))
                                                 (list :mode mode
                                                       :trail-associations (length associations)
                                                       :with-item
                                                       (count-if (lambda (association)
                                                                   (let ((properties (tm:topicmap-association-properties-of association)))
                                                                     (if instrument
                                                                         (funcall instrument context (getf properties :evidence))
                                                                         (getf properties :item))))
                                                                 associations)))))
                    (list (%source-state page text))))))

(defun f1-discrimination ()
  "The F1 witness beside its control: the reading's resolution, a declared-page
instrument, then the reading's resolution again."
  (list :original (observe-trail-source-items)
        :control (observe-trail-source-items #'%declared-trail-item)
        :restored (observe-trail-source-items)
        :evidence-status :observed))

;;;; Observed at 3e84471c, before the reduction

(defun prior-observations ()
  "What a Claude Code session observed at commit 3e84471c on 2026-10-05, before
the reduction was committed as d1849327. Kept as recorded then: the probes in
this file did not exist yet and made none of these, and nothing here derives
them again. Each says how it was made; its targets are forms of the 3e84471c
source snapshot."
  (copy-tree
   '((:kind :prior-observation :id :c1a :state "3e84471c"
      :question "Which top-level forms test text for \"via Thompson\"?"
      :targets ("(:DEFINITION DERIVE-FEDERATED-DATA)"
                "(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)"
                "(:VIEW 👀TOPICMAP DREYECK/WORK/TRAILS-RENDERED-READING:FEDERATED-CONTEXT)")
      :result (:count 3)
      :method "git grep of commit 3e84471c for \"via Thompson\", then reading each match: three (SEARCH \"via Thompson\" ...) tests, in DERIVE-FEDERATED-DATA, CONTEXT-RELATION-ATTRIBUTION and the federated context's Topicmap view."
      :provenance (:kind :claude-code-session :observer "Claude Code" :model "Opus 5.5 Extra"
                   :observation-time "2026-10-05T08:32:29Z")
      :evidence-status :observed)
     (:kind :prior-observation :id :c1b :state "3e84471c"
      :question "Which searches through stored links of several pages use the bare item id as their only key?"
      :targets ("(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)")
      :result (:count 1)
      :method "Reading the text of trails-rendered-federated-context.lisp at 3e84471c: one FIND through (GETHASH \"links\" (GETHASH \"observed\" ...)) keyed by (GETHASH \"item\" link) alone. Item-id lookups within one page's story or journal were read and not counted."
      :provenance (:kind :claude-code-session :observer "Claude Code" :model "Opus 5.5 Extra"
                   :observation-time "2026-10-05T08:31:02Z")
      :evidence-status :observed)
     (:kind :prior-observation :id :c4 :state "3e84471c"
      :question "Which forms write or read the event \"summary\" field?"
      :targets ("(:DEFINITION CONTEXT-DERIVED-EVENTS)")
      :result (:writers 1 :readers 0)
      :method "git grep of commit 3e84471c for \"summary\" across dreyeck/, code, tests and pages: one key of the event table CONTEXT-DERIVED-EVENTS builds, and no reader."
      :provenance (:kind :claude-code-session :observer "Claude Code" :model "Opus 5.5 Extra"
                   :observation-time "2026-10-05T08:32:29Z")
      :evidence-status :observed)
     (:kind :prior-observation :id :f1 :state "3e84471c"
      :question "At Ward's 17:18:24.009Z event, do the Trail associations carry their source item?"
      :targets ("(:DEFINITION CONTEXT-RELATION-ITEM)")
      :result (:original ((:mode :delta :trail-associations 4 :with-item 0)
                          (:mode :state :trail-associations 4 :with-item 0))
               :control ((:mode :delta :trail-associations 4 :with-item 4)
                         (:mode :state :trail-associations 4 :with-item 4))
               :restored ((:mode :delta :trail-associations 4 :with-item 0)
                          (:mode :state :trail-associations 4 :with-item 0)))
      :method "A script in a fresh image of the clean 3e84471c checkout counted the Trail associations carrying :ITEM. For the control it redefined CONTEXT-RELATION-ITEM in that throwaway image to find the page by its declared trail item, then restored the original definition and counted again."
      :raw-output ("F1 HEAD: delta: 4 trail associations, 0 with :item; state: 4 trail associations, 0 with :item"
                   "F1 HEAD: FAIL"
                   "F1 CONTROL item-resolving instrument: delta: 4 trail associations, 4 with :item; state: 4 trail associations, 4 with :item"
                   "F1 CONTROL item-resolving instrument: PASS"
                   "F1 CONTROL restored from-path: delta: 4 trail associations, 0 with :item; state: 4 trail associations, 0 with :item"
                   "F1 CONTROL restored from-path: FAIL")
      :provenance (:kind :claude-code-session :observer "Claude Code" :model "Opus 5.5 Extra"
                   :observation-time "2026-10-05T08:34:01Z")
      :evidence-status :observed))))

(defun prior-observation (id)
  (or (find id (prior-observations) :key (lambda (observation) (getf observation :id)))
      (error "No observation ~S was recorded at 3e84471c." id)))

;;;; The forms they name, as 3e84471c declared them

(defun source-snapshot ()
  "The source snapshot of 3e84471c: the identities of the forms the recorded
observations name. Reading it runs no Git."
  (with-open-file (stream (asdf:system-relative-pathname "dreyeck" +snapshot-file+)
                          :external-format :utf-8)
    (shasht:read-json stream)))

(defun %key-name (key-text)
  "The defined name in a form key's text, e.g. CONTEXT-RELATION-ATTRIBUTION."
  (let ((start (1+ (position #\Space key-text))))
    (subseq key-text start (position-if (lambda (char) (member char '(#\Space #\)))) key-text :start start))))

(defun recorded-target (name)
  "The snapshot's identity of the form NAME defines; NAME is a symbol, a string,
or a form key's text."
  (let ((name (string name)))
    (or (find-if (lambda (identity)
                   (let ((key (gethash "form-key" identity)))
                     (or (string= name key) (string-equal name (%key-name key)))))
                 (gethash "occurrences" (source-snapshot)))
        (error "The 3e84471c snapshot records no form ~A." name))))

(defun target-now (name)
  "The recorded form NAME, observed again in this runtime's source: unchanged,
changed or absent."
  (let ((identity (recorded-target name)))
    (multiple-value-bind (occurrence status) (rec::%observe-now identity)
      (list :kind :target-observation :target (gethash "form-key" identity)
            :recorded-in (gethash "state" (source-snapshot))
            :status status :occurrence occurrence
            :provenance (%executed (list (%source-state (%criticised-page)
                                                        (uiop:read-file-string
                                                         (hyperdoc::source-code-pathname (%criticised-page))
                                                         :external-format :utf-8))))
            :evidence-status :observed))))

(defun record-source-snapshot (state text names pathname)
  "Write the identities of the forms NAMES define, as TEXT declares them, into
PATHNAME as the source snapshot of STATE. TEXT is the criticised page's text
at STATE, supplied by the caller: this reads no Git."
  (let* ((forms (rec:page-forms (%criticised-page) text))
         (identities
           (loop for name in names
                 collect (rec::%occurrence-identity
                          (getf (or (find-if (lambda (form)
                                               (and (getf form :form-key)
                                                    (string-equal (string name)
                                                                  (string (second (getf form :form-key))))))
                                             forms)
                                    (error "~A declares no ~A." state name))
                                :occurrence)))))
    (with-open-file (stream pathname :direction :output :if-exists :supersede :external-format :utf-8)
      (let ((shasht:*write-alist-as-object* t)
            (shasht:*write-indent-string* "  "))
        (shasht:write-json
         (list (cons "source-snapshot-version" 1)
               (cons "state" state)
               (cons "occurrences" (coerce identities 'vector))
               (cons "recording" (list (cons "context" "A development checkout. The caller read the text from Git once, at recording time.")
                                       (cons "recorded-at" (get-universal-time)))))
         stream))
      (terpri stream))
    pathname))

;;;; Judged by Claude

(defparameter +judgement-provenance+
  '(:kind :llm-critic :critic "Claude Code" :model "Opus 5.5 Extra"
    :recorded-at 4000181298 :scope (:target-commit "3e84471c"))
  "Who made the judgements and the recommendation, and when they were recorded.
:RECORDED-AT is a universal time, when the record was made, as for a recorded
evaluation; an observation's time is its :OBSERVATION-TIME.")

(defun judgements ()
  "Claude's judgements about the observations at 3e84471c: an LLM's
interpretations, each resting on the recorded observations its :BASIS names."
  (mapcar (lambda (judgement)
            (append judgement (list :provenance (copy-tree +judgement-provenance+)
                                    :evidence-status :interpreted)))
          (copy-tree
           '((:kind :judgement :label "C1a" :principle :structural-duplication
              :statement "The three observed tests independently encode one attribution interpretation: that \"via Thompson\" in an item's text credits Thompson's page."
              :targets ("(:DEFINITION DERIVE-FEDERATED-DATA)"
                        "(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)"
                        "(:VIEW 👀TOPICMAP DREYECK/WORK/TRAILS-RENDERED-READING:FEDERATED-CONTEXT)")
              :basis ((:state "3e84471c" :observation :c1a)))
             (:kind :judgement :label "C1b" :principle :identity-scope
              :statement "A bare item id is used as a key outside the page and site in which its uniqueness is guaranteed: a forked page keeps its items' ids."
              :targets ("(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)")
              :basis ((:state "3e84471c" :observation :c1b)))
             (:kind :judgement :label "C4" :principle :unnecessary-derived-structure
              :statement "The event \"summary\" is an orphaned derived field: written and never read, and derivable from the event's operation and page title."
              :targets ("(:DEFINITION CONTEXT-DERIVED-EVENTS)")
              :basis ((:state "3e84471c" :observation :c4)))
             (:kind :judgement :label "F1" :principle :behavioural-falsifiability
              :statement "The Evidence contract that a Trail association exposes its source item is falsified at this program state: the witness finds none of the four items, and its control shows that it would find them."
              :targets ("(:DEFINITION CONTEXT-RELATION-ITEM)")
              :basis ((:state "3e84471c" :observation :f1)))))))

(defun judgement (label)
  (or (find label (judgements) :key (lambda (judgement) (getf judgement :label)) :test #'string=)
      (error "No judgement ~A." label)))

(defun resolve-judgement-basis (judgement &optional (observations (prior-observations)))
  "The recorded observations JUDGEMENT rests on. Signals when its basis names
an observation not among OBSERVATIONS, or when the judgement names a target
none of those observations observed, so an interpretation cannot drift away
from its evidence. The evidence status is not consulted."
  (let ((resolved
          (mapcar (lambda (entry)
                    (or (find-if (lambda (observation)
                                   (and (eq (getf entry :observation) (getf observation :id))
                                        (equal (getf entry :state) (getf observation :state))))
                                 observations)
                        (error "Judgement ~A cites observation ~S at ~A, which is not recorded."
                               (getf judgement :label) (getf entry :observation) (getf entry :state))))
                  (getf judgement :basis))))
    (dolist (target (getf judgement :targets) resolved)
      (unless (some (lambda (observation) (member target (getf observation :targets) :test #'equal))
                    resolved)
        (error "Judgement ~A names ~A, which none of its basis observations observed."
               (getf judgement :label) target)))))

;;;; Recommended by Claude

(defun reduction-proposal ()
  "Claude's recommendation after the observations at 3e84471c, with what it
predicts the probes will observe once it is made. Not evidence: it declares
no evidence status, and whether a prediction held is a later observation."
  (list :kind :reduction-proposal :label "C1 + C4"
        :addresses (list "C1a" "C1b" "C4")
        :recommendation "Interpret \"via Thompson\" once, from a page-scoped item; drop the search through stored links by bare item id; remove the event \"summary\" field."
        :predictions (copy-tree '((:probe observe-attribution-tests :count 1)
                                  (:probe observe-links-by-bare-item :count 0)
                                  (:probe observe-event-summary-field :writers 0 :readers 0)))
        :not-addressed (copy-tree '((:label "F1" :reason "a behavioural fix, kept apart from a reduction")
                                    (:label "F2" :reason "a dead branch, deleted on its own")))
        :provenance (copy-tree +judgement-provenance+)))

;;;; Both observations, side by side

(defun observed-transition ()
  "Each condition as observed at 3e84471c beside what its probe observes now.
Both are observations; set side by side, they conclude nothing."
  (flet ((result (observation key) (getf (getf observation :result) key))
         (with-items (modes) (mapcar (lambda (mode) (getf mode :with-item)) modes)))
    (let ((c1a (prior-observation :c1a)) (c1a-now (observe-attribution-tests))
          (c1b (prior-observation :c1b)) (c1b-now (observe-links-by-bare-item))
          (c4 (prior-observation :c4)) (c4-now (observe-event-summary-field))
          (f1 (prior-observation :f1)) (f1-now (observe-trail-source-items)))
      (list :kind :observed-transition
            :rows (list (list :label "C1a" :at-3e84471c (result c1a :count) :now (result c1a-now :count)
                              :observed-then c1a :observed-now c1a-now)
                        (list :label "C1b" :at-3e84471c (result c1b :count) :now (result c1b-now :count)
                              :observed-then c1b :observed-now c1b-now)
                        (list :label "C4"
                              :at-3e84471c (list :writers (result c4 :writers) :readers (result c4 :readers))
                              :now (list :writers (result c4-now :writers) :readers (result c4-now :readers))
                              :observed-then c4 :observed-now c4-now)
                        (list :label "F1"
                              :at-3e84471c (with-items (result f1 :original))
                              :now (with-items (result f1-now :modes))
                              :observed-then f1 :observed-now f1-now))
            :evidence-status :observed))))
