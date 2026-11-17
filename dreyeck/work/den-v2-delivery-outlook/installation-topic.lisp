(defpackage #:den-v2-outlook-topic
  (:use #:cl)
  (:export #:topic-url))

(in-package #:den-v2-outlook-topic)

(defparameter *book-id* "den-v2-delivery-outlook")
(defparameter *page-id* "ZIP entpacken und Plansystem laden")

(defun installation-book ()
  (let* ((system "den-v2-delivery-outlook/topic")
         (directory (truename (asdf:system-relative-pathname system "pages/")))
         (current (hyperbook:find-hyperbook *book-id*)))
    (if (and (typep current 'hyperdoc:hyperdoc)
             (equal directory (probe-file (hyperdoc:directory-of current))))
        current
        (let ((book (hyperdoc:make-hyperdoc
                     :id *book-id*
                     :title "Den v2 Delivery Outlook"
                     :asdf-system-name system
                     :subdirectory "pages"
                     :main-page-id *page-id*)))
          (hyperbook:find-page book *page-id* :signal-error? t)
          ;; REGISTER deduplicates by ID and installs the current server route.
          (when current
            (setf (hyperbook:hyperbooks-of hyperbook:*catalog*)
                  (remove current (hyperbook:hyperbooks-of hyperbook:*catalog*)
                          :test #'eq)))
          (hyperbook:register book)
          book))))

(defun topic-url (&optional (origin "http://127.0.0.1:8080"))
  "Return the local topic URL and the pathname of the page it opens."
  (let* ((book (installation-book))
         (page (hyperbook:find-page book *page-id* :signal-error? t)))
    (values (format nil "~A/~A/~A" (string-right-trim "/" origin)
                    (hyperbook/server::slug book)
                    (hunchentoot:url-encode (hyperbook:path-item-of page)))
            (hyperdoc:file-of page))))
