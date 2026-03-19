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
