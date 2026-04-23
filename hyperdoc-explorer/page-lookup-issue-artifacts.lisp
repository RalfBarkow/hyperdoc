;;;; Explorer integration for page-lookup issue authored artifacts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defmethod page-lookup-issue-authored-artifact-for
    ((issue hb:page-lookup-issue))
  (declare (ignore issue))
  (page-lookup-issue-authored-artifact))

(defmethod page-lookup-issue-behavior-artifact-for
    ((issue hb:page-lookup-issue))
  (declare (ignore issue))
  (page-lookup-issue-behavior-artifact))

(defmethod page-lookup-issue-layout-artifact-for
    ((issue hb:page-lookup-issue))
  (declare (ignore issue))
  (page-lookup-issue-layout-artifact))
