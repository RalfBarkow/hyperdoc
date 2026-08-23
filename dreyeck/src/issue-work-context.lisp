(in-package #:dreyeck/issue)

(defclass dreyeck/issue:issue-work-context nil
          ((dreyeck/issue::repository :reader
            dreyeck/issue:issue-work-context-repository-of :initarg :repository
            :type dreyeck/git:git-repository-checkout)
           (dreyeck/issue::branch :reader
            dreyeck/issue:issue-work-context-branch-of :initarg :branch :type
            (or null string))
           (dreyeck/issue::current-head :reader
            dreyeck/issue:issue-work-context-current-head-of :initarg
            :current-head :type dreyeck/git:git-commit)
           (dreyeck/issue::issue :reader
            dreyeck/issue:issue-work-context-issue-of :initarg :issue :type
            dreyeck/issue:issue-reference))
          (:documentation
           "Observed repository state associated with an issue reference."))

(defun dreyeck/issue:make-issue-work-context
       (dreyeck/issue::repository dreyeck/issue::issue)
  (make-instance 'dreyeck/issue:issue-work-context :repository
                 dreyeck/issue::repository :branch
                 (dreyeck/git:git-current-branch dreyeck/issue::repository)
                 :current-head
                 (dreyeck/git:make-git-commit :repository
                                              dreyeck/issue::repository
                                              :commit-ish "HEAD")
                 :issue dreyeck/issue::issue))
