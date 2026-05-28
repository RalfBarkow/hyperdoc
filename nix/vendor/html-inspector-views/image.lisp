;;;; Views for the image
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package #:html-inspector-views/standard)

;;
;; The singleton image object stores information about systems
;; and packages that are used by various views.
;;

(defclass image (gui-class)
  ((system-layer :reader image-system-layer :initform nil)
   (system-dependees :reader image-system-dependees :initform nil)
   (source-file-map :reader image-source-file-map :initform nil)))

(defmethod image-system-layer :before ((image image))
  (unless (slot-value image 'system-layer)
    (precompute-dependency-data image)))

(defmethod image-system-dependees :before ((image image))
  (unless (slot-value image 'system-dependees)
    (precompute-dependency-data image)))

(defmethod image-source-file-map :before ((image image))
  (unless (slot-value image 'source-file-map)
    (precompute-dependency-data image)))

(defvar *image* (make-instance 'image :pane-title "Image"))

(defmethod text-representation ((image image))
  "Image")

;;
;; Precompute dependency and pathname information on all systems, to
;; speed up view generation.
;;

(defun precompute-dependency-data (image)
  (setf (slot-value image 'system-layer) (precompute-layers))
  (setf (slot-value image 'system-dependees) (precompute-dependees))
  (setf (slot-value image 'source-file-map) (precompute-source-file-map))
  ;; Recompute every time a system is loaded. This may only be done after
  ;; a first computation, which is why the method is define here rather
  ;; than at the top level.
  (defmethod asdf:perform :after ((op asdf:load-op) component)
    (declare (ignore op) (ignore component))
    (precompute-dependency-data *image*)))

(defun precompute-layers ()
  (let ((layers (fset:empty-map 0))) ;; Default of 0 for missing systems
    (labels ((find-layer (system)
               (let ((layer (fset:@ layers system)))
                 (if (= layer 0)
                     (progn
                       (setf layer (compute-layer system))
                       (fset:includef layers system layer)))
                 layer))
             (compute-layer (system)
               (+ 1
                  (reduce #'max
                          (system-dependencies system)
                          :key #'(lambda (s) (find-layer s))
                          :initial-value 0))))
      (dolist (system (loaded-systems))
        (find-layer system))
      layers)))

(defun precompute-dependees ()
  (let ((dependees (fset:empty-map (fset:empty-seq))))
    (dolist (system (loaded-systems))
      (dolist (dep (system-dependencies system))
        (fset:push-last (fset:@ dependees dep) system)))
    (fset:image #'(lambda (key seq)
                    (values key (fset:sort seq #'string<
                                           :key #'component-name)))
                dependees)))

(defun precompute-source-file-map ()
  (-> (loaded-systems)
      asdf-source-file-map))

(defgeneric asdf-source-file-map (component/s))

(defmethod asdf-source-file-map ((components cons))
  (let ((map (fset:empty-map)))
    (dolist (c components)
      (fset:map-unionf map (asdf-source-file-map c)))
    map))

(defmethod asdf-source-file-map ((component asdf/component:component))
    (fset:empty-map))

(defmethod asdf-source-file-map ((component asdf/component:parent-component))
  (asdf-source-file-map (asdf:component-children component)))

(defmethod asdf-source-file-map ((component asdf/component:parent-component))
  (let ((map (fset:empty-map)))
    (dolist (c (asdf:component-children component))
      (fset:map-unionf map (asdf-source-file-map c)))
    map))

(defmethod asdf-source-file-map ((source-file asdf/component:source-file))
  (fset:with (fset:empty-map) (asdf:component-pathname source-file) source-file))

;;
;; Look up the system containing a given source file
;;

(defun find-component (source-file-pathname)
  (fset:@ (image-source-file-map *image*) source-file-pathname))

;;
;; A view for all packages
;;

(defview 👀packages (object image)
  (-> (list-all-packages)
      (sort #'string< :key #'package-name)
      thunk
      (list-view :title "Packages"
                 :priority 2)))

;;
;; A view for all loaded ASDF systems
;;

(defview 👀loaded-systems (object image)
  (-> (loaded-systems)
      (sort #'string< :key #'component-name)
      thunk
      (list-view :title "Loaded systems"
                 :priority 1)))

(defun loaded-systems ()
  (->> (asdf:already-loaded-systems)
       (mapcar #'find-system)))

;;
;; A view for *features*
;;

(defview 👀features (object image)
  (-<> *features*
       copy-list
       (sort #'string<)
       (mapcar #'str:downcase <>)
       thunk
       (list-view :title "Features"
                  :priority 3)))

;;
;; A view for version numbers
;;

(defview 👀version (object image)
  (html-view :title "Versions" :priority 4
    (html
      (:div
       (:h4 "Machine and supporting software")
       (:p (esc (machine-type)) (esc " ") (esc (or (machine-version) "(unknown version)")))
       (:p (esc (software-type)) (esc " ") (esc (or (software-version) "(unknown version)"))))
      (:div 
       (:h4 (esc "Lisp implementation"))
       (:p (esc (lisp-implementation-type)) (esc " ") (esc (lisp-implementation-version))))
      (:div
       (:h4 (esc "ASDF"))
       (:p (esc (asdf:asdf-version))))
            (:div
       (:h4 (esc "UIOP"))
       (:p (esc uiop:*uiop-version*))))))

;;
;; A view for loaded foreign libraries
;;

(defview 👀foreign-libraries (object image)
  (when-let (libs (cffi:list-foreign-libraries))
    (multi-column-list-view libs
                            :title "Foreign libraries" :priority 5
                            :columns '("Name" "File")
                            :display (list #'cffi:foreign-library-name
                                           #'(lambda (l)
                                               (slot-value l 'pathname))))))

;;
;; A view for all registered but not loaded ASDF systems
;;

(defview 👀registered-systems (object image)
  (-<> (set-difference (asdf:registered-systems) (asdf:already-loaded-systems))
       (sort #'string<)
       (mapcar #'find-system <>)
       (list-view :title "Registered unloaded systems"
                  :priority 6)))

;;
;; A view for environment variables
;;

(defview 👀environment-variables (object image)
  (when-let (evs (get-environment-variables))
    (multi-column-list-view evs
                            :title "Environment variables"
                            :priority 7
                            :columns '("Name" "Value")
                            :display (list #'first #'second))))

#-sbcl
(defun get-environment-variables ()
  nil)

#+sbcl
(defun get-environment-variables ()
  (sort 
   (loop for ev in (sb-ext:posix-environ)
         collect (str:split "=" ev))
   #'string<
   :key #'first))


;;
;; A view for active threads
;;

(defview 👀threads (object image)
  (when (and (member :thread-support *FEATURES*)
             (find-package "BT"))
    (-> (bt:all-threads)
        👀items
        (rename :title "Threads"
                :priority 8))))
