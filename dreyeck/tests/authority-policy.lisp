;;;; The authority policy, as a served Catalog applies it: operations stay
;;;; visible, only contracted ones run, and pathnames stay inside the root.

(defpackage #:dreyeck/authority-policy/tests
  (:use #:cl)
  (:local-nicknames (#:ap #:dreyeck/authority-policy)
                    (#:hv #:html-inspector-views))
  (:export #:run-tests #:probe-effect #:*probe-calls*))

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

(defun check-wikipedia-open-withheld ()
  "Served, a Wikipedia page offers no Open in browser, so no click reaches
CLOG:OPEN-BROWSER and no process starts on the server; a development server
still offers it, and clicking it opens the page's URL."
  (let* ((wikipedia (hyperbook/wikipedia::make-wikipedia "en" "Wikipedia" "Main Page"))
         (page (make-instance 'hyperbook/wikipedia::wikipedia-page
                              :hyperbook wikipedia :id "Blog" :title "Blog"))
         (original (symbol-function 'clog:open-browser))
         (opened nil))
    (flet ((click-every-action ()
             ;; What the Inspector does with each reference the title bar offers.
             (dolist (target (%references (hv:title-bar-action-buttons page)))
               (hv:eval-thunk target))))
      (unwind-protect
           (progn
             (setf (symbol-function 'clog:open-browser)
                   (lambda (&rest arguments) (push arguments opened) nil))
             (served (lambda ()
                       (assert (null (%references (hv:title-bar-action-buttons page))))
                       (click-every-action)))
             (assert (null opened) () "Served, a Wikipedia page opened ~S." opened)
             (developing #'click-every-action)
             (assert (equal '((:url "https://en.wikipedia.org/wiki/Blog")) opened) ()
                     "A development server opened ~S." opened))
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
                                   ("wikipedia/open-in-browser" :unsafe)
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

(defun run-tests ()
  (check-operations-stay-inspectable)
  (check-uncontracted-invocation-refused)
  (check-pathnames-stay-inside-the-root)
  (check-fedwiki-actions-withheld)
  (check-wikipedia-open-withheld)
  (check-clipboard-withheld)
  (check-reload-withheld)
  (check-lazy-cell-withheld)
  (check-examples-gated)
  (check-contracts)
  (check-served-catalog-boundary)
  (check-adapters-as-reviewed)
  (format t "~&AUTHORITY-POLICY-PASS: served, Operations stays and shows contract status; an unreviewed ~
new method is listed, gets no Evaluate and is refused if invoked anyway; a contracted reader-like ~
method runs; pathnames outside the repository show nothing; FedWiki's inherited actions, Wikipedia's ~
Open in browser and the server-side clipboard, Reload and a lazy cell's Evaluate are withheld; an example runs only with ~
a contract; ~
the Work operations are contracted but need the authoring capability; adapted upstream points are as reviewed.~%")
  t)
