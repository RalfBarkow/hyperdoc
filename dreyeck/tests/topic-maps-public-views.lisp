;;;; The Topic Maps views a served Catalog offers, one by one: each is rendered as a visitor gets it, and none of them offers a
;;;; run button or a plain thunk. The same views in a development server are the control: there the buttons are, so the
;;;; check that none is offered served can fail.

(defpackage #:dreyeck/topic-maps-public-views/tests
  (:use #:cl)
  (:local-nicknames (#:hv #:html-inspector-views) (#:ap #:dreyeck/authority-policy) (#:review #:dreyeck/work/topic-maps-ctm-review))
  (:export #:run-tests #:public-views #:walk-controls))
(in-package #:dreyeck/topic-maps-public-views/tests)

;;; No network. Rendering these views makes HyperBook's FedWiki client create remote sites (HYPERBOOK/FEDWIKI::GET-FEDWIKI; the hosts are named
;;; by the Work readings on Trails, hub selection and deployment, which the walk reaches from its roots). Each site starts a thread that probes its host on port
;;; 443 and fetches its sitemap. Run as it was, the test depended on the network of the machine it ran on: with live hosts the walk read their
;;; sitemaps (so what it met varied with them); in a build sandbox without network the lookup fails with USOCKET:NS-TRY-AGAIN-ERROR, which
;;; INITIALIZE-FEDWIKI does not handle (it handles host-not-found, timeout, stream and JSON errors), so the unhandled condition in that thread
;;; ended the whole test process (dreyeck/tests ... Nix check, observed 2026-11-02).
;;; The harness gives the test the network it can rely on everywhere: every host fails to resolve, which is a case INITIALIZE-FEDWIKI
;;; handles and keeps as the site's status. It uses only MAKE-FEDWIKI's own keyword seam (:PROTOCOL-PROBE, :SITEMAP-FETCHER,
;;; :PLUGIN-DATA-FETCHER, there to inject operations while preserving production behaviour) and replaces the visited-site table for the
;;; duration. No library source is changed; the function is replaced only while the harness runs and only in its thread; calls that
;;; name their own operations are left as they are.

;;; The replacement of MAKE-FEDWIKI is a global SETF of its function, which every thread sees, so it acts only in the thread that bound
;;; *OFFLINE-FEDWIKI-P* (a binding is thread-local): any other thread, such as a request thread of a Catalog served from the same image,
;;; gets the original function and the original table. The sites' threads are finished and the original function is restored on every
;;; exit, normal or not.

(defvar *offline-fedwiki-p* nil "True only inside CALL-WITH-OFFLINE-FEDWIKI and only in the thread that called it.")
(defvar *offline-hosts* nil "The hosts the views asked FedWiki for during the last CALL-WITH-OFFLINE-FEDWIKI, in order of first request.")

(defun %host-not-found (host)
  (error 'usocket:ns-host-not-found-error :socket nil :host-or-ip host))

(defun %finish-offline-sites ()
  "Wait for the thread of every site in the table. A thread that ended abnormally is left to the status check."
  (loop for wiki being the hash-values of hyperbook/fedwiki::*neighborhood*
        for status = (hyperbook/fedwiki::status-of wiki)
        do (when (typep status 'bordeaux-threads:thread)
             (handler-case (bordeaux-threads:join-thread status) (error () nil)))))

(defun call-with-offline-fedwiki (function)
  "Call FUNCTION in a world where no FedWiki host resolves: no socket is opened and no file is read from a remote site. Afterwards, check that
every site the views created finished by retaining the host-not-found condition, as INITIALIZE-FEDWIKI does for it, and return FUNCTION's
values; the hosts are in *OFFLINE-HOSTS*. Only this thread is affected; the original function is restored on every exit."
  (let* ((symbol 'hyperbook/fedwiki::make-fedwiki)
         (original (fdefinition symbol))
         (hyperbook/fedwiki::*neighborhood* (make-hash-table :test #'equal))
         (*offline-fedwiki-p* t)
         (hosts nil) values)
    (setf *offline-hosts* nil)
    (unwind-protect
         (progn
           (setf (fdefinition symbol)
                 (lambda (domain-name &rest arguments)
                   (if *offline-fedwiki-p*
                       (progn
                         (pushnew domain-name hosts :test #'string=)
                         ;; ARGUMENTS come first, so a caller that names an operation keeps it.
                         (apply original domain-name
                                (append arguments
                                        (list :protocol-probe (lambda (host) (%host-not-found host))
                                              :sitemap-fetcher (lambda (wiki) (%host-not-found (hyperbook/fedwiki::domain-name-of wiki)))
                                              :plugin-data-fetcher (lambda (wiki) (%host-not-found (hyperbook/fedwiki::domain-name-of wiki)))))))
                       (apply original domain-name arguments))))
           (setf values (multiple-value-list (funcall function)))
           (setf *offline-hosts* (reverse hosts))
           ;; The sites' threads are finished before judging them: none may outlive the harness or die with an unhandled condition.
           (%finish-offline-sites)
           (loop for wiki being the hash-values of hyperbook/fedwiki::*neighborhood*
                 for final = (hyperbook/fedwiki::status-of wiki)
                 do (assert (typep final 'usocket:ns-host-not-found-error) ()
                            "~A did not finish by retaining the host-not-found condition: ~S" (hyperbook/fedwiki::domain-name-of wiki) final)
                    (assert (member (hyperbook/fedwiki::domain-name-of wiki) *offline-hosts* :test #'string=) ()
                            "~A is in the table but was not made by the offline harness." (hyperbook/fedwiki::domain-name-of wiki)))
           (values-list values))
      ;; Every exit: the threads of the sites first, then the original function.
      (%finish-offline-sites)
      (setf (fdefinition symbol) original))))

(defun check-offline-harness ()
  "The harness itself, run outside it: it restores the function and the table on a normal and on a non-local exit, finishes the sites'
threads on both, acts only in its own thread, and leaves an operation that a caller names to that caller."
  (let ((original (fdefinition 'hyperbook/fedwiki::make-fedwiki))
        (table hyperbook/fedwiki::*neighborhood*)
        (own-probe-called nil) wiki)
    (flet ((restored-p ()
             (and (eq original (fdefinition 'hyperbook/fedwiki::make-fedwiki)) (eq table hyperbook/fedwiki::*neighborhood*)
                  (not *offline-fedwiki-p*)))
           (own-operations (host)
             (list :protocol-probe (lambda (h) (declare (ignore h)) (setf own-probe-called t) (%host-not-found host))
                   :sitemap-fetcher (lambda (w) (declare (ignore w)) (%host-not-found host))
                   :plugin-data-fetcher (lambda (w) (declare (ignore w)) (%host-not-found host)))))
      ;; Normal exit.
      (call-with-offline-fedwiki (lambda () (hyperbook/fedwiki::get-fedwiki "check-normal.invalid")))
      (assert (restored-p) () "The offline harness did not restore the function and the table after a normal exit.")
      (assert (equal '("check-normal.invalid") *offline-hosts*))
      ;; Non-local exit: restored, and the site's thread finished, not left running.
      (assert (handler-case (call-with-offline-fedwiki
                             (lambda () (setf wiki (hyperbook/fedwiki::get-fedwiki "check-error.invalid")) (error "the test fails here")))
                (error () t))
              () "The error did not propagate out of the offline harness.")
      (assert (restored-p) () "The offline harness did not restore the function and the table after an error.")
      (assert (typep (hyperbook/fedwiki::status-of wiki) 'usocket:ns-host-not-found-error) ()
              "The site's thread was not finished when the harness was left by an error: ~S" (hyperbook/fedwiki::status-of wiki))
      ;; Another thread is not affected, and does not disturb the harness.
      (call-with-offline-fedwiki
       (lambda ()
         (bordeaux-threads:join-thread
          (bordeaux-threads:make-thread
           (lambda () (apply #'hyperbook/fedwiki::make-fedwiki "check-other-thread.invalid" (own-operations "check-other-thread.invalid")))))
         (hyperbook/fedwiki::get-fedwiki "check-own-thread.invalid")))
      (assert (equal '("check-own-thread.invalid") *offline-hosts*) ()
              "The offline harness acted in another thread: ~S" *offline-hosts*)
      ;; An operation the caller names is the caller's.
      (setf own-probe-called nil)
      (call-with-offline-fedwiki
       (lambda ()
         (let ((site (apply #'hyperbook/fedwiki::make-fedwiki "check-own-operations.invalid" (own-operations "check-own-operations.invalid"))))
           (hyperbook/fedwiki::wait-for-sitemap site))))
      (assert own-probe-called () "The offline harness replaced an operation the caller named.")
      (assert (restored-p))))
  t)

(defun served (thunk)
  "THUNK run as the served Catalog runs: a server up, not in development mode."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil))
    (funcall thunk)))

(defun developing (thunk)
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" t))
    (funcall thunk)))

(defun public-views ()
  "Each Topic Maps view that loading dreyeck/work/topic-maps-ctm-review adds to a Catalog: (LABEL OBJECT-THUNK VIEW-TITLES
RUN-BUTTON-LABELS). The objects are made when the list is used, not when this file is loaded."
  (list (list "22U reading page" (lambda () (hyperdoc:page "Reading Slice 22U" :hyperbook "dreyeck/work/topic-maps-project-example"))
              '("Topic Maps 22U") '("Read a fresh 22U Map" "Exercise on a separate fresh Map"))
        (list "Work Breakdown page (an existing page, gaining two views)"
              (lambda () (hyperdoc:page "Work Breakdown" :hyperbook "dreyeck/work/reading"))
              '("Topic Maps 22U" "TMDM model") '("Read a fresh 22U Map" "Exercise on a separate fresh Map"))
        (list "Authoring the CTM Plan Page (an existing page, gaining one view)"
              (lambda () (hyperdoc:page "Authoring the CTM Plan Page" :hyperbook "dreyeck/work/reading"))
              '("TMDM model") '())
        (list "the work topic ctm-plan-page-authoring" (lambda () (uiop:symbol-call :dreyeck/work/tmdm-reading :ctm-work-topic))
              '("TMDM model") '("Read default-type example" "Read explicit-type example"))
        (list "CTM review page" (lambda () (hyperdoc:page "Reviewing the CTM Reader" :hyperbook "dreyeck/work/topic-maps-ctm-review"))
              '() '())
        (list "CTM review claim scheme-plus" (lambda () (review:claim-named "scheme-plus"))
              '() '("Run the experiment"))))

(defun %references (view)
  (hv:view-html view)
  (mapcar #'cdr (hv:view-references view)))

(defun %closure (view &optional (seen (make-hash-table :test #'eq)))
  "VIEW and every view it transcludes, as lists of (HTML . REFERENCES)."
  (unless (gethash view seen)
    (setf (gethash view seen) t)
    (cons (cons (hv:view-html view) (%references view))
          (loop for reference in (%references view)
                when (typep reference 'hv:view) append (%closure reference seen)))))

(defparameter +generic-clog-views+ '("Source" "<span style=\"color: #666;\">Playground</span>")
  "The views of every Inspector object that draw with CLOG instead of HTML, and so have no thunk to read. Source shows source code;
the Playground evaluates only where the Inspector is started with its playground flag, which a served Catalog does not set.")

(defun html-views (object)
  "OBJECT's HTML views. Any other view must be one of the generic CLOG views, or the Catalog has a view this test cannot read."
  (loop for view in (hv:all-views object)
        if (typep view 'hv:html-view) collect view
        else do (assert (member (hv:view-title view) +generic-clog-views+ :test #'string=) ()
                        "~S is a ~S, which this test cannot read" (hv:view-title view) (type-of view))))

(defun rendered (object)
  "All HTML and all references of every HTML view OBJECT has."
  (let ((rows (loop for view in (html-views object) append (%closure view))))
    (values (format nil "~{~A~^~%~}" (mapcar #'car rows)) (loop for row in rows append (cdr row)))))

(defun plain-thunk-p (reference) (and (typep reference 'hv:thunk) (eq (class-of reference) (find-class 'hv:thunk))))

;;; Every executable control a visitor can reach by navigation, found by walking the views and not by reading the call sites.

(defun %view-refs (view seen)
  "VIEW's references, (ID . TARGET), and those of the views it transcludes."
  (hv:view-html view)
  (loop for ref in (hv:view-references view)
        collect ref
        when (and (typep (cdr ref) 'hv:view) (not (gethash (cdr ref) seen)))
          append (progn (setf (gethash (cdr ref) seen) t) (%view-refs (cdr ref) seen))))

(defun walk-controls (roots &key (max-objects 300) (max-depth 2) (max-seconds 1800))
  "Walk the HTML views of ROOTS and, through their inspect references, of what these lead to, breadth first, as a visitor can. What is reached is
fixed by MAX-OBJECTS and MAX-DEPTH, so that it is the same on every machine; MAX-SECONDS is only a safety stop.
A control is a reference the Inspector evaluates when clicked: its id begins eval- or action-. Returns a plist: :CONTROLS (type title id class),
:OBJECTS and :VIEWS counts, :SECONDS, :CLOG-VIEWS (type . title), :ERRORS (type . condition type), :TRUNCATED."
  (let ((seen (make-hash-table :test #'eq)) (views-seen (make-hash-table :test #'eq))
        (queue (mapcar (lambda (root) (cons root 0)) roots))
        controls clog errors visited (objects 0) (views 0) truncated (start (get-internal-real-time)))
    (loop while queue
          do (destructuring-bind (object . depth) (pop queue)
               (unless (gethash object seen)
                 (setf (gethash object seen) t)
                 (cond ((or (>= objects max-objects) (> (/ (- (get-internal-real-time) start) internal-time-units-per-second) max-seconds))
                        (setf truncated t queue nil))
                       (t (incf objects) (push object visited)
                          (handler-case
                              (dolist (view (cons (hv:title-bar-action-buttons object) (hv:all-views object)))
                                (cond ((typep view 'hv:html-view)
                                       (incf views)
                                       (dolist (ref (%view-refs view views-seen))
                                         (let ((id (car ref)) (target (cdr ref)))
                                           (cond ((or (uiop:string-prefix-p "eval-" id) (uiop:string-prefix-p "action-" id))
                                                  (push (list (type-of object) (or (hv:view-title view) "title bar") id (type-of target) target) controls))
                                                 ((and (uiop:string-prefix-p "inspect-" id) (< depth max-depth))
                                                  (setf queue (nconc queue (list (cons target (1+ depth))))))))))
                                      (t (push (cons (type-of object) (hv:view-title view)) clog))))
                            (error (condition) (push (cons (type-of object) (type-of condition)) errors))))))))
    (list :seconds (round (- (get-internal-real-time) start) internal-time-units-per-second) :controls (nreverse controls) :objects objects :views views :clog-views (nreverse clog) :errors (nreverse errors) :visited (nreverse visited) :truncated truncated)))

(defun check-view (label object titles buttons)
  (let ((titles-here (mapcar #'hv:view-title (hv:all-views object))))
    (dolist (title titles) (assert (member title titles-here :test #'string=) () "~A: no view ~S in ~S" label title titles-here)))
  ;; Served: every run button is a marker; no plain thunk is reachable from any view.
  (multiple-value-bind (html references) (served (lambda () (rendered object)))
    (assert (notany #'plain-thunk-p references) () "~A: a plain thunk is reachable when served" label)
    (dolist (button buttons)
      (assert (search (format nil "~A (not run in a served Catalog)" button) html) () "~A: ~S is not shown as not offered" label button)
      (assert (not (search (format nil ">~A</button>" button) html)) () "~A: ~S is offered as a button when served" label button)))
  ;; The control: the same views in a development server do offer them, so the check above could fail.
  (when buttons
    (multiple-value-bind (html references) (developing (lambda () (rendered object)))
      (assert (some #'plain-thunk-p references) () "~A: no plain thunk reachable even when developing; the check proves nothing" label)
      (dolist (button buttons)
        (assert (search (format nil ">~A</button>" button) html) () "~A: ~S is not a button when developing" label button)))))

;;; The controls reachable by navigation, classified. Served, the boundary has already replaced every control that is not reviewed, so the walk
;;; may meet only these kinds, and fails on anything else:
;;;  - a target that is not a thunk (the Inspector's eval-thunk returns it, and a pane opens for it);
;;;  - an OPERATION-THUNK of the slot-reader contract (gated again when clicked, and it reads one slot);
;;;  - a REVIEWED-THUNK, or an instance of a reviewed class: the cursor, point and request controls the owner keeps;
;;;  - a REFUSED-THUNK: a control no one reviewed, which the boundary replaced. The Catalog shows it and does not run it; they are reported.

(defun control-kind (control)
  (let ((target (fifth control)))
    (cond ((not (typep target 'hv:thunk)) :inert)
          ((typep target 'ap:operation-thunk)
           (if (eq (ap:method-contract (ap::operation-thunk-method target)) ap::+slot-reader-contract+) :slot-reader :unknown))
          ((typep target 'ap:refused-thunk) :refused)
          ((typep target 'ap:reviewed-thunk) :reviewed)
          ((ap::%reviewed-control-class-p target) :reviewed-class)
          (t :unknown))))

(defun controls-of-kind (kind controls) (remove-if-not (lambda (control) (eq kind (control-kind control))) controls))

(defun served-walk (roots &rest keys) (served (lambda () (apply #'walk-controls roots keys))))

(defun click (reference) (uiop:symbol-call :dreyeck/authority-policy/tests :click reference))

(defvar *walk* nil "The result of the last served walk, for the checks that need an object it met.")

(defun check-reachable-controls ()
  "Walk from the six public objects, and from the two refused systems' definitions, as a served visitor can, and classify every control."
  (let* ((roots (append (mapcar (lambda (entry) (funcall (second entry))) (public-views))
                        (list (asdf:find-system "dreyeck/work/project" nil) (asdf:find-system "dreyeck/page-attached-hyperdoc" nil))))
         (result (served-walk (remove nil roots) :max-objects 300 :max-depth 2 :max-seconds 1800))
         (controls (getf result :controls)))
    (setf *walk* result)
    (assert (plusp (length controls)) () "the walk found no control at all: it proves nothing")
    (assert (controls-of-kind :slot-reader controls) () "no gated control was met: the classification is untested")
    (assert (null (controls-of-kind :unknown controls)) () "Controls reachable when served that are none of the allowed kinds: ~S"
            (remove-duplicates (mapcar (lambda (c) (list (fourth c) (first c) (second c))) (controls-of-kind :unknown controls)) :test #'equal))
    (assert (or (controls-of-kind :reviewed controls) (controls-of-kind :reviewed-class controls)) ()
            "no reviewed control was met: the cursor and point controls are not reachable in this walk")
    (list :objects (getf result :objects) :truncated (getf result :truncated) :controls (length controls)
          :kinds (loop for kind in '(:inert :slot-reader :reviewed :reviewed-class :refused) collect (cons kind (length (controls-of-kind kind controls))))
          :reviewed-met (remove-duplicates
                         (loop for c in controls
                               for target = (fifth c)
                               when (typep target 'ap:reviewed-thunk) collect (list (ap::reviewed-thunk-identity target) (first c) (second c))
                               when (eq :reviewed-class (control-kind c)) collect (list (type-of target) (first c) (second c)))
                         :test #'equal)
          :refused (remove-duplicates (mapcar (lambda (c) (list (type-of (ap:refused-thunk-original (fifth c))) (first c) (second c))) (controls-of-kind :refused controls))
                                      :test #'equal))))

(defclass probe-object () ())
(hv:defview probe-view (object probe-object)
  (hv:html-view :title "Probe" :priority 1
    (hv:html (:p (hv:eval-button "Extra button" (hv:thunk :ran) "a new executable button")
                 (ap:run-button "Adapter button" (hv:thunk :ran) "through the adapter")))))

(defun check-an-extra-button-is-refused ()
  "A button added later by hv:eval-button, not through the adapter and not reviewed, is met by the walk as a REFUSED-THUNK when served: the
boundary replaced it when the view was made. (Creation and invocation are tested one by one in dreyeck/tests/authority-policy.lisp.)"
  (let* ((result (served-walk (list (make-instance 'probe-object)) :max-objects 5 :max-depth 0))
         (controls (getf result :controls)))
    (assert (= 1 (length controls)) () "expected exactly the plain probe button, found ~S" controls)
    (assert (eq :refused (control-kind (first controls))))
    (assert (eq (find-class 'hv:thunk) (class-of (ap:refused-thunk-original (fifth (first controls))))))
    (assert (typep (click (cons (third (first controls)) (fifth (first controls)))) 'ap:invocation-refused)))
  t)

(defun %first-visited (type visited) (find-if (lambda (object) (typep object type)) visited))

(defun %controls-of-view (object title)
  (let ((view (find title (hv:all-views object) :key #'hv:view-title :test #'string=)))
    (assert view () "~S has no view ~S" object title)
    (sort (remove-if-not (lambda (reference) (or (uiop:string-prefix-p "eval-" (car reference)) (uiop:string-prefix-p "action-" (car reference))))
                         (copy-list (hv:view-references view)))
          #'< :key (lambda (reference) (parse-integer (car reference) :start (1+ (position #\- (car reference))))))))

(defun check-allowed-controls-work ()
  "The cursor and Point controls the owner keeps still work when served: clicked through the Inspector's own path, the conversation
cursor moves and moves back, and a Workspace sign moves the Point (restored afterwards)."
  (let* ((visited (getf *walk* :visited))
         (session (%first-visited (find-symbol "CONVERSATION-SESSION" :dreyeck/work/conversation-coordinates) visited))
         (workspace (%first-visited (find-symbol "TOPICMAP-WORKSPACE" :dreyeck/topicmap) visited)))
    (assert session () "the walk met no conversation session")
    (assert workspace () "the walk met no Topicmap Workspace")
    (served
     (lambda ()
       (let* ((cursor (find-symbol "SESSION-CURSOR" :dreyeck/work/conversation-coordinates))
              (messages (find-symbol "SESSION-MESSAGES" :dreyeck/work/conversation-coordinates))
              (controls (%controls-of-view session "Chronology")))
         (assert (= 2 (length controls)))
         (assert (every (lambda (c) (typep (cdr c) 'ap:reviewed-thunk)) controls) () "the cursor controls are not reviewed thunks: ~S" controls)
         (let ((before (funcall cursor session)) (length (length (funcall messages session))))
           (click (second controls))
           (assert (= (funcall cursor session) (min (1+ before) (1- length))))
           (click (first controls))
           (assert (= (funcall cursor session) before)))))
     )
    (served
     (lambda ()
       (let* ((point (find-symbol "TOPICMAP-WORKSPACE-POINT-OF" :dreyeck/topicmap))
              (history (find-symbol "TOPICMAP-WORKSPACE-HISTORY-OF" :dreyeck/topicmap))
              (old-point (funcall point workspace)) (old-history (copy-list (funcall history workspace)))
              (moves (remove-if-not (lambda (c) (or (typep (cdr c) 'ap:reviewed-thunk) (ap::%reviewed-control-class-p (cdr c))))
                                    (%controls-of-view workspace "Topicmap"))))
         (assert moves () "the Workspace view offers no reviewed control")
         (unwind-protect
              (dolist (move (subseq moves 0 (min 3 (length moves))))
                (assert (not (typep (click move) 'ap:invocation-refused)) () "a reviewed Workspace control was refused"))
           (eval `(setf (,point ',workspace) ',old-point))
           (eval `(setf (,history ',workspace) ',old-history)))))))
  t)

(defun check-workspace-link-withheld ()
  "The direct link from the TMDM model view to the shared Workspace is not in a served Catalog's view, and is there in a development server."
  (let ((topic (uiop:symbol-call :dreyeck/work/tmdm-reading :ctm-work-topic)))
    (assert (not (search "Existing Work Workspace" (served (lambda () (rendered topic))))))
    (assert (search "Existing Work Workspace" (developing (lambda () (rendered topic))))))
  t)

(defparameter +reading-systems+
  '("dreyeck/work/topic-maps-project-example" "dreyeck/work/topic-maps-ctm-review" "dreyeck/work/tmdm-reading"))

(defun check-readings-make-no-direct-controls ()
  "Every control the three readings make goes through RUN-BUTTON: their sources hold no other construction of one."
  (dolist (name +reading-systems+)
    (dolist (component (asdf:component-children (asdf:find-system name)))
      (when (typep component 'asdf:cl-source-file)
        (let ((text (uiop:read-file-string (asdf:component-pathname component))))
          (dolist (forbidden '("eval-button" "action-button" "action-id" "eval-id" "set-on-click" "set-on-mouse-click"))
            (let ((at (search forbidden text)))
              (loop while at
                    do (assert (and (>= at 4) (string= "run-" text :start2 (- at 4) :end2 at)) ()
                               "~A holds ~A outside RUN-BUTTON" (asdf:component-pathname component) forbidden)
                       (setf at (search forbidden text :start2 (1+ at))))))))))
  t)

(defun system-closure (name &optional (seen (make-hash-table :test #'equal)))
  (let ((system (asdf:find-system name nil)))
    (when (and system (not (gethash name seen)))
      (setf (gethash name seen) t)
      (dolist (spec (asdf:system-depends-on system))
        (let ((dependency (ignore-errors (asdf/find-component:resolve-dependency-spec system spec))))
          (when (typep dependency 'asdf:system) (system-closure (asdf:component-name dependency) seen))))))
  seen)

(defun check-refused-systems-unreachable ()
  "The Project Workspace and the page-attached loader are in no served system's closure, are not loaded, and the startup guard accepts
the system a service would name."
  (dolist (name (list* "dreyeck/catalog" "dreyeck/catalog-application" "dreyeck/topic-maps-public-views" +reading-systems+))
    (let ((closure (system-closure name)))
      ;; With the guard's own definition of what is refused: the Project Workspace and its subsystems, the page-attached loader and its.
      (assert (notany (lambda (key) (or (uiop:symbol-call :dreyeck/catalog-topic-maps :refused-system-p key)
                                        (uiop:symbol-call :dreyeck/catalog-topic-maps :loader-system-p key)))
                      (loop for key being the hash-keys of closure collect key))
              () "~A reaches a refused system" name)))
  (assert (not (find-package "DREYECK/WORK/PROJECT")))
  (assert (not (asdf:component-loaded-p "dreyeck/work/project")))
  (assert (not (asdf:component-loaded-p "dreyeck/page-attached-hyperdoc")))
  (assert (equal "dreyeck/work/topic-maps-ctm-review"
                 (uiop:symbol-call :dreyeck/catalog-topic-maps :refuse-project-workspace "dreyeck/work/topic-maps-ctm-review")))
  t)

(defun policy-around-p (method)
  (and (equal '(:around) (method-qualifiers method))
       (let ((source (ignore-errors (sb-introspect:find-definition-source method))))
         (and source (let ((path (sb-introspect:definition-source-pathname source))) (and path (search "authority-policy" (namestring path))))))))

(defun method-source-name (method)
  (let ((source (ignore-errors (sb-introspect:find-definition-source method))))
    (and source (let ((path (sb-introspect:definition-source-pathname source))) (and path (namestring path))))))

(defun playground-pages ()
  "The playground pages of every registered HyperDoc: the Catalog has none."
  (loop for book in (hyperbook::hyperbooks-of hyperbook::*catalog*)
        when (typep book 'hyperdoc:hyperdoc)
          append (remove-if-not (lambda (tool) (typep tool 'hyperdoc::playground-page)) (hyperdoc::tools-of book))))

(defun check-title-bar-actions-withheld ()
  "Every class with a primary TITLE-BAR-ACTION-BUTTONS method has one of the policy's withholding :around methods applicable, so its
actions are cleared when served, with two reviewed exceptions: WIKIPEDIA-PAGE, whose method is this repository's replacement and offers a
link, not a thunk; and PLAYGROUND-PAGE, whose Reset button writes the playground store only and which no registered HyperDoc has an instance of.
A class the policy's drift report names (CONTEXT-FEDWIKI-PAGE) is covered through FEDWIKI-PAGE."
  (let ((uncovered
          (loop for method in (c2mop:generic-function-methods #'hv:title-bar-action-buttons)
                for class = (first (c2mop:method-specializers method))
                when (and (null (method-qualifiers method)) (typep class 'class) (not (eq class (find-class t)))
                          (notany #'policy-around-p (c2mop:compute-applicable-methods-using-classes #'hv:title-bar-action-buttons (list class))))
                  collect (cons (class-name class) method))))
    (dolist (entry uncovered)
      (let ((name (symbol-name (car entry))))
        (assert (or (and (string= name "WIKIPEDIA-PAGE") (search "wikipedia-title-bar" (or (method-source-name (cdr entry)) "")))
                    (and (string= name "PLAYGROUND-PAGE") (null (playground-pages))))
                () "title-bar actions of ~S are not withheld when served" (car entry))))
    (assert (find "CONTEXT-FEDWIKI-PAGE" (c2mop:class-direct-subclasses (find-class 'hyperbook/fedwiki::fedwiki-page))
                  :key (lambda (c) (symbol-name (class-name c))) :test #'string=)
            () "the class the drift report names is no longer a FEDWIKI-PAGE: this check no longer explains it")
    (assert (notany (lambda (entry) (string= "CONTEXT-FEDWIKI-PAGE" (symbol-name (car entry)))) uncovered)))
  t)

(defun run-tests ()
  (check-offline-harness)
  (prog1 (call-with-offline-fedwiki #'run-tests-1)
    (format t "~&TOPIC-MAPS-PUBLIC-VIEWS-OFFLINE: ~D remote FedWiki site~:P asked for by the views, none contacted (every host fails to resolve, a case the FedWiki client retains as the site's status): ~{~A~^, ~}.~%"
            (length *offline-hosts*) *offline-hosts*)))

(defun run-tests-1 ()
  (let ((count 0) (buttons 0))
    (dolist (entry (public-views))
      (destructuring-bind (label object-thunk titles run-buttons) entry
        (check-view label (funcall object-thunk) titles run-buttons)
        (incf count) (incf buttons (length run-buttons))))
    (check-readings-make-no-direct-controls)
    (check-refused-systems-unreachable)
    (check-title-bar-actions-withheld)
    (check-workspace-link-withheld)
    (check-an-extra-button-is-refused)
    (uiop:symbol-call :dreyeck/authority-policy/tests :run-gate-tests)
    (let ((walk (check-reachable-controls)))
      (check-allowed-controls-work)
      (format t "~&TOPIC-MAPS-PUBLIC-VIEWS-PASS: ~D objects, rendered served and developing; ~D run buttons are markers served and buttons developing; no plain thunk is reachable from any served view. Walked ~D objects by navigation (~:[complete~;bounded, not exhaustive~]): ~D controls (~{~(~A~)~^, ~}); none of an unknown kind; reviewed ones met: ~S; refused as unreviewed: ~S. The reviewed cursor and Point controls work when clicked; an extra button is refused at run time; the authority-policy gate checks pass; the readings make no direct control; the refused systems are unreachable; every title-bar action is withheld; the Workspace link is not in the served view.~%"
              count buttons (getf walk :objects) (getf walk :truncated) (getf walk :controls) (mapcar (lambda (kind) (format nil "~(~A~)=~D" (car kind) (cdr kind))) (getf walk :kinds)) (getf walk :reviewed-met) (getf walk :refused)))
    t))
