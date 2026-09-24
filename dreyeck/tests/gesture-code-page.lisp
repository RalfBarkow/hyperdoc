;;;; Three affordances on one code-page definition, and one request.
;;;;
;;;; The Inspector button, the radial menu and the mark must all reach the
;;;; request the button reaches. The gestures are fed as CLOG delivers
;;;; them: pointer payloads in CLOG's format, parsed by the same function
;;;; the page's handlers call, carrying the subject the surface was given.
;;;; No browser timing is involved; the order is the order written here.

(defpackage #:dreyeck/gesture/code-page/tests
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/gesture/operation-request)
                    (#:g #:dreyeck/gesture/clog)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:views #:html-inspector-views))
  (:export #:run-code-page-gesture-tests))

(in-package #:dreyeck/gesture/code-page/tests)

(defparameter *page-id* "Reading the two continuations of one interaction.")

(defun %page ()
  (let ((book (hyperbook:find-hyperbook "dreyeck/gesture/reading"
                                        :signal-error? t)))
    (hyperdoc::ensure-pages-loaded book)
    (hyperbook:find-page book *page-id* :signal-error? t)))

(defun %key ()
  (list :definition (find-symbol "RACE-READING" "DREYECK/GESTURE/ORDERING")))

(defun %button-request (page key)
  "What the Operations view's button for KEY returns, as a click evaluates it."
  (let ((view (find "Operations" (views:all-views page)
                    :key #'views:view-title :test #'string=)))
    (views:view-html view)
    (find key (mapcar (lambda (reference) (views:eval-thunk (cdr reference)))
                      (remove-if-not (lambda (reference)
                                       (typep (cdr reference) 'views:thunk))
                                     (views:view-references view)))
          :key #'r:operation-request-form-key :test #'equal)))

(defun %payload (x which buttons sequence)
  "One pointer event as CLOG's pointer script and the forwarding script send it."
  (format nil "~D:10:0:0:~D:false:false:false:false:~D:10:~D:10:~D:~D"
          x which x x buttons sequence))

(defparameter *mark*
  '((:pointer-down 100 3 2) (:pointer-move 180 0 2) (:pointer-up 180 3 0)))

(defparameter *radial*
  '((:pointer-down 100 3 2) (:reveal-deadline 100 0 2)
    (:pointer-move 180 0 2) (:pointer-up 180 3 0)))

(defun %gesture (steps subject)
  "Every request the completion hook made while STEPS were delivered, and
the window. The hook is the one a surface uses: NEWLY-COMPLETED-P, then
REQUEST-FROM-GESTURE."
  (let* ((requests nil)
         (window (g:make-gesture-window
                  :projection (lambda (window snapshot)
                                (when (g:newly-completed-p window snapshot)
                                  (push (r:request-from-gesture window) requests))))))
    (loop for (kind x which buttons) in steps
          for sequence from 1
          do (g:receive-envelope
              window (g::%envelope-from kind (%payload x which buttons sequence)
                                        subject)))
    (values (reverse requests) window)))

(defun %selected-binding-id (window)
  (let ((binding (g:gesture-window-selection window)))
    (and binding (w:gesture-binding-id binding))))

(defun %menu-shown-before-selection-p (window)
  (let ((log (reverse (g:gesture-window-log window))))
    (let ((shown (position-if (lambda (s) (getf s :menu-visible)) log))
          (chosen (position-if (lambda (s) (getf s :binding)) log)))
      (and shown chosen (< shown chosen)))))

(defun test-three-affordances-one-request ()
  (let* ((page (%page))
         (key (%key))
         (subject (list :type :lisp-source-definition :page page :form-key key))
         (button (%button-request page key)))
    (assert button)
    (multiple-value-bind (marked window) (%gesture *mark* subject)
      (assert (= 1 (length marked)))
      (assert (eq button (first marked)))
      (assert (equal "binding/mark-insert-defexample" (%selected-binding-id window)))
      (assert (not (%menu-shown-before-selection-p window)))
      ;; The subject comes back as the object the surface gave, not a copy.
      (assert (eq subject (nth-value 1 (g:gesture-window-selection window)))))
    (multiple-value-bind (chosen window) (%gesture *radial* subject)
      (assert (= 1 (length chosen)))
      (assert (eq button (first chosen)))
      (assert (equal "binding/radial-insert-defexample" (%selected-binding-id window)))
      (assert (%menu-shown-before-selection-p window)))
    (assert (eq button (r:request-through-binding (r:inspector-binding) page key)))
    (assert (eq (w:insert-executable-defexample-operation)
                (r:operation-request-operation button)))
    (assert (eq page (r:operation-request-page button)))
    (assert (equal key (r:operation-request-form-key button)))
    button))

(defun test-the-route-subject-names-nothing ()
  "The /gesture route's own subject has no page and no definition. A
gesture made with it completes, and is refused a request."
  (multiple-value-bind (requests window)
      (handler-case (%gesture *mark* (list :type :lisp-source-definition
                                            :name 'gesture-window))
        (error () (values :refused nil)))
    (declare (ignore window))
    (assert (eq :refused requests))))

(defun run-code-page-gesture-tests ()
  (let* ((path (asdf:system-relative-pathname
                "dreyeck" "dreyeck/src/gesture-ordering-reading.lisp"))
         (before (uiop:read-file-string path :external-format :utf-8)))
    (test-three-affordances-one-request)
    (test-the-route-subject-names-nothing)
    (assert (string= before (uiop:read-file-string path :external-format :utf-8)))
    (assert (null (find-package "DREYECK/WORKFLOW/AUTHORING")))
    (format t "~&CODE-PAGE-GESTURE-PASS: on RACE-READING the Inspector button, ~
a mark and a radial selection reach one request, EQ, with the shared ~
Operation, the code page and the definition's key; the menu showed before ~
the radial selection and not before the mark; the subject returns as ~
given; the route's placeholder subject is refused; the source file is ~
unchanged and no authoring runtime was loaded.~%")
    t))
