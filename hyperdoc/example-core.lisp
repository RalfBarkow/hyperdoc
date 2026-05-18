;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Example functions
;;

(see (page "Writing source code pages"))

;; An example is a function of zero arguments.

(defmacro defexample (name &body body)
  "Define an example function NAME with BODY.

The syntax is the same as DEFUN, except that example functions take no
arguments.

An optional property list may be provided as the first body form to control
check registration metadata:

  (defexample my-example
    (:register t :system \"hyperdoc/examples/ops\")
    ...body...)

Supported keys mirror REGISTER-EXAMPLE-CHECK keyword arguments."
  (let* ((source-file (or *compile-file-truename* *load-truename*))
         (options (and body
                       (listp (first body))
                       (keywordp (first (first body)))
                       (first body)))
         (forms (if options (rest body) body))
         (register? (if options
                        (getf options :register t)
                        t))
         (system (and options (getf options :system)))
         (package (and options (getf options :package)))
         (page (and options (getf options :page)))
         (title (and options (getf options :title)))
         (tags (and options (getf options :tags))))
    `(progn
       (defun ,name () ,@forms)
       ,(when register?
          `(eval-when (:load-toplevel :execute)
             (register-example-check ',name
                                     :source-file ,source-file
                                     ,@(when system `(:system ,system))
                                     ,@(when package `(:package ,package))
                                     ,@(when page `(:page ,page))
                                     ,@(when title `(:title ,title))
                                     ,@(when tags `(:tags ,tags)))))
       ',name)))

;;
;; Convenience functions for inserting assertions into examples
;;

(defun assert-test (fn x y &key (key #'identity))
  (assert (funcall fn (funcall key x) y))
  x)

(defun assert-equalp (x y &key (key #'identity))
  (assert-test #'equalp x y :key key))

(defun assert-equal (x y &key (key #'identity))
  (assert-test #'equal x y :key key))

(defun assert-eql (x y &key (key #'identity))
  (assert-test #'eql x y :key key))

(defun assert-within-tolerance (x y tolerance &key (key #'identity))
  (declare (type number y tolerance))
  (assert-test #'(lambda (x y)
                   (declare (type number x y))
                   (<= (abs (- x y)) tolerance))
               x y :key key))

(defun assert-step-handoff (ids &key step-id required-predecessor forbidden-predecessor)
  "Assert immediate-predecessor invariants for STEP-ID inside ordered IDS.
Returns a small inspectable plist on success."
  (let* ((position (position step-id ids :test #'equal))
         (predecessor (and position
                           (> position 0)
                           (nth (1- position) ids))))
    (assert position)
    (assert (> position 0))
    (assert-equal required-predecessor predecessor)
    (when forbidden-predecessor
      (assert (not (equal forbidden-predecessor predecessor))))
    (list :step-id step-id
          :position position
          :predecessor predecessor)))

(defun assert-immediate-predecessor (ids step-id predecessor-id)
  "Convenience wrapper for required adjacency."
  (assert-step-handoff ids
                       :step-id step-id
                       :required-predecessor predecessor-id))

(defun assert-not-immediate-predecessor (ids step-id forbidden-predecessor-id)
  "Convenience wrapper for forbidden adjacency.
Requires STEP-ID to be present and not first."
  (let* ((position (position step-id ids :test #'equal))
         (predecessor (and position
                           (> position 0)
                           (nth (1- position) ids))))
    (assert position)
    (assert (> position 0))
    (assert (not (equal forbidden-predecessor-id predecessor)))
    (list :step-id step-id
          :position position
          :predecessor predecessor)))

(defun assert-immediate-successor (ids step-id successor-id)
  "Assert that SUCCESSOR-ID immediately follows STEP-ID in ordered IDS."
  (let* ((position (position step-id ids :test #'equal))
         (successor-pos (and position
                             (< position (1- (length ids)))
                             (1+ position)))
         (successor (and successor-pos
                         (nth successor-pos ids))))
    (assert position)
    (assert successor-pos)
    (assert-equal successor-id successor)
    (list :step-id step-id
          :position position
          :successor successor)))

(defun assert-not-immediate-successor (ids step-id forbidden-successor-id)
  "Assert that FORBIDDEN-SUCCESSOR-ID does not immediately follow STEP-ID."
  (let* ((position (position step-id ids :test #'equal))
         (successor-pos (and position
                             (< position (1- (length ids)))
                             (1+ position)))
         (successor (and successor-pos
                         (nth successor-pos ids))))
    (assert position)
    (assert successor-pos)
    (assert (not (equal forbidden-successor-id successor)))
    (list :step-id step-id
          :position position
          :successor successor)))

(defun assert-step-chain (ids &rest chain)
  "Assert that CHAIN forms an immediate-successor chain in ordered IDS.
Every step id in CHAIN must exist, and each element must be immediately
followed by the next. Returns an inspectable plist on success."
  (assert (>= (length chain) 2))
  (dolist (step-id chain)
    (assert (position step-id ids :test #'equal)))
  (let ((pairs (loop for (a b) on chain while b collect (list a b))))
    (dolist (pair pairs)
      (destructuring-bind (a b) pair
        (assert-immediate-successor ids a b)))
    (list :chain chain
          :pairs pairs)))

;;
;; An example example function
;;

(defexample the-answer
    (:system "hyperdoc" :page "Examples")
    "The answer to the question of life, the universe, and everything."
  (-> 42
      (assert-equal 42)))
