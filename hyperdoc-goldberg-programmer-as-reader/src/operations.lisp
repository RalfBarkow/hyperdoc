;;;; Query and operation functions for the Goldberg Programmer-as-Reader slice.

(in-package #:hyperdoc-goldberg-programmer-as-reader)

(defun make-goldberg-topic-from-data (data)
  (destructuring-bind (id title summary page layer references) data
    (make-instance 'goldberg-topic
                   :id id
                   :title title
                   :summary summary
                   :page page
                   :layer layer
                   :references references)))

(defun make-goldberg-reader-question-from-data (data)
  (destructuring-bind (id number layer question-text prompt summary operation-id) data
    (make-instance 'goldberg-reader-question
                   :id id
                   :number number
                   :layer layer
                   :question-text question-text
                   :prompt prompt
                   :summary summary
                   :operation-id operation-id)))

(defun make-goldberg-reader-operation-from-data (data)
  (destructuring-bind (id title question-id summary preconditions steps result clickable-expression) data
    (make-instance 'goldberg-reader-operation
                   :id id
                   :title title
                   :question-id question-id
                   :summary summary
                   :preconditions preconditions
                   :steps steps
                   :result result
                   :clickable-expression clickable-expression)))

(defparameter *goldberg-topics*
  (mapcar #'make-goldberg-topic-from-data *goldberg-topic-data*))

(defparameter *goldberg-reader-questions*
  (mapcar #'make-goldberg-reader-question-from-data *goldberg-reader-question-data*))

(defparameter *goldberg-reader-operations*
  (mapcar #'make-goldberg-reader-operation-from-data *goldberg-operation-data*))

(defun all-goldberg-topics ()
  "Return the authored Goldberg topic objects."
  (copy-list *goldberg-topics*))

(defun all-goldberg-reader-questions ()
  "Return the twelve Goldberg reader-comprehension questions."
  (copy-list *goldberg-reader-questions*))

(defun all-goldberg-reader-operations ()
  "Return the operations that make the reader-comprehension questions clickable."
  (copy-list *goldberg-reader-operations*))

(defun goldberg-topic-by-id (id)
  (find id *goldberg-topics* :key #'id-of :test #'string=))

(defun goldberg-topic-by-title (title)
  (find title *goldberg-topics* :key #'title-of :test #'string=))

(defun goldberg-reader-question-by-id (id)
  (find id *goldberg-reader-questions* :key #'id-of :test #'eq))

(defun goldberg-reader-operation-by-id (id)
  (find id *goldberg-reader-operations* :key #'id-of :test #'eq))

(defun questions-for-layer (layer)
  (remove-if-not (lambda (question) (eq (layer-of question) layer))
                 *goldberg-reader-questions*))

(defun operations-for-layer (layer)
  (loop for question in (questions-for-layer layer)
        for operation = (goldberg-reader-operation-by-id (operation-id-of question))
        when operation collect operation))

(defun goldberg-layer-overview (layer)
  "Return a plist overview of a Goldberg layer and its questions."
  (let ((spec (assoc layer *goldberg-layer-specs*)))
    (unless spec
      (error "Unknown Goldberg layer ~S. Expected one of ~S."
             layer (mapcar #'first *goldberg-layer-specs*)))
    (destructuring-bind (key &key title summary) spec
      (list :layer key
            :title title
            :summary summary
            :questions (mapcar #'plist-for-reader-question
                               (questions-for-layer key))
            :operations (mapcar #'plist-for-reader-operation
                                (operations-for-layer key))))))

(defun goldberg-reader-question-demo (question-id)
  "Return a clickable example object for QUESTION-ID.

QUESTION-ID is one of:
  :invoke-response, :what-can-i-do-now, :what-is-needed,
  :what-is-that, :where-is-it, :does-any-part-do-this,
  :what-knows-about-that, :how-did-i-get-here, :how-can-i-get-back,
  :current-state, :why-happened, :why-not-happened."
  (let ((question (goldberg-reader-question-by-id question-id)))
    (unless question
      (error "Unknown Goldberg reader question ~S." question-id))
    (let ((operation (goldberg-reader-operation-by-id (operation-id-of question))))
      (list :question (plist-for-reader-question question)
            :operation (and operation (plist-for-reader-operation operation))
            :reader-instruction (prompt-of question)
            :hyperdoc-use
            "Use this object as an inspectable target from an expr link. The result is intentionally data-first so HyperDoc can render it as an object, table, or operation surface."))))

(defun goldberg-reader-question-operation (question-id)
  "Return the operation object for QUESTION-ID."
  (let ((question (goldberg-reader-question-by-id question-id)))
    (unless question
      (error "Unknown Goldberg reader question ~S." question-id))
    (or (goldberg-reader-operation-by-id (operation-id-of question))
        (error "No operation registered for question ~S." question-id))))

(defun goldberg-operation-report (operation-id)
  "Return a plist report for OPERATION-ID."
  (let ((operation (goldberg-reader-operation-by-id operation-id)))
    (unless operation
      (error "Unknown Goldberg operation ~S." operation-id))
    (plist-for-reader-operation operation)))

(defun goldberg-reader-question-matrix ()
  "Return the four-layer/twelve-question matrix as plain data."
  (mapcar (lambda (spec)
            (goldberg-layer-overview (first spec)))
          *goldberg-layer-specs*))

(defun goldberg-zettel-summary ()
  "Return a compact live summary of this ASDF-loaded HyperDoc Zettel slice."
  (list :source (goldberg-source-citation)
        :topics (length *goldberg-topics*)
        :layers (length *goldberg-layer-specs*)
        :questions (length *goldberg-reader-questions*)
        :operations (length *goldberg-reader-operations*)
        :pages '("Goldberg Programmer as Reader.html"
                 "Goldberg Programmer as Reader topic arrangement.html"
                 "Goldberg reading comprehension questions.html"
                 "Goldberg reader operations.html"
                 "Goldberg Smalltalk to HyperDoc crosswalk.html")
        :entry-operation "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-is-that)"))
