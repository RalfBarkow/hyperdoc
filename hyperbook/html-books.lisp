;;;; Minimal HyperBooks with HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; A very basic HyperBook implementation, intended mainly
;; for HyperBook's own documentation. Most of the implementation
;; lives in system hyperbook/explorer.
;;

(defclass html-hyperbook (hyperbook)
  ((title :reader title-of :initarg :title :type string)
   (html-files :accessor html-files-of :initarg :html-files :initform nil :type list)
   (pages :accessor pages-of :initform nil :type '(or null hash-table))
   (main-page-id :reader main-page-id-of :initform nil)))
