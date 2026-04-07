;;;; Process story items
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Find links in Wiki text
;;

(defparameter *url-regex* "(https:\\/\\/www\\.|http:\\/\\/www\\.|https:\\/\\/|http:\\/\\/)?[a-zA-Z0-9]{2,}(\\.[a-zA-Z0-9]{2,})(\\.[a-zA-Z0-9]{2,})?")

(defparameter *any-except-closing-bracket-regex* "(?:[^\\]]*)")

(defparameter *git-commit-hash-length* 40)

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

(defun hex-char-p (char)
  (and char (not (null (digit-char-p char 16)))))

(defun commit-hash-start-p (text start)
  (let* ((length (length text))
         (end (+ start *git-commit-hash-length*)))
    (and (<= end length)
         (or (zerop start)
             (not (hex-char-p (char text (1- start)))))
         (loop for i from start below end
               always (hex-char-p (char text i)))
         (or (= end length)
             (not (hex-char-p (char text end)))))))

(defun next-commit-hash-range (text &optional (start 0))
  (loop with limit = (- (length text) *git-commit-hash-length*)
        for pos from start to limit
        when (commit-hash-start-p text pos)
          do (return (values pos (+ pos *git-commit-hash-length*)))
        finally (return (values nil nil))))

(defun software-heritage-revision-swhid (hash)
  (str:concat "swh:1:rev:" (str:downcase hash)))

(defun software-heritage-revision-url (hash)
  (str:concat "https://archive.softwareheritage.org/"
              (software-heritage-revision-swhid hash)
              "/"))

(defun process-commit-hashes (text page text-fn commit-fn)
  (loop with cursor = 0
        with results = '()
        do (multiple-value-bind (start end)
               (next-commit-hash-range text cursor)
             (if start
                 (progn
                   (when (< cursor start)
                     (push (funcall text-fn (str:substring cursor start text) page)
                           results))
                   (push (funcall commit-fn (str:substring start end text) page)
                         results)
                   (setf cursor end))
                 (progn
                   (when (< cursor (length text))
                     (push (funcall text-fn (str:substring cursor (length text) text) page)
                           results))
                   (return (nreverse results)))))))

(defun process-text-and-links (text page text-fn link-fn)
  (let ((link-positions (cl-ppcre:all-matches *link-regex* text)))
    (loop for (start end) on (cons 0 link-positions)
          for chunk = (str:substring start end text)
          for is-link? = nil then (not is-link?)
          if is-link?
            collect (funcall link-fn chunk page)
          else
            collect (funcall text-fn chunk page))))

;;
;; Extract links from items
;;

(defgeneric extract-links-from-story-item (type item page)
  ;; Default: no links
  (:method ((type t) item page)
    (declare (ignore type item page))
    nil))

(defun extract-links (page)
  (let (wiki-links web-links page-links hyperbook-links)
    (loop for item across (story-of page)
          do (loop for link in (extract-links-from-story-item (item-type-of item) item page)
                   do (typecase link
                        (wiki-link (pushnew link wiki-links
                                            :test #'equal
                                            :key #'hb:key-of))
                        (hb:hyperbook-link (pushnew link hyperbook-links
                                                    :test #'equal
                                                    :key #'hb:key-of))
                        (hb:page-link (pushnew link page-links
                                              :test #'equal
                                              :key #'hb:key-of))
                        (hb:web-link (pushnew link web-links
                                              :test #'equal
                                              :key #'hb:key-of)))))
    (make-instance 'fedwiki-links
                   :wiki-links (sort wiki-links #'string< :key #'target-slug-of)
                   :page-links page-links
                   :hyperbook-links (sort hyperbook-links #'string<
                                          :key #'hb:target-hyperbook-of)
                   :web-links (sort web-links #'string< :key #'hb:url-of))))

(defmethod extract-links-from-wiki-text (text page)
  (loop for item in (process-text-and-links text page
                                            #'(lambda (chunk page)
                                                (process-commit-hashes
                                                 chunk page
                                                 #'(lambda (plain page)
                                                     (declare (ignore plain page))
                                                     nil)
                                                 #'(lambda (hash page)
                                                     (hb:make-web-link
                                                      page
                                                      (software-heritage-revision-url hash)))))
                                            #'collect-link)
        if (listp item)
          append item
        else if item
          collect item))

(defun collect-link (link-text page)
  (if (str:starts-with? "[[" link-text)
      (let ((link (str:substring 2 -2 link-text)))
        (make-wiki-link page :target-title link :target-slug (slug link)))
      (let* ((parts (str:split " " (str:substring 1 -1 link-text)))
             (url (first parts))
             (hb-link (hb:replace-by-hyperbook-link url)))
        (if hb-link
            (if (second hb-link)
                (hb:make-page-link page (first hb-link) (second hb-link))
                (hb:make-hyperbook-link page (first hb-link)))
            (hb:make-web-link page url)))))

;; Paragraphs

(defmethod extract-links-from-story-item ((type (eql :paragraph)) item page)
  (extract-links-from-wiki-text (text-of item) page))

;; Markdown

(defmethod extract-links-from-story-item ((type (eql :markdown)) item page)
  (extract-links-from-wiki-text (text-of item) page))

;; References

(defmethod extract-links-from-story-item ((type (eql :reference)) item page)
  (extract-links-from-wiki-text (text-of item) page))

;; Images

(defmethod extract-links-from-story-item ((type (eql :image)) item page)
  (extract-links-from-wiki-text (text-of item) page))

;;
;; Render story items to HTML
;;

(defgeneric render-story-item (type item page)
  (:method ((type t) item page)
    (declare (ignore page))
    (views:html
      (:div (:i (:small (views:object-ref item
                                          :display (-> type symbol-name str:downcase)))))
      (:pre :style "background-color: #eee;"
       (views:esc (text-of item))))))


(defmethod render-wiki-text (text page)
  (process-text-and-links text page
                          #'(lambda (chunk page)
                              (process-commit-hashes
                               chunk page
                               #'(lambda (plain page)
                                   (declare (ignore page))
                                   (views:html (views:esc plain)))
                               #'(lambda (hash page)
                                   (declare (ignore page))
                                   (render-external-link
                                    (software-heritage-revision-url hash)
                                    hash
                                    nil))))
                          #'render-link))

(defun render-link (link-text page)
  (if (str:starts-with? "[[" link-text)
      (render-wiki-link (str:substring 2 -2 link-text) page)
      (let* ((parts (str:split " " (str:substring 1 -1 link-text)))
             (url (first parts))
             (text (str:join " " (rest parts))))
        (render-external-link url text page))))

(defun render-wiki-link (link-text page)
  (handler-case
      (let ((target (find-target-by-title link-text page)))
        (views:html
          (:span :class "hyperbook-reference"
                 :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                                (cl-who:escape-string (hb:title-of target))
                                (cl-who:escape-string
                                 (hb:title-of (hb:hyperbook-of target))))
                 (views:object-ref target :display link-text))))
    (hb:lookup-failure (c)
      (views:html
        (:span :class "hyperbook-reference hyperbook-error"
               (views:object-ref c :display link-text))))))

(defun render-external-link (url link-text page)
  (declare (ignore page))
  (if-let (hb-link (hb:replace-by-hyperbook-link url))
    (hb:render-hyperbook-or-page-link (first hb-link) (second hb-link) link-text)
    (views:html
      (:a :href url :target "_blank"
          (views:esc link-text)))))

;; Paragraphs

(defmethod render-story-item ((type (eql :paragraph)) item page)
  (views:html
    (:p (render-wiki-text (text-of item) page))))

;; Markdown

(defmethod render-story-item ((type (eql :markdown)) item page)
  (views:html
    (:div (:i (:small (views:object-ref item :display "markdown"))))
    (:pre :style "background-color: #eee;"
          (render-wiki-text (text-of item) page))))

;; References

(defmethod render-story-item ((type (eql :reference)) item page)
  (let* ((data (data-of item))
         (site (gethash "site" data))
         (title (gethash "title" data))
         (slug (gethash "slug" data)))
    (views:html
      (:p
       (:span :class "hyperbook-reference"
              :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                             (cl-who:escape-string title)
                             (cl-who:escape-string (hb:title-of (hb:hyperbook-of page))))
              (views:object-ref
               (handler-case
                   (get-remote-page (hb:hyperbook-of page)
                                    (str:concat site "/" slug)
                                    title)
                 (error (c) c))))
       (views:esc " — ")
       (render-wiki-text (text-of item) page)))))

;; Page folds

(defmethod render-story-item ((type (eql :pagefold)) item page)
  (views:html
    (:div :style "top-margin: 5pt;"
          (:hr :style "color: gray;")
          (:span :style "color: gray;"
                 (views:esc (text-of item))))))

;; Graphviz

(defmethod render-story-item ((type (eql :graphviz)) item page)
  (declare (ignore type page))
  (views:graphviz-snippet
   (text-of item)
   :engine (or (and (data-of item)
                    (gethash "engine" (data-of item)))
               "dot")
   :fallback-title "Raw DOT source"))

;; Images

(defmethod render-story-item ((type (eql :image)) item page)
  (views:html
    (:div :style "text-align:center; background-color: #eee;"
          (:div :style "width: 80%; margin: 0 auto;"
                (:img :src (gethash "url" (data-of item)))
                (:p (render-wiki-text (text-of item) page))))))
