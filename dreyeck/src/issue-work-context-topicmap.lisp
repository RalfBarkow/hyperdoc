(in-package #:dreyeck/issue)

(defun dreyeck/issue::issue-work-context-topicmap (dreyeck/issue::context)
  (let* ((dreyeck/issue::repository
          (dreyeck/issue:issue-work-context-repository-of
           dreyeck/issue::context))
         (dreyeck/issue::root
          (dreyeck/git:git-repository-root-of dreyeck/issue::repository))
         (dreyeck/issue::directory-components
          (pathname-directory dreyeck/issue::root))
         (dreyeck/issue::repository-name
          (let ((dreyeck/issue::component
                 (car (last dreyeck/issue::directory-components))))
            (if (stringp dreyeck/issue::component)
                dreyeck/issue::component
                "Git")))
         (dreyeck/issue::head
          (dreyeck/issue:issue-work-context-current-head-of
           dreyeck/issue::context))
         (dreyeck/issue::repository-id
          (format nil "git-repository:~A" (namestring dreyeck/issue::root)))
         (dreyeck/issue::head-id
          (format nil "git-commit:~A"
                  (dreyeck/git:git-commit-hash-of dreyeck/issue::head)))
         (dreyeck/issue::repository-topic
          (dreyeck/topicmap:make-topicmap-topic :id
                                                dreyeck/issue::repository-id
                                                :type :git-repository-checkout
                                                :label
                                                (format nil "~A repository"
                                                        dreyeck/issue::repository-name)
                                                :object
                                                dreyeck/issue::repository
                                                :view-properties
                                                '(:x 120 :y 220 :visible t
                                                  :pinned t)))
         (dreyeck/issue::head-topic
          (dreyeck/topicmap:make-topicmap-topic :id dreyeck/issue::head-id
                                                :type :git-commit :label
                                                (subseq
                                                 (dreyeck/git:git-commit-hash-of
                                                  dreyeck/issue::head)
                                                 0 12)
                                                :object dreyeck/issue::head
                                                :view-properties
                                                '(:x 700 :y 220 :visible t
                                                  :pinned t)))
         (dreyeck/issue::association
          (dreyeck/topicmap:make-topicmap-association :id
                                                      (format nil
                                                              "association:current-head:~A"
                                                              dreyeck/issue::repository-id)
                                                      :type :current-head :from
                                                      dreyeck/issue::repository-id
                                                      :to
                                                      dreyeck/issue::head-id
                                                      :properties
                                                      '(:from-role :repository
                                                        :to-role
                                                        :head-commit)))
         (dreyeck/issue::issue
          (dreyeck/issue:issue-work-context-issue-of dreyeck/issue::context))
         (dreyeck/issue::issue-coordinate
          (dreyeck/issue:issue-reference-coordinate dreyeck/issue::issue))
         (dreyeck/issue::issue-id
          (format nil "issue:~A:~A/~A#~D"
                  (dreyeck/issue:issue-reference-forge-of dreyeck/issue::issue)
                  (dreyeck/issue:issue-reference-owner-of dreyeck/issue::issue)
                  (dreyeck/issue:issue-reference-repository-of
                   dreyeck/issue::issue)
                  (dreyeck/issue:issue-reference-number-of
                   dreyeck/issue::issue)))
         (dreyeck/issue::issue-topic
          (dreyeck/topicmap:make-topicmap-topic :id dreyeck/issue::issue-id
                                                :type :issue-reference :label
                                                dreyeck/issue::issue-coordinate
                                                :object dreyeck/issue::issue
                                                :view-properties
                                                '(:x 700 :y 340 :visible t
                                                  :pinned t)))
         (dreyeck/issue::tracks-association
          (dreyeck/topicmap:make-topicmap-association :id
                                                      (format nil
                                                              "association:tracks:~A"
                                                              dreyeck/issue::issue-id)
                                                      :type :tracks :from
                                                      dreyeck/issue::repository-id
                                                      :to
                                                      dreyeck/issue::issue-id
                                                      :properties
                                                      '(:from-role :repository
                                                        :to-role
                                                        :tracked-issue))))
    (dreyeck/topicmap:make-topicmap-projection :source dreyeck/issue::context
                                               :topics
                                               (list
                                                dreyeck/issue::repository-topic
                                                dreyeck/issue::head-topic
                                                dreyeck/issue::issue-topic)
                                               :associations
                                               (list dreyeck/issue::association
                                                     dreyeck/issue::tracks-association)
                                               :view-properties
                                               (list :presentation
                                                     :issue-work-context :point
                                                     dreyeck/issue::repository-id
                                                     :scope :current-lisp-image
                                                     :root
                                                     (namestring
                                                      dreyeck/issue::root)
                                                     :branch
                                                     (dreyeck/issue:issue-work-context-branch-of
                                                      dreyeck/issue::context)
                                                     :width 1050 :height 520))))

(defmethod dreyeck/topicmap:topicmap-projection-of
           ((dreyeck/issue::context dreyeck/issue:issue-work-context))
  (dreyeck/issue::issue-work-context-topicmap dreyeck/issue::context))
