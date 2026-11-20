;;;; FAQ asdf-fasl-nix-store, revision 2: hand the verified files to Codex.
;;;; A native SHOP3 plan offers one step at a time; each step is a DITA task step whose Play
;;;; control runs the check and records its evidence. The pattern is catalog-deployment-pr52.
(defpackage #:faq-asdf-handoff
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy) (#:git #:dreyeck/git) (#:hb #:hyperbook))
  (:export #:open-task #:make-handoff #:plan-next #:offered-step #:play-step #:observations
           #:message-of #:repository-of #:handover-receipt #:*open-handoff*))

;;; The diagnosis file is loaded into this package, so that its variable names stay out of CL-USER.
(defpackage #:faq-asdf-handoff/diagnosis (:use #:cl))

(in-package #:faq-asdf-handoff)

;;; What this plan is bound to: the handoff commit, its files and the lock it was verified with.

(defparameter +handoff-commit+ "07b7f51f13494d11cc48e16a72b01da65b77256c")
(defparameter +handoff-branch+ "handoff/faq-asdf-fasl-nix-store-rev2")
(defparameter +handoff-directory+ "docs/faq/asdf-fasl-nix-store/revision-2/")
(defparameter +handoff-files+
  '(("asdf-fasl-nix-store.md" "640d50e3899c857071fce890f7a634cc0c20aca36871d25d3684ff6729f2680e")
    ("check-asdf-fasl-destination.lisp" "929ba46ff8aaa0fd4c8290b36af7ab7b3a1a10d3ef58b87db36c381060fb1293")
    ("diagnose-asdf-fasl-destination.lisp" "37b20d2d7931cb2bcfca39841bd7bec2720601cc2fad2c4282c4c11c8581a1a0")
    ("HANDOVER.md" "f2704bd40ac6462f2e46c8e168edfcfb7e5e49dea61103f9bd5d429f0a2d16ec")
    ("SHA256SUMS" "1572120469e0dfca5a3b019c7c054a334d6d2dfb472210aa97c49a3764d610bb")))
(defparameter +flake-lock-sha256+ "019dcaff428e1abf426f165c3afd70fe163077454d1c348d4965d86a93a7e836")
(defparameter +nixpkgs-revision+ "50ab793786d9de88ee30ec4e4c24fb4236fc2674")

;;; HANDOVER.md, "Check: calls and expected results": case, exit code, kind of destination.
(defparameter +expected-cases+
  '(("C1" 0 :user-cache) ("C2" 0 :store) ("C3" 0 :store) ("C4" 1 :store) ("C5" 1 :store)
    ("C6" 2 :nonexistent) ("C7" 0 :user-cache) ("C8" 3 :none) ("C9" 0 :fix-a) ("C10" 0 :store)
    ("C11" 0 :user-cache)))
;;; The entry's restore table: wrapper, override, call without argument, call with NIL.
(defparameter +expected-restore+
  '(("wrapper" :store) ("override" :user-cache) ("without-argument" :user-cache) ("with-nil" :store)))

(defparameter +book-id+ "faq-asdf-fasl-nix-store-handoff")
(defparameter +task-page-id+ "handoff")
(defparameter +runner+ "dreyeck/work/faq-asdf-handoff/run-checks.sh")
(defvar *planner-lock* (sb-thread:make-mutex :name "FAQ handoff SHOP3 search"))
(defvar *open-handoff* nil)

(defclass handoff ()
  ((repository :initarg :repository :reader repository-of)
   (observations :initform nil :accessor observations)
   (message :initform nil :accessor message-of)
   (lock :initform (sb-thread:make-mutex :name "FAQ handoff") :reader lock-of)))

(defun system-directory ()
  (asdf:system-source-directory "faq-asdf-handoff"))

(defun default-repository ()
  (uiop:ensure-directory-pathname
   (git:trim-git-output (git:git-run-string (system-directory) "rev-parse" "--show-toplevel"))))

(defun make-handoff (&key (repository (default-repository)))
  (make-instance 'handoff :repository (uiop:ensure-directory-pathname repository)))

;;; The plan

(shop3:defdomain (faq-asdf-handoff :noset t)
  ((:operator (!offer ?step) () () ((offered ?step)))
   (:method (next-handoff-step)
     bind-revision ((not (observed :bind-revision))) ((!offer :bind-revision))
     check-asdf ((observed :bind-revision) (not (observed :check-asdf))) ((!offer :check-asdf))
     mac-live ((observed :check-asdf) (not (observed :mac-live))) ((!offer :mac-live))
     mac-fresh ((observed :mac-live) (not (observed :mac-fresh))) ((!offer :mac-fresh))
     hand-over ((observed :mac-fresh) (not (observed :hand-over))) ((!offer :hand-over))
     complete ((observed :hand-over)) ())))

(defun plan-next (handoff)
  "Return the native plan result for the evidence recorded so far."
  (sb-thread:with-mutex (*planner-lock*)
    (let* ((name (gensym "FAQ-HANDOFF-"))
           (facts (loop for (step) in (observations handoff) collect (list 'observed step)))
           ;; SHOP3 4.3.1's tree extractor requires a nonempty primitive plan.
           (collect-trees-p (not (assoc :hand-over (observations handoff))))
           (domain 'faq-asdf-handoff)
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain domain :silently t)
                                       (copy-tree facts) '((next-handoff-step)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain domain) :which :all
                                :verbose 0 :plan-tree collect-trees-p :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :plan-trees trees :final-states states :initial-facts facts
                            :execution-mode :plan-only))
        (shop3:delete-problem problem)))))

(defun offered-step (plan)
  (destructuring-bind (offer) (dreyeck/shop3:plans-of plan)
    (when offer (destructuring-bind ((!offer step)) offer
                  (assert (eq !offer '!offer))
                  step))))

;;; Step 1: bind the revision

(defun git-output (handoff &rest arguments)
  (git:trim-git-output (apply #'git:git-run-string (repository-of handoff) arguments)))

(defun git-exit (handoff &rest arguments)
  (nth-value 2 (apply #'git:git-run-values (repository-of handoff) arguments)))

(defun file-sha256 (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

(defun handoff-file (handoff name)
  (merge-pathnames name (merge-pathnames +handoff-directory+ (repository-of handoff))))

(defun lock-nixpkgs-revision (path)
  (let* ((nodes (gethash "nodes" (shasht:read-json (uiop:read-file-string path))))
         (node (gethash "nixpkgs" (gethash "inputs" (gethash "root" nodes)))))
    (gethash "rev" (gethash "locked" (gethash node nodes)))))

(defun image-dreyeck-revision ()
  "The checkout this image's dreyeck system comes from, as context for the Mac evidence."
  (handler-case
      (let ((directory (asdf:system-source-directory "dreyeck")))
        (list (namestring directory)
              (git:trim-git-output (git:git-run-string directory "rev-parse" "HEAD"))))
    (error () :not-a-git-checkout)))

(defun bind-revision (handoff)
  (unless (zerop (git-exit handoff "cat-file" "-e" (format nil "~A^{commit}" +handoff-commit+)))
    (error "Der Handoff-Commit ~A fehlt in diesem Checkout." +handoff-commit+))
  (let ((head (git-output handoff "rev-parse" "--verify" "HEAD^{commit}")))
    (unless (zerop (git-exit handoff "merge-base" "--is-ancestor" +handoff-commit+ head))
      (error "HEAD ~A enthält den Handoff-Commit ~A nicht." head +handoff-commit+))
    (let ((changed (loop for (name expected) in +handoff-files+
                         for path = (handoff-file handoff name)
                         unless (and (probe-file path) (equal expected (file-sha256 path)))
                           collect name))
          (lock (merge-pathnames "flake.lock" (repository-of handoff))))
      (when changed
        (error "Diese Revision-2-Dateien weichen vom Handoff ab: ~{~A~^, ~}." changed))
      (unless (equal +flake-lock-sha256+ (file-sha256 lock))
        (error "flake.lock hat SHA-256 ~A statt ~A." (file-sha256 lock) +flake-lock-sha256+))
      (unless (equal +nixpkgs-revision+ (lock-nixpkgs-revision lock))
        (error "flake.lock pinnt nixpkgs ~A statt ~A." (lock-nixpkgs-revision lock) +nixpkgs-revision+))
      (list :revision head :handoff-commit +handoff-commit+
            :clean (equal "" (git-output handoff "status" "--porcelain" "--untracked-files=no"))
            :files (mapcar #'first +handoff-files+) :flake-lock +flake-lock-sha256+
            :nixpkgs +nixpkgs-revision+ :image-dreyeck (image-dreyeck-revision)))))

;;; Steps 2 and 3: run the checks and read their lines

(defun dev-shell (handoff &rest arguments)
  "Run ARGUMENTS in the dev shell pinned by the handoff checkout's flake.lock."
  (let ((top (string-right-trim "/" (namestring (repository-of handoff)))))
    (multiple-value-bind (output diagnostic exit)
        ;; The image's SBCL wrapper sets LD_LIBRARY_PATH for its own libraries; nix must not inherit it.
        (uiop:run-program (list* "env" "-u" "LD_LIBRARY_PATH" "-u" "DYLD_LIBRARY_PATH"
                                 "nix" "develop" "--no-update-lock-file" top "-c" arguments)
                          :directory (repository-of handoff) :output :string :error-output :string
                          :ignore-error-status t)
      (unless (and (eql 0 exit) (search "CASE" output))
        (error "Der Prüflauf im Dev-Shell endete mit Exit ~A: ~A" exit
               (subseq diagnostic (max 0 (- (length diagnostic) 600)))))
      output)))

(defun parse-runner-output (text)
  "The tab-separated lines of run-checks.sh as a property list."
  (let (cases created restore platform sbcl restore-exit errors)
    (dolist (line (uiop:split-string text :separator '(#\Newline)))
      (let ((fields (uiop:split-string (string-right-trim '(#\Return) line) :separator '(#\Tab))))
        (cond ((equal (first fields) "CASE") (push (subseq fields 1) cases))
              ((equal (first fields) "CREATED") (push (subseq fields 1) created))
              ((equal (first fields) "RESTORE") (push (subseq fields 1) restore))
              ((equal (first fields) "RESTORE-EXIT") (setf restore-exit (second fields)))
              ((equal (first fields) "PLATFORM") (setf platform (second fields)))
              ((equal (first fields) "SBCL") (setf sbcl (second fields)))
              ((equal (first fields) "ERROR") (push (second fields) errors)))))
    (list :platform platform :sbcl sbcl :cases (nreverse cases) :created (nreverse created)
          :restore (nreverse restore) :restore-exit restore-exit :errors (nreverse errors))))

(defun destination-kind (destination)
  (cond ((or (null destination) (equal destination "-")) :none)
        ((uiop:string-prefix-p "/nix/store/" destination) :store)
        ((uiop:string-prefix-p "/nonexistent/" destination) :nonexistent)
        ((search "/.cache/asdf-nix-store/" destination) :fix-a)
        ((search "/common-lisp/" destination) :user-cache)
        (t :other)))

(defun deviations (parsed)
  "Every difference between the recorded lines and HANDOVER.md; NIL when all agree."
  (append
   (loop for (id exit kind) in +expected-cases+
         for found = (find id (getf parsed :cases) :key #'first :test #'equal)
         for got = (second found)
         unless (or (equal got "skipped")
                    (and found (equal got (princ-to-string exit))
                         (eq kind (destination-kind (third found)))))
           collect (list id :expected (list exit kind)
                         :got (and found (list got (destination-kind (third found))))))
   (let ((created (second (assoc "C7" (getf parsed :created) :test #'equal))))
     (unless (equal created "0") (list (list "C7" :created created))))
   (loop for (point kind) in +expected-restore+
         for found = (second (assoc point (getf parsed :restore) :test #'equal))
         unless (and found (eq kind (destination-kind found)))
           collect (list point :expected kind :got (and found (destination-kind found))))
   (unless (equal "0" (getf parsed :restore-exit))
     (list (list "restore-probe" :exit (getf parsed :restore-exit))))))

(defun check-asdf (handoff)
  (let ((parsed (parse-runner-output (dev-shell handoff "bash" +runner+))))
    (list* :deviations (deviations parsed) parsed)))

(defun platform ()
  (list :software (software-type) :machine (machine-type)
        :lisp (lisp-implementation-version) :asdf (asdf:asdf-version)
        :catalog-port (and (clog:is-running-p) clog:*clog-port*)))

(defun diagnose-in-image (handoff)
  "Load the unchanged diagnosis file into this running image and keep its printed lines."
  (let* ((file (handoff-file handoff "diagnose-asdf-fasl-destination.lisp"))
         (text (with-output-to-string (*standard-output*)
                 (let ((*package* (find-package '#:faq-asdf-handoff/diagnosis)))
                   (load file)))))
    (list :platform (platform)
          :lines (remove "" (uiop:split-string text :separator '(#\Newline)) :test #'equal))))

(defun fresh-read-only (handoff)
  (parse-runner-output (dev-shell handoff "bash" +runner+ "read-only")))

;;; Step 4: the receipt for Codex

(defun darwin-p (evidence)
  (equal "Darwin" (getf (getf evidence :platform) :software)))

(defun handover-receipt (handoff)
  "The evidence of all steps, with the steps that remain open."
  (let* ((observations (observations handoff))
         (bind (cdr (assoc :bind-revision observations)))
         (check (cdr (assoc :check-asdf observations)))
         (live (cdr (assoc :mac-live observations)))
         (fresh (cdr (assoc :mac-fresh observations))))
    (list :faq "asdf-fasl-nix-store" :handoff-commit +handoff-commit+ :branch +handoff-branch+
          :revision (getf bind :revision) :clean (getf bind :clean)
          :flake-lock (getf bind :flake-lock) :nixpkgs (getf bind :nixpkgs)
          :image-dreyeck (getf bind :image-dreyeck)
          :check-asdf (list :platform (getf check :platform) :sbcl (getf check :sbcl)
                            :cases (getf check :cases) :restore (getf check :restore)
                            :deviations (getf check :deviations))
          :mac-live live
          :mac-fresh (list :platform (getf fresh :platform) :cases (getf fresh :cases))
          :open (append
                 (when (getf check :deviations)
                   (list "Abweichungen von HANDOVER.md in Schritt 2 klären."))
                 (unless (darwin-p live)
                   (list "Lesediagnose im weissen SLY-Image auf einem Mac ausführen; dieser Lauf war nicht auf macOS."))
                 (list (format nil "Codex: PR #57 auf Basis von ~A überarbeiten (Revision 2, Review-Befunde 1 bis 3)."
                               +handoff-commit+)
                       "Öffentliche Auslieferung unter /faq/ im separaten fleet-PR für staging; Aktivierung durch den Operator.")))))

;;; Play

(defun play-step (handoff step)
  (sb-thread:with-mutex ((lock-of handoff))
    (handler-case
        (progn
          (unless (eq step (offered-step (plan-next handoff)))
            (error "Dieses Angebot ist veraltet. Aktualisiere das Pane."))
          (setf (message-of handoff) nil)
          (let ((evidence (ecase step
                            (:bind-revision (bind-revision handoff))
                            (:check-asdf (check-asdf handoff))
                            (:mac-live (diagnose-in-image handoff))
                            (:mac-fresh (fresh-read-only handoff))
                            (:hand-over (handover-receipt handoff)))))
            (push (cons step evidence) (observations handoff))
            (setf (message-of handoff)
                  (case step
                    (:bind-revision (format nil "Gebunden an ~A (enthält ~A)." (getf evidence :revision)
                                            +handoff-commit+))
                    (:check-asdf (format nil "~:[Alle Fälle wie in HANDOVER.md.~;Abweichungen: ~:*~S~]"
                                         (getf evidence :deviations)))
                    (t nil)))))
      (error (condition) (setf (message-of handoff) (princ-to-string condition)))))
  handoff)

(policy:register-reviewed-control "faq-asdf-handoff/play"
  :effect "Reads Git and file hashes of the handoff checkout, runs the revision-2 checks in fresh SBCL processes of the pinned dev shell, reads ASDF state in this image, and records the evidence."
  :audit "PLAY-STEP dispatches only the current native SHOP3 offer. No Git transport, no SSH; the checks write only temporary directories, nothing into /nix/store.")

;;; DITA

(defun ditamap-path () (merge-pathnames "faq-asdf-handoff.ditamap" (system-directory)))

(defun topic-paths ()
  "The task topics in the order of the DITA map."
  (let ((root (dita:parse-dita-topic (uiop:read-file-string (ditamap-path) :external-format :utf-8))))
    (assert (equal "map" (plump:tag-name root)))
    (loop for ref in (plump:get-elements-by-tag-name root "topicref")
          collect (merge-pathnames (plump:attribute ref "href") (system-directory)))))

(defun step-id (step) (string-downcase (symbol-name step)))

(defun topic-of-step (step)
  "The task topic that holds STEP, its parsed root and the step element."
  (loop for path in (topic-paths)
        for root = (dita:parse-dita-topic (uiop:read-file-string path :external-format :utf-8))
        for node = (plump:get-element-by-id root (step-id step))
        when node return (values path root node)))

(defun render-topic-with-play (handoff step)
  (multiple-value-bind (path root node) (topic-of-step step)
    (declare (ignore path))
    (assert (and node (equal "step" (plump:tag-name node))))
    (let ((marker (symbol-name (gensym "FAQ-HANDOFF-PLAY-"))))
      (plump:make-text-node (plump:make-element (elt (plump:get-elements-by-tag-name node "cmd") 0) "ph") marker)
      (let* ((html (dita:render-dita-topic (plump:serialize root nil)))
             (offset (or (search marker html) (error "DITA-Schritt kann kein Play anzeigen."))))
        (v:html (v:str (subseq html 0 offset)) " "
                (v:eval-button "Play" (policy:reviewed-thunk "faq-asdf-handoff/play" (play-step handoff step))
                               "Diesen SHOP3-Schritt ausführen und seinen Beleg aufnehmen")
                (v:str (subseq html (+ offset (length marker)))))))))

;;; HyperBook page

(defclass handoff-book (hb:hyperbook)
  ((task-page :initform nil :accessor task-page-of)))

(defclass handoff-page (hb:page)
  ((handoff :initarg :handoff :reader handoff-of)))

(defmethod hb:title-of ((book handoff-book)) "FAQ Handoff")
(defmethod hb:title-of ((page handoff-page)) "FAQ asdf-fasl-nix-store: Revision 2 an Codex übergeben")
(defmethod hb:main-page-id-of ((book handoff-book)) +task-page-id+)

(defmethod hb:find-page ((book handoff-book) id &key signal-error?)
  (or (and (equal id +task-page-id+) (task-page-of book))
      (when signal-error?
        (error 'hb:page-lookup-failure :hyperbook book :page-id id))))

(defun attach-task-page (book handoff)
  (setf (task-page-of book) (make-instance 'handoff-page :id +task-page-id+ :hyperbook book :handoff handoff)))

(defun task-view (handoff)
  (v:html-view :title "DITA Task" :priority -100
    (let* ((plan (plan-next handoff)) (step (offered-step plan)))
      (v:html (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · "
                  (v:esc (format nil "~S" (or step :complete))))
              (:p "Handoff-Commit " (:code (v:esc +handoff-commit+)) " · Checkout "
                  (:code (v:esc (namestring (repository-of handoff)))))
              (when (message-of handoff)
                (v:html (:p :role "status" (v:esc (message-of handoff)))))
              (:ol (dolist (path (topic-paths))
                     (v:html (:li (v:esc (dita:dita-topic-title
                                          (dita:parse-dita-topic
                                           (uiop:read-file-string path :external-format :utf-8))))))))
              (if step
                  (render-topic-with-play handoff step)
                  (v:html (:h3 "Beleg für Codex")
                          (:pre :style "white-space:pre-wrap"
                                (v:esc (let ((*print-right-margin* 110))
                                         (format nil "~S" (cdr (assoc :hand-over (observations handoff)))))))))
              (:h3 "Beobachtungen")
              (:pre :style "white-space:pre-wrap"
                    (v:esc (let ((*print-right-margin* 110))
                             (format nil "~S" (reverse (observations handoff))))))))))

(v:defview handoff-task (handoff handoff)
  (task-view handoff))

(v:defview handoff-page-task (page handoff-page)
  (task-view (handoff-of page)))

(defun open-task (&key (repository (default-repository)) (port 18757))
  "Open the handoff task in this image's running Catalog, for example the white image on port 8080;
without a running Catalog start one on loopback PORT. Return the direct task URL and the handoff."
  (let* ((handoff (make-handoff :repository repository))
         (book (or (hb:find-hyperbook +book-id+) (make-instance 'handoff-book :id +book-id+)))
         (page (attach-task-page book handoff)))
    (unless (clog:is-running-p)
      (hyperbook/server:serve-catalog :host "127.0.0.1" :port port :development nil :pane-width "850px"))
    (unless hyperbook/server::*server-parameters*
      (error "In diesem Image läuft CLOG ohne HyperBook-Catalog; die Task-Seite hätte keine Route."))
    (hb:register book)
    (setf *open-handoff* handoff)
    (values (format nil "http://127.0.0.1:~D/~A/~A" clog:*clog-port*
                    (hyperbook/server::slug book) (hb:path-item-of page))
            handoff)))
