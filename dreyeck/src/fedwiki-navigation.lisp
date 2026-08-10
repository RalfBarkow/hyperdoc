(defpackage #:dreyeck/fedwiki-navigation/prototype
  (:use #:cl)
  (:export
   #:navigation-session
   #:navigation-session-origin
   #:navigation-session-lineup
   #:make-navigation-fixture
   #:session-location
   #:run-navigation-transcript
   #:navigation-transcript-smoke-test
   #:navigation-trace
   #:navigation-trace-initial-session-of
   #:navigation-trace-commands-of
   #:navigation-trace-steps-of
   #:navigation-trace-final-session-of
   #:navigation-trace-result-of
   #:navigation-step
   #:navigation-step-number-of
   #:navigation-step-command-text-of
   #:navigation-step-operation-of
   #:navigation-step-arguments-of
   #:navigation-step-before-of
   #:navigation-step-producer-symbol-of
   #:navigation-step-outcome-of
   #:navigation-step-after-of
   #:navigation-step-link-observation-of
   #:navigation-step-implementation-of
   #:navigation-step-dispatcher-implementation-of
   #:navigation-step-explanation
   #:navigation-position
   #:navigation-position-current-page-slug-of
   #:navigation-position-current-item-id-of
   #:navigation-position-location-of
   #:navigation-link-observation
   #:navigation-link-observation-link-slug-of
   #:navigation-link-observation-source-location-of
   #:navigation-link-observation-target-location-of
   #:navigation-test-outcome
   #:navigation-test-outcome-passed-p
   #:navigation-source-reference
   #:navigation-source-reference-producer-symbol-of
   #:navigation-source-reference-system-name-of
   #:navigation-source-reference-component-name-of
   #:navigation-source-reference-system
   #:navigation-source-reference-component
   #:navigation-source-reference-relative-pathname
   #:navigation-source-reference-source-file
   #:navigation-source-file
   #:navigation-source-file-component-of
   #:navigation-source-file-pathname-of
   #:navigation-source-file-relative-pathname-of
   #:navigation-source-file-contents
   #:make-fedwiki-java-navigation-trace
   #:fedwiki-java-navigation-trace-example))

(in-package #:dreyeck/fedwiki-navigation/prototype)

(defstruct navigation-item
  id
  text
  link-slug)

(defstruct navigation-page
  site
  slug
  title
  story)

(defstruct navigation-panel
  page
  (item-number 0))

(defstruct navigation-session
  origin
  pages
  lineup)


(defstruct (navigation-case-outcome
             (:constructor make-navigation-case-outcome (text)))
  (text "" :type string :read-only t))


(defstruct (navigation-test-outcome
             (:constructor make-navigation-test-outcome
                 (fragment item-text passed-p)))
  (fragment "" :type string :read-only t)
  (item-text "" :type string :read-only t)
  (passed-p nil :type boolean :read-only t))


(define-condition navigation-test-failed (error)
  ((fragment :reader navigation-test-failed-fragment-of
             :initarg :fragment)
   (item-text :reader navigation-test-failed-item-text-of
              :initarg :item-text))
  (:report
   (lambda (condition stream)
     (format stream "The current story item does not contain ~S: ~S"
             (navigation-test-failed-fragment-of condition)
             (navigation-test-failed-item-text-of condition)))))


(defun session-current-panel (session)
  (or (car (last (navigation-session-lineup session)))
      (error "The navigation session has no current panel.")))


(defun session-current-item (session)
  (let* ((panel (session-current-panel session))
         (page (navigation-panel-page panel)))
    (nth (navigation-panel-item-number panel)
         (navigation-page-story page))))


(defun move-next (session)
  (let* ((panel (session-current-panel session))
         (story (navigation-page-story
                 (navigation-panel-page panel)))
         (item-count (length story)))
    (when (zerop item-count)
      (error "Cannot move in an empty story."))
    (setf (navigation-panel-item-number panel)
          (mod (1+ (navigation-panel-item-number panel))
               item-count))
    (session-current-item session)))


(defun text-contains-p (fragment text)
  (not (null (search fragment text :test #'char-equal))))


(defun record-navigation-case (text)
  "Return an observable annotation without changing the navigation session."
  (make-navigation-case-outcome (copy-seq text)))


(defun assert-current-item (session fragment)
  "Assert that the current story item contains FRAGMENT."
  (let* ((item (session-current-item session))
         (text (navigation-item-text item)))
    (unless (text-contains-p fragment text)
      (error 'navigation-test-failed
             :fragment fragment
             :item-text text))
    (make-navigation-test-outcome
     (copy-seq fragment)
     (copy-seq text)
     t)))


(defun find-next (session fragment)
  (let* ((panel (session-current-panel session))
         (initial-item-number
           (navigation-panel-item-number panel)))
    (loop
      (move-next session)
      (when (= (navigation-panel-item-number panel)
               initial-item-number)
        (error "No later story item contains ~S." fragment))
      (let ((item (session-current-item session)))
        (when (text-contains-p fragment
                              (navigation-item-text item))
          (return item))))))


(defun page-for-link (session slug)
  (or (find slug
            (navigation-session-pages session)
            :key #'navigation-page-slug
            :test #'string=)
      (error "No fixture page exists for slug ~S." slug)))


(defun follow-link (session)
  (let* ((item (session-current-item session))
         (slug (navigation-item-link-slug item)))
    (unless slug
      (error "The current item has no link."))
    (let ((page (page-for-link session slug)))
      (setf (navigation-session-lineup session)
            (append (navigation-session-lineup session)
                    (list (make-navigation-panel :page page))))
      (session-current-item session))))


(defun move-back (session title-fragment)
  (loop
    (let* ((lineup (navigation-session-lineup session))
           (panel (car (last lineup))))
      (unless panel
        (error "No lineup page contains ~S in its title."
               title-fragment))
      (when (text-contains-p
             title-fragment
             (navigation-page-title
              (navigation-panel-page panel)))
        (return (session-current-item session)))
      (setf (navigation-session-lineup session)
            (butlast lineup)))))


(defun session-location (session)
  (with-output-to-string (stream)
    (format stream "http://~A"
            (navigation-session-origin session))
    (dolist (panel (navigation-session-lineup session))
      (let ((page (navigation-panel-page panel)))
        (if (string= (navigation-page-site page)
                     (navigation-session-origin session))
            (format stream "/view/~A"
                    (navigation-page-slug page))
            (format stream "/~A/~A"
                    (navigation-page-site page)
                    (navigation-page-slug page)))))))
