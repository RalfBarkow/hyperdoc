;;;; What makes two requests the same request.

(defpackage #:dreyeck/gesture/operation-request/tests
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/gesture/operation-request)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:views #:html-inspector-views))
  (:export #:run-operation-request-tests))

(in-package #:dreyeck/gesture/operation-request/tests)

(defparameter *page-id* "Reading the two continuations of one interaction."
  "A code page of the gesture reading book: gesture-ordering-reading.lisp.")

(defun %page ()
  (let ((book (hyperbook:find-hyperbook "dreyeck/gesture/reading"
                                        :signal-error? t)))
    (hyperdoc::ensure-pages-loaded book)
    (hyperbook:find-page book *page-id* :signal-error? t)))

(defun %key (name)
  (list :definition (find-symbol name "DREYECK/GESTURE/ORDERING")))

(defun %binding (id)
  (find id (w:make-gesture-binding-catalog)
        :key #'w:gesture-binding-id :test #'string=))

(defun %action-thunks (page)
  "The thunks behind the Operations view's buttons, from one rendering of it."
  (let ((view (find "Operations" (views:all-views page)
                    :key #'views:view-title :test #'string=)))
    (assert view)
    (views:view-html view)
    (mapcar #'cdr (remove-if-not (lambda (reference)
                                   (typep (cdr reference) 'views:thunk))
                                 (views:view-references view)))))

(defun %thunk-for (page key)
  "The button for KEY. Asking every button is safe: none of them executes."
  (find key (%action-thunks page)
        :key (lambda (thunk) (r:operation-request-form-key (views:eval-thunk thunk)))
        :test #'equal))

(defun test-the-view-supplies-the-target ()
  (let* ((page (%page))
         (key (%key "RACE-READING"))
         (thunk (%thunk-for page key))
         (request (views:eval-thunk thunk)))
    (assert (typep request 'r:operation-request))
    (assert (eq page (r:operation-request-page request)))
    (assert (equal key (r:operation-request-form-key request)))
    (assert (eq (w:insert-executable-defexample-operation)
                (r:operation-request-operation request)))
    (assert (string= "dreyeck/gesture/reading" (r:operation-request-system request)))
    (assert (string= "gesture-ordering-reading"
                     (pathname-name (r:operation-request-path request))))
    ;; The same button twice, and the button of a fresh rendering: the
    ;; parse behind the view is new each time, the request is not.
    (assert (eq request (views:eval-thunk thunk)))
    (assert (eq request (views:eval-thunk (%thunk-for page key))))
    request))

(defun test-affordances-reach-one-request (request)
  "The Inspector action, the direct call, and the gesture Bindings."
  (let ((page (r:operation-request-page request))
        (key (r:operation-request-form-key request)))
    (assert (eq request (r:ensure-operation-request
                         (w:insert-executable-defexample-operation) page key)))
    (dolist (id '("binding/radial-insert-defexample"
                  "binding/mark-insert-defexample"
                  "binding/inspector-insert-defexample"))
      (assert (eq request (r:request-through-binding (%binding id) page key))))
    ;; A disabled Binding is refused, not silently treated as its Operation.
    (assert (handler-case
                (progn (r:request-through-binding
                        (%binding "binding/radial-disabled-sector") page key)
                       nil)
              (error () t)))))

(defun test-what-distinguishes-requests (request)
  "Operation and target are the identity; each one alone changes it."
  (let* ((page (r:operation-request-page request))
         (key (r:operation-request-form-key request))
         (operation (r:operation-request-operation request))
         (other-operation (w::%make-operation-identity
                           "operation/test-other" "A different operation"))
         (other-target (r:ensure-operation-request
                        operation page (%key "TWO-AUTHORITIES-SESSION")))
         (other-request (r:ensure-operation-request other-operation page key)))
    (assert (not (eq request other-target)))
    (assert (not (eq request other-request)))
    (assert (eq page (r:operation-request-page other-target)))
    (assert (eq other-operation (r:operation-request-operation other-request)))
    ;; A definition the page does not have is refused.
    (assert (handler-case
                (progn (r:ensure-operation-request
                        operation page (list :definition 'no-such-definition))
                       nil)
              (error () t)))))

(defun test-button-and-strip-are-separate-cells ()
  "The button and the gesture strip are separate cells of a two-column row.
A click on one and a press on the other land on different elements, and
the row fits a pane the width the Inspector gives it."
  (let* ((page (%page))
         (view
          (find "Operations" (views:all-views page) :key #'views:view-title
                :test #'string=))
         (dom (plump-parser:parse (views:view-html view)))
         (definitions (length (r:page-definitions page))))
    (flet ((count-in (element tag prefix)
             (count-if
              (lambda (child)
                (eql 0
                     (search prefix (or (plump-dom:attribute child "id") ""))))
              (plump-dom:get-elements-by-tag-name element tag))))
      (let ((cells (plump-dom:get-elements-by-tag-name dom "td")))
        (assert
         (= definitions
            (reduce #'+ cells :key
                    (lambda (cell) (count-in cell "button" "eval-")))))
        (assert
         (= definitions
            (reduce #'+ cells :key
                    (lambda (cell) (count-in cell "div" "transclusion-")))))
        (assert
         (notany
          (lambda (cell)
            (and (plusp (count-in cell "button" "eval-"))
                 (plusp (count-in cell "div" "transclusion-"))))
          cells)))
      (assert
       (every
        (lambda (row)
          (<= (length (plump-dom:get-elements-by-tag-name row "td")) 2))
        (plump-dom:get-elements-by-tag-name dom "tr")))))
  t)

(defun run-operation-request-tests ()
  (let* ((path (asdf:system-relative-pathname
                "dreyeck" "dreyeck/src/gesture-ordering-reading.lisp"))
         (before (uiop:read-file-string path :external-format :utf-8))
         (request (test-the-view-supplies-the-target)))
    (test-affordances-reach-one-request request)
    (test-what-distinguishes-requests request)
    (test-button-and-strip-are-separate-cells)
    (assert (string= before (uiop:read-file-string path :external-format :utf-8)))
    (assert (null (find-package "DREYECK/WORKFLOW/AUTHORING")))
    (format t "~&OPERATION-REQUEST-PASS: the Operations view on a code page ~
supplies the definition, the Binding only the Operation; the same button, a ~
fresh rendering, a direct call and three Bindings reach one request; a ~
different operation or definition is a different request; the button and ~
the gesture strip are separate cells of a two-column row; the source file is ~
unchanged and no authoring runtime was loaded.~%")
    t))
