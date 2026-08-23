(in-package #:dreyeck/issue)

(defclass dreyeck/issue:issue-reference nil
          ((dreyeck/issue::forge :reader dreyeck/issue:issue-reference-forge-of
            :initarg :forge :type string)
           (dreyeck/issue::owner :reader dreyeck/issue:issue-reference-owner-of
            :initarg :owner :type string)
           (dreyeck/issue::repository :reader
            dreyeck/issue:issue-reference-repository-of :initarg :repository
            :type string)
           (number :reader dreyeck/issue:issue-reference-number-of :initarg
            :number :type (integer 1 *)))
          (:documentation
           "Stable reference to an issue in an external issue tracker."))

(defun dreyeck/issue:issue-reference-coordinate (dreyeck/issue::issue)
  (format nil "~A/~A#~D"
          (dreyeck/issue:issue-reference-owner-of dreyeck/issue::issue)
          (dreyeck/issue:issue-reference-repository-of dreyeck/issue::issue)
          (dreyeck/issue:issue-reference-number-of dreyeck/issue::issue)))
