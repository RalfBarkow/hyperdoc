;;;; Inspectable operational targets and host-aware Git remote materializations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass nixos-host-target ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (hostname :reader hostname-of :initarg :hostname :type string)
   (ssh-user :reader ssh-user-of :initarg :ssh-user :type string)
   (checkout-root :reader checkout-root-of :initarg :checkout-root :type pathname)
   (service-name :reader service-name-of :initarg :service-name :type string)
   (deployment-mode :reader deployment-mode-of :initarg :deployment-mode)))

(defclass git-remote-operation ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (host-target :reader host-target-of
                :initarg :host-target
                :type nixos-host-target)
   (remote-name :reader remote-name-of :initarg :remote-name :type string)
   (remote-url :reader remote-url-of :initarg :remote-url :type string)
   (branch :reader branch-of :initarg :branch :type string)
   (operation-kind :reader operation-kind-of :initarg :operation-kind)))

(defclass static-asset-path-resolution ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (request-path :reader request-path-of :initarg :request-path :type string)
   (asset-family :reader asset-family-of :initarg :asset-family)
   (owner-layer :reader owner-layer-of :initarg :owner-layer)
   (mounted-root :reader mounted-root-of :initarg :mounted-root :type pathname)
   (resolved-filesystem-path :reader resolved-filesystem-path-of
                             :initarg :resolved-filesystem-path
                             :type pathname)
   (exists-p :reader exists-p-of :initarg :exists-p)
   (expected-http-contract :reader expected-http-contract-of
                           :initarg :expected-http-contract
                           :type string)
   (current-status-summary :reader current-status-summary-of
                           :initarg :current-status-summary
                           :type string)))

(defclass static-asset-resolution-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (entries :reader entries-of :initarg :entries :type list)
   (computation-mode :reader computation-mode-of
                     :initarg :computation-mode)))

(defclass dreyeck-git-readiness-state-machine-run (state-machine-run)
  ((host-target :reader dreyeck-git-readiness-host-target-of
                :initarg :host-target
                :type nixos-host-target)
   (effective-repository-root :reader dreyeck-git-readiness-effective-repository-root-of
                              :initarg :effective-repository-root
                              :initform nil)
   (repository-root-source :reader dreyeck-git-readiness-repository-root-source-of
                           :initarg :repository-root-source
                           :initform nil)
   (runtime-origin :reader dreyeck-git-readiness-runtime-origin-of
                   :initarg :runtime-origin
                   :initform :unknown)
   (git-executable-available-p
    :reader dreyeck-git-readiness-git-executable-available-p-of
    :initarg :git-executable-available-p
    :initform nil)
   (requested-program :reader dreyeck-git-readiness-requested-program-of
                      :initarg :requested-program
                      :initform nil)
   (resolved-program :reader dreyeck-git-readiness-resolved-program-of
                     :initarg :resolved-program
                     :initform nil)
   (git-metadata-path :reader dreyeck-git-readiness-git-metadata-path-of
                      :initarg :git-metadata-path
                      :initform nil)
   (git-metadata-present-p :reader dreyeck-git-readiness-git-metadata-present-p-of
                           :initarg :git-metadata-present-p
                           :initform nil)
   (upstream-remote-present-p
    :reader dreyeck-git-readiness-upstream-remote-present-p-of
    :initarg :upstream-remote-present-p
    :initform nil)
   (upstream-remote-url :reader dreyeck-git-readiness-upstream-remote-url-of
                        :initarg :upstream-remote-url
                        :initform nil)
   (upstream-main-fetched-p :reader dreyeck-git-readiness-upstream-main-fetched-p-of
                            :initarg :upstream-main-fetched-p
                            :initform nil)
   (blocking-condition :reader dreyeck-git-readiness-blocking-condition-of
                       :initarg :blocking-condition
                       :initform nil)
   (add-upstream-remote-operation
    :reader dreyeck-git-readiness-add-upstream-remote-operation-of
    :initarg :add-upstream-remote-operation
    :type git-remote-operation)
   (fetch-upstream-main-operation
    :reader dreyeck-git-readiness-fetch-upstream-main-operation-of
    :initarg :fetch-upstream-main-operation
    :type git-remote-operation)))

(defgeneric materialization-shell-block (object)
  (:documentation "Render a shell block that materializes OBJECT operationally."))

(defun deployment-mode-label (deployment-mode)
  (ecase deployment-mode
    (:workspace-rooted-nix-run-default
     "workspace-rooted nix run .#default service")
    (:packaged-release-service
     "packaged release service")))

(defun git-remote-operation-kind-label (operation-kind)
  (ecase operation-kind
    (:add-remote "add remote")
    (:fetch-branch "fetch branch")))

(defun ssh-target-string (host-target)
  (format nil "~A@~A"
          (ssh-user-of host-target)
          (hostname-of host-target)))

(defun shell-quote (string)
  (with-output-to-string (stream)
    (write-char #\' stream)
    (loop for char across string
          do (if (char= char #\')
                 (write-string "'\"'\"'" stream)
                 (write-char char stream)))
    (write-char #\' stream)))

(defun shell-block (lines)
  (format nil "~{~A~%~}" lines))

(defun host-shell-lines (host-target body-lines)
  (append (list (format nil "ssh ~A <<'SH'"
                        (shell-quote (ssh-target-string host-target))))
          body-lines
          '("SH")))

(defmethod materialization-shell-block ((host-target nixos-host-target))
  (shell-block
   (host-shell-lines
    host-target
    (list "set -eu"
          (format nil "cd ~A"
                  (shell-quote (namestring (checkout-root-of host-target))))
          (format nil "systemctl show ~A -p ExecStart -p WorkingDirectory"
                  (shell-quote (service-name-of host-target)))))))

(defmethod materialization-shell-block ((operation git-remote-operation))
  (shell-block
   (host-shell-lines
    (host-target-of operation)
    (append
     (list "set -eu"
           (format nil "cd ~A"
                   (shell-quote
                    (namestring (checkout-root-of (host-target-of operation))))))
     (list
      (ecase (operation-kind-of operation)
        (:add-remote
         (format nil "git remote get-url ~A >/dev/null 2>&1 || git remote add ~A ~A"
                 (shell-quote (remote-name-of operation))
                 (shell-quote (remote-name-of operation))
                 (shell-quote (remote-url-of operation))))
        (:fetch-branch
         (format nil "git fetch ~A ~A"
                 (shell-quote (remote-name-of operation))
                 (shell-quote (branch-of operation))))))))))

(defun static-asset-family-label (asset-family)
  (ecase asset-family
    (:boot/html "boot/html")
    (:core-js "core-js")
    (:hyperbook-server-js "hyperbook-server-js")))

(defun static-asset-owner-layer-label (owner-layer)
  (ecase owner-layer
    (:default-clog-static-root
     "default CLOG static root")
    (:hyperbook-server-plugin-mount
     "hyperbook-server asset mount")))

(defun static-asset-computation-mode-label (computation-mode)
  (ecase computation-mode
    (:static-computation
     "static computation from current server wiring")))

(defun dreyeck-git-readiness-runtime-origin-label (origin)
  (ecase origin
    (:packaged-source "packaged source / release image")
    (:live-checkout "live checkout")
    (:unknown "unknown runtime origin")))

(defun dreyeck-git-readiness-state-label (state)
  (ecase state
    (:inspect-runtime "inspect runtime")
    (:inspect-repo-root "inspect repo root")
    (:no-git-executable "no-git-executable")
    (:packaged-source-no-repo "packaged-source-no-repo")
    (:repository-metadata-unavailable "repository-metadata-unavailable")
    (:live-checkout-no-upstream-remote "live-checkout-no-upstream-remote")
    (:upstream-remote-present-not-fetched "upstream-remote-present-not-fetched")
    (:upstream-main-fetched "upstream-main-fetched")
    (:ready-for-git-backed-inspection "ready-for-git-backed-inspection")
    (:git-command-failed "git-command-failed")))

(defun static-asset-request-paths ()
  '("/boot.html"
    "/js/boot.js"
    "/js/jquery.min.js"
    "/hyperbook-server/js/url.js"))

(defun static-asset-family-for-request-path (request-path)
  (cond
    ((string= request-path "/boot.html")
     :boot/html)
    ((or (string= request-path "/js/boot.js")
         (string= request-path "/js/jquery.min.js"))
     :core-js)
    ((string= request-path "/hyperbook-server/js/url.js")
     :hyperbook-server-js)
    (t
     (error "Unknown static asset request path ~S" request-path))))

(defun static-asset-owner-layer-for-request-path (request-path)
  (if (uiop:string-prefix-p "/hyperbook-server/" request-path)
      :hyperbook-server-plugin-mount
      :default-clog-static-root))

(defun hyperbook-server-asset-mounted-root-pathname ()
  (uiop:ensure-directory-pathname
   (asdf:system-relative-pathname :hyperbook/server "assets/")))

(defun clog-static-asset-mounted-root-pathname ()
  (let* ((env-root (when-let (clog-src (uiop:getenv "CLOG_SRC"))
                     (let ((candidate (uiop:ensure-directory-pathname
                                       (merge-pathnames #P"static-files/"
                                                        (uiop:ensure-directory-pathname
                                                         (pathname clog-src))))))
                       (when (probe-file candidate)
                         candidate))))
         (root (or env-root
                   (uiop:ensure-directory-pathname
                    (asdf:system-relative-pathname :clog "static-files/")))))
    (assert (typep root 'pathname) (root)
            "Static root must be a pathname, got ~S" root)
    root))

(defun static-asset-mounted-root-for-request-path (request-path)
  (ecase (static-asset-owner-layer-for-request-path request-path)
    (:default-clog-static-root
     (clog-static-asset-mounted-root-pathname))
    (:hyperbook-server-plugin-mount
     (hyperbook-server-asset-mounted-root-pathname))))

(defun relative-request-pathname (request-path)
  (pathname (string-left-trim "/" request-path)))

(defun static-asset-resolved-pathname (request-path mounted-root)
  (merge-pathnames (relative-request-pathname request-path)
                   mounted-root))

(defun static-asset-expected-http-contract (request-path)
  (cond
    ((string= request-path "/boot.html")
     "Default CLOG boot-page route. It should remain reachable via /boot.html; when no boot file exists, CLOG can fall back to compiled boot HTML.")
    ((or (string= request-path "/js/boot.js")
         (string= request-path "/js/jquery.min.js"))
     "Default CLOG static-root asset route. These files should resolve under the static root passed into clog:initialize.")
    ((string= request-path "/hyperbook-server/js/url.js")
     "hyperbook-server runtime asset route. The request path stays under /hyperbook-server/ and resolves via the hyperbook-server asset mount.")
    (t
     (error "Unknown static asset request path ~S" request-path))))

(defun static-asset-current-status-summary (request-path owner-layer exists-p)
  (cond
    ((and exists-p
          (string= request-path "/boot.html"))
     "Resolves to an existing boot file under the default CLOG static root. The route also carries compiled-boot fallback semantics when no file exists.")
    ((and exists-p
          (eq owner-layer :default-clog-static-root))
     "Resolves to an existing file under the default CLOG static root.")
    ((and exists-p
          (eq owner-layer :hyperbook-server-plugin-mount))
     "Resolves to an existing file under the hyperbook-server asset mount.")
    ((eq owner-layer :default-clog-static-root)
     "The request path maps to the default CLOG static root, but the computed filesystem target does not currently exist.")
    (t
     "The request path maps to the hyperbook-server asset mount, but the computed filesystem target does not currently exist.")))

(defun make-static-asset-path-resolution (request-path)
  (let* ((asset-family (static-asset-family-for-request-path request-path))
         (owner-layer (static-asset-owner-layer-for-request-path request-path))
         (mounted-root (static-asset-mounted-root-for-request-path request-path))
         (resolved-path (static-asset-resolved-pathname request-path mounted-root))
         (exists? (not (null (probe-file resolved-path)))))
    (make-instance 'static-asset-path-resolution
                   :id (format nil "static-asset-path-resolution:~A"
                               (string-left-trim "/" request-path))
                   :title (format nil "Static asset resolution: ~A" request-path)
                   :summary (format nil "Static computation of route ownership and filesystem resolution for ~A." request-path)
                   :request-path request-path
                   :asset-family asset-family
                   :owner-layer owner-layer
                   :mounted-root mounted-root
                   :resolved-filesystem-path resolved-path
                   :exists-p exists?
                   :expected-http-contract (static-asset-expected-http-contract request-path)
                   :current-status-summary (static-asset-current-status-summary
                                            request-path
                                            owner-layer
                                            exists?))))

(defun static-asset-path-resolution-for-request-path (request-path)
  (make-static-asset-path-resolution request-path))

(defun static-asset-path-resolutions ()
  (mapcar #'static-asset-path-resolution-for-request-path
          (static-asset-request-paths)))

(defun hyperdoc-static-asset-resolution-surface ()
  (make-instance 'static-asset-resolution-surface
                 :id "hyperdoc-static-asset-resolution-surface"
                 :title "Static asset path resolution"
                 :summary "Inspectable static computation of route ownership and filesystem resolution for the core CLOG and hyperbook-server asset paths."
                 :entries (static-asset-path-resolutions)
                 :computation-mode :static-computation))

(defun hyperdoc-boot-html-static-asset-path-resolution ()
  (static-asset-path-resolution-for-request-path "/boot.html"))

(defun hyperdoc-boot-js-static-asset-path-resolution ()
  (static-asset-path-resolution-for-request-path "/js/boot.js"))

(defun hyperdoc-jquery-min-js-static-asset-path-resolution ()
  (static-asset-path-resolution-for-request-path "/js/jquery.min.js"))

(defun hyperdoc-url-helper-static-asset-path-resolution ()
  (static-asset-path-resolution-for-request-path "/hyperbook-server/js/url.js"))

(defun dreyeck-ch-nixos-host-target ()
  (make-instance 'nixos-host-target
                 :id "dreyeck-ch-hyperdoc-host-target"
                 :title "dreyeck.ch HyperDoc host target"
                 :summary "Workspace-rooted HyperDoc service target for dreyeck.ch."
                 :hostname "dreyeck.ch"
                 :ssh-user "rgb"
                 :checkout-root #p"/home/rgb/workspace/hyperdoc/"
                 :service-name "hyperdoc"
                 :deployment-mode :workspace-rooted-nix-run-default))

(defun dreyeck-ch-add-konrad-upstream-remote-operation ()
  (make-instance 'git-remote-operation
                 :id "dreyeck-ch-add-konrad-upstream-remote"
                 :title "Add Konrad upstream remote on dreyeck.ch"
                 :summary "Idempotent remote-add materialization for the live dreyeck.ch HyperDoc checkout."
                 :host-target (dreyeck-ch-nixos-host-target)
                 :remote-name "upstream"
                 :remote-url "https://codeberg.org/khinsen/hyperdoc.git"
                 :branch "main"
                 :operation-kind :add-remote))

(defun dreyeck-ch-fetch-upstream-main-operation ()
  (make-instance 'git-remote-operation
                 :id "dreyeck-ch-fetch-upstream-main"
                 :title "Fetch upstream main on dreyeck.ch"
                 :summary "Host-aware fetch materialization for Konrad's upstream main branch."
                 :host-target (dreyeck-ch-nixos-host-target)
                 :remote-name "upstream"
                 :remote-url "https://codeberg.org/khinsen/hyperdoc.git"
                 :branch "main"
                 :operation-kind :fetch-branch))

(defun git-metadata-pathname (repository-root)
  (when repository-root
    (merge-pathnames #P".git/"
                     (uiop:ensure-directory-pathname repository-root))))

(defun git-metadata-present-p (repository-root)
  (not (null (and repository-root
                  (probe-file (git-metadata-pathname repository-root))))))

(defun dreyeck-git-readiness-runtime-origin (&key repository-root
                                                repository-root-source
                                                system)
  (let ((source-file (ignore-errors (asdf:system-source-file system))))
    (cond
      ((git-explicit-repository-root-source-p repository-root-source)
       :live-checkout)
      ((eq repository-root-source :process-working-directory)
       :live-checkout)
      ((nix-store-pathname-p repository-root)
       :packaged-source)
      ((and repository-root
            (probe-file repository-root))
       :live-checkout)
      ((nix-store-pathname-p source-file)
       :packaged-source)
      (source-file
       :live-checkout)
      (t
       :unknown))))

(defun git-output-indicates-missing-remote-p (output remote-name)
  (and output
       (or (search (format nil "No such remote '~A'" remote-name)
                   output
                   :test #'char-equal)
           (search (format nil "No such remote: '~A'" remote-name)
                   output
                   :test #'char-equal))))

(defun git-show-ref-output-present-p (output)
  (and (stringp output)
       (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   output)))))

(defun dreyeck-git-readiness-source-evidence ()
  (list
   (list :layer "Lisp source"
         :reference "hyperdoc/state-machines.lisp"
         :detail "Generic reusable state-machine-definition and state-machine-run objects.")
   (list :layer "Lisp source"
         :reference "hyperdoc/operational-targets.lisp"
         :detail "Read-only readiness probe and explicit dreyeck add-remote/fetch operational targets.")
   (list :layer "Lisp source"
         :reference "hyperdoc-explorer/operational-targets.lisp"
         :detail "Inspector views that expose readiness, repair path, and follow-up links.")
   (list :layer "Test"
         :reference "tests/state-machine-smoke.lisp"
         :detail "Focused readiness classification smoke coverage.")
   (list :layer "Test"
         :reference "tests/git-commit-assimilation-smoke.lisp"
         :detail "Git-unavailable follow-up coverage from the upstream assimilation path.")))

(defun make-dreyeck-git-readiness-state-machine-definition ()
  (make-state-machine-definition
   :id "state-machine-definition/dreyeck-git-readiness"
   :title "dreyeck Git readiness state machine"
   :summary
   "Read-only operational state machine for determining whether the current runtime is ready to inspect Konrad's upstream/main history without hiding remote-add or fetch work behind example clicks."
   :states
   (list
    (make-state-machine-state
     :id "inspect-runtime"
     :title "Inspect runtime"
     :summary "Resolve Git executable availability and the current runtime origin."
     :role :initial
     :entry-condition "A Git-backed inspection request wants explicit readiness evidence."
     :exit-condition "Either Git is unavailable or repo-root inspection can continue.")
    (make-state-machine-state
     :id "inspect-repo-root"
     :title "Inspect repo root"
     :summary "Resolve effective repository root, runtime origin, and .git metadata."
     :entry-condition "A usable Git executable is available."
     :exit-condition "Either readiness is blocked or upstream remote history can be checked.")
    (make-state-machine-state
     :id "no-git-executable"
     :title "No Git executable"
     :summary "The runtime cannot launch a usable Git executable."
     :role :failure)
    (make-state-machine-state
     :id "packaged-source-no-repo"
     :title "Packaged source, no repo metadata"
     :summary "The runtime points at packaged source or a release image without usable Git repository metadata."
     :role :failure)
    (make-state-machine-state
     :id "repository-metadata-unavailable"
     :title "Repository metadata unavailable"
     :summary "The runtime can launch Git, but no usable repository root/.git metadata is available for this checkout."
     :role :failure)
    (make-state-machine-state
     :id "live-checkout-no-upstream-remote"
     :title "Live checkout, no upstream remote"
     :summary "The runtime sees a live checkout but Konrad's upstream remote is not configured."
     :role :terminal)
    (make-state-machine-state
     :id "upstream-remote-present-not-fetched"
     :title "Upstream remote present, not fetched"
     :summary "The upstream remote exists but upstream/main is not yet present locally."
     :role :terminal)
    (make-state-machine-state
     :id "upstream-main-fetched"
     :title "Upstream/main fetched"
     :summary "The runtime can resolve upstream/main locally."
     :role :intermediate)
    (make-state-machine-state
     :id "ready-for-git-backed-inspection"
     :title "Ready for Git-backed inspection"
     :summary "Git executable, repository metadata, upstream remote, and upstream/main are all available."
     :role :terminal)
    (make-state-machine-state
     :id "git-command-failed"
     :title "Git command failed"
     :summary "A Git probe failed for a reason outside the expected executable/repository readiness classes."
     :role :failure))
   :transitions
   (list
    (make-state-machine-transition
     :id "inspect-runtime->no-git-executable"
     :from-state "inspect-runtime"
     :to-state "no-git-executable"
     :trigger "inspect runtime"
     :guard "git executable unavailable"
     :emitted-evidence "git-runtime-unavailable classification"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-runtime->inspect-repo-root"
     :from-state "inspect-runtime"
     :to-state "inspect-repo-root"
     :trigger "inspect runtime"
     :guard "git executable available"
     :emitted-evidence "effective repository root probe"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-repo-root->packaged-source-no-repo"
     :from-state "inspect-repo-root"
     :to-state "packaged-source-no-repo"
     :trigger "inspect repo root"
     :guard "packaged-source-and-no-git-metadata"
     :emitted-evidence "runtime origin and missing repository metadata"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-repo-root->repository-metadata-unavailable"
     :from-state "inspect-repo-root"
     :to-state "repository-metadata-unavailable"
     :trigger "inspect repo root"
     :guard "live-runtime-but-no-repository-metadata"
     :emitted-evidence "missing repository root or .git metadata"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-repo-root->live-checkout-no-upstream-remote"
     :from-state "inspect-repo-root"
     :to-state "live-checkout-no-upstream-remote"
     :trigger "inspect repo root"
     :guard "live-checkout-and-upstream-remote-missing"
     :emitted-evidence "remote lookup result"
     :side-effects "none; explicit add-remote operation remains separate"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-repo-root->upstream-remote-present-not-fetched"
     :from-state "inspect-repo-root"
     :to-state "upstream-remote-present-not-fetched"
     :trigger "inspect repo root"
     :guard "upstream-remote-present-but-upstream-main-missing"
     :emitted-evidence "remote branch lookup result"
     :side-effects "none; explicit fetch operation remains separate"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-repo-root->upstream-main-fetched"
     :from-state "inspect-repo-root"
     :to-state "upstream-main-fetched"
     :trigger "inspect repo root"
     :guard "upstream-main-present"
     :emitted-evidence "refs/remotes/upstream/main"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "inspect-repo-root->git-command-failed"
     :from-state "inspect-repo-root"
     :to-state "git-command-failed"
     :trigger "inspect repo root"
     :guard "unexpected git command failure"
     :emitted-evidence "git-runtime-unavailable classification"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "upstream-main-fetched->ready"
     :from-state "upstream-main-fetched"
     :to-state "ready-for-git-backed-inspection"
     :trigger "verify readiness"
     :guard "all readiness prerequisites satisfied"
     :emitted-evidence "ready-for-git-backed-inspection"
     :side-effects "none"
     :reversible-p nil))
   :initial-state "inspect-runtime"
   :terminal-states '("live-checkout-no-upstream-remote"
                      "upstream-remote-present-not-fetched"
                      "ready-for-git-backed-inspection")
   :failure-states '("no-git-executable"
                     "packaged-source-no-repo"
                     "repository-metadata-unavailable"
                     "git-command-failed")
   :guards '("git executable unavailable"
             "git executable available"
             "packaged-source-and-no-git-metadata"
             "live-runtime-but-no-repository-metadata"
             "live-checkout-and-upstream-remote-missing"
             "upstream-remote-present-but-upstream-main-missing"
             "upstream-main-present"
             "unexpected git command failure"
             "all readiness prerequisites satisfied")
   :events '("inspect runtime"
             "inspect repo root"
             "verify readiness")
   :invariants
   (list
    (list :label "Read-only classification"
          :detail "The readiness machine never mutates remotes or fetches history; it only classifies the current runtime and points at explicit operations.")
    (list :label "Operational repair stays explicit"
          :detail "Add-remote and fetch remain separate host-aware operational-target objects, not side effects of example clicks or proof surfaces.")
    (list :label "Ready means upstream/main is local"
          :detail "The runtime is only ready when a usable Git executable, repository metadata, upstream remote, and upstream/main are all available."))
   :source-evidence (dreyeck-git-readiness-source-evidence)
   :notes
   (list
    (list :label "Operational seam"
          :detail "This machine reuses the existing dreyeck host target plus the add-upstream-remote and fetch-upstream-main operational-target objects as explicit next steps."))
   :multi-initial-p nil
   :multi-current-p nil
   :allow-terminal-outgoing-p nil
   :acyclic-p t))

(defun dreyeck-git-readiness-transition-entry
    (timestamp transition-id from-state to-state detail)
  (list :timestamp timestamp
        :kind :transition
        :transition-id transition-id
        :from-state from-state
        :to-state to-state
        :detail detail))

(defun dreyeck-git-readiness-evidence-entry (timestamp to-state detail)
  (list :timestamp timestamp
        :kind :evidence
        :to-state to-state
        :detail detail))

(defun make-dreyeck-git-readiness-probe
    (&key git-executable-available-p requested-program resolved-program
       effective-repository-root repository-root-source runtime-origin
       git-metadata-present-p upstream-remote-present-p upstream-remote-url
       upstream-main-fetched-p blocking-condition)
  (list :git-executable-available-p git-executable-available-p
        :requested-program requested-program
        :resolved-program resolved-program
        :effective-repository-root effective-repository-root
        :repository-root-source repository-root-source
        :runtime-origin runtime-origin
        :git-metadata-present-p git-metadata-present-p
        :upstream-remote-present-p upstream-remote-present-p
        :upstream-remote-url upstream-remote-url
        :upstream-main-fetched-p upstream-main-fetched-p
        :blocking-condition blocking-condition))

(defun classify-dreyeck-git-readiness-probe (probe)
  (let ((blocking-condition (getf probe :blocking-condition)))
    (cond
      ((or (eq (getf probe :git-executable-available-p) nil)
           (and (typep blocking-condition 'git-runtime-unavailable)
                (eq (classification-of blocking-condition)
                    :git-executable-unavailable)))
       (values "no-git-executable"
               :failed
               "git-executable-unavailable"
               (list "inspect-runtime"
                     "no-git-executable")
               (list
                (dreyeck-git-readiness-transition-entry
                 1
                 "inspect-runtime->no-git-executable"
                 "inspect-runtime"
                 "no-git-executable"
                 "Git executable availability probe failed."))
               (list
                (dreyeck-git-readiness-evidence-entry
                 2
                 "no-git-executable"
                 "No usable Git executable is available in this runtime."))))
      ((or (typep blocking-condition 'git-runtime-unavailable)
           (null (getf probe :effective-repository-root))
           (eq (getf probe :git-metadata-present-p) nil))
       (let* ((runtime-origin (or (getf probe :runtime-origin) :unknown))
              (packaged-p (eq runtime-origin :packaged-source))
              (state (if packaged-p
                         "packaged-source-no-repo"
                         "repository-metadata-unavailable"))
              (classification (if packaged-p
                                  "packaged-source-no-repo"
                                  "repository-metadata-unavailable"))
              (detail (if packaged-p
                          "The runtime points at packaged source without usable repository metadata."
                          "The runtime does not currently expose a usable repository root and .git metadata.")))
         (values state
                 :failed
                 classification
                 (list "inspect-runtime"
                       "inspect-repo-root"
                       state)
                 (list
                  (dreyeck-git-readiness-transition-entry
                   1
                   "inspect-runtime->inspect-repo-root"
                   "inspect-runtime"
                   "inspect-repo-root"
                   "Git executable is available, so repository inspection continued.")
                  (dreyeck-git-readiness-transition-entry
                   2
                   (if packaged-p
                       "inspect-repo-root->packaged-source-no-repo"
                       "inspect-repo-root->repository-metadata-unavailable")
                   "inspect-repo-root"
                   state
                   detail))
                 (list
                  (dreyeck-git-readiness-evidence-entry
                   3
                   state
                   detail)))))
      ((not (getf probe :upstream-remote-present-p))
       (values "live-checkout-no-upstream-remote"
               :finished
               "upstream-remote-missing"
               (list "inspect-runtime"
                     "inspect-repo-root"
                     "live-checkout-no-upstream-remote")
               (list
                (dreyeck-git-readiness-transition-entry
                 1
                 "inspect-runtime->inspect-repo-root"
                 "inspect-runtime"
                 "inspect-repo-root"
                 "Git executable is available and the checkout is inspectable.")
                (dreyeck-git-readiness-transition-entry
                 2
                 "inspect-repo-root->live-checkout-no-upstream-remote"
                 "inspect-repo-root"
                 "live-checkout-no-upstream-remote"
                 "The live checkout does not currently expose the upstream remote."))
               (list
                (dreyeck-git-readiness-evidence-entry
                 3
                 "live-checkout-no-upstream-remote"
                 "Upstream remote lookup returned no configured remote."))))
      ((not (getf probe :upstream-main-fetched-p))
       (values "upstream-remote-present-not-fetched"
               :finished
               "upstream-main-not-fetched"
               (list "inspect-runtime"
                     "inspect-repo-root"
                     "upstream-remote-present-not-fetched")
               (list
                (dreyeck-git-readiness-transition-entry
                 1
                 "inspect-runtime->inspect-repo-root"
                 "inspect-runtime"
                 "inspect-repo-root"
                 "Git executable is available and the checkout is inspectable.")
                (dreyeck-git-readiness-transition-entry
                 2
                 "inspect-repo-root->upstream-remote-present-not-fetched"
                 "inspect-repo-root"
                 "upstream-remote-present-not-fetched"
                 "The upstream remote exists, but upstream/main is not present locally."))
               (list
                (dreyeck-git-readiness-evidence-entry
                 3
                 "upstream-remote-present-not-fetched"
                 "refs/remotes/upstream/main is not currently present."))))
      (t
       (values "ready-for-git-backed-inspection"
               :finished
               nil
               (list "inspect-runtime"
                     "inspect-repo-root"
                     "upstream-main-fetched"
                     "ready-for-git-backed-inspection")
               (list
                (dreyeck-git-readiness-transition-entry
                 1
                 "inspect-runtime->inspect-repo-root"
                 "inspect-runtime"
                 "inspect-repo-root"
                 "Git executable is available and the checkout is inspectable.")
                (dreyeck-git-readiness-transition-entry
                 2
                 "inspect-repo-root->upstream-main-fetched"
                 "inspect-repo-root"
                 "upstream-main-fetched"
                 "The upstream remote and upstream/main are available locally.")
                (dreyeck-git-readiness-transition-entry
                 3
                 "upstream-main-fetched->ready"
                 "upstream-main-fetched"
                 "ready-for-git-backed-inspection"
                 "All readiness prerequisites are satisfied."))
               (list
                (dreyeck-git-readiness-evidence-entry
                 4
                 "ready-for-git-backed-inspection"
                 "Git-backed inspection can proceed without hidden operational repair.")))))))

(defun make-dreyeck-git-readiness-run-notes (probe)
  (remove nil
          (list
           (list :label "Read-only contract"
                 :detail "This readiness object does not add remotes or fetch history. It only classifies current runtime readiness and points to explicit operations.")
           (and (getf probe :effective-repository-root)
                (list :label "Effective repository root"
                      :detail (namestring (getf probe :effective-repository-root))))
           (and (getf probe :upstream-remote-url)
                (list :label "Observed upstream URL"
                      :detail (getf probe :upstream-remote-url))))))

(defun make-dreyeck-git-readiness-run-from-probe (probe)
  (multiple-value-bind (current-state status failure-classification
                        visited-states transition-trace evidence-trace)
      (classify-dreyeck-git-readiness-probe probe)
    (let* ((host-target (dreyeck-ch-nixos-host-target))
           (add-operation (dreyeck-ch-add-konrad-upstream-remote-operation))
           (fetch-operation (dreyeck-ch-fetch-upstream-main-operation))
           (repository-root (getf probe :effective-repository-root)))
      (make-instance 'dreyeck-git-readiness-state-machine-run
                     :id "dreyeck-git-readiness-state-machine-run"
                     :title "dreyeck Git readiness"
                     :summary
                     "Concrete read-only readiness classification for whether the current runtime can inspect Konrad's upstream/main history without hidden mutation."
                     :machine (make-dreyeck-git-readiness-state-machine-definition)
                     :input (list :target-host "dreyeck.ch"
                                  :remote-name "upstream"
                                  :branch "main")
                     :current-state current-state
                     :visited-states visited-states
                     :transition-trace transition-trace
                     :evidence-trace evidence-trace
                     :status status
                     :failure-classification failure-classification
                     :notes (make-dreyeck-git-readiness-run-notes probe)
                     :host-target host-target
                     :effective-repository-root repository-root
                     :repository-root-source (getf probe :repository-root-source)
                     :runtime-origin (or (getf probe :runtime-origin) :unknown)
                     :git-executable-available-p
                     (getf probe :git-executable-available-p)
                     :requested-program (getf probe :requested-program)
                     :resolved-program (getf probe :resolved-program)
                     :git-metadata-path (git-metadata-pathname repository-root)
                     :git-metadata-present-p (getf probe :git-metadata-present-p)
                     :upstream-remote-present-p
                     (getf probe :upstream-remote-present-p)
                     :upstream-remote-url (getf probe :upstream-remote-url)
                     :upstream-main-fetched-p
                     (getf probe :upstream-main-fetched-p)
                     :blocking-condition (getf probe :blocking-condition)
                     :add-upstream-remote-operation add-operation
                     :fetch-upstream-main-operation fetch-operation))))

(defun runtime-probe-directory ()
  (or (current-process-working-directory)
      (uiop:ensure-directory-pathname (uiop:temporary-directory))))

(defun resolve-dreyeck-live-git-readiness-probe (&key (system-designator :hyperdoc))
  (let* ((system (etypecase system-designator
                   (asdf:system system-designator)
                   ((or string symbol)
                    (asdf:find-system system-designator))))
         (git-version-result
           (call-with-git-runtime-boundary
            (lambda ()
              (git-command-output*
               (runtime-probe-directory)
               '("--version")
               :operation "git --version")))))
    (multiple-value-bind (resolved-program requested-program _configuration-source)
        (resolve-git-program)
      (declare (ignore _configuration-source))
      (cond
        ((typep git-version-result 'git-runtime-unavailable)
         (make-dreyeck-git-readiness-probe
          :git-executable-available-p nil
          :requested-program requested-program
          :resolved-program resolved-program
          :runtime-origin
          (dreyeck-git-readiness-runtime-origin :system system)
          :blocking-condition git-version-result))
        (t
         (let ((root-result
                 (call-with-git-runtime-boundary
                  (lambda ()
                    (multiple-value-list
                     (system-repository-root-info system))))))
           (cond
             ((typep root-result 'git-runtime-unavailable)
              (let* ((repository-root (repository-root-of root-result))
                     (repository-root-source
                       (repository-root-source-of root-result))
                     (runtime-origin
                       (dreyeck-git-readiness-runtime-origin
                        :repository-root repository-root
                        :repository-root-source repository-root-source
                        :system system)))
                (make-dreyeck-git-readiness-probe
                 :git-executable-available-p t
                 :requested-program requested-program
                 :resolved-program resolved-program
                 :effective-repository-root repository-root
                 :repository-root-source repository-root-source
                 :runtime-origin runtime-origin
                 :git-metadata-present-p
                 (and repository-root
                      (git-metadata-present-p repository-root))
                 :blocking-condition root-result)))
             (t
              (destructuring-bind (repository-root repository-root-source)
                  root-result
                (let* ((runtime-origin
                         (dreyeck-git-readiness-runtime-origin
                          :repository-root repository-root
                          :repository-root-source repository-root-source
                          :system system))
                       (metadata-present-p
                         (git-metadata-present-p repository-root))
                       (remote-output
                         (call-with-git-runtime-boundary
                          (lambda ()
                            (git-command-output*
                             repository-root
                             '("remote" "get-url" "upstream")
                             :ignore-error-status t
                             :operation "git remote get-url upstream"
                             :repository-root-source repository-root-source)))))
                  (cond
                    ((typep remote-output 'git-runtime-unavailable)
                     (make-dreyeck-git-readiness-probe
                      :git-executable-available-p t
                      :requested-program requested-program
                      :resolved-program resolved-program
                      :effective-repository-root repository-root
                      :repository-root-source repository-root-source
                      :runtime-origin runtime-origin
                      :git-metadata-present-p metadata-present-p
                      :blocking-condition remote-output))
                    ((git-output-indicates-missing-remote-p remote-output "upstream")
                     (make-dreyeck-git-readiness-probe
                      :git-executable-available-p t
                      :requested-program requested-program
                      :resolved-program resolved-program
                      :effective-repository-root repository-root
                      :repository-root-source repository-root-source
                      :runtime-origin runtime-origin
                      :git-metadata-present-p metadata-present-p
                      :upstream-remote-present-p nil))
                    (t
                     (let ((upstream-main-output
                             (call-with-git-runtime-boundary
                              (lambda ()
                                (git-command-output*
                                 repository-root
                                 '("show-ref" "--verify" "refs/remotes/upstream/main")
                                 :ignore-error-status t
                                 :operation
                                 "git show-ref --verify refs/remotes/upstream/main"
                                 :repository-root-source repository-root-source)))))
                       (if (typep upstream-main-output 'git-runtime-unavailable)
                           (make-dreyeck-git-readiness-probe
                            :git-executable-available-p t
                            :requested-program requested-program
                            :resolved-program resolved-program
                            :effective-repository-root repository-root
                            :repository-root-source repository-root-source
                            :runtime-origin runtime-origin
                            :git-metadata-present-p metadata-present-p
                            :upstream-remote-present-p t
                            :upstream-remote-url remote-output
                            :blocking-condition upstream-main-output)
                           (make-dreyeck-git-readiness-probe
                            :git-executable-available-p t
                            :requested-program requested-program
                            :resolved-program resolved-program
                            :effective-repository-root repository-root
                            :repository-root-source repository-root-source
                            :runtime-origin runtime-origin
                            :git-metadata-present-p metadata-present-p
                            :upstream-remote-present-p t
                            :upstream-remote-url remote-output
                            :upstream-main-fetched-p
                            (git-show-ref-output-present-p upstream-main-output))))))))))))))))

(defun make-dreyeck-git-readiness-state-machine-run (&key probe)
  (make-dreyeck-git-readiness-run-from-probe
   (or probe
       (resolve-dreyeck-live-git-readiness-probe))))

(defun git-runtime-followup-objects (&optional condition)
  (declare (ignore condition))
  (list (make-dreyeck-git-readiness-state-machine-run)
        (dreyeck-ch-add-konrad-upstream-remote-operation)
        (dreyeck-ch-fetch-upstream-main-operation)))
