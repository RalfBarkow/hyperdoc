;;;; SCXML AST for HyperDoc compiler MVP
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/scxml)

(defclass scxml-chart ()
  ((name :reader scxml-chart-name-of
         :initarg :name
         :initform nil)
   (initial-state :reader scxml-chart-initial-state-of
                  :initarg :initial-state
                  :initform nil)
   (states :reader scxml-chart-states-of
           :initarg :states
           :initform nil)
   (source-pathname :reader scxml-chart-source-pathname-of
                    :initarg :source-pathname
                    :initform nil)
   (parse-problems :reader scxml-chart-parse-problems-of
                   :initarg :parse-problems
                   :initform nil)))

(defclass scxml-state ()
  ((id :reader scxml-state-id-of
       :initarg :id)
   (final-p :reader scxml-state-final-p-of
            :initarg :final-p
            :initform nil)
   (onentry-actions :reader scxml-state-onentry-actions-of
                    :initarg :onentry-actions
                    :initform nil)
   (transitions :reader scxml-state-transitions-of
                :initarg :transitions
                :initform nil)))

(defclass scxml-transition ()
  ((event :reader scxml-transition-event-of
          :initarg :event
          :initform nil)
   (target :reader scxml-transition-target-of
           :initarg :target
           :initform nil)
   (id :reader scxml-transition-id-of
       :initarg :id
       :initform nil)
   (source-state-id :reader scxml-transition-source-state-id-of
                    :initarg :source-state-id
                    :initform nil)))

(defclass scxml-action ()
  ((kind :reader scxml-action-kind-of
         :initarg :kind)
   (attributes :reader scxml-action-attributes-of
               :initarg :attributes
               :initform nil)))
