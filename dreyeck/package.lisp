;;;; Package definitions for the minimal dreyeck scaffold
;;
;;;; Copyright (c) 2026

(defpackage :dreyeck/server
  (:use :cl)
  (:export #:install-dreyeck-server-scaffold
           #:dreyeck-local-boot-link-redirection
           #:dreyeck-link-target-rewriter))

(defpackage :dreyeck
  (:use :cl)
  (:import-from :dreyeck/server
                #:install-dreyeck-server-scaffold)
  (:export #:install-dreyeck-server-scaffold))
