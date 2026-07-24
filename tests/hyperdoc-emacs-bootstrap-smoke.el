;;; hyperdoc-emacs-bootstrap-smoke.el --- Bootstrap checks -*- lexical-binding: t; -*-

(require 'cl-lib)

(defun hyperdoc-test--nix-library-p (library)
  (let ((path (locate-library library)))
    (and path
         (string-prefix-p "/nix/store/" path)
         (not (string-match-p "/Users/rgb/workspace/gptel" path))
         (not (string-match-p "/\\.emacs\\.d/elpa/" path)))))

(let* ((backend gptel-backend)
       (bootstrap hyperdoc-emacs-bootstrap-file)
       (original-backend hyperdoc-gptel-backend)
       sly-call)
  (load bootstrap nil nil t)
  (unless (eq original-backend hyperdoc-gptel-backend)
    (error "Reload replaced the configured backend"))
  (setenv "HYPERDOC_SLY_HOST" "127.0.0.1")
  (setenv "HYPERDOC_SLY_PORT" "43123")
  (cl-letf (((symbol-function 'sly-connect)
             (lambda (host port) (setq sly-call (list host port)))))
    (hyperdoc-sly-connect-from-environment))
  (let ((result
         (list
          :emacs-version emacs-version
          :invocation-directory invocation-directory
          :emacs-from-new-nix-closure
          (and (string-prefix-p "/nix/store/" invocation-directory)
               (not (string-prefix-p
                     "/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/"
                     invocation-directory)))
          :bootstrap-from-nix-store
          (string-prefix-p "/nix/store/" bootstrap)
          :gptel-library-from-nix-closure
          (hyperdoc-test--nix-library-p "gptel")
          :gptel-openai-library-from-nix-closure
          (hyperdoc-test--nix-library-p "gptel-openai")
          :transient-library-from-nix-closure
          (hyperdoc-test--nix-library-p "transient")
          :compat-library-from-nix-closure
          (hyperdoc-test--nix-library-p "compat")
          :sly-library-from-nix-closure
          (hyperdoc-test--nix-library-p "sly")
          :gptel-defined (fboundp 'gptel)
          :gptel-send-defined (fboundp 'gptel-send)
          :gptel-make-openai-defined (fboundp 'gptel-make-openai)
          :backend-name (gptel-backend-name backend)
          :backend-host (gptel-backend-host backend)
          :backend-endpoint (gptel-backend-endpoint backend)
          :backend-url (gptel-backend-url backend)
          :backend-model gptel-model
          :backend-streaming (gptel-backend-stream backend)
          :backend-header (gptel-backend-header backend)
          :backend-contract
          (and (equal (gptel-backend-name backend) "Local Gemma 4 E2B")
               (equal (gptel-backend-host backend) "127.0.0.1:8081")
               (equal (gptel-backend-endpoint backend) "/v1/chat/completions")
               (equal (gptel-backend-url backend)
                      "http://127.0.0.1:8081/v1/chat/completions")
               (eq gptel-model 'gemma-4-e2b)
               (eq (gptel-backend-stream backend) t)
               (null (gptel-backend-header backend)))
          :backend-reload-stable (eq backend hyperdoc-gptel-backend)
          :existing-host-port-contract-preserved
          (equal sly-call '("127.0.0.1" 43123))
          :production-port-49826-not-contacted
          (not (equal (cadr sly-call) 49826))
          :package-user-dir-unused
          (cl-every #'hyperdoc-test--nix-library-p
                    '("gptel" "gptel-openai" "transient" "compat" "sly"))
          :spacemacs-not-loaded (not (featurep 'spacemacs)))))
    (unless (cl-loop for tail on result by #'cddr
                     for key = (car tail)
                     for value = (cadr tail)
                     unless (memq key '(:emacs-version
                                        :invocation-directory
                                        :backend-name
                                        :backend-host
                                        :backend-endpoint
                                        :backend-url
                                        :backend-model
                                        :backend-header))
                     always value)
      (error "HyperDoc Emacs bootstrap smoke check failed: %S" result))
    (prin1 result)
    (terpri)))

;;; hyperdoc-emacs-bootstrap-smoke.el ends here
