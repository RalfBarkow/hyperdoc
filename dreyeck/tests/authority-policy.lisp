;;;; The authority policy, as a served Catalog applies it: operations stay
;;;; visible, only contracted ones run, and pathnames stay inside the root.

(defpackage #:dreyeck/authority-policy/tests
  (:use #:cl)
  (:local-nicknames (#:ap #:dreyeck/authority-policy)
                    (#:hv #:html-inspector-views))
  (:export #:run-tests #:run-gate-tests #:probe-effect #:*probe-calls*))

(in-package #:dreyeck/authority-policy/tests)

;;; A downstream method nobody has reviewed, applicable to every page.
(defvar *probe-calls* 0)
(defgeneric probe-effect (page))
(defmethod probe-effect ((page hyperbook:page))
  (incf *probe-calls*)
  :ran)

(defun served (thunk)
  "THUNK run as the served Catalog runs: a server up, not in development mode."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil))
    (funcall thunk)))

(defun developing (thunk)
  "THUNK run as a trusted local runtime runs: a server up, in development mode."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" t))
    (funcall thunk)))

(defun %code-page ()
  (let ((book (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t)))
    (find "reading.lisp" (coerce (hyperdoc::code-pages-of book) 'list)
          :key (lambda (page) (file-namestring (hyperdoc::source-code-pathname page))) :test #'string=)))

(defun %view (object title)
  (find title (hv:all-views object) :key #'hv:view-title :test #'string=))

(defun %operations (object)
  "The Inspector's generic Operations view, not a page's own view of that name."
  (%view object (html-inspector-views/standard::dimmed "Operations")))

(defun %references (view)
  (hv:view-html view)
  (mapcar #'cdr (hv:view-references view)))

(defun %operation-thunks (object)
  (remove-if-not (lambda (x) (typep x 'ap:operation-thunk)) (%references (%operations object))))

(defun %offered-p (object name)
  "Whether OBJECT's Operations view renders an Evaluate for the method named NAME."
  (find name (%operation-thunks object)
        :key (lambda (thunk) (symbol-name (c2mop:generic-function-name
                                           (c2mop:method-generic-function (ap::operation-thunk-method thunk)))))
        :test #'string=))

(defun %method (name object)
  (find name (remove-if-not #'html-inspector-views/standard::callable-with-one-arg?
                            (html-inspector-views/standard::find-applicable-methods object))
        :key (lambda (m) (symbol-name (c2mop:generic-function-name (c2mop:method-generic-function m))))
        :test #'string=))

(defun %forged (name object)
  "What evaluating an invocation of NAME on OBJECT returns, however it was obtained."
  (let ((method (%method name object)))
    (hv:eval-thunk (make-instance 'ap:operation-thunk
                                  :fn (let ((gf (c2mop:method-generic-function method))) (lambda () (funcall gf object)))
                                  :method method :target object))))

(defun check-operations-stay-inspectable ()
  "Operations stays; an unresolved or uncontracted method is listed with its
status and gets no Evaluate; a contracted one does, and runs."
  (let ((page (%code-page)))
    (served
     (lambda ()
       (let ((html (hv:view-html (%operations page))))
         (assert (%operations page))
         (dolist (needle '("load-page" "unresolved" "path-item-of" "contracted" "probe-effect" "no contract"))
           (assert (search needle html) () "Operations does not show ~S." needle))
         (assert (not (%offered-p page "LOAD-PAGE")))
         (assert (not (%offered-p page "PROBE-EFFECT")))
         (assert (%offered-p page "PATH-ITEM-OF"))
         (assert (equal (hyperbook:path-item-of page) (%forged "PATH-ITEM-OF" page))))))
    t))

(defun check-uncontracted-invocation-refused ()
  "Even an invocation obtained some other way is refused when evaluated, and
nothing runs. Without the served policy the same invocation runs: the gate is
what refused."
  (let ((page (%code-page)))
    (setf *probe-calls* 0)
    (served
     (lambda ()
       (assert (typep (%forged "PROBE-EFFECT" page) 'ap:invocation-refused))
       (assert (typep (%forged "LOAD-PAGE" page) 'ap:invocation-refused))
       (assert (search "no operation contract" (ap:invocation-refused-reason (%forged "PROBE-EFFECT" page))))))
    (assert (zerop *probe-calls*))
    (assert (%offered-p page "PROBE-EFFECT"))
    (assert (eq :ran (%forged "PROBE-EFFECT" page)))
    (assert (= 1 *probe-calls*))
    t))

(defun check-pathnames-stay-inside-the-root ()
  "Served, a pathname inside the repository shows its views; one outside shows
none, so following a Path view upwards reaches nothing to list or read."
  (let* ((inside (asdf:system-relative-pathname "dreyeck" "dreyeck.asd"))
         (root #P"/")
         (outside (user-homedir-pathname)))
    (served
     (lambda ()
       (assert (%view inside "Path"))
       (assert (%view (asdf:system-source-directory "dreyeck") "Items"))
       (dolist (pathname (list root outside))
         (dolist (title '("Items" "Path" "Content" "Components"))
           (assert (not (%view pathname title)) () "~A offers ~A." pathname title)))
       ;; Every pathname the Path view offers upwards leads nowhere outside the root.
       (dolist (offered (remove-if-not #'pathnamep (%references (%view inside "Path"))))
         (unless (ap:pathname-disclosure-permitted-p offered)
           (assert (notany (lambda (title) (%view offered title)) '("Items" "Path" "Content")))))
       (assert (null (%references (hv:title-bar-action-buttons inside))))))
    (assert (%view root "Items"))
    t))

(defun check-fedwiki-actions-withheld ()
  "Served, the local FedWiki book and its pages offer none of the inherited
network or process actions; without the served policy the book does."
  (let* ((site-root (dreyeck/local-fedwiki-view:configured-site-root))
         (wiki (dreyeck/local-fedwiki-page:register-local-fedwiki
                site-root dreyeck/local-fedwiki-view::*default-wiki-id*))
         (page (make-instance 'dreyeck/local-fedwiki-page:local-fedwiki-page
                              :hyperbook wiki :id "authority-policy-probe" :site-root site-root)))
    (served (lambda ()
              (assert (null (%references (hv:title-bar-action-buttons wiki))))
              (assert (null (%references (hv:title-bar-action-buttons page))))))
    (assert (%references (hv:title-bar-action-buttons wiki)))
    t))

(defun check-wikipedia-open-is-navigation ()
  "A Wikipedia page's Open in browser is an ordinary link, the same served and on
a development server: shown, to the page's URL, in a new tab, with nothing for
the Inspector to invoke, so no click reaches CLOG:OPEN-BROWSER and no process
starts on the server."
  (let* ((wikipedia (hyperbook/wikipedia::make-wikipedia "en" "Wikipedia" "Main Page"))
         (page (make-instance 'hyperbook/wikipedia::wikipedia-page
                              :hyperbook wikipedia :id "Blog" :title "Blog"))
         (original (symbol-function 'clog:open-browser))
         (opened nil))
    (flet ((check-title-bar ()
             (let* ((view (hv:title-bar-action-buttons page))
                    (html (hv:view-html view))
                    (links (plump:get-elements-by-tag-name (plump:parse html) "a")))
               ;; What the Inspector does with each reference the title bar offers.
               (dolist (target (%references view))
                 (hv:eval-thunk target))
               (assert (= 1 (length links)) () "The title bar shows ~S." html)
               (assert (string= "Open in browser" (plump:text (first links))))
               (assert (string= "https://en.wikipedia.org/wiki/Blog" (plump:attribute (first links) "href")))
               (assert (string= "_blank" (plump:attribute (first links) "target")))
               (assert (null (hv:view-references view)) () "The title bar offers ~S." (hv:view-references view))
               (assert (notany (lambda (prefix) (search prefix html)) '("action-" "eval-")) ()
                       "The title bar names a reference: ~S." html))))
      (unwind-protect
           (progn
             (setf (symbol-function 'clog:open-browser)
                   (lambda (&rest arguments) (push arguments opened) nil))
             (served #'check-title-bar)
             (developing #'check-title-bar)
             (assert (null opened) () "A Wikipedia page opened ~S on the server." opened))
        (setf (symbol-function 'clog:open-browser) original))))
  t)

(defun check-clipboard-withheld ()
  "Served, a string offers no Copy to clipboard, which would start a process
on the server; without the served policy it does."
  (served (lambda () (assert (null (%references (hv:title-bar-action-buttons "a string"))))))
  (assert (%references (hv:title-bar-action-buttons "a string")))
  t)

(defun check-reload-withheld ()
  "Served, a HyperDoc and its text pages offer no Reload, which re-reads page
files into the running image; without the served policy the HyperDoc does."
  (let* ((book (hyperbook:find-hyperbook "dreyeck/lisp-critic/reading" :signal-error? t))
         (page (hyperbook:find-page book "Anatomy of a Critique" :signal-error? t)))
    (served (lambda ()
              (assert (null (%references (hv:title-bar-action-buttons book))))
              (assert (null (%references (hv:title-bar-action-buttons page))))))
    (assert (%references (hv:title-bar-action-buttons book))))
  t)

(defun check-lazy-cell-withheld ()
  "Served, a lazy cell offers no Evaluate; without the served policy it does."
  (let ((cell (lwcells::cell 1)))
    (served (lambda () (assert (null (%references (hv:title-bar-action-buttons cell))))))
    (assert (%references (hv:title-bar-action-buttons cell))))
  t)

(defun %all-references (view)
  "VIEW's references, and those of the views it transcludes."
  (loop for reference in (%references view)
        append (cons reference (and (typep reference 'hv:view) (%all-references reference)))))

(defun %example-thunks (object title)
  (remove-if-not (lambda (x) (typep x 'ap:example-thunk)) (%all-references (%view object title))))

(defun check-examples-gated ()
  "Served, an example's run button appears only for an example with a contract,
and a run obtained otherwise is refused; without the served policy it runs."
  (let* ((recorded (hyperbook:find-page (hyperbook:find-hyperbook "dreyeck/lisp-critic/reading" :signal-error? t)
                                        "Reading a Recorded Critique" :signal-error? t))
         (code (%code-page))
         (uncontracted (find-symbol "THE-ANSWER" "HYPERDOC"))
         (run (make-instance 'ap:example-thunk :fn (lambda () (funcall (symbol-function uncontracted)))
                                               :example uncontracted)))
    (served
     (lambda ()
       (assert (equal '("SETF-PUSH-RECORDED-EXAMPLE" "X-PLUS-1-RECORDED-EXAMPLE")
                      (sort (mapcar (lambda (thunk) (symbol-name (ap::example-thunk-example thunk)))
                                    (%example-thunks recorded "Content"))
                            #'string<)))
       (assert (null (%example-thunks code "Source")))
       (assert (some (lambda (view) (and (typep view 'hv:view) (search "<span title='Not run here" (hv:view-html view))))
                     (cons (%view code "Source") (%all-references (%view code "Source")))))
       (assert (typep (hv:eval-thunk run) 'ap:invocation-refused))))
    (assert (%example-thunks code "Source"))
    (assert (eql 42 (hv:eval-thunk run))))
  t)

(defun check-run-buttons ()
  "A reading's run button is upstream's where the policy is not enforced; served, it is a marker, and its thunk is never
registered, so no click can reach it."
  (let ((thunk (make-instance 'hv:thunk :fn (lambda () :ran))))
    (flet ((rendered ()
             (let ((view (hv:html-view :title "Run" (hv:html (:p (ap:run-button "Run it" thunk "Run DEFEXAMPLE"))))))
               (list (hv:view-html view) (mapcar #'cdr (hv:view-references view))))))
      (destructuring-bind (html references) (developing #'rendered)
        (assert (search "inspector-action" html))
        (assert (member thunk references)))
      (destructuring-bind (html references) (served #'rendered)
        (assert (search "Run it" html))
        (assert (search "not run in a served Catalog" html))
        (assert (not (search "inspector-action" html)))
        (assert (not (member thunk references))))))
  t)

;;; The runtime boundary: a control no one reviewed is refused when served, whoever made it and however it got into the view.

(defvar *ran* nil "Set by the probe controls, so that a refused control can be shown not to have run.")
(defclass boundary-probe () ())
(hv:defview boundary-probe-view (object boundary-probe)
  (hv:html-view :title "Boundary probe" :priority 1
    (hv:html (:p (hv:eval-button "Plain eval" (hv:thunk (setf *ran* :eval)))
                 (hv:action-button "Plain action" (hv:thunk (setf *ran* :action)))
                 (hv:eval-button "Reviewed" (ap:reviewed-thunk "conversation/select-message" (setf *ran* :reviewed)))
                 (hv:eval-button "Not a thunk" #'identity)))))

(defmacro with-clog-stubs (&body body)
  "The Inspector's click path marks the button with CLOG classes; here there is no browser, so those calls do nothing."
  `(progn (sb-int:encapsulate 'clog:remove-class 'authority-test (lambda (f &rest args) (declare (ignore f args)) nil))
          (sb-int:encapsulate 'clog:add-class 'authority-test (lambda (f &rest args) (declare (ignore f args)) nil))
          (unwind-protect (progn ,@body)
            (sb-int:unencapsulate 'clog:remove-class 'authority-test)
            (sb-int:unencapsulate 'clog:add-class 'authority-test))))

(defun click (reference)
  "What a click on the control REFERENCE (id . thunk) does: the Inspector's own click path."
  (with-clog-stubs (clog-moldable-inspector::eval-thunk-with-active-button nil nil (cdr reference))))

(defun probe-view () (find "Boundary probe" (hv:all-views (make-instance 'boundary-probe)) :key #'hv:view-title :test #'string=))
(defun controls-by-label (view)
  "The references of VIEW in the order the probe made them: plain eval, plain action, reviewed, not a thunk."
  (let ((references (remove-if-not (lambda (reference) (or (uiop:string-prefix-p "eval-" (car reference)) (uiop:string-prefix-p "action-" (car reference))))
                                   (hv:view-references view))))
    (assert (= 4 (length references)))
    (destructuring-bind (plain-eval plain-action reviewed non-thunk)
        (sort (copy-list references) #'< :key (lambda (reference) (parse-integer (car reference) :start (1+ (position #\- (car reference))))))
      (list :plain-eval plain-eval :plain-action plain-action :reviewed reviewed :non-thunk non-thunk))))

(defun check-control-boundary ()
  "CREATION: a plain thunk registered by HV:EVAL-BUTTON or HV:ACTION-BUTTON is replaced when served and untouched when developing; a reviewed
thunk, and a target that is not a thunk, are kept. INVOCATION: through the Inspector's click path a replaced control returns a refusal and
its function never runs, a reviewed control runs, and a control registered after the view was computed is replaced when the references are next read."
  ;; creation, served
  (served
   (lambda ()
     (let ((c (controls-by-label (probe-view))))
       (setf *ran* nil)
       (assert (typep (cdr (getf c :plain-eval)) 'ap:refused-thunk))
       (assert (typep (cdr (getf c :plain-action)) 'ap:refused-thunk))
       (assert (eq (class-of (ap:refused-thunk-original (cdr (getf c :plain-eval)))) (find-class 'hv:thunk)))
       (assert (typep (cdr (getf c :reviewed)) 'ap:reviewed-thunk))
       (assert (eq #'identity (cdr (getf c :non-thunk))))
       (assert (null *ran*) () "creating the controls ran one")
       ;; invocation
       (assert (typep (click (getf c :plain-eval)) 'ap:invocation-refused))
       (assert (typep (click (getf c :plain-action)) 'ap:invocation-refused))
       (assert (null *ran*) () "a refused control ran")
       (assert (eq :reviewed (click (getf c :reviewed))))
       (assert (eq :reviewed *ran*))
       (assert (eq #'identity (click (getf c :non-thunk)))))))
  ;; a control added to the references after the view was computed
  (served
   (lambda ()
     (let ((view (probe-view)))
       (hv:view-html view)
       (setf *ran* nil)
       (push (cons "eval-99999" (hv:thunk (setf *ran* :late))) (slot-value view 'hv::references))
       (let ((late (assoc "eval-99999" (hv:view-references view) :test #'string=)))
         (assert (typep (cdr late) 'ap:refused-thunk))
         (assert (typep (click late) 'ap:invocation-refused))
         (assert (null *ran*))))))
  ;; developing: nothing is replaced and the plain control runs (the original behaviour)
  (developing
   (lambda ()
     (let ((c (controls-by-label (probe-view))))
       (setf *ran* nil)
       (assert (eq (class-of (cdr (getf c :plain-eval))) (find-class 'hv:thunk)))
       (assert (eq :eval (click (getf c :plain-eval))))
       (assert (eq :eval *ran*)))))
  ;; a reviewed control must be registered
  (assert (handler-case (progn (ap:reviewed-thunk "no/such/control" 1) nil) (error () t)))
  t)

(defun check-reviewed-controls-match-their-sites ()
  "The registered identities are exactly those the sources use: no call site names an unregistered control (it would fail on creation),
and no registration is dead. Test sources are not scanned."
  (let ((used '()) (root (asdf:system-source-directory "dreyeck")))
    (dolist (file (append (directory (merge-pathnames "dreyeck/src/*.lisp" root)) (directory (merge-pathnames "dreyeck/work/**/*.lisp" root))))
      (unless (search "/tests/" (namestring file))
        (let* ((text (uiop:read-file-string file)) (needle "reviewed-thunk \"") (at (search needle text)))
          (loop while at
                do (let* ((start (+ at (length needle))) (end (position #\" text :start start)))
                     (unless (uiop:string-prefix-p "dreyeck/authority-policy" (subseq text (max 0 (- at 40)) at))
                       (pushnew (subseq text start end) used :test #'string=))
                     (setf at (search needle text :start2 end)))))))
    (let ((registered (ap:reviewed-control-identities)))
      (assert (null (set-difference used registered :test #'string=)) () "used but not registered: ~S" (set-difference used registered :test #'string=))
      (assert (null (set-difference registered used :test #'string=)) () "registered but used nowhere: ~S" (set-difference registered used :test #'string=))))
  t)

(defun check-contracts ()
  "The Work operations are fully contracted and still not invocable in a Catalog:
the authoring capability is absent. The audited upstream candidates are
registered as unresolved or unsafe."
  (dolist (identity '("operation/change-work-status" "operation/create-relationship"))
    (let ((contract (ap:find-operation-contract identity)))
      (assert (eq :contracted (ap:contract-status contract)))
      (assert (ap:contract-verification-evidence contract))
      (multiple-value-bind (allowed reason) (ap:invocation-decision contract)
        (assert (not allowed))
        (assert (search "authoring-environment" reason)))))
  (loop for (identity status) in '(("hyperdoc:load-page" :unresolved) ("hyperbook:register" :unresolved)
                                   ("fedwiki/reload" :unsafe) ("fedwiki/open-external" :unsafe)
                                   ("copy-to-clipboard" :unsafe) ("page-attached/activation" :unsafe)
                                   ("hyperdoc/reload" :unresolved) ("cell/evaluate" :unresolved)
                                   ("example/setf-push-recorded-example" :contracted)
                                   ("example/x-plus-1-recorded-example" :contracted))
        do (assert (eq status (ap:contract-status (ap:find-operation-contract identity))) () "~A" identity))
  t)

(defun %closure (name &optional seen)
  (let ((system (asdf:find-system name nil)))
    (if (or (null system) (member (asdf:component-name system) seen :test #'string=))
        seen
        (let ((seen (cons (asdf:component-name system) seen)))
          (dolist (dependency (asdf:system-depends-on system) seen)
            (let ((dependency-name (cond ((stringp dependency) dependency)
                                         ((symbolp dependency) (string-downcase dependency)))))
              (when dependency-name (setf seen (%closure dependency-name seen)))))))))

(defun check-served-catalog-boundary ()
  "The Catalog carries the policy and not the page-attached activation."
  (let ((closure (%closure "dreyeck/catalog")))
    (assert (member "dreyeck/authority-policy" closure :test #'string=))
    (assert (not (member "dreyeck/local-fedwiki-page/activation-inspector" closure :test #'string=))))
  t)

(defun check-adapters-as-reviewed ()
  "Every adapted upstream point is as reviewed; a changed one is reported."
  (assert (null (ap:containment-adapter-drift)) () "Drifted: ~S" (ap:containment-adapter-drift))
  (let ((tampered (list (append (list :sha256 "0") (first ap:+containment-adapters+)))))
    (assert (= 1 (length (ap:containment-adapter-drift tampered)))))
  t)

(defun run-gate-tests ()
  "The checks that need nothing of the machine they run on. RUN-TESTS adds the three that do: CHECK-FEDWIKI-ACTIONS-WITHHELD reads a
~/.wiki/dreyeck.ch, CHECK-RELOAD-WITHHELD needs a HyperDoc the user can write (not a /nix/store source built by another user), and
CHECK-ADAPTERS-AS-REVIEWED compares the adapted upstream points and classes with what was reviewed."
  (check-operations-stay-inspectable)
  (check-uncontracted-invocation-refused)
  (check-pathnames-stay-inside-the-root)
  (check-wikipedia-open-is-navigation)
  (check-clipboard-withheld)
  (check-lazy-cell-withheld)
  (check-examples-gated)
  (check-run-buttons)
  (check-control-boundary)
  (check-reviewed-controls-match-their-sites)
  (check-contracts)
  (check-served-catalog-boundary)
  t)

(defun run-tests ()
  (run-gate-tests)
  (check-fedwiki-actions-withheld)
  (check-reload-withheld)
  (check-adapters-as-reviewed)
  (format t "~&AUTHORITY-POLICY-PASS: served, Operations stays and shows contract status; an unreviewed ~
new method is listed, gets no Evaluate and is refused if invoked anyway; a contracted reader-like ~
method runs; pathnames outside the repository show nothing; FedWiki's inherited actions, the server-side ~
clipboard, Reload and a lazy cell's Evaluate are withheld; Wikipedia's Open in browser is the same link served and ~
developing, and nothing opens on the server; an example runs only with a contract; a reading's plain run button is not offered, and its thunk not registered; ~
a control no one reviewed is replaced when served, however made, and refuses when clicked, while a reviewed one runs; ~
the Work operations are contracted but need the authoring capability; adapted upstream points are as reviewed.~%")
  t)
