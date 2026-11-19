(with-eval-after-load 'sly
  (defun hyperdoc-sly-image-in-mode-line ()
    (let ((conn (sly-current-connection)))
      (if (and conn (process-live-p conn))
          (format "PID %s · Slynk %s · %s"
                  (or (sly-pid conn) "…")
                  (sly-connection-port conn)
                  (if sly-buffer-connection "Buffer" "Standard"))
        "kein Image")))
  (add-to-list 'sly-extra-mode-line-constructs
               'hyperdoc-sly-image-in-mode-line t)
  (force-mode-line-update t))
