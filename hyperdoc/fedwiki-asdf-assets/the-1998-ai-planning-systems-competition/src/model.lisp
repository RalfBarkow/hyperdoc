;;;; Stable model constants for the McDermott 2000 reading artifact.

(in-package #:the-1998-ai-planning-systems-competition)

(defparameter *reading-slug*
  "the-1998-ai-planning-systems-competition")

(defparameter *reading-title*
  "The 1998 AI Planning Systems Competition")

(defparameter *reading-system-name*
  "the-1998-ai-planning-systems-competition")

(defparameter *network-required-p* nil)

(defparameter *fedwiki-journal-date-ms* 1782950400000)

(defun artifact-root ()
  (uiop:ensure-directory-pathname
   (asdf:system-source-directory *reading-system-name*)))

(defun asset-db-pathname ()
  (merge-pathnames
   "assets/the-1998-ai-planning-systems-competition.dmx.sqlite"
   (artifact-root)))

(defun page-json-pathname ()
  (merge-pathnames
   "pages/the-1998-ai-planning-systems-competition.json"
   (artifact-root)))

(defun relative-artifact-path (pathname)
  (let* ((root (namestring (artifact-root)))
         (path (namestring pathname)))
    (if (uiop:string-prefix-p root path)
        (subseq path (length root))
        path)))
