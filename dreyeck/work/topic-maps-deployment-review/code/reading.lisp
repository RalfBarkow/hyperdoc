;;;; Explicit Runs, ASDF Origins and the Reading's Entry
(in-package #:topic-maps-deployment-review)

(hyperdoc:see (hyperdoc:page "Deploying Topic Maps with HyperDoc" :hyperbook "topic-maps-deployment-review"))
(hyperdoc:see #'snap:verify-snapshot-tree)
(hyperdoc:see #'c:topic-maps-origins)
(hyperdoc:see #'c:refuse-project-workspace)

;;; Two things in this reading run, and only when their button is pressed. Each answers a question that only running
;;; can answer: is the Topic Maps source of this very image the commit without reports/, and is the Project Workspace
;;; refused here before anything of it is loaded? Their buttons are plain v:thunk buttons; whether the served Catalog's
;;; authority policy was enforced when one ran is recorded with the run (see Execution Authority).

(defun review-page (title) (hyperbook:find-page +book-id+ title :signal-error? t))

;;; ASDF origins, as this image resolves them when shown

(defclass asdf-origins () ()
  (:documentation "Where ASDF finds the systems this candidate is about, in this image, asked when shown."))
(defmethod v:text-representation ((o asdf-origins)) "ASDF origins in this image")
(defvar *origins* (make-instance 'asdf-origins))
(defun topic-maps-origins-now () *origins*)
(defparameter +origin-systems+
  '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm" "topic-maps/project-work-example"
    "dreyeck" "dreyeck/source-snapshot" "dreyeck/catalog-topic-maps" "dreyeck/work/project"))

(v:defview asdf-origins-view (origins asdf-origins)
  (v:html-view :title "ASDF origins" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Where ASDF finds the systems, in this image")
       (:p "Asked when this view is shown. Finding a system reads its definition; it loads nothing.")
       (:table :class "inspector-table"
        (:tr (:th "System") (:th "Source directory") (:th "Kind") (:th "Loaded here"))
        (dolist (name +origin-systems+)
          (let* ((system (asdf:find-system name nil)) (root (and system (asdf:system-source-directory system))))
            (v:html (:tr (:td (if system (v:object-ref system :display name) (v:esc name)))
                         (:td (:code (v:esc (if root (namestring root) "not found"))))
                         (:td (v:esc (if root (string-downcase (snap:source-kind root)) "—")))
                         (:td (v:esc (if (and system (asdf:component-loaded-p system)) "yes" "no"))))))))
       (:p "The packaged executable checks the same thing before it serves: " (v:object-ref #'c:topic-maps-origins :select "Source code")
           ". Its recorded run: " (v:object-ref (evidence "package-check/lisp.log") :select "Record" :display "the ASDF-ORIGIN lines of the package contract") ".")
       (reading-links)))))

;;; Whose methods ASDF runs: the two identities the first guard replaced

(defclass method-origins () ()
  (:documentation "For each ASDF method identity the first version of the guard defined, where the method ASDF runs now was defined, asked when shown."))
(defmethod v:text-representation ((o method-origins)) "Which ASDF methods the first guard replaced")
(defvar *method-origins* (make-instance 'method-origins))
(defun method-origins () *method-origins*)
(defun guard-methods ()
  "The method identity each definition of the first guard occupied: (label generic-function qualifiers specializer-classes text)."
  (list (list "operate :before (t t)" #'asdf:operate '(:before) (list (find-class t) (find-class t))
              "ASDF's check for ASDF-BINARY-LOCATIONS, (operation-class system &rest args), whose specializers are also (t t)")
        (list "perform :before (operation component)" #'asdf:perform '(:before)
              (list (find-class 'asdf:operation) (find-class 'asdf:component))
              "ASDF's (ensure-all-directories-exist (output-files o c)) before every action")))
(defun method-source (generic qualifiers classes)
  (let* ((method (find-method generic qualifiers classes nil))
         (source (and method (sb-introspect:find-definition-source method))))
    (values method (and source (sb-introspect:definition-source-pathname source)))))
(defun guard-replaced-asdf-methods-p ()
  "Whether a method ASDF runs for one of the first guard's identities is defined in the candidate's guard file, not in ASDF's."
  (every (lambda (entry) (destructuring-bind (label generic qualifiers classes asdf) entry
                           (declare (ignore label asdf))
                           (let ((pathname (nth-value 1 (method-source generic qualifiers classes))))
                             (and pathname (search "catalog-topic-maps" (namestring pathname))))))
         (guard-methods)))

(v:defview method-origins-view (origins method-origins)
  (v:html-view :title "Method origins" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Whose methods ASDF runs for the two identities the first guard replaced")
       (:p "A method is identified by its generic function, qualifiers and specializers. Defining a method with the same three replaces the earlier one. "
           "The first version of the guard defined two methods with the identities below and so replaced two of ASDF's own (" (v:object-ref (excerpt "startup:guard-methods") :select "Historical source" :display "its text, kept") "; "
           "the probe's record is in the collision page). Asked when this view is shown, where the method with each identity is defined now:")
       (:table :class "inspector-table"
        (:tr (:th "Method") (:th "Defined now in") (:th "ASDF's own"))
        (dolist (entry (guard-methods))
          (destructuring-bind (label generic qualifiers classes asdf) entry
            (multiple-value-bind (method pathname) (method-source generic qualifiers classes)
              (v:html (:tr (:td (if method (v:object-ref method :select "Generic" :display label) (v:esc label)))
                           (:td (:code (v:esc (if pathname (namestring pathname) "unknown"))))
                           (:td (v:esc asdf))))))))
       (:p (v:esc (if (guard-replaced-asdf-methods-p)
                      "At least one of them is still the guard's: the first guard's defect is present in this image."
                      "Neither is the guard's: both are ASDF's own, so dreyeck/catalog-topic-maps no longer replaces them.")))
       (:p "The correction: the guard is now an explicit check of the Catalog's startup, " (v:object-ref (excerpt "startup:guard") :select "Source excerpt" :display "its source")
           ", and it defines no method on any ASDF generic function. The fresh-process test compares ASDF's method objects before and after loading it: "
           (v:object-ref (file-named "scripts/test-asdf-method-preservation.lisp") :select "Candidate file") ".")
       (reading-links)))))

;;; Verifying the snapshot now

(defclass verification-runner ()
  ((runs :initform nil :accessor runner-runs :documentation "(verification policy-enforced-p universal-time), newest first."))
  (:documentation "Verification of this image's Topic Maps source, on request."))
(defmethod v:text-representation ((r verification-runner)) "Verify the snapshot now")
(defvar *verification-runner* (make-instance 'verification-runner))
(defun the-verification-runner () *verification-runner*)

(hyperdoc:defexample verify-snapshot-now
  "Verify, now and without .git, that ASDF's Topic Maps source in this image is b2eecffa without reports/."
  (let ((verification (snap:verify-store-snapshot (asdf:system-source-directory "topic-maps") c:+topic-maps-commit+)))
    (push (list verification (ap:policy-enforced-p) (get-universal-time)) (runner-runs *verification-runner*))
    verification))

(v:defview verification-runner-view (runner verification-runner)
  (v:html-view :title "Verify now" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Verify this image's Topic Maps source now")
       (:p "Hashes every shipped file of " (:code (v:esc (namestring (asdf:system-source-directory "topic-maps"))))
           " as Git would, and checks the chain from the commit object to the files against "
           (v:object-ref (snap:find-snapshot-manifest c:+topic-maps-commit+) :display "the manifest") ". It reads; it writes nothing.")
       (:p (v:eval-button "Verify the snapshot now" (v:thunk (verify-snapshot-now)) "Run verify-snapshot-now"))
       (:p "The procedure: " (v:object-ref #'verify-snapshot-now :select "Source code") ", which calls "
           (v:object-ref #'snap:verify-store-snapshot :select "Source code") " and "
           (v:object-ref #'snap:verify-snapshot-tree :select "Source code") ".")
       (:h3 "Runs in this image")
       (if (runner-runs runner)
           (v:html (:ul (dolist (run (runner-runs runner))
                          (destructuring-bind (verification enforced at) run
                            (v:html (:li (v:object-ref verification :select "Source snapshot")
                                         (v:esc (format nil " at ~A (universal time); the served Catalog's authority policy was ~:[not ~;~]enforced when it ran."
                                                        at enforced))))))))
           (v:html (:p "None yet: rendering this view verifies nothing.")))
       (:p "The recorded runs of the same verifier: " (v:object-ref (evidence "package-check/lisp.log") :select "Record" :display "in the build sandbox")
           " · " (v:object-ref (evidence "checkout-source-snapshot.log") :select "Record" :display "from the checkout"))
       (reading-links)))))

;;; Trying the Project Workspace against the guard

(defclass guard-trial ()
  ((results :initform nil :accessor runner-runs))
  (:documentation "Asking the packaged startup check whether it refuses the Project Workspace, on request. The check reads system definitions and loads nothing."))
(defmethod v:text-representation ((g guard-trial)) "Project Workspace guard")
(defclass guard-result ()
  ((condition :initarg :condition :reader result-condition)
   (packages-unchanged :initarg :packages-unchanged :reader result-packages-unchanged)
   (loaded :initarg :loaded :reader result-loaded)
   (enforced :initarg :enforced :reader result-enforced)
   (at :initarg :at :reader result-at)))
(defmethod v:text-representation ((r guard-result))
  (if (result-condition r) "Refused before anything was loaded" "Not refused"))
(defvar *guard-trial* (make-instance 'guard-trial))
(defun the-guard-trial () *guard-trial*)
(defun project-packages ()
  (remove-if-not (lambda (p) (uiop:string-prefix-p "DREYECK/WORK/PROJECT" (package-name p))) (list-all-packages)))

(hyperdoc:defexample try-project-workspace-under-guard
  "Ask the packaged startup check whether it refuses dreyeck/work/project, and report what happened. It loads nothing."
  (let* ((before (project-packages))
         (condition (handler-case (progn (c:refuse-project-workspace "dreyeck/work/project") nil)
                      (c:project-workspace-refused (refusal) refusal)))
         (result (make-instance 'guard-result :condition condition :packages-unchanged (equal before (project-packages))
                                              :loaded (asdf:component-loaded-p "dreyeck/work/project")
                                              :enforced (ap:policy-enforced-p) :at (get-universal-time))))
    (push result (runner-runs *guard-trial*))
    result))

(v:defview guard-trial-view (trial guard-trial)
  (v:html-view :title "Guard" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "The Project Workspace guard")
       (:p "The packaged executable's " (v:object-ref #'c:main :select "Source code") " calls " (v:object-ref #'c:verify-startup :select "Source code")
           " before it serves: it verifies the Topic Maps origins, then " (v:object-ref #'c:refuse-project-workspace :select "Source code")
           " reads the definition of the system the Catalog is asked to load, and of its dependencies, and refuses if one is the Project Workspace "
           "(" (v:object-ref #'c:refused-system-p :select "Source code") ") or the page-attached system loader (" (v:object-ref #'c:loader-system-p :select "Source code") "). "
           "It adds no method to ASDF. The excerpt: " (v:object-ref (excerpt "startup:guard") :select "Source excerpt") ".")
       (:p "The button asks it about " (:code "dreyeck/work/project") " in this image. The check only reads definitions: nothing of the Project Workspace is loaded, by this button or by anything else here.")
       (:p (v:eval-button "Ask whether the Project Workspace is refused" (v:thunk (try-project-workspace-under-guard))
                          "Run try-project-workspace-under-guard"))
       (:p "The procedure: " (v:object-ref #'try-project-workspace-under-guard :select "Source code") ".")
       (:h3 "Trials in this image")
       (if (runner-runs trial)
           (v:html (:ul (dolist (r (runner-runs trial)) (v:html (:li (v:object-ref r :select "Guard result"))))))
           (v:html (:p "None yet: rendering this view asks nothing.")))
       (:p "Recorded: " (v:object-ref (evidence "package-check/executable.log") :select "Record" :display "the executable refuses it before listening")
           " · " (v:object-ref (evidence "package-check/lisp.log") :select "Record" :display "the guard's own checks, before the correction"))
       (reading-links)))))

(v:defview guard-result-view (r guard-result)
  (v:html-view :title "Guard result" :priority -10
    (v:html
      (:h2 (v:esc (v:text-representation r)))
      (:p (if (result-condition r)
              (v:html "Condition: " (v:object-ref (result-condition r)) (v:esc (format nil " — ~A" (result-condition r))))
              (v:esc "No refusal was signalled.")))
      (:p (v:esc (format nil "Project Workspace packages ~:[changed~;unchanged~]; dreyeck/work/project ~:[not ~;~]loaded; the authority policy was ~:[not ~;~]enforced; at ~A (universal time)."
                         (result-packages-unchanged r) (result-loaded r) (result-enforced r) (result-at r))))
      (reading-links))))

;;; The manifest, as this reading shows it (dreyeck/source-snapshot itself defines no view for it)

(v:defview snapshot-manifest-view (manifest snap:snapshot-manifest)
  (v:html-view :title "Manifest" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (format nil "The snapshot manifest of Topic Maps ~A" (snap:manifest-commit manifest))))
       (:p "Written by " (v:object-ref (excerpt "snapshot:create") :select "Source excerpt") " from the local repository; read from "
           (v:object-ref (file-named "nix/topic-maps-b2eecffa.manifest") :select "Candidate file") ".")
       (:p (v:esc (format nil "NAR hash ~A. Excluded: ~{~A~^, ~}." (snap:manifest-nar-hash manifest) (snap:manifest-excluded manifest))))
       (:h3 "The raw commit object")
       (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (snap:manifest-commit-object manifest)))
       (:h3 (v:esc (format nil "The root tree ~A" (snap:manifest-root-tree manifest))))
       (:table :class "inspector-table"
        (:tr (:th "Mode") (:th "Type") (:th "Id") (:th "Name") (:th "In the snapshot"))
        (dolist (entry (snap:manifest-entries manifest))
          (destructuring-bind (mode type id name) entry
            (v:html (:tr (:td (:code (v:esc mode))) (:td (v:esc type)) (:td (:code (v:esc id))) (:td (:code (v:esc name)))
                         (:td (v:esc (if (member name (snap:manifest-excluded manifest) :test #'string=) "excluded: named, not shipped" "shipped"))))))))
       (:p "Checked by " (v:object-ref (evidence "archive-verification.json") :select "Record" :display "the archive verification")
           " and, on request, by " (v:object-ref (the-verification-runner) :select "Verify now" :display "the Lisp verifier") ".")
       (reading-links)))))

(hyperdoc:defhyperdoc *topic-maps-deployment-review*
  :title "Deploying Topic Maps with HyperDoc"
  :id "topic-maps-deployment-review"
  :asdf-system-name "topic-maps-deployment-review"
  :subdirectory "pages"
  :code-subdirectory "code"
  :main-page-id "Deploying Topic Maps with HyperDoc")
