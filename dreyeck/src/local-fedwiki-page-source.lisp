;;;; One observation of a local Federated Wiki page file, and its story Items

(in-package #:dreyeck/local-fedwiki-page)

;; A LOCAL-FEDWIKI-PAGE holds the JSON it was hydrated from, not the bytes, and
;; it may be older than the file. An observation reads the file's bytes once:
;; the SHA-256 and the JSON come from the same bytes, so the digest names
;; exactly the page the Items were read from. Observing writes nothing.

(defclass local-fedwiki-page-source ()
  ((site-root :initarg :site-root :reader page-source-site-root)
   (slug :initarg :slug :reader page-source-slug)
   (pathname :initarg :pathname :reader page-source-pathname)
   (sha256 :initarg :sha256 :reader page-source-sha256)
   (octet-count :initarg :octet-count :reader page-source-octet-count)
   (observed-at :initarg :observed-at :reader page-source-observed-at)
   (json :initarg :json :reader page-source-json))
  (:documentation "The page file SLUG under SITE-ROOT as read at OBSERVED-AT:
its SHA-256, its length in octets and the JSON parsed from those octets."))

(defun %read-octets (pathname)
  (with-open-file (stream pathname :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (unless (= (length octets) (read-sequence octets stream))
        (error "The page file ~A changed while it was read." pathname))
      octets)))

(defun observe-local-fedwiki-page-source (site-root slug)
  "Read the page file SLUG under SITE-ROOT once and return what it held."
  (let* ((root (%canonical-site-root site-root))
         (pathname (dreyeck/fedwiki-assets:local-fedwiki-page-pathname root slug))
         (octets (%read-octets pathname)))
    (make-instance 'local-fedwiki-page-source
                   :site-root root :slug slug :pathname pathname
                   :sha256 (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets))
                   :octet-count (length octets)
                   :observed-at (get-universal-time)
                   :json (shasht:read-json (sb-ext:octets-to-string octets :external-format :utf-8)))))

(defun local-fedwiki-page-source-of (page)
  "Observe the file PAGE was read from, now."
  (observe-local-fedwiki-page-source (local-fedwiki-page-site-root-of page) (hyperbook:id-of page)))

(defun page-source-current-p (source)
  "Whether the page file still has SOURCE's digest. Reads, never writes."
  (equal (page-source-sha256 source)
         (page-source-sha256 (observe-local-fedwiki-page-source (page-source-site-root source)
                                                                (page-source-slug source)))))

(defun %source-story (source)
  (coerce (or (gethash "story" (page-source-json source)) (vector)) 'list))

(defclass local-story-item ()
  ((source :initarg :source :reader story-item-source)
   (index :initarg :index :reader story-item-index))
  (:documentation "The INDEXth story Item of the page as SOURCE observed it.
Its id and content are read from SOURCE's JSON; nothing is copied out."))

(defun source-story-items (source)
  "One LOCAL-STORY-ITEM per story Item of SOURCE, in story order."
  (loop for item in (%source-story source)
        for index from 0
        collect (make-instance 'local-story-item :source source :index index)))

(defun story-item-json (item)
  "A copy of ITEM's JSON exactly as its source observed it."
  (hyperbook/fedwiki::copy-page-json (nth (story-item-index item) (%source-story (story-item-source item)))))

(defun story-item-id (item) (gethash "id" (story-item-json item)))
(defun story-item-type (item) (gethash "type" (story-item-json item)))
(defun story-item-text (item) (or (gethash "text" (story-item-json item)) ""))

(defmethod print-object ((item local-story-item) stream)
  (print-unreadable-object (item stream :type t)
    (format stream "~A ~A at ~D" (story-item-type item) (story-item-id item) (story-item-index item))))
