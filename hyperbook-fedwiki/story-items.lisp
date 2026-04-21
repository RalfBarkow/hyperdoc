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

(defun graphviz-story-item-engine-of (item)
  (or (and (data-of item)
           (gethash "engine" (data-of item)))
      "dot"))

(defun graphviz-story-item-sync-draft-script ()
  "var shell=this.closest(\".hyperbook-fedwiki-graphviz-edit-shell\");\
 if(!shell){return false;}\
 var textarea=shell.querySelector(\".hyperbook-fedwiki-graphviz-editor\");\
 var inputId=shell.dataset.fedwikiGraphvizInputId;\
 var hiddenInput=inputId ? shell.querySelector(\"#\"+CSS.escape(inputId)) : null;\
 if(textarea && hiddenInput){\
 hiddenInput.value=textarea.value;\
 hiddenInput.dispatchEvent(new Event(\"input\",{bubbles:true}));\
 hiddenInput.dispatchEvent(new Event(\"change\",{bubbles:true}));\
 }")

(defun graphviz-story-item-edit-button-script ()
  (format nil "~A\
 var editState=shell && shell.querySelector(\".hyperbook-fedwiki-graphviz-edit-state\");\
 var editButton=shell && shell.querySelector(\".hyperbook-fedwiki-graphviz-edit-button\");\
 if(editState){editState.hidden=false;}\
 if(editButton){editButton.hidden=true;}\
 var textarea=shell && shell.querySelector(\".hyperbook-fedwiki-graphviz-editor\");\
 if(textarea){\
 textarea.focus();\
 textarea.setSelectionRange(textarea.value.length, textarea.value.length);\
 }\
 return false;"
          (graphviz-story-item-sync-draft-script)))

(defun graphviz-story-item-preview-script ()
  (format nil "~A\
 var placeholder=shell && shell.querySelector(\".inspector-graphviz\");\
 if(!placeholder){return false;}\
 var textarea=shell.querySelector(\".hyperbook-fedwiki-graphviz-editor\");\
 var dot=textarea ? textarea.value : \"\";\
 placeholder.setAttribute(\"data-inspector-graphviz-dot\", dot);\
 placeholder.setAttribute(\"data-inspector-graphviz-state\", \"pending\");\
 placeholder.removeAttribute(\"data-inspector-graphviz-rendered\");\
 var canvas=placeholder.querySelector(\".inspector-graphviz-canvas\");\
 if(canvas){\
 canvas.innerHTML=`<p class=inspector-graphviz-pending>Rendering Graphviz diagram...</p>`;\
 }\
 var fallback=placeholder.querySelector(\".inspector-graphviz-dot-fallback pre\");\
 if(fallback){fallback.textContent=dot;}\
 var errorNode=placeholder.querySelector(\".inspector-graphviz-error\");\
 if(errorNode){errorNode.remove();}\
 if(window.inspectorGraphviz && window.inspectorGraphviz.renderPlaceholder){\
 window.inspectorGraphviz.renderPlaceholder(placeholder);\
 }\
 return false;"
          (graphviz-story-item-sync-draft-script)))

(defun graphviz-story-item-cancel-script ()
  "var shell=this.closest(\".hyperbook-fedwiki-graphviz-edit-shell\");\
 if(!shell){return false;}\
 var canonicalDot=shell.dataset.fedwikiGraphvizCanonicalDot || \"\";\
 var textarea=shell.querySelector(\".hyperbook-fedwiki-graphviz-editor\");\
 if(textarea){textarea.value=canonicalDot;}\
 var inputId=shell.dataset.fedwikiGraphvizInputId;\
 var hiddenInput=inputId ? shell.querySelector(\"#\"+CSS.escape(inputId)) : null;\
 if(hiddenInput){\
 hiddenInput.value=canonicalDot;\
 hiddenInput.dispatchEvent(new Event(\"input\",{bubbles:true}));\
 hiddenInput.dispatchEvent(new Event(\"change\",{bubbles:true}));\
 }\
 var placeholder=shell.querySelector(\".inspector-graphviz\");\
 if(placeholder){\
 placeholder.setAttribute(\"data-inspector-graphviz-dot\", canonicalDot);\
 placeholder.setAttribute(\"data-inspector-graphviz-state\", \"pending\");\
 placeholder.removeAttribute(\"data-inspector-graphviz-rendered\");\
 var canvas=placeholder.querySelector(\".inspector-graphviz-canvas\");\
 if(canvas){\
 canvas.innerHTML=`<p class=inspector-graphviz-pending>Rendering Graphviz diagram...</p>`;\
 }\
 var fallback=placeholder.querySelector(\".inspector-graphviz-dot-fallback pre\");\
 if(fallback){fallback.textContent=canonicalDot;}\
 var errorNode=placeholder.querySelector(\".inspector-graphviz-error\");\
 if(errorNode){errorNode.remove();}\
 if(window.inspectorGraphviz && window.inspectorGraphviz.renderPlaceholder){\
 window.inspectorGraphviz.renderPlaceholder(placeholder);\
 }\
 }\
 var editState=shell.querySelector(\".hyperbook-fedwiki-graphviz-edit-state\");\
 var editButton=shell.querySelector(\".hyperbook-fedwiki-graphviz-edit-button\");\
 if(editState){editState.hidden=true;}\
 if(editButton){editButton.hidden=false;}\
 return false;")

(defun graphviz-story-item-save-script ()
  "var shell=this.closest(\".hyperbook-fedwiki-graphviz-edit-shell\");\
 if(!shell){return false;}\
 var textarea=shell.querySelector(\".hyperbook-fedwiki-graphviz-editor\");\
 var dot=textarea ? textarea.value : \"\";\
 this.setAttribute(\"data-hyperbook-fedwiki-graphviz-dot\", dot);\
 this.value=dot;\
 var inputId=shell.dataset.fedwikiGraphvizInputId || \"\";\
 var hiddenInput=inputId ? document.getElementById(inputId) : null;\
 if(hiddenInput){\
 hiddenInput.value=dot;\
 hiddenInput.dispatchEvent(new Event(\"input\",{bubbles:true}));\
 hiddenInput.dispatchEvent(new Event(\"change\",{bubbles:true}));\
 }\
 var submitButton=this.previousElementSibling && this.previousElementSibling.firstElementChild;\
 if(!submitButton){return false;}\
 window.setTimeout(function () { submitButton.click(); }, 250);\
 return false;")

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

(defclass adapted-audio-snippet ()
  ((source-item :reader adapted-audio-snippet-source-item-of
                :initarg :source-item
                :type story-item)
   (source-page :reader adapted-audio-snippet-source-page-of
                :initarg :source-page
                :type fedwiki-page)
   (target-url :reader adapted-audio-snippet-target-url-of
               :initarg :target-url
               :type string)
   (caption :reader adapted-audio-snippet-caption-of
            :initarg :caption
            :type string)
   (url-kind :reader adapted-audio-snippet-url-kind-of
             :initarg :url-kind
             :type keyword)
   (summary :reader adapted-audio-snippet-summary-of
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

(defmethod views:text-representation ((snippet adapted-audio-snippet))
  (format nil "audio ~A"
          (adapted-audio-snippet-target-url-of snippet)))

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
(defparameter *direct-media-audio-extensions*
  '(".mp3" ".m4a" ".aac" ".ogg" ".opus" ".wav" ".flac"))

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

(defun normalize-audio-snippet-source-text (text)
  (coerce (remove #\Return (or text "")) 'string))

(defun audio-snippet-first-non-empty-line-and-caption (text)
  (let* ((normalized (normalize-audio-snippet-source-text text))
         (lines (cl-ppcre:split "\\n" normalized))
         (index (position-if (lambda (line)
                               (plusp (length (string-trim '(#\Space #\Tab #\Newline)
                                                           line))))
                             lines)))
    (if index
        (values (string-trim '(#\Space #\Tab #\Newline)
                             (nth index lines))
                (string-trim '(#\Space #\Tab #\Newline)
                             (format nil "~{~A~^~%~}"
                                     (subseq lines (1+ index)))))
        (values nil ""))))

(defun audio-snippet-html-contaminated-first-line-p (line)
  (or (search "<audio" line :test #'char-equal)
      (search "<source" line :test #'char-equal)
      (search "type=\"audio/" line :test #'char-equal)
      (search "type='audio/" line :test #'char-equal)))

(defun audio-direct-media-url-p (url)
  (let* ((query-position (position #\? url))
         (fragment-position (position #\# url))
         (end (reduce #'min
                      (remove nil (list query-position fragment-position))
                      :initial-value (length url)))
         (lowercase-url (string-downcase (subseq url 0 end))))
    (loop for extension in *direct-media-audio-extensions*
          thereis (str:ends-with? extension lowercase-url))))

(defun classify-audio-snippet-url (url)
  (if (audio-direct-media-url-p url)
      :direct-media
      :fallback-only))

(defun parse-audio-snippet-source-text (text)
  (multiple-value-bind (first-line caption)
      (audio-snippet-first-non-empty-line-and-caption text)
    (cond
      ((null first-line)
       (values nil
               ""
               nil
               :missing-url
               "Audio snippet must start with an absolute http(s) URL."
               nil))
      ((string= first-line "-")
       (values nil
               caption
               nil
               :placeholder-url
               "Audio snippet placeholder '-' is unsupported in this slice."
               (list :first-line first-line)))
      ((audio-snippet-html-contaminated-first-line-p first-line)
       (values nil
               caption
               nil
               :raw-audio-html-unsupported
               "Raw <audio ...> HTML or HTML-contaminated audio lines are unsupported in this slice. Expected an absolute http(s) URL on the first non-empty line."
               (list :first-line first-line)))
      ((not (absolute-http-url-p first-line))
       (values nil
               caption
               nil
               :non-http-url
               "Audio snippet first line must be an absolute http(s) URL."
               (list :first-line first-line)))
      (t
       (values first-line
               caption
               (classify-audio-snippet-url first-line)
               nil
               nil
               nil)))))

(defmethod adapt-plugin-like-story-item ((type (eql :audio)) item page)
  (declare (ignore type))
  (multiple-value-bind (target-url caption url-kind parse-failure message partial-fields)
      (parse-audio-snippet-source-text (text-of item))
    (if parse-failure
        (make-story-item-adaptation-failure
         item page parse-failure message
         :snippet-kind :audio
         :partial-fields partial-fields)
        (make-instance 'adapted-audio-snippet
                       :source-item item
                       :source-page page
                       :target-url target-url
                       :caption caption
                       :url-kind url-kind
                       :summary (format nil "Audio ~A" target-url)))))

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

(defun render-audio-snippet-caption (snippet page)
  (when (plusp (length (adapted-audio-snippet-caption-of snippet)))
    (views:html
      (:div :class "fedwiki-audio-snippet-caption"
            :style "white-space: pre-wrap;"
            (render-wiki-text (adapted-audio-snippet-caption-of snippet)
                              page)))))

(defun render-audio-snippet-open-link (snippet label)
  (views:html
    (:p
     (:a :href (adapted-audio-snippet-target-url-of snippet)
         :target "_blank"
         :rel "noopener noreferrer"
         (views:esc label)))))

(defun render-audio-snippet-direct-media (snippet page)
  (views:html
    (:div :class "fedwiki-audio-snippet-direct-media"
          (:audio :controls "controls"
                  :preload "none"
                  :src (adapted-audio-snippet-target-url-of snippet))
          (render-audio-snippet-caption snippet page)
          (render-audio-snippet-open-link snippet "Open/download audio"))))

(defun render-audio-snippet-fallback-only (snippet page)
  (views:html
    (:div :class "fedwiki-audio-snippet-fallback-only"
          (:p (:b (views:esc "External audio reference")))
          (render-audio-snippet-caption snippet page)
          (render-audio-snippet-open-link snippet "Open audio reference"))))

(defun render-audio-adaptation-failure (failure)
  (render-story-item-adaptation-failure failure))

(defun render-adapted-audio-snippet (snippet page)
  (ecase (adapted-audio-snippet-url-kind-of snippet)
    (:direct-media
     (views:html
       (:div :class "fedwiki-audio-snippet"
             (render-audio-snippet-direct-media snippet page))))
    (:fallback-only
     (views:html
       (:div :class "fedwiki-audio-snippet"
             (render-audio-snippet-fallback-only snippet page))))))

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

;; Audio

(defmethod render-story-item ((type (eql :audio)) item page)
  (let ((adapted (adapt-plugin-like-story-item type item page)))
    (typecase adapted
      (adapted-audio-snippet
       (render-adapted-audio-snippet adapted page))
      (story-item-adaptation-failure
       (render-audio-adaptation-failure adapted))
      (t
       (render-audio-adaptation-failure
        (make-story-item-adaptation-failure
         item page :missing-adaptation-result
         "Audio adaptation produced no inspectable result."
         :snippet-kind :audio))))))

;; Graphviz

(defmethod render-story-item ((type (eql :graphviz)) item page)
  (declare (ignore type))
  (let* ((dot (text-of item))
         (engine (graphviz-story-item-engine-of item))
         (editable-p (localhost-fedwiki-story-item-editable-p page))
         (draft-cell (and editable-p (lwcells:cell dot)))
         (draft-input-id (and editable-p
                              (html-inspector-views/reactive:input-id
                               draft-cell :event :change))))
    (views:html
      (:div :class "hyperbook-fedwiki-graphviz-edit-shell"
            :data-fedwiki-graphviz-story-item-id (id-of item)
            :data-fedwiki-graphviz-canonical-dot dot
            :data-fedwiki-graphviz-engine engine
            :data-fedwiki-graphviz-editable (if editable-p "true" "false")
            :data-fedwiki-graphviz-input-id (or draft-input-id "")
            (:div :class "hyperbook-fedwiki-graphviz-view-state"
                  (views:graphviz-snippet
                   dot
                   :engine engine
                   :fallback-title "Raw DOT source"))
            (when editable-p
              (views:html
                (:div :class "hyperbook-fedwiki-graphviz-controls"
                      (:button :type "button"
                               :class "hyperbook-fedwiki-graphviz-edit-button"
                               :onclick (graphviz-story-item-edit-button-script)
                               "Edit DOT"))
                (:div :class "hyperbook-fedwiki-graphviz-edit-state"
                      :hidden "hidden"
                      (:label :class "hyperbook-fedwiki-graphviz-editor-label"
                              "DOT source")
                      (:textarea :class "hyperbook-fedwiki-graphviz-editor"
                                 :rows "10"
                                 :spellcheck "false"
                                 :data-fedwiki-graphviz-input-id draft-input-id
                                 :oninput (graphviz-story-item-sync-draft-script)
                                 (views:esc dot))
                      (:input :type "hidden" :id draft-input-id :value dot)
                      (:div :class "hyperbook-fedwiki-graphviz-editor-actions"
                            (:button :type "button"
                                     :class "hyperbook-fedwiki-graphviz-preview-button"
                                     :onclick (graphviz-story-item-preview-script)
                                     "Preview")
                            " "
                            (:span :class "hyperbook-fedwiki-graphviz-save-submit"
                                   :style "display:none"
                                   (views:action-button
                                    "Save"
                                    (views:thunk
                                      (persist-localhost-fedwiki-story-item-text-edit
                                       page
                                       item
                                       (lwcells:cell-ref draft-cell))
                                     t)
                                    "Persist the current DOT as a FedWiki story-item text edit"))
                            " "
                            (:button :type "button"
                                     :class "hyperbook-fedwiki-graphviz-save-button"
                                     :onclick (graphviz-story-item-save-script)
                                     "Save")
                            " "
                            (:button :type "button"
                                     :class "hyperbook-fedwiki-graphviz-cancel-button"
                                     :onclick (graphviz-story-item-cancel-script)
                                     "Cancel")))))))))

;; Images

(defmethod render-story-item ((type (eql :image)) item page)
  (views:html
    (:div :style "text-align:center; background-color: #eee;"
          (:div :style "width: 80%; margin: 0 auto;"
                (:img :src (gethash "url" (data-of item)))
                (:p (render-wiki-text (text-of item) page))))))
