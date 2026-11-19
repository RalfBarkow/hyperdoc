;;; Attach only: the launcher has already created the authoritative SBCL.
(require 'sly)
(load (expand-file-name "hyperdoc-sly-mode-line.el"
                        (file-name-directory load-file-name)))
(setq default-directory
      (file-name-as-directory (getenv "HYPERDOC_REPO_ROOT")))
(sly-connect (getenv "HYPERDOC_SLYNK_HOST")
             (string-to-number (getenv "HYPERDOC_SLYNK_PORT")))
