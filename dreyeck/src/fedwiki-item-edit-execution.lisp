;;;; From a previewed Item edit to an authorized, executed, persisted and verified one
(defpackage #:dreyeck/fedwiki-item-edit-execution
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/fedwiki-item-edit-preview)
                    (#:lp #:dreyeck/local-fedwiki-page)
                    (#:plan #:dreyeck/fedwiki-page-edit-plan)
                    (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:aa #:dreyeck/authenticated-page-authoring)
                    (#:ae #:dreyeck/authoring-envelope)
                    (#:fa #:dreyeck/fedwiki-assets)
                    (#:v #:html-inspector-views))
  (:export #:complete-item-edit #:item-edit-completion #:completion-preview #:completion-action #:completion-date
           #:completion-body #:completion-body-keccak-256 #:completion-request #:completion-authority
           #:completion-envelope-octets #:attach-signed-request
           #:execute-completed-edit #:item-edit-execution #:execution-completion #:execution-edit
           #:execution-authenticated #:execution-previous-source #:execution-persisted-source
           #:execution-journal-entry #:execution-facts #:execution-verification #:execution-states
           #:verify-persisted-edit #:execution-verification-object #:verification-facts #:verification-verified-p
           #:execution-refused #:execution-refusal-reason #:execution-refusal-detail #:unix-milliseconds
           #:interactive-execute #:execution-refusal #:refusal-condition #:refusal-completion #:refusal-challenge-used-p
           #:refusal-outcome #:refusal-observation #:execution-unclear #:execution-unclear-cause
           #:execution-unclear-observation #:execution-expectation #:execution-deviations #:execution-condition
           #:execution-observed #:json-equal))
(in-package #:dreyeck/fedwiki-item-edit-execution)

;; The preview computes; this executes, and only with an authorization it does not make.
;;
;; The steps, each a separate object, none implied by the one before:
;;
;;   proposed     an ITEM-EDIT-PROPOSAL, the intended change
;;   previewed    an ITEM-EDIT-PREVIEW, the change computed against one page revision;
;;                its Action, PREVIEW-ACTION, has no date and is never changed
;;   completed    an ITEM-EDIT-COMPLETION: a copy of that Action with one more field, date
;;   authorized   a request signed over exactly {expected, completed Action} by a principal
;;                the authority registers, with a fresh challenge and a rule for this site,
;;                page and operation. Opening a pane or loading this system grants nothing.
;;   executed     EDIT-FEDWIKI-PAGE-ITEM, the existing writer, returned a FEDWIKI-PAGE-EDIT
;;   persisted    the page file read again shows exactly that edit
;;   verified     a new process, which loads only SHASHT and IRONCLAD, read the file and
;;                compared it with the completed Action
;;
;; What this guarantees, and what it does not (the tests in tests/fedwiki-item-edit-execution.lisp pin each):
;;
;;   guaranteed   nothing is consumed or written unless the operation, the site root, the page, the Item, the
;;                date and the signed body all match the completion, and the page file is the revision the
;;                preview read at the moment this operation looks at it; of two concurrent requests in this
;;                process exactly one is persisted (the writer's page lock); a refusal that is signalled
;;                before the writer can replace the page (ours, the authorization's, the writer's before its
;;                write) is signalled as it is, and for those the claim "no page byte was written" holds;
;;                the result follows the file read again: the completed Action in it makes an
;;                ITEM-EDIT-EXECUTION, its absence EXECUTION-UNCLEAR. Three facts are kept apart: how the
;;                file compares with the preview (EXPECTATION :as-previewed or :differs, with DEVIATIONS; no
;;                condition enters it), the condition the run signalled, if any (CONDITION, kept as an object),
;;                and whom the write is ascribed to (OBSERVED :ATTRIBUTION: only the writer's own return or its
;;                :verification refusal ascribe it to this call; an unused challenge excludes this call; else it
;;                is undetermined, since another process may have written the same Action). A new process can
;;                confirm the file; that confirms the file, not that the run was clean or that this call wrote.
;;   not          protection against another OS process, such as the Node wiki server, writing the page
;;                between the revision check and the writer's own read (the writer then applies the edit to the
;;                newer page: :differs; or refuses if E3 changed, with the challenge already used up), or
;;                between the writer's read and the rename (that other write is lost, and the read after the
;;                write cannot tell); nor durability after a crash (no sync); nor that the signature covers
;;                the page revision (it covers the expected Item and the Action only; the revision is
;;                checked here, outside the signature); nor anything about an interruption, which is not
;;                caught. An unchanged file is not a proof that nothing was written: only a condition known to
;;                be signalled before the replacement allows that claim.
;;
;; A step is named only where its evidence exists. The date: FedWiki's own client sets
;; action.date = new Date().getTime() before it stores an Action and its server appends the
;; Action it receives as it is. Here the same is done by an explicit operation, COMPLETE-ITEM-EDIT:
;; milliseconds since 1970-01-01 UTC, taken from the clock when the completion is made. What is
;; signed is the completed Action, so what was authorized is what is journaled.

(define-condition execution-refused (error)
  ((reason :initarg :reason :reader execution-refusal-reason)
   (detail :initarg :detail :reader execution-refusal-detail))
  (:report (lambda (condition stream)
             (format stream "Execution refused (~(~A~)): ~A" (execution-refusal-reason condition)
                     (execution-refusal-detail condition))))
  (:documentation "A check before the authorization was used failed: nothing was consumed and nothing was written."))
(defun refuse (reason control &rest arguments)
  (error 'execution-refused :reason reason :detail (apply #'format nil control arguments)))

(defun unix-milliseconds ()
  "Milliseconds since 1970-01-01T00:00:00Z, as FedWiki's client takes them."
  (multiple-value-bind (seconds microseconds) (sb-ext:get-time-of-day)
    (+ (* 1000 seconds) (floor microseconds 1000))))

(defun %json-octets (value)
  (sb-ext:string-to-octets (let ((*print-pretty* nil)) (shasht:write-json value nil)) :external-format :utf-8))
(defun %hex (octets) (ironclad:byte-array-to-hex-string octets))

;;; Completing the Action

(defclass item-edit-completion ()
  ((preview :initarg :preview :reader completion-preview)
   (action :initarg :action :reader completion-action)
   (date :initarg :date :reader completion-date)
   (body :initarg :body :reader completion-body)
   (body-keccak :initarg :body-keccak :reader completion-body-keccak-256)
   (authority :initform nil :accessor completion-authority)
   (request :initform nil :accessor completion-request))
  (:documentation "The previewed Action completed with a date, and the body to be signed.
It is not an authorization: it names what an authorization would have to cover."))

(defun complete-item-edit (preview &key (now (unix-milliseconds)))
  "An ITEM-EDIT-COMPLETION for PREVIEW: a copy of its Action, with the date NOW added.
PREVIEW-ACTION is not changed. NOW is milliseconds since 1970 UTC."
  (unless (typep preview 'p:item-edit-preview)
    (refuse :not-a-preview "~S is not an ITEM-EDIT-PREVIEW; an unchanged text or a conflict has no Action to complete" preview))
  (unless (typep now '(integer 1)) (refuse :bad-date "~S is not a date in milliseconds" now))
  (when (nth-value 1 (gethash "date" (p:preview-action preview)))
    (refuse :already-dated "the previewed Action already has a date"))
  (let* ((action (plan::%copy-json (p:preview-action preview)))
         (body (let ((object (make-hash-table :test #'equal)))
                 (setf (gethash "expected" object) (plan::%copy-json (p:preview-expected-item preview))
                       (gethash "action" object) action)
                 object)))
    (setf (gethash "date" action) now)
    (let ((octets (%json-octets body)))
      (make-instance 'item-edit-completion :preview preview :action action :date now :body octets
                                           :body-keccak (%hex (ae:keccak-256 octets))))))

(defun completion-envelope-octets (completion &key service principal challenge (site "localhost") (operation "fedwiki-page-edit"))
  "The envelope a client would sign for COMPLETION: its page is the previewed page, its body digest
that of the completion's body. Built from CHALLENGE, which an authority issued."
  (let ((slug (lp:page-source-slug (p:preview-source (completion-preview completion)))))
    (sb-ext:string-to-octets
     (format nil "~A~%service=~A~%principal=~A~%operation=~A~%site=~A~%page=~A~%nonce=~A~%issued-at=~D~%expires-at=~D~%body-keccak256=~A"
             ae:+authoring-envelope-version+ service principal operation site slug
             (aa:authoring-challenge-nonce challenge) (aa:authoring-challenge-issued-at challenge)
             (aa:authoring-challenge-expires-at challenge) (completion-body-keccak-256 completion))
     :external-format :utf-8)))

(defun attach-signed-request (completion authority request)
  "Record that trusted code holds a signed REQUEST for COMPLETION and the AUTHORITY that would judge it.
This authorizes nothing: executing is a separate, explicit act, and the request is checked then."
  (setf (completion-authority completion) authority (completion-request completion) request)
  completion)

;;; Executing

(defun json-equal (a b)
  "The writer's own equality of page JSON, in one place: what the writer calls equal is what is compared here."
  (plan::%json-equal a b))

(define-condition execution-unclear (error)
  ((completion :initarg :completion :reader execution-unclear-completion)
   (cause :initarg :cause :initform nil :reader execution-unclear-cause)
   (observation :initarg :observation :reader execution-unclear-observation))
  (:report (lambda (condition stream)
             (format stream "Execution unclear: the completed Action is not in the page file read again, and ~
                             whether this execution wrote is not established (~S)"
                     (execution-unclear-observation condition))))
  (:documentation "The operation ended in a way that does not show whether it wrote, and the completed Action
cannot be found in the page file read again. The observation says what was seen; nothing more is claimed."))

(defclass item-edit-execution ()
  ((completion :initarg :completion :reader execution-completion)
   (edit :initarg :edit :initform nil :reader execution-edit)
   (authenticated :initarg :authenticated :initform nil :reader execution-authenticated)
   (previous-source :initarg :previous-source :reader execution-previous-source)
   (persisted-source :initarg :persisted-source :reader execution-persisted-source)
   (journal-entry :initarg :journal-entry :reader execution-journal-entry)
   (facts :initarg :facts :reader execution-facts)
   (expectation :initarg :expectation :reader execution-expectation)
   (deviations :initarg :deviations :initform nil :reader execution-deviations)
   (condition :initarg :condition :initform nil :reader execution-condition)
   (observed :initarg :observed :reader execution-observed)
   (verification :initform nil :accessor execution-verification))
  (:documentation "What one explicit execution of one completed Action left: the completed Action found in the page
file read again, and how that file compares with the preview. EXPECTATION says only how the file read again compares with the
preview: :AS-PREVIEWED, or :DIFFERS with DEVIATIONS. CONDITION, the one signalled during the run, if any, is kept apart
and says nothing about the file. OBSERVED has :ATTRIBUTION, whom the write is ascribed to (see %ATTRIBUTION). EDIT, the writer's
record, and AUTHENTICATED are there only where the writer returned. Verified only when a new process says so."))

(defun %site-root (authority site) (aa:authoring-authority-site-root authority site))

(defun %same-directory-p (a b) (equal (namestring (truename a)) (namestring (truename b))))

(defun %challenge-state (authority request)
  "Whether the single-use challenge REQUEST names is :USED, :UNUSED or :UNKNOWN to AUTHORITY. Used up is not persisted."
  (let* ((nonce (ignore-errors (ae:authoring-envelope-nonce (ae:parse-authoring-envelope (getf request :envelope)))))
         (challenge (and nonce (aa:find-authoring-challenge (aa:authoring-authority-challenges authority) nonce))))
    (cond ((null challenge) :unknown) ((aa:authoring-challenge-used-p challenge) :used) (t :unused))))

(defun %refused-before-the-page-was-replaced-p (condition)
  "True only for what the code signals before the writer replaces the page. Our own checks come before the
authorized call. In AUTHENTICATE-AUTHORIZE-FEDWIKI-PAGE-EDIT the order is: envelope, principal, signature, body, service,
challenge, rule, body data, consume, capability, writer. In the writer, every refusal but :VERIFICATION is made before
MATERIALIZE-FEDWIKI-PAGE-JSON. Anything else, an unknown error or a refusal after the replacement, says nothing about it."
  (or (typep condition 'execution-refused)
      (typep condition 'aa:authoring-request-refused)
      (typep condition 'ae:authoring-envelope-refused)
      (typep condition 'fa:invalid-fedwiki-page-slug)
      (and (typep condition 'pa:fedwiki-page-edit-refused)
           (not (eq :verification (pa:page-edit-refusal-reason condition))))))

(defun %attribution (edit condition challenge-state)
  "Whom the write seen in the file can be ascribed to, from what this call itself observed, not from the file alone.
:WRITER-RETURNED   the writer of this call returned its record;
:WRITER-VERIFICATION  the writer of this call signalled its :VERIFICATION refusal, which it does only after it replaced the page;
:NOT-THIS-CALL     the challenge is unused, and consuming it comes before the writer in AUTHENTICATE-AUTHORIZE-FEDWIKI-PAGE-EDIT,
                   so this call's writer cannot have run;
:UNDETERMINED      anything else: another process may have written the same Action. The file alone does not tell."
  (cond (edit :writer-returned)
        ((and (typep condition 'pa:fedwiki-page-edit-refused) (eq :verification (pa:page-edit-refusal-reason condition)))
         :writer-verification)
        ((eq :unused challenge-state) :not-this-call)
        (t :undetermined)))

(defun %own-write-p (attribution) (and (member attribution '(:writer-returned :writer-verification)) t))

(defun %look (observed persisted action item-id replacement)
  "What the page file read again shows of the completed ACTION against the page OBSERVED when previewing:
(:EDIT-PRESENT bool :DEVIATIONS plist :ENTRY the journal entry :FACTS plist)."
  (let* ((before (lp:page-source-json observed)) (after (lp:page-source-json persisted))
         (old-story (coerce (gethash "story" before) 'list)) (new-story (coerce (gethash "story" after) 'list))
         (old-journal (coerce (gethash "journal" before) 'list)) (new-journal (coerce (gethash "journal" after) 'list))
         (entry (car (last new-journal)))
         (item (find item-id new-story :key (lambda (i) (gethash "id" i)) :test #'equal))
         (present (and entry (json-equal entry action) item (json-equal item replacement)))
         (others (loop for old in old-story for new in new-story
                       unless (or (equal item-id (gethash "id" new)) (json-equal old new)) collect (gethash "id" new)))
         (deviations nil))
    (flet ((deviate (key value) (setf deviations (append deviations (list key value)))))
      (when present
        (unless (= (length old-story) (length new-story)) (deviate :story-items (list (length old-story) (length new-story))))
        (when others (deviate :other-changed-items others))
        (unless (equal (mapcar (lambda (i) (gethash "id" i)) old-story) (mapcar (lambda (i) (gethash "id" i)) new-story))
          (deviate :story-order-changed t))
        (unless (= (length new-journal) (1+ (length old-journal))) (deviate :journal-growth (- (length new-journal) (length old-journal))))
        (unless (and (>= (length new-journal) (length old-journal)) (every #'json-equal old-journal new-journal))
          (deviate :older-journal-entries-changed t))
        (let ((other-keys (remove-if (lambda (k) (member k '("story" "journal") :test #'equal))
                                     (loop for k being the hash-keys of before collect k))))
          (unless (every (lambda (k) (json-equal (gethash k before) (gethash k after))) other-keys)
            (deviate :other-top-level-changed t)))))
    (list :edit-present (and present t) :deviations deviations :entry entry
          :facts (list :story-items (length new-story) :journal-entries (length new-journal)
                       :changed-ids (loop for old in old-story for new in new-story unless (json-equal old new) collect (gethash "id" new))
                       :entry-equals-completed-action (and entry (json-equal entry action) t)
                       :entry-date (and entry (gethash "date" entry)) :item-id item-id))))

(defun execute-completed-edit (authority completion request &key (now (unix-milliseconds)))
  "Execute COMPLETION with the signed REQUEST that AUTHORITY judges, by the existing writer.
Checked first, before the authorization is used: the operation, the site root the authority gives its site id, the
page, the identity of the Item, the date, the body (the signed body must be the completion's, byte for byte) and that
the page file is still the revision the preview read. Then AUTHENTICATE-AUTHORIZE-FEDWIKI-PAGE-EDIT checks the principal,
the challenge and the rule, derives the capability and calls EDIT-FEDWIKI-PAGE-ITEM.

What it yields follows what the page file read again shows, not what was signalled:
  - a refusal made before the writer could replace the page (ours, the authorization's, the writer's before its
    write) is signalled as it is: EXECUTION-REFUSED, AUTHORING-REQUEST-REFUSED, AUTHORING-ENVELOPE-REFUSED or
    FEDWIKI-PAGE-EDIT-REFUSED;
  - if the completed Action is the last journal entry of the file read again and its Item is in place, an
    ITEM-EDIT-EXECUTION is returned, whatever else was signalled: :AS-PREVIEWED, or :DIFFERS with the deviations and
    the original condition;
  - otherwise EXECUTION-UNCLEAR: whether this execution wrote cannot be told from the file.
Interruptions are not caught."
  (let* ((preview (completion-preview completion))
         (item (p:proposal-item (p:preview-proposal preview)))
         (observed (lp:story-item-source item))
         (root (lp:page-source-site-root observed))
         (slug (lp:page-source-slug observed))
         (item-id (lp:story-item-id item))
         (envelope (ae:parse-authoring-envelope (getf request :envelope)))
         (action (completion-action completion))
         (before-sha nil))
    (unless (equal "fedwiki-page-edit" (ae:authoring-envelope-operation envelope))
      (refuse :wrong-operation "the request is for ~A" (ae:authoring-envelope-operation envelope)))
    (let ((site-root (%site-root authority (ae:authoring-envelope-site envelope))))
      (unless site-root (refuse :unknown-site "the authority has no site ~A" (ae:authoring-envelope-site envelope)))
      (unless (%same-directory-p site-root root)
        (refuse :site-root-differs "the site ~A is another directory than the one the preview read" (ae:authoring-envelope-site envelope))))
    (unless (equal slug (ae:authoring-envelope-page envelope))
      (refuse :page-differs "the request is for ~A, the preview read ~A" (ae:authoring-envelope-page envelope) slug))
    (unless (and (equal item-id (gethash "id" action)) (equal item-id (gethash "id" (gethash "item" action))))
      (refuse :item-differs "the Action does not name ~A" item-id))
    (unless (integerp (gethash "date" action)) (refuse :undated "the Action to execute has no date"))
    (unless (equalp (completion-body completion) (getf request :body))
      (refuse :body-differs "the signed body is not the completion's body"))
    (let ((current (lp:observe-local-fedwiki-page-source root slug)))
      (setf before-sha (lp:page-source-sha256 current))
      (unless (and (equal before-sha (lp:page-source-sha256 observed))
                   (equal before-sha (lp:page-source-sha256 (p:preview-source preview))))
        (refuse :stale-revision "the page file is revision ~A, the preview read ~A" before-sha (lp:page-source-sha256 observed))))
    ;; From here on the page may be replaced. What comes out is decided by looking at the file.
    (let ((condition nil) (edit nil) (authenticated nil))
      (handler-case (multiple-value-setq (edit authenticated)
                      (aa:authenticate-authorize-fedwiki-page-edit authority request :now now))
        (error (c) (setf condition c)))
      (when (and condition (%refused-before-the-page-was-replaced-p condition)) (error condition))
      (let* ((persisted (ignore-errors (lp:observe-local-fedwiki-page-source root slug)))
             (seen (and persisted (%look observed persisted action item-id (gethash "item" action))))
             (observation (list :previewed-sha (lp:page-source-sha256 observed) :before-sha before-sha
                                :after-sha (and persisted (lp:page-source-sha256 persisted))
                                :file-readable (and persisted t)
                                :file-changed (and persisted (not (equal before-sha (lp:page-source-sha256 persisted))))
                                :edit-present (and seen (getf seen :edit-present))
                                :challenge-state (%challenge-state authority request))))
        (unless (and seen (getf seen :edit-present))
          (error 'execution-unclear :completion completion :cause condition :observation observation))
        (let ((deviations (getf seen :deviations))
              (challenge-state (getf observation :challenge-state)))
          (make-instance 'item-edit-execution
                         :completion completion :edit edit
                         :authenticated (or authenticated (ignore-errors (aa:authenticate-authoring-request authority request)))
                         :previous-source observed :persisted-source persisted
                         :journal-entry (getf seen :entry) :facts (getf seen :facts)
                         :expectation (if deviations :differs :as-previewed) :deviations deviations
                         :condition condition
                         :observed (append observation
                                           (list :attribution (%attribution edit condition challenge-state)
                                                 :without-condition (null condition)))))))))

(defclass execution-refusal ()
  ((completion :initarg :completion :reader refusal-completion)
   (condition :initarg :condition :reader refusal-condition)
   (outcome :initarg :outcome :reader refusal-outcome)
   (challenge-used-p :initarg :challenge-used-p :reader refusal-challenge-used-p)
   (observation :initarg :observation :reader refusal-observation))
  (:documentation "An explicit execution that produced no ITEM-EDIT-EXECUTION. OUTCOME is :NOT-WRITTEN only where the
condition is one signalled before the page could be replaced, and :UNCLEAR where it cannot be told. The challenge's
state is recorded; a used challenge is not a persisted Action."))

(defun %file-observation (completion)
  "What the page file is now, against the revision the preview read."
  (let* ((observed (lp:story-item-source (p:proposal-item (p:preview-proposal (completion-preview completion)))))
         (now (ignore-errors (lp:observe-local-fedwiki-page-source (lp:page-source-site-root observed) (lp:page-source-slug observed)))))
    (list :previewed-sha (lp:page-source-sha256 observed) :after-sha (and now (lp:page-source-sha256 now))
          :file-readable (and now t)
          :file-changed (and now (not (equal (lp:page-source-sha256 now) (lp:page-source-sha256 observed)))))))

(defun interactive-execute (completion)
  "What the Execute button of an attached request yields: an ITEM-EDIT-EXECUTION, or an EXECUTION-REFUSAL naming what
is known (:NOT-WRITTEN, :UNCLEAR) with the file's state and the challenge's. Any other condition is signalled as itself."
  (let ((authority (completion-authority completion)) (request (completion-request completion)))
    (unless (and authority request) (refuse :nothing-attached "no signed request is attached to this completion"))
    (flet ((refused (condition outcome observation)
             (make-instance 'execution-refusal
                            :completion completion :condition condition :outcome outcome
                            :challenge-used-p (%challenge-state authority request)
                            :observation (or observation (%file-observation completion)))))
      (handler-case (execute-completed-edit authority completion request)
        (execution-unclear (condition) (refused condition :unclear (execution-unclear-observation condition)))
        (error (condition)
          (if (%refused-before-the-page-was-replaced-p condition)
              (refused condition :not-written nil)
              (error condition)))))))

;;; Verifying in a new process

(defparameter +verifier+ "
(require :asdf)
(asdf:load-system \"shasht\")
(asdf:load-system \"ironclad\")
(defun jequal (a b)
  (cond ((and (hash-table-p a) (hash-table-p b))
         (and (= (hash-table-count a) (hash-table-count b))
              (loop for k being the hash-keys of a using (hash-value v)
                    always (multiple-value-bind (w present) (gethash k b) (and present (jequal v w))))))
        ((and (vectorp a) (vectorp b) (not (stringp a)) (not (stringp b)))
         (and (= (length a) (length b)) (every #'jequal a b)))
        (t (equal a b))))
(defun read-json-file (path) (shasht:read-json (uiop:read-file-string path :external-format :utf-8)))
(let* ((saved (read-json-file ~S))
       (proposal (read-json-file ~S))
       (original (gethash \"originalPage\" proposal))
       (replacement (gethash \"replacement\" proposal))
       (action (gethash \"action\" proposal))
       (id (gethash \"id\" replacement))
       (story (gethash \"story\" saved)) (old-story (gethash \"story\" original))
       (journal (gethash \"journal\" saved)) (old-journal (gethash \"journal\" original))
       (entry (aref journal (1- (length journal)))))
  (format t \"~~&FRESH-EXECUTION-VERIFIED ~~S~~%\"
          (list :sha256 (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 ~S))
                :story-items (length story) :journal-entries (length journal)
                :changed-ids (loop for new across story for old across old-story unless (jequal new old) collect (gethash \"id\" new))
                :same-ids (equal (map 'list (lambda (i) (gethash \"id\" i)) story) (map 'list (lambda (i) (gethash \"id\" i)) old-story))
                :replacement-in-place (jequal replacement (find id story :key (lambda (i) (gethash \"id\" i)) :test #'equal))
                :older-journal-unchanged (and (= (length journal) (1+ (length old-journal))) (jequal (subseq journal 0 (length old-journal)) old-journal))
                :new-entry-equals-completed-action (jequal entry action)
                :new-entry-date (gethash \"date\" entry)
                :other-top-level-equal (every (lambda (k) (jequal (gethash k saved) (gethash k original)))
                                              (remove-if (lambda (k) (member k '(\"story\" \"journal\") :test #'equal))
                                                         (loop for k being the hash-keys of original collect k))))))
")

(defclass execution-verification-object ()
  ((execution :initarg :execution :reader verification-execution)
   (facts :initarg :facts :reader verification-facts)
   (verified-p :initarg :verified-p :reader verification-verified-p))
  (:documentation "What a new process read from the saved page file, and whether that matches the completed Action."))
(defun execution-verification-object (execution) (execution-verification execution))

(defun verify-persisted-edit (execution)
  "Read the saved page file in a new SBCL that loads only SHASHT and IRONCLAD and compare it with the
completed Action, the replacement Item and the original page. The result is kept on EXECUTION."
  (let* ((completion (execution-completion execution))
         (preview (completion-preview completion))
         (saved (lp:page-source-pathname (execution-persisted-source execution)))
         (directory (merge-pathnames (format nil "item-edit-verification-~D/" (random 1000000000)) (uiop:temporary-directory)))
         (proposal (merge-pathnames "proposal.json" directory))
         (script (merge-pathnames "verify.lisp" directory))
         (program (or (uiop:argv0) (first sb-ext:*posix-argv*))))
    (ensure-directories-exist proposal)
    (unwind-protect
         (progn
           (let ((document (make-hash-table :test #'equal)))
             (setf (gethash "originalPage" document) (lp:page-source-json (execution-previous-source execution))
                   (gethash "replacement" document) (gethash "item" (completion-action completion))
                   (gethash "expected" document) (p:preview-expected-item preview)
                   (gethash "action" document) (completion-action completion))
             (with-open-file (out proposal :direction :output :if-exists :supersede :external-format :utf-8)
               (shasht:write-json document out)))
           (with-open-file (out script :direction :output :if-exists :supersede :external-format :utf-8)
             (format out +verifier+ (namestring saved) (namestring proposal) (namestring saved)))
           (multiple-value-bind (output error-output status)
               (uiop:run-program (list program "--noinform" "--non-interactive" "--load" (namestring script))
                                 :output :string :error-output :output :ignore-error-status t)
             (declare (ignore error-output))
             (let ((at (search "FRESH-EXECUTION-VERIFIED " output)))
               (unless (and (zerop status) at) (error "The verifying process failed (status ~S):~%~A" status output))
               (let* ((facts (let ((*read-eval* nil) (*package* (find-package "COMMON-LISP-USER")))
                               (read-from-string output t nil :start (+ at (length "FRESH-EXECUTION-VERIFIED ")))))
                      (before-count (length (lp:source-story-items (execution-previous-source execution))))
                      (item-id (getf (execution-facts execution) :item-id))
                      (verified (and (= before-count (getf facts :story-items))
                                     (equal (list item-id) (getf facts :changed-ids))
                                     (getf facts :same-ids) (getf facts :replacement-in-place)
                                     (getf facts :older-journal-unchanged) (getf facts :new-entry-equals-completed-action)
                                     (integerp (getf facts :new-entry-date)) (getf facts :other-top-level-equal)
                                     (equal (getf facts :sha256) (lp:page-source-sha256 (lp:observe-local-fedwiki-page-source
                                                                                         (lp:page-source-site-root (execution-persisted-source execution))
                                                                                         (lp:page-source-slug (execution-persisted-source execution))))))))
                 (setf (execution-verification execution)
                       (make-instance 'execution-verification-object :execution execution :facts facts :verified-p (and verified t)))))))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore))))

(defun execution-states (execution)
  "The six steps and the object that is the evidence of each; NIL where there is none. EXECUTED is the writer's record,
or, where the writer signalled its :VERIFICATION refusal, the journal entry found in the file; where the write cannot be
ascribed to this call it is NIL, though the Action is PERSISTED. VERIFIED needs a new process to have confirmed the file AND
the file to be as previewed. Whether the run signalled a condition is a separate fact (OBSERVED :WITHOUT-CONDITION)."
  (let* ((completion (execution-completion execution)) (preview (completion-preview completion))
         (verification (execution-verification execution)))
    (list (list :proposed (p:preview-proposal preview))
          (list :previewed preview)
          (list :authorized (execution-authenticated execution))
          (list :executed (or (execution-edit execution)
                              (and (%own-write-p (getf (execution-observed execution) :attribution))
                                   (execution-journal-entry execution))))
          (list :persisted (execution-persisted-source execution))
          (list :verified (and verification (verification-verified-p verification)
                               (eq :as-previewed (execution-expectation execution)) verification)))))

;;; Inspection

(defmethod v:text-representation ((completion item-edit-completion)) "Completed Action")
(defmethod v:text-representation ((execution item-edit-execution))
  (format nil (if (%own-write-p (getf (execution-observed execution) :attribution)) "Executed edit of ~A" "Observed edit of ~A")
          (getf (execution-facts execution) :item-id)))
(defmethod v:text-representation ((verification execution-verification-object))
  (format nil "Verification: ~A" (if (verification-verified-p verification) "verified" "not verified")))
(defmethod v:text-representation ((refusal execution-refusal))
  (ecase (refusal-outcome refusal) (:not-written "Execution refused") (:unclear "Execution unclear")))

(defun ref (object &optional label select)
  (v:html (v:object-ref object :display (or label (v:text-representation object)) :select select)))
(defun fref (symbol &optional label)
  (ref (fdefinition symbol) (or label (string-downcase (symbol-name symbol)))))
(defun yes-no (value) (if value "yes" "no"))

(v:defview preview-execution-view (preview p:item-edit-preview)
  (v:html-view :title "Execution" :priority 1
    (v:html
      (:h2 "From this preview to an executed edit")
      (:p "This preview " (:strong "is previewed") ": " (ref preview "it was computed") " against revision "
          (:code (v:esc (lp:page-source-sha256 (p:preview-source preview)))) ". It is not authorized, executed or persisted, and nothing here grants it.")
      (:p "The Action it holds, " (ref (p:preview-action preview) "preview-action") ", has no date, and it stays as it is. "
          "To execute, a copy of it is first completed with a date (" (fref 'complete-item-edit) "); a principal that an authority registers "
          "then signs that completed Action; only the existing writer " (:code "edit-fedwiki-page-item") " writes it.")
      (:p (v:eval-button "Complete the Action with a date" (v:thunk (complete-item-edit preview)))
          " — this makes a copy and writes nothing; it is not an authorization."))))

(v:defview completion-view (completion item-edit-completion)
  (v:html-view :title "Completed Action" :priority 0
    (let* ((preview (completion-preview completion)) (proposed (p:preview-action preview))
           (action (completion-action completion))
           (added (loop for key being the hash-keys of action unless (nth-value 1 (gethash key proposed)) collect key))
           (request (completion-request completion)))
      (v:html
        (:h2 "The Action that would be authorized")
        (:p "The previewed Action (" (ref proposed "the proposed Action") ") has no date. The completed Action ("
            (ref action "this one") ") is a copy with " (v:esc (format nil "~{~A~^, ~}" added)) " added: "
            (:code (v:esc (princ-to-string (completion-date completion)))) ", milliseconds since 1970-01-01 UTC, from the clock when it was completed. "
            "FedWiki's client does the same before it stores an Action. Everything else equals the proposed Action: "
            (v:esc (if (plan::%json-equal (let ((copy (plan::%copy-json action))) (remhash "date" copy) copy) proposed) "checked, equal." "NOT EQUAL.")))
        (:p "What a signature has to cover is the body " (:code "{expected, action}") ": " (:code (v:esc (format nil "keccak-256 ~A" (completion-body-keccak-256 completion))))
            ". The expected Item is " (ref (p:preview-expected-item preview) "the Item as the page held it") ".")
        (:table :class "inspector-table"
          (:tr (:td "proposed") (:td "yes — " (ref (p:preview-proposal preview) "the proposal" "Edit proposal")))
          (:tr (:td "previewed") (:td "yes — " (ref preview "the preview" "Preview")))
          (:tr (:td "completed") (:td "yes — this completed Action"))
          (:tr (:td "authorized") (:td (v:esc (if request "a signed request is attached; it has not been checked yet" "no")) ". Attaching grants nothing."))
          (:tr (:td "executed, persisted, verified") (:td "no")))
        (if request
            (v:html (:p "Executing checks the request against the completion, then lets the authority judge it. "
                        (v:eval-button "Execute the attached signed request" (v:thunk (interactive-execute completion)))))
            (v:html (:p "To authorize: the authority issues a challenge, a registered principal signs the envelope for this body with its own key, "
                        "outside this image, and trusted code attaches the signed request (" (fref 'attach-signed-request) ").")))))))

(defun %observation-rows (observation)
  (loop for (key value) on observation by #'cddr
        do (v:html (:tr (:td (v:esc (string-downcase (symbol-name key)))) (:td (:code (v:esc (princ-to-string value))))))))

(v:defview execution-refusal-view (refusal execution-refusal)
  (v:html-view :title "Refusal" :priority 0
    (let ((condition (refusal-condition refusal)) (observation (refusal-observation refusal)))
      (v:html
        (:h2 (v:esc (ecase (refusal-outcome refusal) (:not-written "Not executed") (:unclear "Outcome unclear"))))
        (:p (v:esc (princ-to-string condition)))
        (ecase (refusal-outcome refusal)
          (:not-written
           (v:html (:p "No page byte was written: the condition is one that is signalled before the writer can replace the page.")))
          (:unclear
           (v:html (:p "It cannot be told whether this execution wrote the page. The completed Action is not in the page file read again. "
                       "An unchanged file does not show that nothing was written, and a changed one does not show that it was written here. "
                       "Only what was observed is stated."))))
        (:table :class "inspector-table"
          (:tr (:td "challenge") (:td (:code (v:esc (string-downcase (symbol-name (refusal-challenge-used-p refusal)))))
                                     " — a used challenge is not a persisted Action"))
          (%observation-rows observation))
        (:p (ref (refusal-completion refusal) "Back to the completed Action" "Completed Action") " / " (ref condition "the condition"))))))

(v:defview execution-view (execution item-edit-execution)
  (v:html-view :title "Execution" :priority 0
    (let* ((completion (execution-completion execution)) (preview (completion-preview completion))
           (edit (execution-edit execution)) (facts (execution-facts execution))
           (persisted (execution-persisted-source execution)) (verification (execution-verification execution))
           (states (execution-states execution)) (as-previewed (eq :as-previewed (execution-expectation execution)))
           (deviations (execution-deviations execution)) (condition (execution-condition execution))
           (observed (execution-observed execution)) (attribution (getf observed :attribution)))
      (v:html
        (:h2 (v:esc (format nil (if (%own-write-p attribution) "Executed edit of ~A" "Edit Action observed in the persisted page, Item ~A")
                                (getf facts :item-id))))
        (if as-previewed
            (v:html (:p (:strong "File as previewed.") " The completed Action is the last journal entry of the page file read again, "
                        "and nothing else differs from the preview."))
            (v:html (:p (:strong "File differs from the preview.") " The completed Action is in the page file read again, but the file is not what was previewed:")
                    (:ul (loop for (key value) on deviations by #'cddr
                               do (v:html (:li (:code (v:esc (string-downcase (symbol-name key)))) ": " (:code (v:esc (princ-to-string value)))))))))
        (if condition
            (v:html (:p (:strong "The run did not end cleanly.") " A condition was signalled: " (ref condition "the original condition")
                        ". It is kept, and it says nothing about whether the file is as previewed."))
            (v:html (:p (:strong "The run ended without a condition."))))
        (:p (:strong "Origin of the write: ")
            (ecase attribution
              (:writer-returned (v:html "the writer of this call returned its record."))
              (:writer-verification (v:html "the writer of this call signalled its :verification refusal, which it does only after it replaced the page."))
              (:not-this-call (v:html "not this call: the challenge is unused and is consumed before the writer runs. The Action is in the file all the same; something else wrote it."))
              (:undetermined (v:html "not determinable. The Action is observed in the persisted file, but nothing shows that this call wrote it; "
                                     "another process may have written the same Action."))))
        (:table :class "inspector-table"
          (loop for (name evidence) in states
                do (v:html (:tr (:td (v:esc (string-downcase (symbol-name name))))
                                (:td (cond (evidence (v:html (:strong "yes") " — " (ref evidence)))
                                           ((and (eq name :verified) verification)
                                            (v:html (:strong "no") ", a new process read the file but it is not as previewed: " (ref verification nil)))
                                           (t (v:html (:strong "no") ", not shown"))))))))
        (:p (:strong "Authorized") " by " (if (execution-authenticated execution) (ref (execution-authenticated execution) "the authenticated principal") (v:html "an authenticated principal"))
            ": the signed body is the completed Action (" (ref (completion-action completion) "the Action") ", " (ref completion "its completion") ").")
        (:p (:strong "Executed")
            (cond (edit (v:html " by " (fref 'pa:edit-fedwiki-page-item "edit-fedwiki-page-item") ", which returned " (ref edit "the page edit") " for Item "
                                (:code (v:esc (getf facts :item-id))) ", whose previous state was " (ref (pa:page-edit-previous-item edit) "this Item") "."))
                  ((%own-write-p attribution) (v:html " by " (fref 'pa:edit-fedwiki-page-item "edit-fedwiki-page-item") " — it did not return; the journal entry in the file is the evidence."))
                  (t (v:html ": not shown. Only that the Action is persisted was observed."))))
        (:p (:strong "Persisted") ": the page file was read again (" (ref persisted "the persisted page source") ", "
            (ref (lp:page-source-json persisted) "its JSON") "): "
            (v:esc (format nil "~D Items, ~D journal entries, changed Items ~{~A~^, ~}; " (getf facts :story-items)
                           (getf facts :journal-entries) (getf facts :changed-ids)))
            (ref (execution-journal-entry execution) "the last journal entry")
            (v:esc (format nil " equals the completed Action, date ~D." (getf facts :entry-date))))
        (:p (:strong "Verified") ": "
            (cond ((and verification as-previewed (verification-verified-p verification))
                   (v:html (ref verification nil) " (the file only; whether the run was clean is stated above)."))
                  (verification (v:html "no. " (ref verification nil) "."))
                  (t (v:html "not yet. A new process has not read the file. "
                             (v:eval-button "Verify in a new process" (v:thunk (verify-persisted-edit execution)))))))
        (:table :class "inspector-table"
          (:tr (:td "challenge") (:td (:code (v:esc (string-downcase (symbol-name (getf observed :challenge-state))))) " — a used challenge is not a persisted Action"))
          (%observation-rows (list :previewed-sha (getf observed :previewed-sha) :before-sha (getf observed :before-sha)
                                   :after-sha (getf observed :after-sha))))
        (:p "Compared with the preview: " (ref (p:preview-action preview) "the previewed Action") " has no date; the journal entry is that Action plus the date, "
            "as " (ref completion "the completion") " states.")))))

(v:defview verification-view (verification execution-verification-object)
  (v:html-view :title "Verification" :priority 0
    (v:html
      (:h2 (v:esc (if (verification-verified-p verification) "Verified in a new process" "Not verified")))
      (:p "A new SBCL process, which loads only shasht and ironclad, read the saved file and compared it with the completed Action, the replacement Item and the original page.")
      (:table :class "inspector-table"
        (loop for (key value) on (verification-facts verification) by #'cddr
              do (v:html (:tr (:td (v:esc (string-downcase (symbol-name key)))) (:td (:code (v:esc (princ-to-string value))))))))
      (:p (ref (verification-execution verification) "Back to the executed edit" "Execution")))))

(v:defview executed-edit-view (edit pa:fedwiki-page-edit)
  (v:html-view :title "Executed edit" :priority 1
    (let* ((capability (pa:page-edit-capability edit)) (slug (pa:page-edit-slug edit))
           (page (ignore-errors (lp:observe-local-fedwiki-page-source (pa:capability-site-root capability) slug)))
           (journal (and page (gethash "journal" (lp:page-source-json page)))))
      (v:html
        (:h2 (v:esc (format nil "Executed edit of ~A on ~A" (pa:page-edit-item-id edit) slug)))
        (:p "The Action that was appended: " (ref (pa:page-edit-action edit) "the Action") ". The Item it replaced: "
            (ref (pa:page-edit-previous-item edit) "the previous Item") ".")
        (if page
            (v:html (:p "The page file as it is now: " (ref page "the page source") ", "
                        (ref (lp:page-source-json page) "its JSON") "; its last journal entry: "
                        (if (plusp (length journal)) (ref (aref journal (1- (length journal))) "the journal entry") (v:html "none")) "."))
            (v:html (:p (:em "The page file cannot be read now."))))
        (:p "Made by " (fref 'pa:edit-fedwiki-page-item "edit-fedwiki-page-item") ".")))))
