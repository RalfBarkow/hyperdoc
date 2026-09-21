;;;; Historical ASDF declarations extracted from Git blobs without evaluation.
;;;;
;;;; The scanner itself now lives in DREYECK/ASDF-SOURCE: it only ever
;;;; took a string, and reading a definition is not a Git question.

(in-package #:dreyeck/git)


(defclass historical-asdf-file-projection ()
  ((file
    :reader historical-asdf-file-projection-file-of
    :initarg :file
    :type git-file-at-commit)
   (declarations
    :reader historical-asdf-file-projection-declarations-of
    :initarg :declarations
    :initform nil
    :type list)
   (issues
    :reader historical-asdf-file-projection-issues-of
    :initarg :issues
    :initform nil
    :type list)))

(defclass historical-asdf-system-declaration ()
  ((file
    :reader historical-asdf-system-declaration-file-of
    :initarg :file
    :type git-file-at-commit)
   (source-designator
    :reader historical-asdf-system-declaration-source-designator-of
    :initarg :source-designator
    :type string)
   (canonical-name
    :reader historical-asdf-system-declaration-canonical-name-of
    :initarg :canonical-name
    :type string)
   (dependencies
    :accessor historical-asdf-system-declaration-dependencies-of
    :initarg :dependencies
    :initform nil
    :type list)))

(defclass historical-asdf-dependency-reference ()
  ((file
    :reader historical-asdf-dependency-reference-file-of
    :initarg :file
    :type git-file-at-commit)
   (declaration
    :reader historical-asdf-dependency-reference-declaration-of
    :initarg :declaration
    :type historical-asdf-system-declaration)
   (relation
    :reader historical-asdf-dependency-reference-relation-of
    :initarg :relation
    :initform :depends-on)
   (source-designator
    :reader historical-asdf-dependency-reference-source-designator-of
    :initarg :source-designator
    :type string)
   (canonical-name
    :reader historical-asdf-dependency-reference-canonical-name-of
    :initarg :canonical-name
    :initform nil
    :type (or null string))
   (support-status
    :reader historical-asdf-dependency-reference-support-status-of
    :initarg :support-status
    :type (member :supported :unsupported))))

(defclass current-asdf-dependency-resolution ()
  ((reference
    :reader current-asdf-dependency-resolution-reference-of
    :initarg :reference
    :type historical-asdf-dependency-reference)
   (status
    :reader current-asdf-dependency-resolution-status-of
    :initarg :status
    :type (member :resolved :unresolved :unsupported))
   (target
    :reader current-asdf-dependency-resolution-target-of
    :initarg :target
    :initform nil)
   (observed-in
    :reader current-asdf-dependency-resolution-observed-in-of
    :initarg :observed-in
    :initform :current-lisp-image)))

(defclass historical-asdf-parse-issue ()
  ((file
    :reader historical-asdf-parse-issue-file-of
    :initarg :file
    :type git-file-at-commit)
   (position
    :reader historical-asdf-parse-issue-position-of
    :initarg :position
    :type integer)
   (message
    :reader historical-asdf-parse-issue-message-of
    :initarg :message
    :type string)))

(defmethod print-object
    ((declaration historical-asdf-system-declaration) stream)
  (print-unreadable-object (declaration stream :type t :identity nil)
    (format stream "~A"
            (historical-asdf-system-declaration-canonical-name-of
             declaration))))

(defmethod print-object
    ((reference historical-asdf-dependency-reference) stream)
  (print-unreadable-object (reference stream :type t :identity nil)
    (format stream "~A ~A"
            (historical-asdf-dependency-reference-relation-of reference)
            (or
             (historical-asdf-dependency-reference-canonical-name-of
              reference)
             (historical-asdf-dependency-reference-source-designator-of
              reference)))))

(defmethod print-object
    ((resolution current-asdf-dependency-resolution) stream)
  (print-unreadable-object (resolution stream :type t :identity nil)
    (format stream "~A in current Lisp image"
            (current-asdf-dependency-resolution-status-of resolution))))



(defun make-historical-dependency-reference
    (file declaration node support-status canonical-name)
  (make-instance
   'historical-asdf-dependency-reference
   :file file
   :declaration declaration
   :relation :depends-on
   :source-designator (dreyeck/asdf-source:asdf-source-node-raw node)
   :canonical-name canonical-name
   :support-status support-status))

(defun dependency-references-from-node (file declaration node)
  (cond
    ((null node) nil)
    ((eq :list (dreyeck/asdf-source:asdf-source-node-kind node))
     (mapcar
      (lambda (dependency-node)
        (let ((canonical-name
                (dreyeck/asdf-source:simple-asdf-designator-name dependency-node)))
          (make-historical-dependency-reference
           file
           declaration
           dependency-node
           (if canonical-name :supported :unsupported)
           canonical-name)))
      (dreyeck/asdf-source:asdf-source-node-children node)))
    (t
     (list
      (make-historical-dependency-reference
       file declaration node :unsupported nil)))))

(defun declaration-from-node (file node)
  (let* ((children (dreyeck/asdf-source:asdf-source-node-children node))
         (designator (second children))
         (canonical-name (and designator
                              (dreyeck/asdf-source:simple-asdf-designator-name designator))))
    (when canonical-name
      (let ((declaration
              (make-instance
               'historical-asdf-system-declaration
               :file file
               :source-designator (dreyeck/asdf-source:asdf-source-node-raw designator)
               :canonical-name canonical-name)))
        (setf
         (historical-asdf-system-declaration-dependencies-of declaration)
         (dependency-references-from-node
          file declaration (dreyeck/asdf-source:depends-on-node node)))
        declaration))))

(defun extract-historical-asdf-reference-projection (file source)
  (let ((*read-eval* nil))
    (multiple-value-bind (nodes raw-issues)
        (dreyeck/asdf-source:scan-asdf-source source)
      (make-instance
       'historical-asdf-file-projection
       :file file
       :declarations
       (remove nil
               (mapcar
                (lambda (node)
                  (when (dreyeck/asdf-source:asdf-defsystem-form-p node)
                    (declaration-from-node file node)))
                nodes))
       :issues
       (mapcar
        (lambda (issue)
          (make-instance
           'historical-asdf-parse-issue
           :file file
           :position (first issue)
           :message (second issue)))
        raw-issues)))))

(defun git-asdf-file-p (file)
  (string-equal "asd"
                (or (pathname-type (pathname (git-file-path-of file))) "")))

(defun git-file-asdf-reference-projection (file &key refresh)
  "Extract historical ASDF references from FILE without evaluating its blob."
  (check-type file git-file-at-commit)
  (unless (git-asdf-file-p file)
    (return-from git-file-asdf-reference-projection nil))
  (when (or refresh
            (null (git-file-asdf-reference-projection-cache file)))
    (setf (git-file-asdf-reference-projection-cache file)
          (handler-case
              (extract-historical-asdf-reference-projection
               file (git-file-contents file))
            (condition (condition)
              (make-instance
               'historical-asdf-file-projection
               :file file
               :issues
               (list
                (make-instance
                 'historical-asdf-parse-issue
                 :file file
                 :position 0
                 :message (format nil "~A" condition))))))))
  (git-file-asdf-reference-projection-cache file))

(defun historical-asdf-dependency-resolution (reference)
  "Resolve REFERENCE only against systems registered in the current image."
  (check-type reference historical-asdf-dependency-reference)
  (if (eq :unsupported
          (historical-asdf-dependency-reference-support-status-of reference))
      (make-instance
       'current-asdf-dependency-resolution
       :reference reference
       :status :unsupported)
      (let* ((name
               (historical-asdf-dependency-reference-canonical-name-of
                reference))
             (target (and name (asdf:registered-system name))))
        (make-instance
         'current-asdf-dependency-resolution
         :reference reference
         :status (if target :resolved :unresolved)
         :target target))))
