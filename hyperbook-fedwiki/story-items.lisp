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

;;
;; Optional second-stage adaptation for plugin-like snippet story items
;;

(defclass adapted-video-snippet ()
  ((source-item :reader adapted-video-snippet-source-item-of
                :initarg :source-item
                :type story-item)
   (source-page :reader adapted-video-snippet-source-page-of
                :initarg :source-page
                :type fedwiki-page)
   (provider :reader adapted-video-snippet-provider-of
             :initarg :provider
             :type keyword)
   (video-id :reader adapted-video-snippet-video-id-of
             :initarg :video-id
             :type string)
   (caption :reader adapted-video-snippet-caption-of
            :initarg :caption
            :type string)
   (canonical-url :reader adapted-video-snippet-canonical-url-of
                  :initarg :canonical-url
                  :type string)
   (embed-url :reader adapted-video-snippet-embed-url-of
              :initarg :embed-url
              :type string)
   (summary :reader adapted-video-snippet-summary-of
            :initarg :summary
            :type string)))

(defclass adapted-frame-snippet ()
  ((source-item :reader adapted-frame-snippet-source-item-of
                :initarg :source-item
                :type story-item)
   (source-page :reader adapted-frame-snippet-source-page-of
                :initarg :source-page
                :type fedwiki-page)
   (target-url :reader adapted-frame-snippet-target-url-of
               :initarg :target-url
               :type string)
   (height :reader adapted-frame-snippet-height-of
           :initarg :height
           :type integer)
   (summary :reader adapted-frame-snippet-summary-of
            :initarg :summary
            :type string)))

(defclass story-item-adaptation-failure ()
  ((source-item :reader adaptation-failure-source-item-of
                :initarg :source-item
                :type story-item)
   (source-page :reader adaptation-failure-source-page-of
                :initarg :source-page
                :type fedwiki-page)
   (snippet-kind :reader adaptation-failure-snippet-kind-of
                 :initarg :snippet-kind
                 :type keyword)
   (reason :reader adaptation-failure-reason-of
           :initarg :reason
           :type keyword)
   (message :reader adaptation-failure-message-of
            :initarg :message
            :type string)
   (partial-fields :reader adaptation-failure-partial-fields-of
                   :initarg :partial-fields
                   :initform nil
                   :type list)))

(defmethod views:text-representation ((snippet adapted-video-snippet))
  (format nil "video ~A"
          (adapted-video-snippet-video-id-of snippet)))

(defmethod views:text-representation ((snippet adapted-frame-snippet))
  (format nil "frame ~A"
          (adapted-frame-snippet-target-url-of snippet)))

(defmethod views:text-representation ((failure story-item-adaptation-failure))
  (format nil "~(~A~) adaptation failed"
          (adaptation-failure-snippet-kind-of failure)))

(defgeneric adapt-plugin-like-story-item (type item page)
  (:method ((type t) item page)
    (declare (ignore type item page))
    nil))

(defun normalize-video-snippet-source-text (text)
  (coerce (remove #\Return (or text "")) 'string))

(defun split-video-snippet-source-text (text)
  (let* ((normalized (normalize-video-snippet-source-text text))
         (newline-position (position #\Newline normalized))
         (header (if newline-position
                     (subseq normalized 0 newline-position)
                     normalized))
         (caption (if newline-position
                      (subseq normalized (1+ newline-position))
                      "")))
    (values (string-trim '(#\Space #\Tab #\Newline) header)
            (string-trim '(#\Space #\Tab #\Newline) caption))))

(defun parse-video-snippet-header (header)
  (let* ((tokens (remove ""
                        (cl-ppcre:split "\\s+" header)
                        :test #'string=))
         (provider-token (first tokens))
         (video-id (second tokens)))
    (cond
      ((null provider-token)
       (values nil nil :malformed-header))
      ((not (string= (string-upcase provider-token) "YOUTUBE"))
       (values provider-token video-id :unsupported-provider))
      ((null video-id)
       (values provider-token nil :missing-video-id))
      ((> (length tokens) 2)
       (values provider-token video-id :malformed-header))
      (t
       (values provider-token video-id nil)))))

(defun youtube-watch-url (video-id)
  (format nil "https://www.youtube.com/watch?v=~A" video-id))

(defun youtube-embed-url (video-id)
  (format nil "https://www.youtube.com/embed/~A" video-id))

(defun make-story-item-adaptation-failure (item page reason message
                                           &key
                                             (snippet-kind :video)
                                             partial-fields)
  (make-instance 'story-item-adaptation-failure
                 :source-item item
                 :source-page page
                 :snippet-kind snippet-kind
                 :reason reason
                 :message message
                 :partial-fields partial-fields))

(defun video-snippet-partial-fields (&key provider video-id)
  (cond
    ((and provider video-id)
     (list :provider provider :video-id video-id))
    (provider
     (list :provider provider))
    (video-id
     (list :video-id video-id))
    (t
     nil)))

(defmethod adapt-plugin-like-story-item ((type (eql :video)) item page)
  (declare (ignore type))
  (multiple-value-bind (header caption)
      (split-video-snippet-source-text (text-of item))
    (multiple-value-bind (provider-token video-id parse-failure)
        (parse-video-snippet-header header)
      (case parse-failure
        (:unsupported-provider
         (make-story-item-adaptation-failure
          item page :unsupported-provider
          (format nil "Unsupported video provider ~A. Only YOUTUBE <video-id> is supported in this slice."
                  provider-token)
          :partial-fields
          (video-snippet-partial-fields
           :provider provider-token
           :video-id video-id)))
        (:missing-video-id
         (make-story-item-adaptation-failure
          item page :missing-video-id
          "Video snippet header must be YOUTUBE <video-id>."
          :partial-fields
          (video-snippet-partial-fields
           :provider provider-token)))
        (:malformed-header
         (make-story-item-adaptation-failure
          item page :malformed-header
          "Malformed video snippet header. Expected YOUTUBE <video-id>."
          :partial-fields
          (video-snippet-partial-fields
           :provider provider-token
           :video-id video-id)))
        (otherwise
         (make-instance 'adapted-video-snippet
                        :source-item item
                        :source-page page
                        :provider :youtube
                        :video-id video-id
                        :caption caption
                        :canonical-url (youtube-watch-url video-id)
                        :embed-url (youtube-embed-url video-id)
                        :summary (format nil "YouTube video ~A" video-id)))))))

(defparameter *default-frame-snippet-height* 300)

(defun normalize-frame-snippet-source-text (text)
  (coerce (remove #\Return (or text "")) 'string))

(defun frame-snippet-raw-iframe-html-p (text)
  (let ((trimmed (string-left-trim '(#\Space #\Tab #\Newline #\Return)
                                   (or text ""))))
    (not (null (search "<iframe" trimmed :test #'char-equal)))))

(defun frame-snippet-non-empty-lines (text)
  (remove ""
          (mapcar (lambda (line)
                    (string-trim '(#\Space #\Tab #\Newline) line))
                  (cl-ppcre:split "\\n"
                                   (normalize-frame-snippet-source-text text)))
          :test #'string=))

(defun absolute-http-url-p (url)
  (or (str:starts-with? "http://" url)
      (str:starts-with? "https://" url)))

(defun parse-frame-snippet-height-line (line)
  (let ((tokens (remove ""
                       (cl-ppcre:split "\\s+" line)
                       :test #'string=)))
    (cond
      ((or (/= (length tokens) 2)
           (not (string= (string-upcase (first tokens)) "HEIGHT")))
       (values nil
               :malformed-height
               "Frame snippet second line must be HEIGHT <pixels>."))
      (t
       (let ((height-token (second tokens)))
         (handler-case
             (let ((height (parse-integer height-token)))
               (if (plusp height)
                   (values height nil nil)
                   (values nil
                           :malformed-height
                           "Frame snippet HEIGHT must be a positive integer.")))
           (parse-error ()
             (values nil
                     :malformed-height
                     "Frame snippet HEIGHT must be a positive integer."))))))))

(defun parse-frame-snippet-source-text (text)
  (cond
    ((frame-snippet-raw-iframe-html-p text)
     (values nil
             nil
             :raw-iframe-html-unsupported
             "Raw <iframe ...> HTML is unsupported in this slice. Expected <url> plus optional HEIGHT <pixels>."
             (let ((first-line (first (frame-snippet-non-empty-lines text))))
               (and first-line
                    (list :first-line first-line)))))
    (t
     (let ((lines (frame-snippet-non-empty-lines text)))
       (cond
         ((null lines)
          (values nil
                  nil
                  :missing-url
                  "Frame snippet must start with a target URL."
                  nil))
         ((> (length lines) 2)
          (values nil
                  nil
                  :malformed-frame-snippet
                  "Frame snippet supports only <url> and optional HEIGHT <pixels> in this slice."
                  (list :first-line (first lines)
                        :second-line (second lines)
                        :extra-line (third lines))))
         ((not (absolute-http-url-p (first lines)))
          (values nil
                  nil
                  :malformed-frame-snippet
                  "Frame snippet first line must be an absolute http(s) URL."
                  (list :first-line (first lines))))
         ((null (second lines))
          (values (first lines)
                  *default-frame-snippet-height*
                  nil
                  nil
                  nil))
         (t
          (multiple-value-bind (height parse-failure message)
              (parse-frame-snippet-height-line (second lines))
            (if parse-failure
                (values nil
                        nil
                        parse-failure
                        message
                        (list :target-url (first lines)
                              :height-line (second lines)))
                (values (first lines) height nil nil nil)))))))))

(defmethod adapt-plugin-like-story-item ((type (eql :frame)) item page)
  (declare (ignore type))
  (multiple-value-bind (target-url height parse-failure message partial-fields)
      (parse-frame-snippet-source-text (text-of item))
    (if parse-failure
        (make-story-item-adaptation-failure
         item page parse-failure message
         :snippet-kind :frame
         :partial-fields partial-fields)
        (make-instance 'adapted-frame-snippet
                       :source-item item
                       :source-page page
                       :target-url target-url
                       :height height
                       :summary (format nil "Frame ~A" target-url)))))

(defun render-video-snippet-preferred (snippet page)
  (views:html
    (:div :class "fedwiki-video-snippet-preferred"
          (:iframe :src (adapted-video-snippet-embed-url-of snippet)
                   :title (adapted-video-snippet-summary-of snippet)
                   :width "560"
                   :height "315"
                   :loading "lazy"
                   :allow "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                   :allowfullscreen "allowfullscreen")
          (when (plusp (length (adapted-video-snippet-caption-of snippet)))
            (views:html
              (:p :class "fedwiki-video-snippet-caption"
                  (render-wiki-text
                   (adapted-video-snippet-caption-of snippet)
                   page)))))))

(defun render-video-snippet-fallback (snippet page &key (include-caption-p t))
  (views:html
    (:div :class "fedwiki-video-snippet-fallback"
          (:p
           (:a :href (adapted-video-snippet-canonical-url-of snippet)
               :target "_blank"
               :rel "noopener noreferrer"
               (views:esc "Watch on YouTube")))
          (when (and include-caption-p
                     (plusp (length (adapted-video-snippet-caption-of snippet))))
            (views:html
              (:p :class "fedwiki-video-snippet-caption"
                  (render-wiki-text
                   (adapted-video-snippet-caption-of snippet)
                   page)))))))

(defun adaptation-failure-heading (failure)
  (format nil "~A adaptation failed."
          (string-capitalize
           (string-downcase
            (symbol-name (adaptation-failure-snippet-kind-of failure))))))

(defun render-story-item-adaptation-failure (failure)
  (let ((item (adaptation-failure-source-item-of failure)))
    (views:html
      (:div :class "fedwiki-story-item-adaptation-failure"
            (:p
             (:b (views:esc (adaptation-failure-heading failure))))
            (:p (views:esc (adaptation-failure-message-of failure)))
            (:p
             (views:esc "Failure object: ")
             (views:object-ref failure))
            (:p
             (views:esc "Original story item: ")
             (views:object-ref item))
            (:pre :style "background-color: #eee;"
                  (views:esc (text-of item)))))))

(defun render-video-adaptation-failure (failure)
  (render-story-item-adaptation-failure failure))

(defun render-adapted-video-snippet (snippet page)
  (views:html
    (:div :class "fedwiki-video-snippet"
          (render-video-snippet-preferred snippet page)
          (render-video-snippet-fallback
           snippet
           page
           :include-caption-p nil))))

(defun render-frame-snippet-preferred (snippet)
  (views:html
    (:div :class "fedwiki-frame-snippet-preferred"
          (:iframe :src (adapted-frame-snippet-target-url-of snippet)
                   :title (adapted-frame-snippet-summary-of snippet)
                   :width "100%"
                   :height (princ-to-string
                            (adapted-frame-snippet-height-of snippet))
                   :loading "lazy"))))

(defun render-frame-snippet-fallback (snippet)
  (views:html
    (:div :class "fedwiki-frame-snippet-fallback"
          (:p
           (:a :href (adapted-frame-snippet-target-url-of snippet)
               :target "_blank"
               :rel "noopener noreferrer"
               (views:esc "Open frame target")))
          (:p
           (:small
            (views:esc
             (format nil "Frame height: ~D px"
                     (adapted-frame-snippet-height-of snippet))))))))

(defun render-frame-adaptation-failure (failure)
  (render-story-item-adaptation-failure failure))

(defun render-adapted-frame-snippet (snippet)
  (views:html
    (:div :class "fedwiki-frame-snippet"
          (render-frame-snippet-preferred snippet)
          (render-frame-snippet-fallback snippet))))

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

;; Video

(defmethod render-story-item ((type (eql :video)) item page)
  (let ((adapted (adapt-plugin-like-story-item type item page)))
    (typecase adapted
      (adapted-video-snippet
       (render-adapted-video-snippet adapted page))
      (story-item-adaptation-failure
       (render-video-adaptation-failure adapted))
      (t
       (render-video-adaptation-failure
        (make-story-item-adaptation-failure
         item page :missing-adaptation-result
         "Video adaptation produced no inspectable result."))))))

;; Frames

(defmethod render-story-item ((type (eql :frame)) item page)
  (let ((adapted (adapt-plugin-like-story-item type item page)))
    (typecase adapted
      (adapted-frame-snippet
       (render-adapted-frame-snippet adapted))
      (story-item-adaptation-failure
       (render-frame-adaptation-failure adapted))
      (t
       (render-frame-adaptation-failure
        (make-story-item-adaptation-failure
         item page :missing-adaptation-result
         "Frame adaptation produced no inspectable result."
         :snippet-kind :frame))))))

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
