;;;; Projection of historical ASDF references onto Dreyeck's topicmap model.

(in-package #:dreyeck/git)

(defun git-asdf-stable-fragment (value)
  (with-output-to-string (stream)
    (loop for character across (string-downcase (format nil "~A" value))
          do (write-char
              (if (or (alphanumericp character)
                      (find character "-_."))
                  character
                  #\-)
              stream))))

(defun historical-asdf-commit-id (file)
  (format nil "git-commit:~A"
          (git-commit-hash-of (git-file-commit-of file))))

(defun historical-asdf-file-id (file)
  (format nil "git-file:~A:~A"
          (git-commit-hash-of (git-file-commit-of file))
          (git-asdf-stable-fragment (git-file-path-of file))))

(defun historical-asdf-declaration-id (declaration)
  (format nil "asdf-declaration:~A:~A"
          (git-commit-hash-of
           (git-file-commit-of
            (historical-asdf-system-declaration-file-of declaration)))
          (git-asdf-stable-fragment
           (historical-asdf-system-declaration-canonical-name-of
            declaration))))

(defun historical-asdf-reference-index (reference)
  (or
   (position
    reference
    (historical-asdf-system-declaration-dependencies-of
     (historical-asdf-dependency-reference-declaration-of reference)))
   0))

(defun historical-asdf-reference-id (reference)
  (format nil "asdf-dependency:~A:~A:~D"
          (git-commit-hash-of
           (git-file-commit-of
            (historical-asdf-dependency-reference-file-of reference)))
          (git-asdf-stable-fragment
           (historical-asdf-system-declaration-canonical-name-of
            (historical-asdf-dependency-reference-declaration-of reference)))
          (historical-asdf-reference-index reference)))

(defun current-asdf-target-id (resolution)
  (let ((reference
          (current-asdf-dependency-resolution-reference-of resolution)))
    (if (eq :resolved
            (current-asdf-dependency-resolution-status-of resolution))
        (format nil "current-asdf-system:~A"
                (git-asdf-stable-fragment
                 (historical-asdf-dependency-reference-canonical-name-of
                  reference)))
        (format nil "current-asdf-resolution:~A:~A"
                (historical-asdf-reference-id reference)
                (string-downcase
                 (symbol-name
                  (current-asdf-dependency-resolution-status-of
                   resolution)))))))

(defun historical-topic-properties (x y)
  (list :x x :y y :visible t :pinned t))

(defun current-topic-properties (x y)
  (list :x x :y y :visible t :pinned nil))

(defun make-commit-topic (file)
  (let ((commit (git-file-commit-of file)))
    (dreyeck/topicmap:make-topicmap-topic
     :id (historical-asdf-commit-id file)
     :type :git-commit
     :label
     (format nil "Git commit ~A"
             (subseq (git-commit-hash-of commit) 0 7))
     :object commit
     :temporal-scope :historical
     :view-properties (historical-topic-properties 30 80))))

(defun make-file-topic (file)
  (dreyeck/topicmap:make-topicmap-topic
   :id (historical-asdf-file-id file)
   :type :git-file-at-commit
   :label
   (format nil "~A @ ~A"
           (git-file-path-of file)
           (subseq (git-commit-hash-of (git-file-commit-of file)) 0 7))
   :object file
   :temporal-scope :historical
   :view-properties (historical-topic-properties 270 80)))

(defun make-declaration-topic (declaration row)
  (dreyeck/topicmap:make-topicmap-topic
   :id (historical-asdf-declaration-id declaration)
   :type :historical-asdf-system-declaration
   :label
   (format nil "~A @ ~A"
           (historical-asdf-system-declaration-canonical-name-of declaration)
           (subseq
            (git-commit-hash-of
             (git-file-commit-of
              (historical-asdf-system-declaration-file-of declaration)))
            0 7))
   :object declaration
   :temporal-scope :historical
   :view-properties
   (historical-topic-properties 510 (+ 40 (* row 115)))))

(defun make-reference-topic (reference row)
  (dreyeck/topicmap:make-topicmap-topic
   :id (historical-asdf-reference-id reference)
   :type :historical-asdf-dependency-reference
   :label
   (format nil "dependency reference ~A @ ~A"
           (or
            (historical-asdf-dependency-reference-canonical-name-of reference)
            (historical-asdf-dependency-reference-source-designator-of
             reference))
           (subseq
            (git-commit-hash-of
             (git-file-commit-of
              (historical-asdf-dependency-reference-file-of reference)))
            0 7))
   :object reference
   :temporal-scope :historical
   :view-properties
   (historical-topic-properties 750 (+ 40 (* row 115)))))

(defun make-resolution-topic (resolution row)
  (let* ((reference
           (current-asdf-dependency-resolution-reference-of resolution))
         (resolved-p
           (eq :resolved
               (current-asdf-dependency-resolution-status-of resolution)))
         (object
           (if resolved-p
               (current-asdf-dependency-resolution-target-of resolution)
               resolution)))
    (dreyeck/topicmap:make-topicmap-topic
     :id (current-asdf-target-id resolution)
     :type (if resolved-p :asdf-system :asdf-resolution)
     :label
     (if resolved-p
         (format nil "ASDF:SYSTEM ~A"
                 (historical-asdf-dependency-reference-canonical-name-of
                  reference))
         (format nil "~:(~A~) in current image: ~A"
                 (current-asdf-dependency-resolution-status-of resolution)
                 (historical-asdf-dependency-reference-source-designator-of
                  reference)))
     :object object
     :temporal-scope :current-lisp-image
     :view-properties
     (current-topic-properties 990 (+ 40 (* row 115))))))

(defun make-topicmap-association-between (type from to)
  (dreyeck/topicmap:make-topicmap-association
   :id (format nil "association:~(~A~):~A:~A" type from to)
   :type type
   :from from
   :to to))

(defun reference-resolution-association-type (resolution)
  (case (current-asdf-dependency-resolution-status-of resolution)
    (:resolved :resolves-to-in-current-image)
    (:unresolved :unresolved-in-current-image)
    (:unsupported :unsupported-in-current-image)))

(defun make-focused-reference-topicmap (reference)
  (let* ((declaration
           (historical-asdf-dependency-reference-declaration-of reference))
         (file
           (historical-asdf-dependency-reference-file-of reference))
         (resolution
           (historical-asdf-dependency-resolution reference))
         (commit-topic (make-commit-topic file))
         (file-topic (make-file-topic file))
         (declaration-topic (make-declaration-topic declaration 0))
         (reference-topic (make-reference-topic reference 0))
         (resolution-topic (make-resolution-topic resolution 0))
         (topics
           (list commit-topic file-topic declaration-topic reference-topic
                 resolution-topic)))
    (dreyeck/topicmap:make-topicmap-projection
     :source reference
     :topics topics
     :associations
     (list
      (make-topicmap-association-between
       :has-file-at-commit
       (dreyeck/topicmap:topicmap-topic-id-of commit-topic)
       (dreyeck/topicmap:topicmap-topic-id-of file-topic))
      (make-topicmap-association-between
       :declares-system
       (dreyeck/topicmap:topicmap-topic-id-of file-topic)
       (dreyeck/topicmap:topicmap-topic-id-of declaration-topic))
      (make-topicmap-association-between
       :depends-on
       (dreyeck/topicmap:topicmap-topic-id-of declaration-topic)
       (dreyeck/topicmap:topicmap-topic-id-of reference-topic))
      (make-topicmap-association-between
       (reference-resolution-association-type resolution)
       (dreyeck/topicmap:topicmap-topic-id-of reference-topic)
       (dreyeck/topicmap:topicmap-topic-id-of resolution-topic)))
     :view-properties '(:width 1240 :height 300))))

(defun pushnew-topic (topic topics)
  (if (find (dreyeck/topicmap:topicmap-topic-id-of topic)
            topics
            :key #'dreyeck/topicmap:topicmap-topic-id-of
            :test #'string=)
      topics
      (append topics (list topic))))

(defun make-file-reference-topicmap (file)
  (let* ((projection (git-file-asdf-reference-projection file))
         (commit-topic (make-commit-topic file))
         (file-topic (make-file-topic file))
         (topics (list commit-topic file-topic))
         (associations
           (list
            (make-topicmap-association-between
             :has-file-at-commit
             (dreyeck/topicmap:topicmap-topic-id-of commit-topic)
             (dreyeck/topicmap:topicmap-topic-id-of file-topic))))
         (row 0))
    (dolist
        (declaration
          (historical-asdf-file-projection-declarations-of projection))
      (let ((declaration-topic (make-declaration-topic declaration row)))
        (setf topics (pushnew-topic declaration-topic topics))
        (push
         (make-topicmap-association-between
          :declares-system
          (dreyeck/topicmap:topicmap-topic-id-of file-topic)
          (dreyeck/topicmap:topicmap-topic-id-of declaration-topic))
         associations)
        (let ((references
                (historical-asdf-system-declaration-dependencies-of
                 declaration)))
          (dolist (reference references)
            (let* ((resolution
                     (historical-asdf-dependency-resolution reference))
                   (reference-topic (make-reference-topic reference row))
                   (resolution-topic (make-resolution-topic resolution row)))
              (setf topics (pushnew-topic reference-topic topics)
                    topics (pushnew-topic resolution-topic topics))
              (push
               (make-topicmap-association-between
                :depends-on
                (dreyeck/topicmap:topicmap-topic-id-of declaration-topic)
                (dreyeck/topicmap:topicmap-topic-id-of reference-topic))
               associations)
              (push
               (make-topicmap-association-between
                (reference-resolution-association-type resolution)
                (dreyeck/topicmap:topicmap-topic-id-of reference-topic)
                (dreyeck/topicmap:topicmap-topic-id-of resolution-topic))
               associations)
              (incf row)))
          (when (null references)
            (incf row)))))
    (dreyeck/topicmap:make-topicmap-projection
     :source projection
     :topics topics
     :associations (nreverse associations)
     :view-properties
     (list :width 1240 :height (max 360 (+ 180 (* row 115)))))))

(defgeneric historical-asdf-reference-topicmap (object)
  (:documentation
   "Project historical ASDF reference OBJECT without choosing a renderer."))

(defmethod historical-asdf-reference-topicmap
    ((file git-file-at-commit))
  (when (git-file-asdf-reference-projection file)
    (make-file-reference-topicmap file)))

(defmethod historical-asdf-reference-topicmap
    ((reference historical-asdf-dependency-reference))
  (make-focused-reference-topicmap reference))

(defmethod dreyeck/topicmap:topicmap-projection-of ((file git-file-at-commit))
  (historical-asdf-reference-topicmap file))

(defmethod dreyeck/topicmap:topicmap-projection-of
    ((reference historical-asdf-dependency-reference))
  (historical-asdf-reference-topicmap reference))
