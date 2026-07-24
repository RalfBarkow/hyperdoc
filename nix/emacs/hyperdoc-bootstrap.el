;;; hyperdoc-bootstrap.el --- Isolated HyperDoc Emacs startup -*- lexical-binding: t; -*-

;; This file is copied into an immutable Nix output.  The HyperDoc Emacs
;; launchers load that output under `emacs -Q'; user init files and package.el
;; are intentionally outside this startup path.

(require 'server)
(require 'subr-x)
(require 'gptel)
(require 'gptel-openai)
(require 'sly)

(defconst hyperdoc-emacs-bootstrap-file
  (or load-file-name buffer-file-name)
  "Immutable file from which the HyperDoc Emacs bootstrap was loaded.")

(defconst hyperdoc-gptel-backend-name "Local Gemma 4 E2B")
(defconst hyperdoc-gptel-default-host "127.0.0.1:8081")
(defconst hyperdoc-gptel-endpoint "/v1/chat/completions")
(defconst hyperdoc-gptel-default-model "gemma-4-e2b")

(defvar hyperdoc-gptel-backend nil
  "OpenAI-compatible local Gemma backend owned by this bootstrap.")

(defun hyperdoc--environment-value (name fallback)
  "Return non-empty environment variable NAME, or FALLBACK."
  (let ((value (getenv name)))
    (if (and value (not (string-empty-p value))) value fallback)))

(defun hyperdoc--configure-gptel ()
  "Create the local Gemma backend once and install new-buffer defaults."
  (let* ((host (hyperdoc--environment-value
                "HYPERDOC_GPTEL_HOST" hyperdoc-gptel-default-host))
         (model-name (hyperdoc--environment-value
                      "HYPERDOC_GPTEL_MODEL" hyperdoc-gptel-default-model))
         (model (intern model-name)))
    (unless hyperdoc-gptel-backend
      (setq hyperdoc-gptel-backend
            (gptel-make-openai hyperdoc-gptel-backend-name
              :protocol "http"
              :host host
              :endpoint hyperdoc-gptel-endpoint
              :stream t
              :header nil
              :models (list model))))
    (setq-default gptel-backend hyperdoc-gptel-backend
                  gptel-model model)))

(defun hyperdoc--start-emacs-server ()
  "Start the dedicated named server during interactive startup."
  (setq server-name
        (hyperdoc--environment-value
         "HYPERDOC_EMACS_SERVER_NAME" "hyperdoc"))
  (unless (or noninteractive (server-running-p server-name))
    (server-start)))

(defun hyperdoc-sly-connect-from-environment ()
  "Connect SLY using the endpoint supplied by the launcher environment."
  (let* ((host (or (getenv "HYPERDOC_SLY_HOST")
                   (error "HYPERDOC_SLY_HOST is not set")))
         (port-text (or (getenv "HYPERDOC_SLY_PORT")
                        (error "HYPERDOC_SLY_PORT is not set"))))
    (unless (string-match-p "\\`[0-9]+\\'" port-text)
      (error "Invalid HYPERDOC_SLY_PORT: %S" port-text))
    (sly-connect host (string-to-number port-text))))

(hyperdoc--configure-gptel)
(hyperdoc--start-emacs-server)

(provide 'hyperdoc-bootstrap)
;;; hyperdoc-bootstrap.el ends here
