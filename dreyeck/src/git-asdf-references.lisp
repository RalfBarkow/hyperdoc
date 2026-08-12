;;;; Historical ASDF declarations extracted from Git blobs without evaluation.

(in-package #:dreyeck/git)

(defstruct asdf-source-node
  kind
  raw
  value
  children
  start
  end)

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

(defun asdf-source-delimiter-p (character)
  (or (null character)
      (find character "()\";'`," :test #'char=)
      (find character '(#\Space #\Tab #\Newline #\Return #\Page)
            :test #'char=)))

(defun scan-historical-asdf-source (source)
  "Parse SOURCE into a package-free structural tree without invoking READ."
  (let ((position 0)
        (length (length source))
        (issues nil))
    (labels
        ((prefix-at-p (prefix)
           (and (<= (+ position (length prefix)) length)
                (string= prefix source
                         :start2 position
                         :end2 (+ position (length prefix)))))
         (skip-line-comment ()
           (loop while (and (< position length)
                            (not (find (char source position)
                                       '(#\Newline #\Return))))
                 do (incf position)))
         (skip-block-comment ()
           (let ((start position)
                 (depth 0))
             (loop while (< position length)
                   do (cond
                        ((prefix-at-p "#|")
                         (incf depth)
                         (incf position 2))
                        ((prefix-at-p "|#")
                         (decf depth)
                         (incf position 2)
                         (when (zerop depth) (return)))
                        (t (incf position))))
             (unless (zerop depth)
               (push (list start "Unterminated #| ... |# comment.")
                     issues))))
         (skip-ignored ()
           (loop
             (loop while (and (< position length)
                              (find (char source position)
                                    '(#\Space #\Tab #\Newline #\Return #\Page)))
                   do (incf position))
             (cond
               ((and (< position length)
                     (char= (char source position) #\;))
                (skip-line-comment))
               ((prefix-at-p "#|")
                (skip-block-comment))
               (t (return)))))
         (parse-string-node ()
           (let ((start position))
             (incf position)
             (let ((value
                     (with-output-to-string (stream)
                       (loop while (< position length)
                             for character = (char source position)
                             do (incf position)
                                (cond
                                  ((char= character #\\)
                                   (if (< position length)
                                       (progn
                                         (write-char (char source position)
                                                     stream)
                                         (incf position))
                                       (push
                                        (list start
                                              "Trailing escape in string.")
                                        issues)))
                                  ((char= character #\")
                                   (return))
                                  (t (write-char character stream)))
                             finally
                                (push (list start "Unterminated string.")
                                      issues)))))
               (make-asdf-source-node
                :kind :string
                :raw (subseq source start position)
                :value value
                :start start
                :end position))))
         (parse-character-node ()
           (let ((start position))
             (incf position 2)
             (when (< position length)
               (if (asdf-source-delimiter-p (char source position))
                   (incf position)
                   (loop while (and (< position length)
                                    (not
                                     (asdf-source-delimiter-p
                                      (char source position))))
                         do (incf position))))
             (make-asdf-source-node
              :kind :token
              :raw (subseq source start position)
              :value (subseq source start position)
              :start start
              :end position)))
         (parse-token-node ()
           (let ((start position))
             (loop while (and (< position length)
                              (not
                               (asdf-source-delimiter-p
                                (char source position))))
                   do (incf position))
             (when (= start position)
               (incf position))
             (make-asdf-source-node
              :kind :token
              :raw (subseq source start position)
              :value (subseq source start position)
              :start start
              :end position)))
         (parse-reader-eval-node ()
           (let ((start position))
             (incf position 2)
             (skip-ignored)
             (let ((child (and (< position length) (parse-form))))
               (push
                (list start
                      "Reader-evaluation form #. was retained as unsupported and was not evaluated.")
                issues)
               (make-asdf-source-node
                :kind :reader-eval
                :raw (subseq source start position)
                :children (and child (list child))
                :start start
                :end position))))
         (parse-list-node ()
           (let ((start position)
                 (children nil)
                 (closed-p nil))
             (incf position)
             (loop
               (skip-ignored)
               (cond
                 ((>= position length) (return))
                 ((char= (char source position) #\))
                  (incf position)
                  (setf closed-p t)
                  (return))
                 (t (push (parse-form) children))))
             (unless closed-p
               (push (list start "Unterminated list.") issues))
             (make-asdf-source-node
              :kind :list
              :raw (subseq source start position)
              :children (nreverse children)
              :start start
              :end position)))
         (parse-form ()
           (skip-ignored)
           (cond
             ((>= position length) nil)
             ((prefix-at-p "#.") (parse-reader-eval-node))
             ((prefix-at-p "#\\") (parse-character-node))
             ((char= (char source position) #\() (parse-list-node))
             ((char= (char source position) #\") (parse-string-node))
             ((char= (char source position) #\))
              (let ((start position))
                (incf position)
                (push (list start "Unexpected closing parenthesis.") issues)
                (make-asdf-source-node
                 :kind :error
                 :raw ")"
                 :start start
                 :end position)))
             (t (parse-token-node)))))
      (let ((nodes nil))
        (loop
          (skip-ignored)
          (when (>= position length) (return))
          (push (parse-form) nodes))
        (values (nreverse nodes) (nreverse issues))))))

(defun simple-asdf-designator-name (node)
  (case (asdf-source-node-kind node)
    (:string (string-downcase (asdf-source-node-value node)))
    (:token
     (let ((raw (asdf-source-node-raw node)))
       (unless (or (zerop (length raw))
                   (and (char= (char raw 0) #\#)
                        (not (uiop:string-prefix-p "#:" raw)))
                   (find #\| raw))
         (let* ((without-uninterned
                  (if (uiop:string-prefix-p "#:" raw)
                      (subseq raw 2)
                      raw))
                (last-colon (position #\: without-uninterned :from-end t))
                (name (if last-colon
                          (subseq without-uninterned (1+ last-colon))
                          without-uninterned)))
           (unless (zerop (length name))
             (string-downcase name))))))
    (otherwise nil)))

(defun asdf-defsystem-form-p (node)
  (and (eq :list (asdf-source-node-kind node))
       (let ((head (first (asdf-source-node-children node))))
         (and head
              (string= "defsystem"
                       (or (simple-asdf-designator-name head) ""))))))

(defun depends-on-node (defsystem-node)
  (let ((children (asdf-source-node-children defsystem-node)))
    (loop for tail on (cddr children)
          for key = (first tail)
          when (and key
                    (eq :token (asdf-source-node-kind key))
                    (string-equal ":depends-on"
                                  (asdf-source-node-raw key)))
            return (second tail))))

(defun make-historical-dependency-reference
    (file declaration node support-status canonical-name)
  (make-instance
   'historical-asdf-dependency-reference
   :file file
   :declaration declaration
   :relation :depends-on
   :source-designator (asdf-source-node-raw node)
   :canonical-name canonical-name
   :support-status support-status))

(defun dependency-references-from-node (file declaration node)
  (cond
    ((null node) nil)
    ((eq :list (asdf-source-node-kind node))
     (mapcar
      (lambda (dependency-node)
        (let ((canonical-name
                (simple-asdf-designator-name dependency-node)))
          (make-historical-dependency-reference
           file
           declaration
           dependency-node
           (if canonical-name :supported :unsupported)
           canonical-name)))
      (asdf-source-node-children node)))
    (t
     (list
      (make-historical-dependency-reference
       file declaration node :unsupported nil)))))

(defun declaration-from-node (file node)
  (let* ((children (asdf-source-node-children node))
         (designator (second children))
         (canonical-name (and designator
                              (simple-asdf-designator-name designator))))
    (when canonical-name
      (let ((declaration
              (make-instance
               'historical-asdf-system-declaration
               :file file
               :source-designator (asdf-source-node-raw designator)
               :canonical-name canonical-name)))
        (setf
         (historical-asdf-system-declaration-dependencies-of declaration)
         (dependency-references-from-node
          file declaration (depends-on-node node)))
        declaration))))

(defun extract-historical-asdf-reference-projection (file source)
  (let ((*read-eval* nil))
    (multiple-value-bind (nodes raw-issues)
        (scan-historical-asdf-source source)
      (make-instance
       'historical-asdf-file-projection
       :file file
       :declarations
       (remove nil
               (mapcar
                (lambda (node)
                  (when (asdf-defsystem-form-p node)
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
