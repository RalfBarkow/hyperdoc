;;;; ASDF systems as a HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; The "ASDF Systems" hyperbook
;;

(defclass asdf-systems (hyperbook) ())

(defvar *asdf-systems* (make-instance 'asdf-systems :id "asdf-systems"))

(defmethod title-of ((hb asdf-systems))
  "ASDF Systems")

(eval-when (:load-toplevel)
  (register *asdf-systems*))

;;
;; Pages for ASDF systems
;;

(defclass asdf-system-page (page)
  ((system :reader system-of :initarg :system :type asdf:system)))

(defmethod find-page ((hb asdf-systems) page-id &key signal-error?)
  (when-let(system (asdf:find-system page-id signal-error?))
    (make-instance 'asdf-system-page
                   :hyperbook hb
                   :id page-id
                   :system system)))

(defmethod dom-of ((page asdf-system-page))
  (plump:make-root))

(defmethod links-of ((page asdf-system-page))
  (declare (ignore page))
  nil)

(defmethod find-link-sources ((hb asdf-systems) hyperbook-id page-id)
  (declare (ignore hb))
  nil)

(views:defview 👀system-views (page asdf-system-page)
  (views:specific-views (system-of page)))

;;
;; Two views for the ASDF Systems hyperbook
;;

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

;;
;; Remove the "content" views of hyperbooks and pages
;;

(views:defview views:👀content (hb asdf-systems)
  (declare (ignore hb))
  nil)

(views:defview views:👀content (page asdf-system-page)
  (declare (ignore page))
  nil)
