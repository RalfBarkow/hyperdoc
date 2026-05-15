;;;; Topic constructors and optional HyperDoc registration.

(in-package #:hyperdoc-goldberg-programmer-as-reader)

(defun goldberg-programmer-as-reader-topic ()
  (goldberg-topic-by-id "goldberg-programmer-as-reader"))

(defun goldberg-programmer-as-reader-arrangement-topic ()
  (goldberg-topic-by-id "goldberg-programmer-as-reader-arrangement"))

(defun goldberg-reading-comprehension-questions-topic ()
  (goldberg-topic-by-id "goldberg-reading-comprehension-question"))

(defun goldberg-reader-operations-topic ()
  (goldberg-topic-by-id "reader-operation"))

(defun goldberg-smalltalk-hyperdoc-crosswalk-topic ()
  (goldberg-topic-by-id "program-as-dynamic-database"))

(defun find-hyperdoc-make-topic-symbol ()
  "Return HYPERDOC::MAKE-TOPIC when HyperDoc is present, otherwise NIL."
  (let ((package (find-package "HYPERDOC")))
    (and package (find-symbol "MAKE-TOPIC" package))))

(defun call-hyperdoc-make-topic (topic make-topic-symbol)
  (funcall (symbol-function make-topic-symbol)
           :id (id-of topic)
           :title (title-of topic)
           :summary (summary-of topic)
           :references (references-of topic)))

(defun register-goldberg-topics-into-hyperdoc (&key (signal-error nil))
  "Register this slice's topics into a loaded HyperDoc image when available.

The ASDF system remains standalone. If the HYPERDOC package and its internal
MAKE-TOPIC function are present, each Goldberg topic is materialized into the
HyperDoc topic registry. Otherwise this function returns an explicit unavailable
status, or signals when SIGNAL-ERROR is true."
  (let ((make-topic-symbol (find-hyperdoc-make-topic-symbol)))
    (cond
      ((and make-topic-symbol (fboundp make-topic-symbol))
       (list :status :registered
             :count (length (mapcar (lambda (topic)
                                      (call-hyperdoc-make-topic topic make-topic-symbol))
                                    *goldberg-topics*))))
      (signal-error
       (error "Cannot register Goldberg topics because HYPERDOC::MAKE-TOPIC is not available."))
      (t
       (list :status :unavailable
             :reason "HYPERDOC::MAKE-TOPIC is not available in this image."
             :topics (mapcar #'plist-for-topic *goldberg-topics*))))))
