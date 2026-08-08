(defpackage #:dreyeck/fedwiki-navigation/prototype
  (:use #:cl))

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
