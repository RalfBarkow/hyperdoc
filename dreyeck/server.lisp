;;;; Minimal executable dreyeck scaffold
;;
;;;; Copyright (c) 2026

(in-package :dreyeck/server)

(defparameter +dreyeck-local-boot-urls+
  '("http://127.0.0.1:8080/boot.html"
    "http://localhost:8080/boot.html"
    "https://hauptsache.dreyeck.ch/assets/home/index.html"
    "https://hauptsache.dreyeck.ch/boot.html"))

(defparameter +dreyeck-local-target-aliases+
  '("dreyeck:catalog"
    "dreyeck:local-boot"))

(defun dreyeck-local-boot-link-redirection (url)
  (when (and (stringp url)
             (member url +dreyeck-local-boot-urls+ :test #'string=))
    (list "hyperdoc/explorer")))

(defun dreyeck-link-target-rewriter (source-page hyperbook-id page-id
                                     &key element link-text)
  (declare (ignore source-page element link-text))
  (if (member hyperbook-id +dreyeck-local-target-aliases+ :test #'string=)
      (values "hyperdoc/explorer" page-id t)
      (values hyperbook-id page-id nil)))

(defun install-dreyeck-server-scaffold ()
  (hyperbook:register-link-redirection 'dreyeck-local-boot-link-redirection)
  (hyperbook:register-link-target-rewriter 'dreyeck-link-target-rewriter)
  t)

(hyperbook/server:register-server-startup-hook 'install-dreyeck-server-scaffold)
(install-dreyeck-server-scaffold)
