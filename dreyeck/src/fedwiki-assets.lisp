;; Discover local assets referenced by Federated Wiki pages

(in-package #:dreyeck/fedwiki-assets)

(defun local-fedwiki-page-pathname (site-root slug)
  "Return the local page pathname for SLUG below SITE-ROOT."
  (check-type slug string)
  (merge-pathnames
   (format nil "pages/~A" slug)
   (uiop:ensure-directory-pathname site-root)))

(defun read-local-fedwiki-page (site-root slug)
  "Read the local Federated Wiki page identified by SLUG as JSON data.

This operation reads only the local page file.  It performs no network
access and does not load HYPERBOOK/FEDWIKI."
  (let ((pathname
          (local-fedwiki-page-pathname site-root slug)))
    (with-open-file
        (stream
         pathname
         :direction :input
         :external-format :utf-8)
      (shasht:read-json stream))))

(defun assets-story-items (page-json)
  "Return the story items whose Federated Wiki type is \"assets\"."
  (check-type page-json hash-table)
  (let ((story
          (gethash "story" page-json #())))
    (loop
      for item across story
      when
        (string-equal
         "assets"
         (or (gethash "type" item) ""))
      collect item)))

(defun assets-reference-of (assets-item)
  "Return the logical assets reference stored in an assets story item."
  (check-type assets-item hash-table)
  (let ((reference
          (gethash "text" assets-item)))
    (check-type reference string)
    reference))

(defun local-fedwiki-assets-root (site-root)
  "Return the local assets root below SITE-ROOT."
  (uiop:ensure-directory-pathname
   (merge-pathnames
    "assets/"
    (uiop:ensure-directory-pathname site-root))))

(defun resolve-local-assets (site-root assets-item)
  "Resolve ASSETS-ITEM against the local assets root of SITE-ROOT.

The story item stores a logical reference such as
\"pages/reading-java-source-as-data\".  This function performs the
local materialization step but does not require the resulting directory
to contain any particular kind of asset."
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (assets-reference-of assets-item)
    (local-fedwiki-assets-root site-root))))

(defun discover-asdf-files (assets-directory)
  "Return the .asd files immediately contained in ASSETS-DIRECTORY.

No ASDF file is evaluated or loaded by this operation."
  (let ((directory
          (uiop:directory-exists-p
           (uiop:ensure-directory-pathname
            assets-directory))))
    (when directory
      (sort
       (remove-if-not
        (lambda (pathname)
          (string-equal
           "asd"
           (or (pathname-type pathname) "")))
        (uiop:directory-files directory))
       #'string<
       :key #'namestring))))

(defun discover-page-attached-asdf-files (site-root slug)
  "Discover .asd files reachable through the page's assets story items.

This is a read-only discovery operation.  It neither calls ASDF:LOAD-ASD
nor loads any discovered system."
  (let* ((page-json
           (read-local-fedwiki-page site-root slug))
         (items
           (assets-story-items page-json)))
    (loop
      for item in items
      append
        (discover-asdf-files
         (resolve-local-assets site-root item)))))

(defun page-attached-asdf-discovery-observation (site-root slug)
  "Return inspectable evidence for page-attached ASDF discovery."
  (let* ((page-file
           (local-fedwiki-page-pathname site-root slug))
         (page-json
           (read-local-fedwiki-page site-root slug))
         (items
           (assets-story-items page-json))
         (references
           (mapcar #'assets-reference-of items))
         (directories
           (mapcar
            (lambda (item)
              (resolve-local-assets site-root item))
            items))
         (asdf-files
           (loop
             for directory in directories
             append
               (discover-asdf-files directory))))
    (list
     :slug slug
     :page-file page-file
     :page-title (gethash "title" page-json)
     :assets-items items
     :assets-references references
     :assets-directories directories
     :asdf-files asdf-files)))
