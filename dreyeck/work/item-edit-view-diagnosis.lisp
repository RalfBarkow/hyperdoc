;;;; Reading the diagnosis of the missing Edit view of Story Item E3
(defpackage #:dreyeck/work/item-edit-view-diagnosis
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:v #:html-inspector-views))
  (:export #:read-diagnosis #:diagnosis #:diagnosis-findings #:diagnosis-observations
           #:diagnosis-sources #:diagnosis-closure #:diagnosis-e3 #:diagnosis-availability
           #:finding #:finding-id #:finding-epistemic #:finding-statement #:finding-basis
           #:finding-evidence #:finding-limit
           #:runtime-observation #:observation-id #:observation-phase #:observation-sequence
           #:observation-text #:observation-parsed #:observation-provenance
           #:source-observation #:source-id #:source-line #:source-file #:source-digest
           #:load-closure #:closure-root #:closure-systems #:closure-contains-p
           #:current-availability #:availability-state #:availability-live-page
           #:system-load-closure #:diagnosis-source-error #:+operator-observations+))
(in-package #:dreyeck/work/item-edit-view-diagnosis)
(hyperdoc:see (hyperdoc:page "Authoring the CTM Plan Page" :hyperbook "dreyeck/work/reading"))

;; The diagnosis of why Story Item E3 had no Edit tab. It states nothing the
;; reader cannot follow back: every finding names the objects or the supplied
;; observations it rests on. Source is read from disk; the load closure is
;; computed from the ASDF definitions registered in this image; what the
;; operator saw in a running image is kept as supplied, apart from what this
;; image shows now. Reading it loads no system, evaluates no operator
;; expression, records no Evaluation Record and writes nothing.

(defparameter +retained-e3-page-sha+
  "d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff")
(defparameter +e3-id+ "ed37e9bac2fcd548")
(defparameter +slug+ "ctm-and-tmdm-in-hyperdoc")
(defparameter +preview-system+ "dreyeck/fedwiki-item-edit-preview")
(defparameter +catalog-system+ "dreyeck/catalog-application")
(defparameter +preview-package+ "DREYECK/FEDWIKI-ITEM-EDIT-PREVIEW")
(defparameter +writer-package+ "DREYECK/FEDWIKI-PAGE-AUTHORING")
(defparameter +epistemic-classes+ '(:observed :derived :inferred :hypothesized :unresolved))

(define-condition diagnosis-source-error (error)
  ((reason :initarg :reason :reader source-error-reason))
  (:report (lambda (condition stream)
             (format stream "E3 edit-view diagnosis refused: ~A" (source-error-reason condition)))))
(defun refuse (control &rest arguments)
  (error 'diagnosis-source-error :reason (apply #'format nil control arguments)))

;;; What the operator supplied

(defparameter +operator-provenance+
  '(:kind :operator-supplied
    :observation-time :not-supplied
    :expression :not-supplied
    :remote-id :not-supplied
    :evaluation-record :none
    :channel "typed into the Claude Code conversation by the operator, from the SLY mREPL of the running image; the original transcript was not supplied"
    :runtime (:image "SBCL 2.4.10 started by `nix develop -c hyperdoc-sly`, SLY/Slynk on 127.0.0.1"
              :branch "codex/conversation-coordinates-delivery"
              :commit "aabbb983cbaaf713e7406856d853694c5166d5ef"
              :mode ":development t"
              :source "start banner as reported by the operator"))
  "What every operator-supplied observation shares. None was recorded by a hook:
times, the evaluated expressions and remote ids were not supplied and are not invented.")

(defparameter +operator-observations+
  '((:id "before-1" :phase :before :sequence 1 :kind :output
     :text "(:SYSTEM-KNOWN T :SYSTEM-LOADED NIL
 :PACKAGE NIL :WRITER-LOADED NIL)")
    (:id "before-2" :phase :before :sequence 2 :kind :output
     :text "(:REGISTERED NIL :METHODS NIL)")
    (:id "before-3" :phase :before :sequence 3 :kind :output
     :text "(:SYSTEM-KNOWN T :SYSTEM-LOADED NIL
 :VIEW-REGISTERED NIL
 :WRITER-PACKAGE-PRESENT NIL)")
    (:id "load" :phase :action :sequence 4 :kind :action
     :text "(asdf:load-system \"dreyeck/fedwiki-item-edit-preview\")")
    (:id "load-warnings" :phase :after :sequence 5 :kind :event
     :text "Several redefinition warnings, among them a package warning for DREYECK/WORK/READING. Their wording was not supplied.")
    (:id "after-1" :phase :after :sequence 6 :kind :output
     :text "(:SYSTEM-LOADED T
 :VIEW-REGISTERED T
 :WRITER-LOADED NIL)"))
  "In the order the operator reported them. The sequence numbers order the
report; they are not clock times.")

;;; Source the claims rest on, found on disk and checked against this image

(defparameter +source-specs+
  '((:id "src-catalog-application" :file "dreyeck.asd"
     :marker "(defsystem \"dreyeck/catalog-application\""
     :system "dreyeck/catalog-application"
     :declares ("dreyeck/local-fedwiki-view" "clack-handler-hunchentoot" "uiop")
     :statement "The ASDF system dreyeck/catalog-application declares three dependencies; the preview system is none of them.")
    (:id "src-preview-system" :file "dreyeck.asd"
     :marker "(defsystem \"dreyeck/fedwiki-item-edit-preview\""
     :system "dreyeck/fedwiki-item-edit-preview"
     :declares ("dreyeck/fedwiki-page-edit-plan" "dreyeck/local-fedwiki-view" "html-inspector-views"
                "html-inspector-views/reactive" "lwcells" "shasht")
     :statement "The preview system declares its own dependencies, among them neither the page-authoring writer nor a capability.")
    (:id "src-defview" :file "dreyeck/src/fedwiki-item-edit-preview.lisp"
     :marker "(v:defview story-item-edit-offer (item lp:local-story-item)"
     :statement "The view story-item-edit-offer, titled Edit, is defined for LOCAL-STORY-ITEM in the preview system's source and nowhere else.")
    (:id "src-additive-load" :file "dreyeck/src/catalog-application.lisp"
     :marker "(asdf:load-system catalog-system)"
     :statement "START-CATALOG loads an additional system only when CATALOG-SYSTEM differs from the default; nothing else loads the preview system.")
    (:id "src-white-image" :file "scripts/hyperdoc-slynk.lisp"
     :marker ";;; One fresh, editor-independent white image. No application systems are loaded."
     :statement "The SLY launcher starts a white image; it loads no application system, so the Catalog's closure is loaded only when START-CATALOG or an operator does so.")
    (:id "src-activation-default" :file "scripts/test-item-edit-preview-activation.mjs"
     :marker "assert.equal(await last().getByRole('button',{name:'Edit',exact:true}).count(),0)"
     :statement "The controlled test added by commit 44ebc23a starts a default Catalog and asserts that E3 has no Edit button.")
    (:id "src-activation-activated" :file "scripts/test-item-edit-preview-activation.mjs"
     :marker "await tab('Edit');await last().getByText('Prepare edit proposal',{exact:true}).first().click()"
     :statement "The same test starts a Catalog with HYPERDOC_CATALOG_SYSTEM=dreyeck/fedwiki-item-edit-preview and follows E3, Edit, Prepare edit proposal to the Preview."))
  "File, a marker that occurs exactly once in it, and for systems the
dependencies its definition declares in the image.")

(defun repo-file (relative)
  (asdf:system-relative-pathname "dreyeck/work/reading" relative))
(defun file-text (path) (uiop:read-file-string path :external-format :utf-8))
(defun file-digest (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

;;; Objects

(defclass diagnosis ()
  ((findings :initarg :findings :reader diagnosis-findings)
   (observations :initarg :observations :reader diagnosis-observations)
   (sources :initarg :sources :reader diagnosis-sources)
   (closure :initarg :closure :reader diagnosis-closure)
   (e3 :initarg :e3 :reader diagnosis-e3)
   (availability :initarg :availability :reader diagnosis-availability))
  (:documentation "One reading of the E3 edit-view diagnosis: findings with the
objects and supplied observations each rests on, and this image's present state."))

(defclass finding ()
  ((id :initarg :id :reader finding-id)
   (epistemic :initarg :epistemic :reader finding-epistemic)
   (statement :initarg :statement :reader finding-statement)
   (basis :initarg :basis :initform nil :accessor finding-basis)
   (evidence :initarg :evidence :initform nil :reader finding-evidence)
   (claim :initarg :claim :initform nil :reader finding-claim)
   (context :initarg :context :reader finding-context)
   (limit :initarg :limit :initform nil :reader finding-limit)))

(defclass runtime-observation ()
  ((id :initarg :id :reader observation-id)
   (phase :initarg :phase :reader observation-phase)
   (sequence :initarg :sequence :reader observation-sequence)
   (kind :initarg :kind :reader observation-kind)
   (text :initarg :text :reader observation-text)
   (parsed :initarg :parsed :reader observation-parsed)
   (provenance :initarg :provenance :reader observation-provenance))
  (:documentation "One operator-supplied observation from a running image, verbatim.
It is not an Evaluation Record and says nothing about the image as it is now."))

(defclass source-observation ()
  ((id :initarg :id :reader source-id)
   (file :initarg :file :reader source-file)
   (line :initarg :line :reader source-line)
   (digest :initarg :digest :reader source-digest)
   (marker :initarg :marker :reader source-marker)
   (statement :initarg :statement :reader source-statement)
   (system :initarg :system :initform nil :reader source-system)
   (declares :initarg :declares :initform nil :reader source-declares)))

(defclass load-closure ()
  ((root :initarg :root :reader closure-root)
   (systems :initarg :systems :reader closure-systems)
   (missing :initarg :missing :reader closure-missing)
   (definition-file :initarg :definition-file :reader closure-definition-file)
   (definition-digest :initarg :definition-digest :reader closure-definition-digest))
  (:documentation "The systems ASDF would load for ROOT, from the definitions
registered in this image. Computed without loading anything."))

(defclass e3-observation (work:work-fedwiki-item-observation) ()
  (:documentation "Story Item E3 as the retained local copy of the page holds it."))

(defclass availability ()
  ((state :initarg :state :reader availability-state)
   (time :initarg :time :reader availability-time)
   (objects :initarg :objects :reader availability-objects)
   (live-page :initarg :live-page :reader availability-live-page))
  (:documentation "What this image has now. A reading of the present, taken while
the diagnosis was read; it is not what the operator observed."))

(defmethod v:text-representation ((diagnosis diagnosis)) "E3 edit-view diagnosis")
(defmethod v:text-representation ((finding finding))
  (format nil "~(~A~) ~A" (finding-epistemic finding) (finding-id finding)))
(defmethod v:text-representation ((observation runtime-observation))
  (format nil "Operator-supplied ~(~A~): ~A" (observation-phase observation) (observation-id observation)))
(defmethod v:text-representation ((source source-observation))
  (format nil "Source ~A:~D" (source-file source) (source-line source)))
(defmethod v:text-representation ((closure load-closure))
  (format nil "Load closure of ~A (~D systems)" (closure-root closure) (length (closure-systems closure))))
(defmethod v:text-representation ((observation e3-observation)) "E3 in the retained copy of the page")
(defmethod v:text-representation ((availability availability)) "This image now")

;;; Load closure, from definitions only

(defun %dependency-names (system)
  (loop for dependency in (asdf:system-depends-on system)
        for name = (cond ((stringp dependency) dependency)
                         ((symbolp dependency) (string-downcase (symbol-name dependency)))
                         ((and (consp dependency) (eq (first dependency) :version)) (second dependency)))
        when name collect name))

(defun system-load-closure (root)
  "The LOAD-CLOSURE of the system ROOT. FIND-SYSTEM reads a definition and loads no
code. Systems no definition is found for are kept apart; none is invented."
  (let ((seen (make-hash-table :test 'equal)) (missing nil)
        (definition (asdf:find-system root nil)))
    (unless definition (refuse "no definition of ~A is registered in this image" root))
    (labels ((visit (name)
               (unless (gethash name seen)
                 (setf (gethash name seen) t)
                 (let ((system (asdf:find-system name nil)))
                   (if system (mapc #'visit (%dependency-names system)) (push name missing))))))
      (visit root))
    (let ((file (asdf:system-source-file definition)))
      (make-instance 'load-closure
                     :root root
                     :systems (sort (loop for name being the hash-keys of seen collect name) #'string<)
                     :missing (sort missing #'string<)
                     :definition-file file :definition-digest (and file (file-digest file))))))

(defun closure-contains-p (closure system) (and (member system (closure-systems closure) :test #'equal) t))

;;; Reading

(defun %locate (text marker file)
  (let ((at (search marker text)))
    (unless at (refuse "~S does not occur in ~A" marker file))
    (when (search marker text :start2 (1+ at)) (refuse "~S occurs more than once in ~A" marker file))
    (1+ (count #\Newline text :end at))))

(defun read-source-observation (spec)
  (destructuring-bind (&key id file marker statement system declares) spec
    (let* ((path (repo-file file))
           (line (%locate (file-text path) marker file)))
      (when system
        (let ((definition (asdf:find-system system nil)))
          (unless definition (refuse "~A has no definition registered in this image" system))
          (unless (equal declares (%dependency-names definition))
            (refuse "~A declares ~S in this image, not the observed ~S" system (%dependency-names definition) declares))))
      (make-instance 'source-observation :id id :file file :line line :digest (file-digest path)
                     :marker marker :statement statement :system system :declares declares))))

(defun parse-output (text)
  "The plist OPERATOR-SUPPLIED output TEXT prints. Data only: nothing is evaluated."
  (let ((*read-eval* nil) (*package* (find-package "COMMON-LISP-USER")))
    (let ((value (read-from-string text)))
      (and (listp value) (evenp (length value)) value))))

(defun read-runtime-observation (spec)
  (destructuring-bind (&key id phase sequence kind text) spec
    (make-instance 'runtime-observation :id id :phase phase :sequence sequence :kind kind :text text
                   :parsed (and (eq kind :output) (parse-output text))
                   :provenance +operator-provenance+)))

(defun %observation (observations id)
  (or (find id observations :key #'observation-id :test #'equal) (refuse "no observation ~A" id)))
(defun %value (observation key)
  (loop for (indicator value) on (observation-parsed observation) by #'cddr
        when (eq indicator key) do (return value)
        finally (refuse "~A states no ~S" (observation-id observation) key)))

(defun %e3-observation ()
  (let* ((path (repo-file "dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json"))
         (json (shasht:read-json (uiop:read-file-string path :external-format :utf-8)))
         (story (gethash "story" json))
         (matches (remove +e3-id+ story :key (lambda (item) (gethash "id" item)) :test-not #'equal)))
    (unless (equal +retained-e3-page-sha+ (file-digest path)) (refuse "the retained copy of the page differs from revision ~A" +retained-e3-page-sha+))
    (unless (= 1 (length matches)) (refuse "the retained copy holds E3 ~D times" (length matches)))
    (change-class (work:observe-work-fedwiki-item "localhost:3000" +slug+ (aref matches 0)) 'e3-observation)))

;;; The present state of this image

(defun %symbol (name package-name)
  (let ((package (find-package package-name)))
    (and package (find-symbol name package))))

(defun %live-page (site-root)
  "E3 on the page file at SITE-ROOT, read now, or why that is not possible. Reads only."
  (handler-case
      (let* ((observe (%symbol "OBSERVE-LOCAL-FEDWIKI-PAGE-SOURCE" "DREYECK/LOCAL-FEDWIKI-PAGE"))
             (sha (%symbol "PAGE-SOURCE-SHA256" "DREYECK/LOCAL-FEDWIKI-PAGE"))
             (json (%symbol "PAGE-SOURCE-JSON" "DREYECK/LOCAL-FEDWIKI-PAGE"))
             (root (or site-root
                       (let ((configured (%symbol "CONFIGURED-SITE-ROOT" "DREYECK/LOCAL-FEDWIKI-VIEW")))
                         (and configured (funcall configured))))))
        (cond ((not (and observe sha json)) (list :state :unavailable :reason "the local page-source reader is not in this image"))
              ((null root) (list :state :unavailable :reason "no site root is configured"))
              (t (let* ((source (funcall observe root +slug+))
                        (story (coerce (or (gethash "story" (funcall json source)) (vector)) 'list))
                        (item (find +e3-id+ story :key (lambda (item) (gethash "id" item)) :test #'equal)))
                   (list :state :available :site-root (namestring root) :sha256 (funcall sha source)
                         :same-revision-as-retained (equal (funcall sha source) +retained-e3-page-sha+)
                         :e3-present (and item t) :items (length story))))))
    (error (condition) (list :state :unavailable :reason (princ-to-string condition)))))

(defun current-availability (&key (site-root nil))
  "What this image holds now of each object the diagnosis is about. Loads nothing."
  (let* ((preview-system (asdf:find-system +preview-system+ nil))
         (catalog-system (asdf:find-system +catalog-system+ nil))
         (view-symbol (%symbol "STORY-ITEM-EDIT-OFFER" +preview-package+))
         (view-functions (%symbol "*VIEW-FUNCTIONS*" "HTML-INSPECTOR-VIEWS"))
         (generic (and view-symbol (fboundp view-symbol) (fdefinition view-symbol)))
         (proposal (let ((s (%symbol "ITEM-EDIT-PROPOSAL" +preview-package+))) (and s (find-class s nil))))
         (preview (let ((s (%symbol "ITEM-EDIT-PREVIEW" +preview-package+))) (and s (find-class s nil)))))
    (make-instance
     'availability
     :time (get-universal-time)
     :live-page (%live-page site-root)
     :state (list :preview-system-known (and preview-system t)
                  :preview-system-loaded (and preview-system (asdf:component-loaded-p preview-system) t)
                  :preview-package (and (find-package +preview-package+) t)
                  :view-function-bound (and generic t)
                  :view-registered (and view-symbol view-functions (boundp view-functions)
                                        (member view-symbol (symbol-value view-functions)) t)
                  :view-methods (and generic (length (sb-mop:generic-function-methods generic)))
                  :proposal-class (and proposal t) :preview-class (and preview t)
                  :writer-package (and (find-package +writer-package+) t)
                  :catalog-application-known (and catalog-system t)
                  :catalog-application-loaded (and catalog-system (asdf:component-loaded-p catalog-system) t))
     :objects (list :preview-system preview-system :catalog-application catalog-system
                    :generic-function generic :proposal-class proposal :preview-class preview))))

;;; The findings

(defun %finding (id epistemic statement context &key basis evidence claim limit)
  (make-instance 'finding :id id :epistemic epistemic :statement statement :context context
                          :basis basis :evidence evidence :claim claim :limit limit))

(defun check-closure-claim (closure excluded)
  "EXCLUDED, a system the Catalog is claimed not to load, if CLOSURE does not contain it."
  (when (closure-contains-p closure excluded)
    (refuse "~A is in the load closure of ~A; it cannot be claimed excluded" excluded (closure-root closure)))
  excluded)

(defun %checked-state-change (observations)
  "Refuse unless the supplied OBSERVATIONS show the Edit view absent before and present after."
  (unless (and (null (%value (%observation observations "before-1") :system-loaded))
               (null (%value (%observation observations "before-2") :registered))
               (null (%value (%observation observations "before-3") :view-registered))
               (eq t (%value (%observation observations "after-1") :system-loaded))
               (eq t (%value (%observation observations "after-1") :view-registered))
               (null (%value (%observation observations "after-1") :writer-loaded)))
    (refuse "the supplied observations do not show the view absent before and present after the load")))

(defun build-findings (closure sources observations e3 excluded)
  (let* ((by-id (lambda (id) (or (find id sources :key #'source-id :test #'equal) (refuse "no source ~A" id))))
         (obs (lambda (id) (%observation observations id)))
         (source-context (format nil "files of this checkout; ~A has SHA-256 ~A" "dreyeck.asd" (closure-definition-digest closure)))
         (operator-context "the operator's running image before and after its explicit load; no clock time was supplied")
         (list nil))
    (flet ((add (finding) (push finding list) finding))
      (let* ((s-catalog (add (%finding "observed-catalog-dependencies" :observed
                                      (source-statement (funcall by-id "src-catalog-application"))
                                      source-context :evidence (list (funcall by-id "src-catalog-application")))))
             (s-preview (add (%finding "observed-preview-system" :observed
                                      (source-statement (funcall by-id "src-preview-system"))
                                      source-context :evidence (list (funcall by-id "src-preview-system")))))
             (s-defview (add (%finding "observed-view-definition" :observed
                                      (source-statement (funcall by-id "src-defview"))
                                      source-context :evidence (list (funcall by-id "src-defview")))))
             (s-additive (add (%finding "observed-additive-loading" :observed
                                       (source-statement (funcall by-id "src-additive-load"))
                                       source-context :evidence (list (funcall by-id "src-additive-load")))))
             (s-white (add (%finding "observed-white-image-start" :observed
                                    (source-statement (funcall by-id "src-white-image"))
                                    source-context :evidence (list (funcall by-id "src-white-image")))))
             (r-before (add (%finding "observed-before-loading" :observed
                                     "Before the explicit load the operator saw the preview system known but not loaded, its package absent, the view not registered and no writer loaded."
                                     operator-context :evidence (mapcar obs '("before-1" "before-2" "before-3"))
                                     :limit "Operator-supplied output; the evaluated expressions and times were not supplied.")))
             (r-load (add (%finding "observed-explicit-load" :observed
                                   "The operator loaded the preview system explicitly with asdf:load-system."
                                   operator-context :evidence (list (funcall obs "load")))))
             (r-warnings (add (%finding "observed-load-warnings" :observed
                                       "The load produced several redefinition warnings, among them a package warning for DREYECK/WORK/READING."
                                       operator-context :evidence (list (funcall obs "load-warnings"))
                                       :limit "The wording of the warnings was not supplied; their meaning is not established.")))
             (r-after (add (%finding "observed-after-loading" :observed
                                    "After the load the operator saw the preview system loaded, the view registered and still no writer loaded."
                                    operator-context :evidence (list (funcall obs "after-1")))))
             (e3-finding (add (%finding "observed-e3-in-retained-copy" :observed
                                       "The retained local copy of the page, revision d7215c50, holds E3 (ed37e9bac2fcd548) as the eleventh of 18 Items, a paragraph."
                                       "the repository's retained copy of the page; not the page file of any running wiki"
                                       :evidence (list e3))))
             (d-closure (add (%finding "derived-preview-not-in-catalog-closure" :derived
                                      (format nil "The preview system is not in the load closure of ~A: ~D systems are, from the definitions registered in this image."
                                              (closure-root closure) (length (closure-systems closure)))
                                      "computed when this diagnosis was read, from the ASDF definitions registered in this image"
                                      :basis (list s-catalog s-preview) :evidence (list closure)
                                      :claim (list :excludes (check-closure-claim closure excluded) :from (closure-root closure))
                                      :limit "defsystem-depends-on and in-order-to are not part of a load closure and were not followed.")))
             (d-change (add (%finding "derived-registration-changed-across-load" :derived
                                     "The view was not registered before the explicit load and was registered after it, while the writer stayed unloaded."
                                     "two operator-supplied states of one running image, in the reported order"
                                     :basis (list r-before r-load r-after)
                                     :claim (list :view-registered :nil-to-t)
                                     :limit "One before/after pair; the load did more than register this view.")))
             (i-cause (add (%finding "inferred-edit-view-absent-because-system-not-loaded" :inferred
                                    "The Edit view was missing from the observed image because the preview system had not been loaded, not because a policy withheld a registered view."
                                    "inference from the closure, the view definition, one before/after pair and the controlled test of commit 44ebc23a"
                                    :basis (list d-closure d-change s-defview s-additive s-white)
                                    :evidence (mapcar by-id '("src-activation-default" "src-activation-activated"))
                                    :limit "The Inspector image that showed the missing tab is not established to be the observed one; the policy for the Preview action was not observed.")))
             (h-warnings (add (%finding "hypothesized-redefinition-warnings" :hypothesized
                                       "The redefinition warnings arose because loading re-evaluated definitions already present in the image, for example where the loaded definitions or compiled files differ from the current source."
                                       "untested"
                                       :limit "No comparison of the image's definitions with the source was made; the warnings are not read.")))
             (u-image (add (%finding "unresolved-screenshot-image" :unresolved
                                    "Whether the Inspector that showed no Edit tab ran in the image whose state was observed."
                                    "not established" :limit "Needs the identity of the image of the screenshot.")))
             (u-browser (add (%finding "unresolved-browser-check" :unresolved
                                      "Whether E3 now offers the Edit tab in the browser, and the path Prepare edit proposal, Edit proposal, Preview."
                                      "not yet observed" :limit "Needs the operator's observation in the running Inspector.")))
             (u-warnings (add (%finding "unresolved-warning-meaning" :unresolved
                                       "What the redefinition warnings and the package warning for DREYECK/WORK/READING mean."
                                       "not established" :limit "Needs the wording of the warnings.")))
             (u-originals (add (%finding "unresolved-original-transcripts" :unresolved
                                        "The evaluated expressions, their times and the original mREPL transcripts."
                                        "not supplied" :limit "Needs the original transcripts; none are reconstructed from the summaries.")))
             (all (reverse list)))
        (declare (ignorable r-warnings e3-finding h-warnings u-image u-browser u-warnings u-originals i-cause))
        all))))

(defun validate-diagnosis (diagnosis)
  "DIAGNOSIS if each finding stands on what its class requires and nothing else."
  (let ((seen nil))
    (dolist (finding (diagnosis-findings diagnosis))
      (unless (member (finding-epistemic finding) +epistemic-classes+)
        (refuse "~A has the unknown class ~S" (finding-id finding) (finding-epistemic finding)))
      (when (find (finding-id finding) seen :key #'finding-id :test #'equal)
        (refuse "~A occurs twice" (finding-id finding)))
      (ecase (finding-epistemic finding)
        (:observed
         (when (finding-basis finding) (refuse "observed ~A rests on a finding" (finding-id finding)))
         (unless (finding-evidence finding) (refuse "observed ~A names no observation" (finding-id finding))))
        ((:derived :inferred)
         (unless (finding-basis finding) (refuse "~(~A~) ~A names no basis" (finding-epistemic finding) (finding-id finding)))
         (dolist (basis (finding-basis finding))
           (unless (member basis seen :test #'eq) (refuse "~A rests on ~A, which is not an earlier finding" (finding-id finding) (finding-id basis)))
           (when (member (finding-epistemic basis) '(:hypothesized :unresolved))
             (refuse "~A rests on the ~(~A~) ~A" (finding-id finding) (finding-epistemic basis) (finding-id basis)))
           (when (and (eq :derived (finding-epistemic finding)) (eq :inferred (finding-epistemic basis)))
             (refuse "derived ~A rests on the inferred ~A" (finding-id finding) (finding-id basis)))))
        ((:hypothesized :unresolved)
         (when (finding-basis finding) (refuse "~(~A~) ~A claims a basis" (finding-epistemic finding) (finding-id finding)))))
      (dolist (item (finding-evidence finding))
        (when (and (typep item 'runtime-observation)
                   (not (eq :operator-supplied (getf (observation-provenance item) :kind))))
          (refuse "~A is not operator-supplied" (observation-id item))))
      (push finding seen))
    diagnosis))

(defun read-diagnosis (&key (operator-observations +operator-observations+)
                            (excluded +preview-system+) (site-root nil))
  "A fresh reading: the source found on disk, the closure computed from this
image's definitions, the supplied observations as given, and this image's state now.
Loads no system and writes nothing; SITE-ROOT names the page store to look at for E3."
  (let* ((closure (system-load-closure +catalog-system+))
         (sources (mapcar #'read-source-observation +source-specs+))
         (observations (mapcar #'read-runtime-observation operator-observations))
         (e3 (%e3-observation)))
    (%checked-state-change observations)
    (validate-diagnosis
     (make-instance 'diagnosis :findings (build-findings closure sources observations e3 excluded)
                               :observations observations :sources sources :closure closure :e3 e3
                               :availability (current-availability :site-root site-root)))))

;;; Inspection

(defun ref (object &optional label select)
  (v:html (v:object-ref object :display (or label (v:text-representation object)) :select select)))
(defun time-string (universal-time)
  (multiple-value-bind (second minute hour day month year) (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" year month day hour minute second)))
(defun diagnosis-links (diagnosis)
  (v:html (:p (ref diagnosis "Diagnosis" "Diagnosis") " / "
              (ref (diagnosis-availability diagnosis) "This image now" "Image now") " / "
              (ref (diagnosis-closure diagnosis) "Load closure" "Load closure"))))
(defvar *diagnosis-of* (make-hash-table :test 'eq :weakness :key)
  "The diagnosis each of its parts belongs to, so a view can lead back to it.")
(defun remember (diagnosis)
  (dolist (part (append (diagnosis-findings diagnosis) (diagnosis-observations diagnosis)
                        (diagnosis-sources diagnosis)
                        (list (diagnosis-closure diagnosis) (diagnosis-e3 diagnosis)
                              (diagnosis-availability diagnosis))))
    (setf (gethash part *diagnosis-of*) diagnosis))
  diagnosis)
(defun owner (part) (gethash part *diagnosis-of*))

(v:defview work-topic-e3-diagnosis (topic work:work-topic)
  (when (equal "ctm-plan-page-authoring" (tm:topicmap-topic-id-of topic))
    (v:html-view :title "E3 edit-view diagnosis" :priority 998
      (let ((diagnosis (remember (read-diagnosis))))
        (v:html (:h2 "Diagnosis of the missing Edit tab")
          (:p "The question, a provisional explanation, the evidence, what would refute it and the next observation. Opening it loads no system.")
          (:p (ref diagnosis "Open the diagnosis" "Diagnosis")))))))

(defparameter +measurement-labels+
  '((:system-known "Preview system known to ASDF") (:system-loaded "Preview system loaded")
    (:package "Preview package present") (:view-registered "Edit view registered")
    (:registered "Edit view registered (probe key REGISTERED)") (:methods "Methods found")
    (:writer-loaded "Page-authoring writer loaded") (:writer-package-present "Writer package present")))

(defun comparison-rows (observations)
  "One (KEY BEFORE AFTER) row per measurement key the supplied outputs name, in
first-seen order. BEFORE and AFTER hold (OBSERVATION . VALUE), in reported order. A key
is compared only with itself: keys that look alike stay separate rows."
  (let ((rows nil))
    (dolist (observation (sort (copy-list observations) #'< :key #'observation-sequence))
      (when (and (eq :output (observation-kind observation)) (member (observation-phase observation) '(:before :after)))
        (loop for (key value) on (observation-parsed observation) by #'cddr
              do (let ((row (or (find key rows :key #'first)
                                (let ((new (list key nil nil))) (setf rows (append rows (list new))) new))))
                   (if (eq :before (observation-phase observation))
                       (setf (second row) (append (second row) (list (cons observation value))))
                       (setf (third row) (append (third row) (list (cons observation value)))))))))
    rows))

(defun value-text (value) (cond ((eq value t) "Yes") ((null value) "No") (t (prin1-to-string value))))
(defun comparison-text (before after)
  (flet ((values-of (entries) (remove-duplicates (mapcar (lambda (entry) (value-text (cdr entry))) entries) :test #'equal)))
    (cond ((and before after)
           (if (equal (values-of before) (values-of after))
               (format nil "unchanged: ~{~A~^ / ~}" (values-of before))
               (format nil "~{~A~^ / ~} → ~{~A~^ / ~}" (values-of before) (values-of after))))
          (before "measured only before loading; nothing to compare")
          (t "measured only after loading; nothing to compare"))))
(defun measurement-cell (entries)
  (if (null entries)
      (v:html (:em "not measured"))
      (v:html (dolist (entry entries)
                (v:html (v:esc (value-text (cdr entry))) " (" (ref (car entry) (observation-id (car entry)) "Observation") ") ")))))

(defun %part (parts id key)
  (or (find id parts :key key :test #'equal) (refuse "the diagnosis holds no ~A" id)))

(v:defview diagnosis-overview (diagnosis diagnosis)
  (v:html-view :title "Diagnosis" :priority 0
    (remember diagnosis)
    (let* ((findings (diagnosis-findings diagnosis))
           (sources (diagnosis-sources diagnosis))
           (observations (diagnosis-observations diagnosis))
           (closure (diagnosis-closure diagnosis)))
      (flet ((finding-ref (id label) (ref (%part findings id #'finding-id) label "Finding"))
             (source-ref (id label) (ref (%part sources id #'source-id) label "Source"))
             (observation-ref (id label) (ref (%part observations id #'observation-id) label "Observation")))
        (v:html
          (:h2 "Why was E3's Edit tab missing?")
          (:h3 "Question")
          (:p "Story Item " (:code "E3") " (a paragraph, ID " (:code "ed37e9bac2fcd548") ") of the Federated Wiki page "
              (:code "ctm-and-tmdm-in-hyperdoc") " could be inspected in HyperDoc, but the Inspector offered no "
              (:strong "Edit") " tab for it. Why?")
          (:h3 "Explanation (provisional)")
          (:p "The Edit view is defined in the optional ASDF system " (:code "dreyeck/fedwiki-item-edit-preview")
              ". That system is not in the load closure of the normal Catalog (" (:code "dreyeck/catalog-application")
              "), so an image started the ordinary way has no Edit view for a Story Item.")
          (:p "Check it yourself: " (source-ref "src-preview-system" "the preview system's definition") "; "
              (source-ref "src-catalog-application" "the Catalog's declared dependencies") "; "
              (source-ref "src-defview" "where the Edit view is defined") "; "
              (ref closure "the computed load closure" "Load closure") "; "
              (finding-ref "derived-preview-not-in-catalog-closure" "how the exclusion is derived") ".")
          (:p (:strong "Provisional for the original browser observation. ")
              "This explains the missing tab only if the Inspector that showed no Edit tab ran in an image without the preview system. "
              "Which image that was is not established ("
              (finding-ref "unresolved-screenshot-image" "open question: which image?") "). "
              "The inference and its limits: "
              (finding-ref "inferred-edit-view-absent-because-system-not-loaded" "why this is an inference, not an observation") ".")
          (:h3 "Evidence")
          (:h4 "1. Operator observations from one running image (historical)")
          (:p "Typed in by the operator from the SLY mREPL. The evaluated expressions, times and remote IDs were not supplied, and these are not automatically captured Evaluation Records. "
              "Only measurements of the same kind are compared; keys that look alike, such as the two writer keys, are separate rows.")
          (:table :class "inspector-table"
            (:tr (:th "Measurement") (:th "Before loading") (:th "After loading") (:th "Comparison"))
            (dolist (row (comparison-rows observations))
              (destructuring-bind (key before after) row
                (v:html (:tr (:td (v:esc (or (second (assoc key +measurement-labels+)) (symbol-name key))) " " (:code (v:esc (symbol-name key))))
                             (:td (measurement-cell before)) (:td (measurement-cell after))
                             (:td (v:esc (comparison-text before after))))))))
          (:p "Between the two states the operator loaded the system explicitly ("
              (observation-ref "load" "the asdf:load-system call") "). The load produced warnings ("
              (observation-ref "load-warnings" "reported; wording not supplied") ").")
          (:h4 "2. Controlled test from commit 44ebc23a (historical, run separately)")
          (:p "Commit 44ebc23a added a script that starts a served Catalog on a copy of the retained page. Its source asserts that "
              "on a default Catalog E3 has no Edit button, and that with "
              (:code "HYPERDOC_CATALOG_SYSTEM=dreyeck/fedwiki-item-edit-preview") " E3 offers Edit and the path Prepare edit proposal, Edit proposal, Preview works, with the page file unchanged and no writer loaded. "
              "It was run when the commit was made. It was " (:strong "not run in this session") " and was not run against the image in question. "
              "Inspect its source: " (source-ref "src-activation-default" "the check on the default Catalog") "; "
              (source-ref "src-activation-activated" "the check on the activated Catalog") ".")
          (:h3 "Falsification")
          (:p "The explanation is not sufficient for the concrete Inspector if either of these is observed:")
          (:ul
            (:li "In an Inspector connected to an image in which the Edit view is registered, E3 is opened again from Page source, as a new pane, and still shows no Edit tab. "
                 "Then view selection, pane refresh or policy must be examined, and loading the system was not enough. "
                 "What this image holds now: " (ref (diagnosis-availability diagnosis) "This image now" "Image now") ".")
            (:li "The preview system is in the Catalog's load closure after all. This reading refuses to be produced then; look at "
                 (ref closure "the closure" "Load closure") "."))
          (:h3 "What we do not know yet")
          (:ul
            (:li (finding-ref "unresolved-screenshot-image" "Which image showed the missing tab?"))
            (:li (finding-ref "unresolved-warning-meaning" "What the redefinition warnings mean"))
            (:li (finding-ref "unresolved-original-transcripts" "The original transcripts, expressions and times")))
          (:h3 "Next observation")
          (:p "Open E3 again from Page source in the Inspector of the image in which the Edit view is registered. "
              (:strong "Prediction: ") "an Edit tab appears. Then follow Edit, Prepare edit proposal, Edit proposal, Preview. "
              "A preview writes nothing: the page file and its journal stay as they are. Authorization to execute an edit is a separate question. "
              "(" (finding-ref "unresolved-browser-check" "open observation") ")")
          (:h3 "More to inspect")
          (:p (ref diagnosis "All findings, by how they are known" "Findings by how they are known") " / "
              (ref diagnosis "Subjects" "Subjects") " / "
              (ref diagnosis "Operator observations" "Operator observations") " / "
              (ref (diagnosis-e3 diagnosis) "E3 in the retained copy" "E3 evidence") " (a historical copy, not necessarily the page on any server)"))))))

(v:defview diagnosis-findings-view (diagnosis diagnosis)
  (v:html-view :title "Findings by how they are known" :priority -3
    (remember diagnosis)
    (v:html
      (:h2 "Findings by how they are known")
      (:p "Each finding leads to the objects or the supplied observations it rests on. The operator's observations are historical; they are not this image's state.")
      (dolist (class +epistemic-classes+)
        (v:html (:h3 (v:esc (string-capitalize (symbol-name class))))
          (:ul (dolist (finding (diagnosis-findings diagnosis))
                 (when (eq class (finding-epistemic finding))
                   (v:html (:li (ref finding (finding-id finding) "Finding") " — " (v:esc (finding-statement finding))))))))))))

(v:defview diagnosis-subjects (diagnosis diagnosis)
  (v:html-view :title "Subjects" :priority -1
    (remember diagnosis)
    (let* ((availability (diagnosis-availability diagnosis))
           (objects (availability-objects availability)))
      (v:html
        (:h2 "What the diagnosis is about")
        (:p "A subject the image does not hold is shown as unavailable, with the source that defines it. Nothing here loads it.")
        (:ul
          (:li "ASDF system " (:code "dreyeck/catalog-application") ": "
               (if (getf objects :catalog-application)
                   (ref (getf objects :catalog-application) "system in this image") (v:html "no definition in this image"))
               " / " (ref (diagnosis-closure diagnosis) "its load closure" "Load closure"))
          (:li "ASDF system " (:code "dreyeck/fedwiki-item-edit-preview") ": "
               (if (getf objects :preview-system)
                   (v:html (ref (getf objects :preview-system) "system in this image")
                           (v:esc (if (getf (availability-state availability) :preview-system-loaded) " (loaded)" " (defined, not loaded)")))
                   (v:html "no definition in this image"))
               " / " (ref (find "src-preview-system" (diagnosis-sources diagnosis) :key #'source-id :test #'equal) "its definition" "Source"))
          (:li "Generic function " (:code "story-item-edit-offer") ": "
               (if (getf objects :generic-function)
                   (ref (getf objects :generic-function) "generic function in this image")
                   (v:html "not defined in this image"))
               " / " (ref (find "src-defview" (diagnosis-sources diagnosis) :key #'source-id :test #'equal) "its defview form" "Source"))
          (:li "Proposal and preview classes: "
               (if (getf objects :proposal-class)
                   (v:html (ref (getf objects :proposal-class) "item-edit-proposal") " / " (ref (getf objects :preview-class) "item-edit-preview"))
                   (v:html "not defined in this image; defined in the preview system's source"))
               " / " (ref (find "src-defview" (diagnosis-sources diagnosis) :key #'source-id :test #'equal) "source file" "Source"))
          (:li "Wiki page " (:code "ctm-and-tmdm-in-hyperdoc") ", Story Item E3 " (:code "ed37e9bac2fcd548") ": "
               (ref (diagnosis-e3 diagnosis) "E3 in the retained copy" "E3 evidence")
               " / " (ref availability "page file in this image now" "Image now")))
        (diagnosis-links diagnosis)))))

(v:defview diagnosis-history (diagnosis diagnosis)
  (v:html-view :title "Operator observations" :priority -2
    (remember diagnosis)
    (v:html
      (:h2 "What the operator reported, in the reported order")
      (:p "Supplied, not recorded: no times, expressions or remote ids exist for these. Before and after belong to the operator's image, not to this one.")
      (:ol (dolist (observation (diagnosis-observations diagnosis))
             (v:html (:li (ref observation nil "Observation"))))))))

(v:defview finding-view (finding finding)
  (v:html-view :title "Finding" :priority 0
    (let ((diagnosis (owner finding)))
      (v:html
        (:h2 (v:esc (v:text-representation finding)))
        (:p (v:esc (finding-statement finding)))
        (:table :class "inspector-table"
          (:tr (:td "How it is known") (:td (v:esc (string-downcase (symbol-name (finding-epistemic finding))))))
          (:tr (:td "Context") (:td (v:esc (finding-context finding))))
          (when (finding-claim finding) (v:html (:tr (:td "Claim checked") (:td (:code (v:esc (prin1-to-string (finding-claim finding))))))))
          (when (finding-limit finding) (v:html (:tr (:td "Limit") (:td (v:esc (finding-limit finding)))))))
        (when (finding-basis finding)
          (v:html (:h3 "Rests on findings")
            (:ul (dolist (basis (finding-basis finding)) (v:html (:li (ref basis nil "Finding") " — " (v:esc (finding-statement basis))))))))
        (when (finding-evidence finding)
          (v:html (:h3 "Evidence")
            (:ul (dolist (item (finding-evidence finding))
                   (v:html (:li (ref item nil (typecase item (runtime-observation "Observation") (source-observation "Source")
                                                    (load-closure "Load closure") (t "E3 evidence")))))))))
        (when diagnosis (diagnosis-links diagnosis))))))

(v:defview runtime-observation-view (observation runtime-observation)
  (v:html-view :title "Observation" :priority 0
    (let ((diagnosis (owner observation)))
      (v:html
        (:h2 (v:esc (v:text-representation observation)))
        (:p "Supplied by the operator, verbatim. It is not an Evaluation Record and describes the operator's running image at some time not supplied, not this image.")
        (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (observation-text observation)))
        (when (observation-parsed observation)
          (v:html (:table :class "inspector-table"
                    (loop for (key value) on (observation-parsed observation) by #'cddr
                          do (v:html (:tr (:td (v:esc (symbol-name key))) (:td (v:esc (prin1-to-string value)))))))))
        (:table :class "inspector-table"
          (:tr (:td "Kind") (:td (v:esc (string-downcase (symbol-name (observation-kind observation))))))
          (:tr (:td "Phase") (:td (v:esc (string-downcase (symbol-name (observation-phase observation))))))
          (:tr (:td "Reported position") (:td (v:esc (princ-to-string (observation-sequence observation)))))
          (loop for (key value) on (observation-provenance observation) by #'cddr
                do (v:html (:tr (:td (v:esc (string-downcase (symbol-name key)))) (:td (v:esc (prin1-to-string value)))))))
        (when diagnosis
          (v:html (:p "Findings that rest on it:")
            (:ul (dolist (finding (diagnosis-findings diagnosis))
                   (when (member observation (finding-evidence finding) :test #'eq)
                     (v:html (:li (ref finding nil "Finding"))))))
            (diagnosis-links diagnosis)))))))

(v:defview source-observation-view (source source-observation)
  (v:html-view :title "Source" :priority 0
    (let ((diagnosis (owner source)))
      (v:html
        (:h2 (v:esc (v:text-representation source)))
        (:p (v:esc (source-statement source)))
        (:table :class "inspector-table"
          (:tr (:td "File") (:td (:code (v:esc (source-file source))) " — " (ref (repo-file (source-file source)) "open the file")))
          (:tr (:td "Line") (:td (v:esc (princ-to-string (source-line source)))))
          (:tr (:td "Marker, found once") (:td (:code (v:esc (source-marker source)))))
          (:tr (:td "File SHA-256 when read") (:td (:code (v:esc (source-digest source)))))
          (when (source-system source)
            (v:html (:tr (:td "Declared dependencies") (:td (v:esc (format nil "~{~A~^, ~}" (source-declares source))))
                       ) (:tr (:td "Checked") (:td "against the definition registered in this image; refused if they differ"))))
          )
        (when diagnosis (diagnosis-links diagnosis))))))

(v:defview load-closure-view (closure load-closure)
  (v:html-view :title "Load closure" :priority 0
    (let ((diagnosis (owner closure)))
      (v:html
        (:h2 (v:esc (v:text-representation closure)))
        (:p "Computed from ASDF definitions registered in this image, following declared dependencies only. No system was loaded to compute it.")
        (:table :class "inspector-table"
          (:tr (:td "Definition file") (:td (:code (v:esc (princ-to-string (closure-definition-file closure))))))
          (:tr (:td "Definition SHA-256") (:td (:code (v:esc (princ-to-string (closure-definition-digest closure))))))
          (:tr (:td "Contains " (:code (v:esc +preview-system+)))
               (:td (v:esc (if (closure-contains-p closure +preview-system+) "yes" "no"))))
          (:tr (:td "Contains the writer " (:code "dreyeck/fedwiki-page-authoring"))
               (:td (v:esc (if (closure-contains-p closure "dreyeck/fedwiki-page-authoring") "yes" "no"))))
          (:tr (:td "Contains " (:code "dreyeck/work/reading") ", which holds this diagnosis")
               (:td (v:esc (if (closure-contains-p closure "dreyeck/work/reading") "yes" "no"))))
          (:tr (:td "Without a definition") (:td (v:esc (format nil "~S" (closure-missing closure))))))
        (:h3 "Systems")
        (:pre :style "white-space:pre-wrap" (v:esc (format nil "~{~A~^~%~}" (closure-systems closure))))
        (when diagnosis (diagnosis-links diagnosis))))))

(v:defview e3-observation-view (observation e3-observation)
  (v:html-view :title "E3 evidence" :priority -1
    (let ((diagnosis (owner observation)))
      (v:html
        (:h2 "Story Item E3 in the retained copy")
        (:p "Retained copy of the page " (:code (v:esc +slug+)) ", revision " (:code (v:esc +retained-e3-page-sha+))
            ". It is a repository file, not the page file of a running wiki.")
        (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere"
              (v:esc (gethash "text" (work:fedwiki-item-observation-item observation))))
        (:p (ref (work:fedwiki-item-observation-item observation) "Whole retained Story Item"))
        (when diagnosis
          (v:html (:p (ref (diagnosis-availability diagnosis) "Is the page file in this image the same revision?" "Image now"))
            (diagnosis-links diagnosis)))))))

(v:defview availability-view (availability availability)
  (v:html-view :title "Image now" :priority 0
    (let ((diagnosis (owner availability)))
      (v:html
        (:h2 "This image now")
        (:p (v:esc (format nil "Read at ~A while the diagnosis was read. This is a reading of the present, not the operator's observation, and viewing it loads nothing." (time-string (availability-time availability)))))
        (:table :class "inspector-table"
          (loop for (key value) on (availability-state availability) by #'cddr
                do (v:html (:tr (:td (v:esc (string-downcase (symbol-name key)))) (:td (v:esc (prin1-to-string value)))))))
        (:h3 "The page file")
        (:table :class "inspector-table"
          (loop for (key value) on (availability-live-page availability) by #'cddr
                do (v:html (:tr (:td (v:esc (string-downcase (symbol-name key)))) (:td (v:esc (prin1-to-string value)))))))
        (when (eq :unavailable (getf (availability-live-page availability) :state))
          (v:html (:p "The page file could not be read here. E3 is shown from the retained copy; the live E3 is not observed.")))
        (when diagnosis (diagnosis-links diagnosis))))))
