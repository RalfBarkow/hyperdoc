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
