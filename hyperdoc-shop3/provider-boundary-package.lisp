;;;; Package definition for the optional SHOP3 provider boundary helper
;;
;;;; Copyright (c) 2026

(defpackage #:hyperdoc/shop3-provider
  (:use #:common-lisp)
  (:export
   #:register-shop3-provider-source-registry
   #:shop3-provider-boundary-report-selected-directories
   #:shop3-provider-boundary-report-rejected-directories))

(in-package #:hyperdoc/shop3-provider)
