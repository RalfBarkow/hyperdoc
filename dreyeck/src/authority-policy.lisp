;;;; Who may make a method run, and what a view may reveal: containment over
;;;; HyperDoc and its Inspector, owned by dreyeck, with upstream untouched.
;;;;
;;;; The Inspector offers every one-argument method applicable to an inspected
;;;; object, and runs it on click for whoever clicks. Applicability is not
;;;; authority. Here an offered method runs only if a contract says it may:
;;;;
;;;;   applicable                          visible, with its contract status
;;;;   contracted + permitted + capable    invocable
;;;;   anything else                       visible, and refused
;;;;
;;;; A contract is registered explicitly and names the one method it was
;;;; reviewed for. Purity is never inferred, with one mechanical exception:
;;;; a slot reader returns its slot and nothing else.
;;;;
;;;; Disclosure is a separate question. A pathname view reveals the file
;;;; system, so pathname views stay inside the allowed roots. Title-bar actions
;;;; that start a process on the server or fetch over the network are withheld:
;;;; copying a pathname or a string to the server's clipboard, and FedWiki's
;;;; Reload and Open.
;;;;
;;;; All of this is enforced where the served Catalog runs: a server is up,
;;;; not in development mode. An image without a server, or a developer's
;;;; server, shows the same statuses and refuses nothing.
;;;;
;;;; This is containment, not the architecture. The Operations view is a
;;;; replaced upstream method, and the gates rest on upstream internals;
;;;; +CONTAINMENT-ADAPTERS+ records each point with the source it relies on,
;;;; and CONTAINMENT-ADAPTER-DRIFT reports any that has moved.

(defpackage #:dreyeck/authority-policy
  (:use #:cl)
  (:local-nicknames (#:hv #:html-inspector-views)
                    (#:hvs #:html-inspector-views/standard))
  (:export #:operation-contract
           #:contract-identity #:contract-operation #:contract-applicability
           #:contract-status #:contract-effect-classes #:contract-effect-extent
           #:contract-authority #:contract-preconditions #:contract-required-capability
           #:contract-required-permission #:contract-execution #:contract-postconditions
           #:contract-verification-evidence #:contract-failure-modes
           #:contract-replay-semantics #:contract-audit-provenance
           #:register-operation-contract #:find-operation-contract #:method-contract
           #:invocation-decision #:method-invocation-decision #:policy-enforced-p
           #:operation-thunk #:invocation-refused #:invocation-refused-reason
           #:allowed-disclosure-roots #:pathname-disclosure-permitted-p
           #:+containment-adapters+ #:containment-adapter-drift))

(in-package #:dreyeck/authority-policy)

;;;; Contracts

(defclass operation-contract ()
  ((identity :initarg :identity :reader contract-identity)
   (operation :initarg :operation :initform nil :reader contract-operation
              :documentation "The generic function name, for a method contract.")
   (applicability :initarg :applicability :initform nil :reader contract-applicability
                  :documentation "The class name of the one method reviewed, or :ANY.")
   (status :initarg :status :reader contract-status
           :documentation ":CONTRACTED, :UNRESOLVED or :UNSAFE.")
   (effect-classes :initarg :effect-classes :initform nil :reader contract-effect-classes)
   (effect-extent :initarg :effect-extent :initform nil :reader contract-effect-extent)
   (authority :initarg :authority :initform nil :reader contract-authority)
   (preconditions :initarg :preconditions :initform nil :reader contract-preconditions)
   (required-capability :initarg :required-capability :initform :none
                        :reader contract-required-capability)
   (required-permission :initarg :required-permission :initform :anonymous
                        :reader contract-required-permission)
   (execution :initarg :execution :initform nil :reader contract-execution)
   (postconditions :initarg :postconditions :initform nil :reader contract-postconditions)
   (verification-evidence :initarg :verification-evidence :initform nil
                          :reader contract-verification-evidence)
   (failure-modes :initarg :failure-modes :initform nil :reader contract-failure-modes)
   (replay-semantics :initarg :replay-semantics :initform nil :reader contract-replay-semantics)
   (audit-provenance :initarg :audit-provenance :initform nil :reader contract-audit-provenance))
  (:documentation "What invoking one operation may do, who may ask for it,
what the image must be able to do, and how its result is checked."))

(defmethod print-object ((contract operation-contract) stream)
  (print-unreadable-object (contract stream :type t)
    (format stream "~A ~(~A~)" (contract-identity contract) (contract-status contract))))

(defvar *contracts* (make-hash-table :test #'equal)
  "Every registered contract, by identity.")

(defun register-operation-contract (&rest initargs)
  (let ((contract (apply #'make-instance 'operation-contract initargs)))
    (setf (gethash (contract-identity contract) *contracts*) contract)))

(defun find-operation-contract (identity)
  (gethash identity *contracts*))

(defparameter +slot-reader-contract+
  (make-instance 'operation-contract
                 :identity "slot reader" :status :contracted
                 :effect-classes '(:observational)
                 :effect-extent "nothing changes: the method returns one slot's value"
                 :authority "the object's own slot, which its Slots view already shows"
                 :execution "the reader method"
                 :verification-evidence "mechanical: the method is a STANDARD-READER-METHOD"
                 :audit-provenance "CLOS: a slot reader's behaviour is defined by the class, not by code")
  "The one contract that is inferred rather than registered.")

(defun %method-class-name (method)
  (let ((specializer (first (c2mop:method-specializers method))))
    (and (typep specializer 'class) (class-name specializer))))

(defun method-contract (method)
  "The contract for METHOD: the registered one reviewed for exactly this method
or for all methods of its generic function, the slot-reader contract, or NIL."
  (let ((name (c2mop:generic-function-name (c2mop:method-generic-function method)))
        (class (%method-class-name method)))
    (or (loop for contract being the hash-values of *contracts*
              when (and (equal name (contract-operation contract))
                        (let ((applicability (contract-applicability contract)))
                          (or (eq :any applicability) (eq class applicability))))
                return contract)
        (and (typep method 'c2mop:standard-reader-method) +slot-reader-contract+))))

;;;; Decisions

(defun policy-enforced-p ()
  "Whether this is a served runtime not in development mode. Read softly: this
layer must not depend on the HTTP server, only on whether one is running."
  (let* ((package (find-package :hyperbook/server))
         (symbol (and package (find-symbol "*SERVER-PARAMETERS*" package)))
         (parameters (and symbol (boundp symbol) (symbol-value symbol))))
    (and parameters (not (second parameters)) t)))

(defun %capability-present-p (capability)
  (ecase capability
    (:none t)
    (:authoring-environment
     (let* ((package (find-package "DREYECK/WORKFLOW/AUTHORING"))
            (make (and package (find-symbol "MAKE-AUTHORING-ENVIRONMENT" package))))
       (and make (fboundp make) (handler-case (and (funcall make) t) (error () nil)))))))

(defun %permission-granted-p (permission)
  "Only anonymous invocation exists yet: a contract requiring anything more is
never satisfied until principals exist."
  (eq :anonymous permission))

(defun invocation-decision (contract)
  "Whether CONTRACT permits invocation here and now, and why."
  (cond ((null contract) (values nil "no operation contract"))
        ((not (eq :contracted (contract-status contract)))
         (values nil (format nil "contract status is ~(~A~)" (contract-status contract))))
        ((not (%capability-present-p (contract-required-capability contract)))
         (values nil (format nil "the runtime capability ~(~A~) is absent"
                             (contract-required-capability contract))))
        ((not (%permission-granted-p (contract-required-permission contract)))
         (values nil (format nil "invocation permission ~(~A~) is not granted to an anonymous visitor"
                             (contract-required-permission contract))))
        (t (values t "contracted, permitted and capable"))))

(defun method-invocation-decision (method)
  "INVOCATION-DECISION for METHOD's contract, where the policy is enforced."
  (if (policy-enforced-p)
      (invocation-decision (method-contract method))
      (values t "not enforced: no served runtime, or a development server")))

;;;; The execution gate

(define-condition invocation-refused (error)
  ((method :initarg :method :reader invocation-refused-method)
   (target :initarg :target :reader invocation-refused-target)
   (reason :initarg :reason :reader invocation-refused-reason))
  (:report (lambda (condition stream)
             (format stream "Not invoked: ~A." (invocation-refused-reason condition))))
  (:documentation "An offered method that the policy did not let run. Nothing
was called."))

(defclass operation-thunk (hv:thunk)
  ((method :initarg :method :reader operation-thunk-method)
   (target :initarg :target :reader operation-thunk-target))
  (:documentation "The invocation of one offered method on one object. The
decision is taken again when it is evaluated, not only when it was shown."))

(defmethod hv:eval-thunk ((thunk operation-thunk))
  (multiple-value-bind (allowed reason) (method-invocation-decision (operation-thunk-method thunk))
    (if allowed
        (call-next-method)
        (make-condition 'invocation-refused :method (operation-thunk-method thunk)
                                            :target (operation-thunk-target thunk) :reason reason))))

;;;; Operations, shown with their contracts
;;
;; Replaces upstream's 👀OPERATIONS method on T (see +CONTAINMENT-ADAPTERS+).
;; It lists the same methods, grouped the same way, and adds each one's
;; contract status. Only a permitted method gets an Evaluate button, and
;; that button is an OPERATION-THUNK, gated again when clicked.

(defun %status-text (method)
  (let ((contract (method-contract method)))
    (multiple-value-bind (allowed reason) (method-invocation-decision method)
      (format nil "~:[no contract~;~:*~A~]~@[ (~{~(~A~)~^, ~})~] -- ~:[not invocable: ~A~;~*invocable~]"
              (and contract (format nil "~(~A~)" (contract-status contract)))
              (and contract (contract-effect-classes contract))
              allowed reason))))

(defmethod hvs::👀operations ((object t))
  (let ((groups (make-hash-table :test #'equal)))
    (dolist (method (remove-if-not #'hvs::callable-with-one-arg? (hvs::find-applicable-methods object)))
      (push method (gethash (hvs::method-package-name method) groups)))
    (hv:html-view :title (hvs::dimmed "Operations") :priority 120
      (hv:html
        (dolist (package-name (sort (loop for key being the hash-keys of groups collect key) #'string<))
          (let* ((methods (gethash package-name groups))
                 (package (hvs::method-package (first methods))))
            (flet ((label (method) (let ((*package* package)) (hvs::method-fn-name method))))
              (hv:html
                (:details
                 :open (hvs::open-package-operations? object package-name)
                 (:summary (hv:esc (string-downcase package-name)))
                 (:table :class "inspector-table"
                  (dolist (method (sort (copy-list methods) #'string< :key #'label))
                    (hv:html
                      (:tr (:td (if (method-invocation-decision method)
                                    (hv:eval-button hvs::*icon-eval*
                                                    (make-instance 'operation-thunk
                                                                   :fn (let ((gf (c2mop:method-generic-function method)))
                                                                         (lambda () (funcall gf object)))
                                                                   :method method :target object)
                                                    "Evaluate")
                                    (hv:esc "·")))
                           (:td (hv:object-ref method :display #'label))
                           (:td (let ((contract (method-contract method)))
                                  (if contract
                                      (hv:object-ref contract :display (%status-text method))
                                      (hv:esc (%status-text method))))))))))))))))))

(hv:defview contract-view (contract operation-contract)
  (hv:html-view :title "Contract" :priority 1
    (hv:html
      (:table :class "inspector-table"
        (loop for (label reader) in '(("Identity" contract-identity) ("Status" contract-status)
                                      ("Operation" contract-operation) ("Applicability" contract-applicability)
                                      ("Effect classes" contract-effect-classes) ("Effect extent" contract-effect-extent)
                                      ("Authority" contract-authority) ("Preconditions" contract-preconditions)
                                      ("Required capability" contract-required-capability)
                                      ("Required permission" contract-required-permission)
                                      ("Execution" contract-execution) ("Postconditions" contract-postconditions)
                                      ("Verification evidence" contract-verification-evidence)
                                      ("Failure modes" contract-failure-modes)
                                      ("Replay semantics" contract-replay-semantics)
                                      ("Audit provenance" contract-audit-provenance))
              do (hv:html (:tr (:td (hv:esc label))
                               (:td (hv:esc (princ-to-string (funcall reader contract)))))))))))

;;;; Disclosure: pathname views and title-bar actions

(defun allowed-disclosure-roots ()
  "Where a served runtime may show the file system: this repository."
  (list (asdf:system-source-directory "dreyeck")))

(defun pathname-disclosure-permitted-p (pathname)
  (or (not (policy-enforced-p))
      (let ((path (or (ignore-errors (truename pathname)) pathname)))
        (some (lambda (root) (uiop:subpathp path (or (ignore-errors (truename root)) root)))
              (allowed-disclosure-roots)))))

(defmacro %define-pathname-disclosure-gate (view)
  `(defmethod ,view :around ((object pathname))
     (when (pathname-disclosure-permitted-p object)
       (call-next-method))))

(%define-pathname-disclosure-gate hvs::👀path)
(%define-pathname-disclosure-gate hvs::👀items)
(%define-pathname-disclosure-gate hvs::👀content)
(%define-pathname-disclosure-gate hvs::👀components)

(defun %withhold-actions (view)
  "VIEW, the upstream action-button view, with its buttons never computed."
  (when (policy-enforced-p)
    (setf (hv:view-html view) "" (hv:view-references view) nil))
  view)

(defmacro %define-action-withholding (class)
  `(defmethod hv:title-bar-action-buttons :around ((object ,class))
     (%withhold-actions (call-next-method))))

(%define-action-withholding pathname)
(%define-action-withholding string)
(%define-action-withholding hyperbook/fedwiki::fedwiki)
(%define-action-withholding hyperbook/fedwiki::fedwiki-page)

;;;; The registered contracts

(register-operation-contract
 :identity "hyperbook:path-item-of on page" :operation 'hyperbook:path-item-of
 :applicability 'hyperbook:page :status :contracted :effect-classes '(:observational)
 :effect-extent "nothing changes: returns the page's path item, its id"
 :authority "the page object's id" :execution "(hyperbook:path-item-of page)"
 :postconditions "the page is unchanged"
 :verification-evidence "reviewed source: hyperbook/hyperbooks.lisp, (:method ((page page)) (id-of page))"
 :failure-modes "none" :replay-semantics "repeatable"
 :audit-provenance "upstream 8a114919, reviewed 2026-09-29 for the method on HYPERBOOK:PAGE only")

(register-operation-contract
 :identity "hyperdoc:load-page" :operation 'hyperdoc:load-page :applicability :any
 :status :unresolved :effect-classes '(:image-local)
 :effect-extent "re-reads the page file and replaces parse tree, id and links; the code-page method EVALs the argument of every HYPERDOC:SEE form found on disk"
 :authority "whatever the page file on disk holds now, which after a deploy is not what the image loaded"
 :audit-provenance "upstream 8a114919 hyperdoc-explorer; dreyeck :AFTER in dreyeck/src/hyperdoc-pages.lisp; invoked on a loopback production witness, 2026-09-29")

(register-operation-contract
 :identity "hyperbook:register" :operation 'hyperbook:register :applicability :any
 :status :unresolved :effect-classes '(:image-local)
 :effect-extent "pushes the book into the Catalog, and the server re-installs its route"
 :audit-provenance "upstream 8a114919 hyperbook/catalog.lisp and hyperbook-server/server.lisp")

(register-operation-contract
 :identity "hyperdoc:asdf-system-of" :operation 'hyperdoc:asdf-system-of :applicability :any
 :status :unresolved :effect-classes '(:observational :image-local)
 :effect-extent "ASDF:FIND-SYSTEM, which re-reads a system's .asd when the file changed on disk"
 :audit-provenance "upstream 8a114919 hyperdoc/core.lisp")

(register-operation-contract
 :identity "fedwiki/reload" :status :unsafe :effect-classes '(:external :image-local)
 :effect-extent "an HTTP request to the wiki's domain, then the page's title, story and journal replaced by the reply"
 :execution "HYPERBOOK/FEDWIKI::RELOAD-PAGE, from a FedWiki page's title bar"
 :audit-provenance "upstream 8a114919 hyperbook-fedwiki/pages.lisp; inherited by dreyeck's local FedWiki pages")

(register-operation-contract
 :identity "fedwiki/open-external" :status :unsafe :effect-classes '(:external)
 :effect-extent "CLOG:OPEN-BROWSER: starts xdg-open on the server"
 :execution "the title bar of a FedWiki book or page"
 :audit-provenance "upstream 8a114919 hyperbook-fedwiki/views.lisp and pages.lisp; inherited by dreyeck's local FedWiki")

(register-operation-contract
 :identity "copy-to-clipboard" :status :unsafe :effect-classes '(:external)
 :effect-extent "TRIVIAL-CLIPBOARD:TEXT: starts a clipboard process on the server"
 :execution "the title bar of any pathname or string"
 :audit-provenance "html-inspector-views 386df893 pathnames.lisp and strings.lisp")

(register-operation-contract
 :identity "page-attached/activation" :status :unsafe :effect-classes '(:persistent :image-local)
 :effect-extent "evaluates a page-attached .asd and loads its system: code that arrived with a page"
 :preconditions "none: no EXECUTION-PERMITTED-P check on this path"
 :execution "DREYECK/FEDWIKI-HYPERDOC:ACTIVATE-LOCAL-FEDWIKI-PAGE-HYPERDOC, from DREYECK/LOCAL-FEDWIKI-PAGE/ACTIVATION-INSPECTOR, which the served Catalog does not load"
 :audit-provenance "dreyeck b915ab08 dreyeck/src/fedwiki-hyperdoc.lisp")

(register-operation-contract
 :identity "operation/change-work-status" :status :contracted :effect-classes '(:persistent)
 :effect-extent "one HTML file: the status value's character range, and nothing else"
 :authority "the exact observed Work Topic declaration, by its source snapshot"
 :preconditions "the request's refusals, checked again when planning; the page is still the plan's snapshot"
 :required-capability :authoring-environment :required-permission :owner
 :execution "DREYECK/WORK/AUTHORING:EXECUTE-WORK-STATUS-CHANGE"
 :postconditions "the file is the verified candidate; the reloaded page shows the status"
 :verification-evidence "candidate verified before installation; installed source reread, and the Topic observed from it"
 :failure-modes "refused before planning; apply refused, nothing written; unverified, installed but not accepted"
 :replay-semantics "refused once applied: the request no longer holds"
 :audit-provenance "dreyeck a4141ca9")

(register-operation-contract
 :identity "operation/create-relationship" :status :contracted :effect-classes '(:persistent)
 :effect-extent "one HTML file: one statement inserted after the last one, and nothing else"
 :authority "the observed page snapshot and both endpoint declarations"
 :preconditions "the request's refusals, including a statement the page already makes, checked again when planning"
 :required-capability :authoring-environment :required-permission :owner
 :execution "DREYECK/WORK/AUTHORING:EXECUTE-WORK-RELATIONSHIP-CREATION"
 :postconditions "the file is the verified candidate; reading it finds exactly one such statement"
 :verification-evidence "candidate verified before installation; the Association and statement observed by rereading"
 :failure-modes "refused; apply refused, nothing written; unverified, installed but not accepted"
 :replay-semantics "refused once applied: the page already states the relationship"
 :audit-provenance "dreyeck 73cc52dd")

;;;; Containment adapters and their drift

(defparameter +containment-adapters+
  '((:point "HTML-INSPECTOR-VIEWS/STANDARD::👀OPERATIONS on T, replaced"
     :system "html-inspector-views" :file "basic.lisp" :form "(defview 👀operations (object t)"
     :sha256 "ec2e38560063869408fa4f46bc42344e0de7d707c155d736501e3594e9d8c771")
    (:point "the Inspector evaluates eval and action references with HV:EVAL-THUNK"
     :system "clog-moldable-inspector" :file "inspector.lisp" :form "(defun eval-thunk-with-active-button"
     :sha256 "49bace4a195dd8d5be5020a44d4cecfd21182ffd81574f93a079e7435b5fc2fe")
    (:point "an action-button view is computed lazily from its thunk"
     :system "html-inspector-views" :file "title-bar.lisp" :form "(defmethod title-bar-action-buttons :around ((object t))"
     :sha256 "38a9d2a07ca7abf8d9a4753b75debe5f3f761dff9ec6aec9a1fb419fc6b5df45")
    (:point "a view's HTML is computed only while its HTML slot is empty"
     :system "html-inspector-views" :file "views.lisp" :form "(defmethod view-html :before ((view html-view))"
     :sha256 "ead88cd43d332099705b8d98ddee322f735bfb52b9c12e3d0a6633987c02289e"))
  "Each upstream point this layer replaces or relies on, with the digest of the
source form as reviewed: html-inspector-views 386df893, clog-moldable-inspector
b369f0a4, the revisions dreyeck's flake pins.")

(defparameter +known-pathname-views+
  '("👀COMPONENTS" "👀PATH" "👀ITEMS" "👀CONTENT")
  "The views with a method on PATHNAME when this layer was reviewed. Each is gated.")

(defparameter +known-title-bar-classes+
  '("LAZY-CELL" "PATHNAME" "STRING" "DIST" "RELEASE" "SYSTEM" "HYPERDOC" "TEXT-PAGE" "FEDWIKI"
    "FEDWIKI-PAGE" "REMOTE-FEDWIKI-PAGE" "WIKIPEDIA-PAGE" "PLAYGROUND-PAGE" "LOCAL-FEDWIKI-PAGE")
  "The classes with a primary title-bar method when this layer was reviewed.")

(defun %form-text (text start)
  "The balanced form in TEXT that starts at START."
  (let ((depth 0) (in-string nil) (i start))
    (loop while (< i (length text))
          do (let ((c (char text i)))
               (cond (in-string (cond ((char= c #\\) (incf i)) ((char= c #\") (setf in-string nil))))
                     ((char= c #\") (setf in-string t))
                     ((char= c #\;) (setf i (or (position #\Newline text :start i) (length text))))
                     ((and (char= c #\#) (< (1+ i) (length text)) (char= (char text (1+ i)) #\\)) (incf i 2))
                     ((char= c #\() (incf depth))
                     ((char= c #\)) (decf depth) (when (zerop depth) (return-from %form-text (subseq text start (1+ i)))))))
             (incf i))))

(defun %source-form-digest (system file form)
  (let* ((path (merge-pathnames file (asdf:system-source-directory system)))
         (text (and (probe-file path) (uiop:read-file-string path :external-format :utf-8)))
         (start (and text (search form text))))
    (and start
         (ironclad:byte-array-to-hex-string
          (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets (%form-text text start) :external-format :utf-8))))))

(defun containment-adapter-drift (&optional (adapters +containment-adapters+))
  "Each adapted upstream point that no longer matches what was reviewed, and each
new pathname view or title-bar class that nothing here has reviewed. NIL when
everything is as reviewed."
  (append
   (loop for adapter in adapters
         for digest = (%source-form-digest (getf adapter :system) (getf adapter :file) (getf adapter :form))
         unless (equal digest (getf adapter :sha256))
           collect (list :point (getf adapter :point) :expected (getf adapter :sha256) :found digest))
   (loop for view in hv::*view-functions*
         when (and (fboundp view)
                   (find (find-class 'pathname) (c2mop:generic-function-methods (fdefinition view))
                         :key (lambda (m) (first (c2mop:method-specializers m))))
                   (not (member (symbol-name view) +known-pathname-views+ :test #'string=)))
           collect (list :point (format nil "new pathname view ~S" view)))
   (loop for method in (c2mop:generic-function-methods #'hv:title-bar-action-buttons)
         for class = (first (c2mop:method-specializers method))
         when (and (null (method-qualifiers method)) (typep class 'class) (not (eq class (find-class t)))
                   (not (member (symbol-name (class-name class)) +known-title-bar-classes+ :test #'string=)))
           collect (list :point (format nil "new title-bar actions on ~S" (class-name class))))))
