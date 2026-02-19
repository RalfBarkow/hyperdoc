;;;; Wiki pages
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Page story
;;

(defclass story-item ()
  ((item-type :reader item-type-of :type keyword :initarg :item-type)
   (id :reader id-of :type string :initarg :id)
   (text :reader text-of :type string :initarg :text)
   (data :reader data-of :type hash-table :initarg :data)))

(defun make-story (items)
  (map 'vector #'make-story-item items))

(defun make-story-item (item)
  (let ((type (->> item
                (gethash "type")
                (str:upcase)
                alexandria:make-keyword))
        (id (->> item
                (gethash "id")))
        (text (->> item
                (gethash "text"))))
    (remhash "type" item)
    (remhash "id" item)
    (remhash "text" item)
    (when (zerop (hash-table-count item))
      (setf item nil))
    (make-instance 'story-item
                   :item-type type
                   :id (or id "")
                   :text (or text "")
                   :data item)))

(defmethod views:text-representation ((item story-item))
  (let* ((text (text-of item))
         (length (length text))
         (length-limit 60)
         (excerpt (str:substring 0 length-limit text)))
    (str:concat (-> item item-type-of symbol-name str:downcase)
                ": "
                (if (<= length length-limit)
                    excerpt
                    (str:concat excerpt "...")))))

(views:defview 👀data (item story-item)
  (views:html-view :title "Data" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "type"))
                   (:td (views:object-ref (-> item item-type-of symbol-name str:downcase))))
              (:tr (:td (views:esc "id"))
                   (:td (views:object-ref (id-of item))))
              (:tr (:td (views:esc "text"))
                   (:td (views:object-ref (text-of item))))
              (when-let (data (data-of item))
                (loop for key being the hash-keys in data
                        using (hash-value value)
                      do (views:html
                           (:tr (:td (views:esc key))
                                (:td (views:object-ref value))))))))))
;;
;; Render story items as HTML
;;

(defparameter *url-regex* "(https:\\/\\/www\\.|http:\\/\\/www\\.|https:\\/\\/|http:\\/\\/)?[a-zA-Z0-9]{2,}(\\.[a-zA-Z0-9]{2,})(\\.[a-zA-Z0-9]{2,})?")

(defparameter *any-except-closing-bracket-regex* "(?:[^\\]]*)")

(defparameter *link-regex*
  (str:concat "\\["
              "(?:"
              ;; Wiki links
              "(?:\\[" *any-except-closing-bracket-regex* "\\])"
              "|"
              ;; external links
              "(?:" *url-regex* "\\s*" *any-except-closing-bracket-regex* ")"
              ")"
              "\\]"))

(defgeneric render-story-item (type item page)
  (:method ((type t) item page)
    (declare (ignore page))
    (views:html
      (:div (:i (:small (views:object-ref item :display (-> type symbol-name str:downcase)))))
      (:pre (views:esc (text-of item))))))

(defmethod render-story-item ((type (eql :paragraph)) item page)
  (let* ((text (text-of item))
         (link-positions (cl-ppcre:all-matches *link-regex* text)))
    (views:html
      (:p (loop for (start end) on (cons 0 link-positions)
                for chunk = (str:substring start end text)
                for is-link? = nil then (not is-link?)
                do (if is-link?
                       (render-link (str:substring 2 -2 chunk) page)
                       (views:esc chunk)))))))

(defun render-link (link-text page)
  (views:html
    (views:esc link-text)))

(defmethod render-story-item ((type (eql :reference)) item page)
  (let* ((data (data-of item))
         (site (gethash "site" data))
         (title (gethash "title" data)))
    (views:html
      (:p
       (:span :class "hyperbook-reference"
              :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                             (cl-who:escape-string title)
                             (cl-who:escape-string (hb:title-of (hb:hyperbook-of page))))
              (views:object-ref
               (handler-case
                   (hb:find-page (get-fedwiki site) title)
                 (error (c) c))))
       (views:esc " — ")
       (views:esc (text-of item))))))

(views:defview 👀story (page fedwiki-page)
  (load-page page)
  (views:html-view :title "Story" :priority 2
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc (hb:title-of page)))
            (loop for item across (story-of page)
                  do (views:html
                       (:div :title (-> item item-type-of symbol-name str:downcase)
                             (render-story-item (item-type-of item) item page))))))))

;;
;; Page journal
;;

(defclass journal-entry ()
  ((entry-type :reader entry-type-of :type keyword :initarg :entry-type)
   (date :reader date-of :type (or null local-time:timestamp) :initarg :date)
   (data :reader data-of :type hash-table :initarg :data)))

(defun make-journal (entries)
  (map 'vector #'make-journal-entry entries))

(defun make-journal-entry (entry)
  (let ((type (->> entry
                (gethash "type")
                (str:upcase)
                alexandria:make-keyword))
        (date (->> entry
                (gethash "date")
                wiki-date-to-timestamp)))
    (remhash "type" entry)
    (remhash "date" entry)
    (make-instance 'journal-entry
                   :entry-type type
                   :date date
                   :data entry)))

(defun site-of (entry)
  (->> entry
    data-of
    (gethash "site")))

(defun extract-context (journal)
  (let (fork-sites)
    (loop for entry across journal
          for site = (site-of entry)
          when site
            do (setf fork-sites
                     (cons site
                           (remove site fork-sites :test #'equal))))
    (mapcar #'get-fedwiki fork-sites)))

