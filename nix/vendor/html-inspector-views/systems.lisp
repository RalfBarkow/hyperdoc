;;;; Views for ASDF systems and their components
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package #:html-inspector-views/standard)

;;
;; Text representations
;;

(defmethod text-representation ((object asdf/component:component))
  (str:join "/" (asdf:component-find-path object)))

(defmethod text-representation ((object asdf/system:system))
  (asdf:component-name object))

;;
;; Dependency view
;;

(defview 👀dependencies (system asdf/system:system)
  (when (system-dependencies system)
    (-<> system
         dependency-tree
         cdr 
         (cons nil <>)
         thunk
         tree-view
         (rename :title "Dependencies"
                 :priority 5))))

(defview 👀dependency-graph (system asdf/system:system)
  (when (system-dependencies system)
        (graphviz-view (thunk (dot-graph-from-edges (dependency-pairs system)))
                       :engine "dot"
                       :title "Dependency graph"
                       :priority 6)))

(defun dot-graph-from-edges (edges)
  (let* ((ids (node-ids edges))
         (layers (image-system-layer *image*))
         (used-layers (->> ids fset:domain (fset:image layers))))
    (flet ((subgraph (layer)
             (let ((cluster (fset:filter #'(lambda (s-i)
                                             (= layer (fset:lookup layers
                                                                   (car s-i))))
                                         (fset:convert 'fset:set ids))))
               `(:subgraph ,(format nil "cluster_~d" layer)
                           (= :color :white)
                           ,@(fset:convert 'list
                             (fset:image #'(lambda (s-i)
                                             `(,(cdr s-i)
                                               (:label ,(component-name (car s-i)))
                                               (:shape :box)))
                                         cluster))))))
      `(:digraph nil
                 ,@(fset:convert 'list
                     (fset:image #'subgraph used-layers))
                 ,@(fset:convert 'list
                     (fset:image #'(lambda (e)
                                     `(:-> ()
                                           ,(fset:lookup ids (first e))
                                           ,(fset:lookup ids (second e))))
                                 edges))))))

(defun dependency-pairs (system)
  (let ((deps (fset:convert 'fset:set (system-dependencies system))))
    (fset:reduce #'fset:union (fset:image #'dependency-pairs deps)
                 ;; Use a two-element list for each pair, rather than a single
                 ;; cons cell, because of a bug in FSet:
                 ;;   https://github.com/slburson/fset/issues/56
                 :initial-value (fset:image #'(lambda (d) (list system d)) deps))))

(defun node-ids (edges)
  (let ((nodes (fset:reduce #'(lambda (s e)
                                (-> s (fset:with (first e)) (fset:with (second e))))
                            edges
                            :initial-value (fset:empty-set)))
        (id-map (fset:empty-map)))
    (fset:do-set (n nodes)
      (fset:includef id-map n (inspect-id n)))
    id-map))

(defun dependency-tree (system)
  (cons system
        (mapcar #'dependency-tree
                (sort (system-dependencies system)
                      #'string< :key #'component-name))))

(defclass missing-component ()
  ((name :reader component-name :initarg :name)
   (reason :reader missing-component-reason :initarg :reason :initform :missing)
   (condition :reader missing-component-condition :initarg :condition :initform nil)
   (depending-system :reader missing-component-depending-system
                     :initarg :depending-system
                     :initform nil)))

(defmethod component-name ((component asdf:component))
  (asdf:component-name component))

(defmethod component-name ((component null))
  "<nil ASDF component>")

(defmethod text-representation ((object missing-component))
  (format nil "~A (~(~A~))"
          (component-name object)
          (missing-component-reason object)))

(defmethod html-representation ((object missing-component) &optional id)
  (let ((text (text-representation object)))
    (if id
        (html (:span :id id :class "inspector-error" (esc text)))
        (html (:span :class "inspector-error" (esc text))))))

(defun make-missing-component (name reason &key condition depending-system)
  (make-instance 'missing-component
                 :name name
                 :reason reason
                 :condition condition
                 :depending-system depending-system))

(defun find-system (name &key depending-system)
  (cond
    ((null name)
     (make-missing-component "<nil ASDF component>"
                             :nil-dependency
                             :depending-system depending-system))
    ((typep name 'asdf:system)
     name)
    ((typep name 'missing-component)
     name)
    ((or (stringp name) (symbolp name))
     (handler-case
         (or (asdf:find-system name nil)
             (make-missing-component name
                                     :missing
                                     :depending-system depending-system))
       (asdf:missing-component (condition)
         (make-missing-component name
                                 :missing
                                 :condition condition
                                 :depending-system depending-system))
       (condition (condition)
         (make-missing-component name
                                 :failed
                                 :condition condition
                                 :depending-system depending-system))))
    (t
     (make-missing-component (princ-to-string name)
                             :unsupported-dependency-designator
                             :depending-system depending-system))))

(defgeneric system-depends-on (system)
  (:method ((system asdf:system))
    (handler-case
        (asdf:system-depends-on system)
      (condition (condition)
        (list
         (make-missing-component (component-name system)
                                 :failed-dependency-probe
                                 :condition condition
                                 :depending-system system)))))
  (:method ((system missing-component))
    nil)
  (:method ((system null))
    nil))

(defun dependency-component (dependency depending-system)
  (cond
    ((null dependency)
     (make-missing-component "<nil ASDF dependency>"
                             :nil-dependency
                             :depending-system depending-system))
    ((or (typep dependency 'asdf:system)
         (typep dependency 'missing-component))
     dependency)
    ((or (stringp dependency)
         (symbolp dependency))
     (find-system dependency :depending-system depending-system))
    (t
     nil)))

(defun system-dependencies (system)
  (loop for dependency in (system-depends-on system)
        for component = (dependency-component dependency system)
        when component
          collect component))

;;
;; Dependendee view
;;

(defview 👀dependees (system asdf/system:system)
  (when (system-dependees system)
    (-<> system
         dependee-tree
         cdr
         (cons nil <>)
         thunk
         tree-view
         (rename :title "Dependees"
                 :priority 7))))

(defview 👀dependee-graph (system asdf/system:system)
  (graphviz-view (thunk (dot-graph-from-edges (dependee-pairs system)))
                 :engine "dot"
                 :title "Dependee graph"
                 :priority 8))

(defun dependee-pairs (system)
  (let ((deps (fset:convert 'fset:set (system-dependees system))))
    (fset:reduce #'fset:union (fset:image #'dependee-pairs deps)
                 :initial-value (fset:image #'(lambda (d) (list d system)) deps))))

(defun system-dependees (system)
  (->> system
       (fset:lookup (image-system-dependees *image*))
       (fset:convert 'list)))

(defun dependee-tree (system)
  (cons system
        (mapcar #'dependee-tree (system-dependees system))))

;;
;; Source code view (ASD file)
;;

(defview 👀source (system asdf/system:system)
  (-> system
      asdf:system-source-file
      👀content 
      (rename :title "Source"
              :priority 1)))

;;
;; Children view
;;

(defview 👀children (c asdf/component:parent-component)
  (when-let (children (asdf:component-children c))
    (-> children
        👀items
        (rename :title "Children"
                 :priority 2))))

;;
;; Directory view of component-pathname
;;

(defview 👀directory (component asdf/component:parent-component)
  (-<> component
    asdf:component-pathname
    👀items
    (rename :title "Files"
            :priority 3)))

;;
;; Source code view for source files
;;

(defview 👀source (file asdf:source-file)
  (when-let (pathname (asdf:component-pathname file))
    (-> pathname
        source-view
        (rename :title "Source"
                :priority 1))))

;;
;; Plan view
;;

(defview 👀actions (plan asdf/plan:plan)
  (-> plan
      asdf/plan:plan-actions
      (multi-column-list-view
       :title "Actions" :priority 1
       :columns '("Operation" "Component")
       :display (list #'asdf/action:action-operation #'asdf/action:action-component)
       :inspect-items :by-column)))

(defview 👀plan (system asdf/system:system)
  (rename
   (handler-case (-<> system
                   (asdf:make-plan nil 'asdf:load-op <>)
                   👀actions)
     (asdf:system-definition-error (e) (👀error-message e)))
   :title "Plan" :priority 5))


(defmethod text-representation ((op asdf/operation:operation))
  (-> op
      class-of
      class-name
      symbol-name
      str:downcase))

;;
;; Source repository view
;;

(defview 👀repository (system asdf/system:system)
  (when-let (repo-list (asdf:system-source-control system))
    (html-view :title "Repository" :priority 4
               (html (:table :class "inspector-table"
                       (:tr (:th (esc "VCS")) (:th (esc "URL")))
                       (loop for (label . url) in (alexandria:plist-alist repo-list)
                             do (html (:tr (:td (esc (symbol-name label)))
                                           (:td (:a :href url
                                                    :target "_blank"
                                                    (esc url)))))))))))
