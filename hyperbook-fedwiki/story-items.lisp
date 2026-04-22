;;;; Process story items
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Find links in Wiki text
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
  (process-text-and-links text page
                          #'(lambda (chunk page)
                              (declare (ignore chunk page))
                              nil)
                          #'collect-link))

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
                              (declare (ignore page))
                              (views:html (views:esc chunk)))
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

;; Images

(defmethod render-story-item ((type (eql :image)) item page)
  (views:html
    (:div :style "text-align:center; background-color: #eee;"
          (:div :style "width: 80%; margin: 0 auto;"
                (:img :src (gethash "url" (data-of item)))
                (:p (render-wiki-text (text-of item) page))))))

;; Graphviz dot language

(defmethod render-story-item ((type (eql :graphviz)) item page)
  ;; The graphviz plugin
  ;;   https://github.com/fedwiki/wiki-plugin-graphviz
  ;; accepts an extended DOT syntax in item.text.
  ;; It is preprocessed, with the final
  ;; DOT script stored in item.dot. However,
  ;; item.dot is not systematically stored in the
  ;; page, so it may be missing.
  ;;
  ;; For now, we feed item.dot to Graphviz, will
  ;; item.text as a fallback. We should of course
  ;; do all the preprocessing that the graphviz
  ;; plugin does.
  (let ((dot (or (some->> item data-of (gethash "dot"))
                 (text-of item))))
    (views:transclusion (views:graphviz-view dot))))

;; Missing story item types (with reference to examples)

;; assets
;; wiki.ralfbarkow.ch/reflections-on-graphviz-plugin

;; code
;; wiki.ralfbarkow.ch/0000000010

;; frame
;; fed.wiki/dorkbotpdx-may-2023
;; fed.wiki/breakfast-on-the-bridge

;; grep
;; wiki.dbbs.co/welcome-visitors

;; html
;; fed.wiki/dorkbotpdx-may-2023
;; wiki.ralfbarkow.ch/0000000010

;; line
;; fed.wiki/dorkbotpdx-may-2023

;; map
;; fed.wiki/breakfast-on-the-bridge

;; markdown
;; fed.wiki/breakfast-on-the-bridge
;; fed.wiki.org/digest-2014-06-25
;; wiki.ralfbarkow.ch/0000000010

;; roster
;; fed.wiki/watch-everything

;; video
;; wiki.ralfbarkow.ch/a-beautiful-wiki-page

;; find examples
(defun find-examples-for-story-item-types ()
  (let ((m (make-hash-table)))
    (loop for site being the hash-values of *neighborhood*
          append (loop for page being the hash-values of (pages-of site)
                       for story = (story-of page)
                       when story
                         append (loop for item across story
                                      for type = (item-type-of item)
                                      unless (member type '(:paragraph :pagefold :image :reference))
                                        do (pushnew page (gethash type m)))))
    m))

