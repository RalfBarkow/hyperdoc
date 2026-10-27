(defpackage #:dreyeck/catalog-topic-maps/tests
  (:use #:cl)
  (:local-nicknames (#:c #:dreyeck/catalog-topic-maps) (#:snap #:dreyeck/source-snapshot)
                    (#:ex #:dreyeck/work/topic-maps-project-example))
  (:export #:run-tests))
(in-package #:dreyeck/catalog-topic-maps/tests)
(defvar *checks* nil)
(defmacro check (label form)
  `(progn (unless ,form (error "Topic Maps Catalog check failed: ~A" ,label)) (push ,label *checks*)))
(defmacro refused (form) `(handler-case (progn ,form nil) (c:project-workspace-refused () t)))

(defun system-closure (name &optional (seen (make-hash-table :test #'equal)))
  "The names of the systems NAME reaches, found from their definitions alone."
  (let ((system (asdf:find-system name nil)))
    (when (and system (not (gethash name seen)))
      (setf (gethash name seen) t)
      (dolist (spec (asdf:system-depends-on system))
        (let ((dependency (ignore-errors (asdf/find-component:resolve-dependency-spec system spec))))
          (when (typep dependency 'asdf:system) (system-closure (asdf:component-name dependency) seen))))))
  seen)

(defun project-packages ()
  (remove-if-not (lambda (p) (uiop:string-prefix-p "DREYECK/WORK/PROJECT" (package-name p))) (list-all-packages)))

(defun run-tests ()
  "The package's own contract. It runs only on the package's snapshot, as the caller must state."
  (unless (equal "nix-store-snapshot" (uiop:getenv "HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE"))
    (error "These checks need the packaged Topic Maps snapshot; HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE must say nix-store-snapshot."))
  (let ((*checks* nil))
    ;; One pin: the package, the 22U reading, the review and the manifest name the same commit.
    (check :one-pinned-commit (and (string= c:+topic-maps-commit+ ex:+source-revision+)
                                   (string= c:+topic-maps-commit+ (snap:manifest-commit (snap:find-snapshot-manifest ex:+source-revision+)))))
    ;; ASDF's Topic Maps systems all come from the verified /nix/store snapshot; HyperDoc from its own store source.
    (let ((verification (c:topic-maps-origins)))
      (check :origins-are-the-verified-snapshot
             (and (typep verification 'snap:snapshot-verification)
                  (uiop:string-prefix-p "/nix/store/" (namestring (snap:verification-root verification)))))
      (check :hyperdoc-from-a-store-source (eq :nix-store-snapshot (snap:source-kind (asdf:system-source-directory "dreyeck"))))
      (check :hyperdoc-revision-stated (plusp (length (uiop:getenv "HYPERDOC_SOURCE_REVISION")))))
    ;; Loopback only.
    (check :loopback-hosts (and (c:loopback-host-p "127.0.0.1") (c:loopback-host-p "::1")))
    (check :public-hosts-refused (notany #'c:loopback-host-p '("0.0.0.0" "::" "localhost" "dreyeck.ch" "" nil)))
    ;; The Project Workspace and anything depending on it are refused at startup, from system definitions alone: the check is
    ;; the application's own, and it adds no method to ASDF (scripts/test-asdf-method-preservation.lisp tests that, in a
    ;; fresh process, before and after loading this system).
    (check :refused-names (and (c:refused-system-p "dreyeck/work/project") (c:refused-system-p "dreyeck/work/project/tests")
                               (not (c:refused-system-p "dreyeck/work/projects")) (not (c:refused-system-p "dreyeck/work/project-x"))))
    (let ((before (project-packages)) (loaded (asdf:already-loaded-systems)))
      (check :project-workspace-refused (refused (c:refuse-project-workspace "dreyeck/work/project")))
      (check :project-workspace-tests-refused (refused (c:refuse-project-workspace "dreyeck/work/project/tests")))
      (asdf:defsystem "dreyeck/catalog-topic-maps/probe-depending-on-project" :depends-on ("dreyeck/work/project"))
      (asdf:defsystem "dreyeck/catalog-topic-maps/probe-depending-indirectly" :depends-on ("dreyeck/catalog-topic-maps/probe-depending-on-project"))
      (unwind-protect
           (progn (check :dependent-refused (refused (c:refuse-project-workspace "dreyeck/catalog-topic-maps/probe-depending-on-project")))
                  (check :indirect-dependent-refused (refused (c:refuse-project-workspace "dreyeck/catalog-topic-maps/probe-depending-indirectly"))))
        (asdf:clear-system "dreyeck/catalog-topic-maps/probe-depending-on-project")
        (asdf:clear-system "dreyeck/catalog-topic-maps/probe-depending-indirectly"))
      ;; Before anything is loaded: the refusal itself loaded no system and created no package of the Project Workspace.
      (check :nothing-of-it-loaded (and (equal before (project-packages)) (equal loaded (asdf:already-loaded-systems))
                                        (not (asdf:component-loaded-p "dreyeck/work/project"))))
      ;; The startup: the origins are verified first, and the refusal follows, before the Catalog starts anything.
      (let* ((output (make-string-output-stream))
             (refusal (let ((*standard-output* output)) (handler-case (progn (c:verify-startup "dreyeck/work/project") nil) (c:project-workspace-refused (c) c)))))
        (check :startup-refuses-the-project-workspace (typep refusal 'c:project-workspace-refused))
        (check :startup-verified-origins-first (search "Topic Maps snapshot verified without .git" (get-output-stream-string output)))
        (check :startup-refusal-says-why (search "is bound to Topic Maps 5a4a668" (princ-to-string refusal))))
      (check :startup-permits-the-default-catalog (typep (let ((*standard-output* (make-broadcast-stream))) (c:verify-startup "dreyeck/catalog")) 'snap:snapshot-verification))
      (check :startup-permits-the-optional-readings
             (every (lambda (name) (let ((*standard-output* (make-broadcast-stream))) (c:verify-startup name)))
                    '("dreyeck/work/topic-maps-ctm-review" "dreyeck/work/topic-maps-project-example")))
      (check :nothing-loaded-by-permitting (and (equal before (project-packages)) (not (asdf:component-loaded-p "dreyeck/work/project")))))
    ;; After startup, the one application path that loads a system named by a wiki page is refused as a catalog system, together
    ;; with the systems that depend on it (the activation button of a local FedWiki page is among them).
    (check :loader-refused
           (typep (handler-case (progn (c:refuse-project-workspace "dreyeck/page-attached-hyperdoc") nil) (c:project-workspace-refused (c) c))
                  'c:page-attached-loader-refused))
    (check :loader-dependents-refused
           (every (lambda (name) (refused (c:refuse-project-workspace name)))
                  '("dreyeck/fedwiki-hyperdoc" "dreyeck/local-fedwiki-page/activation-inspector" "dreyeck/page-attached-hyperdoc/tests")))
    (check :loader-names (and (c:loader-system-p "dreyeck/page-attached-hyperdoc") (c:loader-system-p "dreyeck/page-attached-hyperdoc/tests")
                              (not (c:loader-system-p "dreyeck/page-attached-asdf")) (not (c:loader-system-p "dreyeck/page-attached-hyperdocs"))))
    ;; The system the check looks at is the one the Catalog's own startup loads.
    (flet ((catalog-chooses (value)
             (getf (dreyeck/catalog-application::%configuration '("8080") (lambda (name) (and (equal name "HYPERDOC_CATALOG_SYSTEM") value))) :catalog-system))
           (check-chooses (value) (c:requested-catalog-system (lambda (name) (and (equal name "HYPERDOC_CATALOG_SYSTEM") value)))))
      (check :requested-system-is-the-catalogs
             (every (lambda (value) (equal (catalog-chooses value) (check-chooses value))) '(nil "dreyeck/work/project" "dreyeck/work/topic-maps-ctm-review" ""))))
    ;; The production Catalog: its default membership has nothing refused, and it does not load this startup policy.
    (let ((default (system-closure "dreyeck/catalog")))
      (check :production-catalog-has-no-refused-system (notany #'c:refused-system-p (loop for name being the hash-keys of default collect name)))
      (check :production-catalog-does-not-load-the-startup-policy
             (notany (lambda (name) (equal name "dreyeck/catalog-topic-maps")) (loop for name being the hash-keys of default collect name)))
      (check :production-catalog-application-does-not-either
             (not (gethash "dreyeck/catalog-topic-maps" (system-closure "dreyeck/catalog-application")))))
    ;; The optional readings are permitted at startup, and they load and register their HyperBooks.
    (asdf:load-system "dreyeck/work/topic-maps-ctm-review")
    (check :readings-registered
           (every (lambda (id) (hyperbook:find-hyperbook id :signal-error? nil))
                  '("dreyeck/work/topic-maps-project-example" "dreyeck/work/topic-maps-ctm-review")))
    ;; The optional runtime, once its readings are loaded, has neither the loader nor the Project Workspace; and what loads page-attached
    ;; code in it (the Lisp critic's loader, the reconstruction runner) refuses in a served runtime that is not in development mode,
    ;; which is how the executable starts. The gate reads the server's parameters: (pane-width development).
    (check :no-page-attached-loader-in-the-runtime
           (and (null (find-package "DREYECK/PAGE-ATTACHED-HYPERDOC")) (null (find-package "DREYECK/FEDWIKI-HYPERDOC"))
                (not (asdf:component-loaded-p "dreyeck/page-attached-hyperdoc")) (not (asdf:component-loaded-p "dreyeck/work/project"))))
    (let ((symbol (find-symbol "*SERVER-PARAMETERS*" (or (find-package "HYPERBOOK/SERVER") (error "The server package is not in this runtime.")))))
      (check :page-attached-execution-refused-when-served
             (progv (list symbol) (list (list "700px" nil))
               (not (uiop:symbol-call :dreyeck/page-attached-system-projection :execution-permitted-p))))
      (check :page-attached-execution-permitted-in-development
             (progv (list symbol) (list (list "700px" t))
               (uiop:symbol-call :dreyeck/page-attached-system-projection :execution-permitted-p))))
    (format t "~&CATALOG-TOPIC-MAPS-PASS: ~D assertions; Topic Maps ~A from the verified store snapshot, loopback only, Project Workspace refused at startup.~%"
            (length *checks*) (subseq c:+topic-maps-commit+ 0 8))
    t))
