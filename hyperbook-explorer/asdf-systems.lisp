;;;; ASDF systems as a HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defclass asdf-systems (hyperbook) ())

(defvar *asdf-systems* (make-instance 'asdf-systems :id "asdf-systems"))

(defmethod title-of ((hb asdf-systems))
  "ASDF Systems")

(eval-when (:load-toplevel)
  (register *asdf-systems*))

(defmethod find-page ((hb asdf-systems) page-id &key signal-error?)
  (asdf:find-system page-id signal-error?))

(views:defview 👀loaded-systems (object asdf-systems)
  (declare (ignore object))
  (-> (mapcar #'asdf:find-system (asdf:already-loaded-systems))
      (sort #'string< :key #'asdf:component-name)
      views:thunk
      (views:list-view :title "Loaded systems"
                       :priority 1)))

(views:defview 👀registered-systems (object asdf-systems)
  (-<> (set-difference (asdf:registered-systems) (asdf:already-loaded-systems))
       (sort #'string<)
       (mapcar #'asdf:find-system <>)
       (views:list-view :title "Registered unloaded systems"
                        :priority 2)))
