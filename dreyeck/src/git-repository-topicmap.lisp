(in-package #:dreyeck/git)

(defun git-repository-topicmap-projection (common-lisp-user::repository)
  (let* ((common-lisp-user::root
          (git-repository-root-of common-lisp-user::repository))
         (common-lisp-user::directory-components
          (pathname-directory common-lisp-user::root))
         (common-lisp-user::repository-name
          (let ((common-lisp-user::component
                 (car (last common-lisp-user::directory-components))))
            (if (stringp common-lisp-user::component)
                common-lisp-user::component
                "Git")))
         (common-lisp-user::head
          (make-git-commit :repository common-lisp-user::repository :commit-ish
                           "HEAD"))
         (common-lisp-user::repository-id
          (format nil "git-repository:~A" (namestring common-lisp-user::root)))
         (common-lisp-user::head-id
          (format nil "git-commit:~A"
                  (git-commit-hash-of common-lisp-user::head)))
         (common-lisp-user::repository-topic
          (dreyeck/topicmap:make-topicmap-topic :id
                                                common-lisp-user::repository-id
                                                :type :git-repository-checkout
                                                :label
                                                (format nil "~A repository"
                                                        common-lisp-user::repository-name)
                                                :object
                                                common-lisp-user::repository
                                                :view-properties
                                                '(:x 120 :y 220 :visible t
                                                  :pinned t)))
         (common-lisp-user::head-topic
          (dreyeck/topicmap:make-topicmap-topic :id common-lisp-user::head-id
                                                :type :git-commit :label
                                                (subseq
                                                 (git-commit-hash-of
                                                  common-lisp-user::head)
                                                 0 12)
                                                :object common-lisp-user::head
                                                :view-properties
                                                '(:x 700 :y 220 :visible t
                                                  :pinned t)))
         (common-lisp-user::association
          (dreyeck/topicmap:make-topicmap-association :id
                                                      (format nil
                                                              "association:current-head:~A"
                                                              common-lisp-user::repository-id)
                                                      :type :current-head :from
                                                      common-lisp-user::repository-id
                                                      :to
                                                      common-lisp-user::head-id
                                                      :properties
                                                      '(:from-role :repository
                                                        :to-role
                                                        :head-commit))))
    (dreyeck/topicmap:make-topicmap-projection :source
                                               common-lisp-user::repository
                                               :topics
                                               (list
                                                common-lisp-user::repository-topic
                                                common-lisp-user::head-topic)
                                               :associations
                                               (list
                                                common-lisp-user::association)
                                               :view-properties
                                               (list :presentation
                                                     :repository-state :point
                                                     common-lisp-user::repository-id
                                                     :scope :current-lisp-image
                                                     :root
                                                     (namestring
                                                      common-lisp-user::root)
                                                     :branch
                                                     (git-current-branch
                                                      common-lisp-user::repository)
                                                     :width 1050 :height 520))))

(defmethod dreyeck/topicmap:topicmap-projection-of
           ((common-lisp-user::repository git-repository-checkout))
  (git-repository-topicmap-projection common-lisp-user::repository))


(defmethod dreyeck/topicmap:topicmap-projection-of
           ((slice dreyeck/git:git-source-slice))
  (let* ((commit (dreyeck/git:git-source-slice-commit-of slice))
         (hash (dreyeck/git:git-commit-hash-of commit))
         (selections (dreyeck/git:git-source-slice-selections-of slice))
         (sparse-mode (dreyeck/git:git-source-slice-sparse-mode-of slice))
         (slice-id
          (format nil "git-source-slice:~A:~A:~S" hash sparse-mode selections))
         (commit-id (format nil "git-commit:~A" hash))
         (slice-topic
          (make-instance 'dreyeck/topicmap:topicmap-topic :id slice-id :type
                         :git-source-slice :label
                         (format nil "source slice ~{~A~^, ~}" selections)
                         :object slice :view-properties
                         '(:x 120 :y 220 :visible t :pinned t)))
         (commit-topic
          (make-instance 'dreyeck/topicmap:topicmap-topic :id commit-id :type
                         :git-commit :label hash :object commit
                         :view-properties
                         '(:x 700 :y 220 :visible t :pinned t)))
         (association
          (make-instance 'dreyeck/topicmap:topicmap-association :id
                         (format nil
                                 "association:git-source-slice-commit-of:~A"
                                 slice-id)
                         :type 'dreyeck/git:git-source-slice-commit-of :from
                         slice-id :to commit-id :properties
                         '(:from-role :source-slice :to-role :commit))))
    (make-instance 'dreyeck/topicmap:topicmap-projection :source slice :topics
                   (list slice-topic commit-topic) :associations
                   (list association) :view-properties
                   (list :point slice-id :scope :current-lisp-image :width 1050
                         :height 520))))
