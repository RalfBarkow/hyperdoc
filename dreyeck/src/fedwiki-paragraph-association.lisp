;;;; One HTML paragraph of a HyperDoc page, associated with one paragraph Item of a Federated Wiki page.
;;;;
;;;; Read docs/fedwiki-paragraph-association.md first. In short:
;;;;  * The HTML file stays what it is and is never written. This file adds no attribute to it and no new editor.
;;;;  * When the page "Assessing an Upstream Commit" is loaded, its introductory P in the real plump parse tree changes
;;;;    class to ASSOCIATED-PARAGRAPH (the pattern of the demo's inspector-code-item). That object is what the Inspector
;;;;    selects; it keeps its identity, children and attributes.
;;;;  * Its view "Original Wiki editor" embeds the ORIGINAL client's own text editor for the Wiki Item
;;;;    (assessing-an-upstream-commit, 5555555555555555) through the one frame adapter of
;;;;    tests/fedwiki-original-editor/server.mjs. That server authorizes and performs every write, with the Item's id and
;;;;    an edit Action in the page journal. This file never writes a Wiki page.
;;;;  * The persisted text is the Item's text. Reading the stored page again (and loading the page) puts that text into the
;;;;    in-memory parse tree, so the page shows it. The HTML text is the seed and the fallback only.
(defpackage #:dreyeck/fedwiki-paragraph-association
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:cfg #:dreyeck/fedwiki-original-editor-configuration)
                    (#:v #:html-inspector-views))
  (:export #:associated-paragraph #:paragraph-binding #:binding-of #:associated-paragraph-p
           #:binding-html-text #:binding-stored-text #:binding-configuration #:binding-problem #:binding-source
           #:plain-text #:introduction-paragraph #:association-page-p #:bind-page #:refresh-from-storage))
(in-package #:dreyeck/fedwiki-paragraph-association)

(defparameter +directory-name+ "upstream-intake")
(defparameter +file-name+ "Assessing an Upstream Commit.html"
  "The one HTML source this association is declared for: directory name and file name. A declaration, not a search.")

(defclass paragraph-binding ()
  ((html-pathname :initarg :html-pathname :reader binding-html-pathname)
   (html-text :initarg :html-text :reader binding-html-text
              :documentation "The plain text of the HTML paragraph as the file has it: the seed, never edited here.")
   (stored-text :initform nil :accessor binding-stored-text
                :documentation "The Item's text as the last reading of the stored page found it, or NIL.")
   (source :initform nil :accessor binding-source
           :documentation "The LOCAL-FEDWIKI-PAGE-SOURCE of that reading, or NIL.")
   (configuration :initform nil :accessor binding-configuration
                  :documentation "The configuration the last reading used; the view offers what that configuration offers.")
   (problem :initform nil :accessor binding-problem
            :documentation "Why the stored page could not be read as this Item, or NIL."))
  (:documentation "What the association knows about one HTML paragraph. The Wiki Item is not copied here as a second
source: STORED-TEXT is the last observation of it."))

;; The introductory P, in place. Subclassing keeps its identity and its place in the parse tree.
(defclass associated-paragraph (plump:element)
  ((binding :initarg :binding :reader binding-of)))

(defun associated-paragraph-p (object) (typep object 'associated-paragraph))

(defun %replace-all (string old new)
  (with-output-to-string (out)
    (loop with start = 0
          for hit = (search old string :start2 start)
          do (write-string string out :start start :end (or hit (length string)))
             (if hit
                 (progn (write-string new out) (setf start (+ hit (length old))))
                 (return)))))

(defun %decode (text)
  (dolist (pair '(("&lt;" "<") ("&gt;" ">") ("&quot;" "\"") ("&#39;" "'") ("&amp;" "&")) text)
    (setf text (%replace-all text (first pair) (second pair)))))

(defun plain-text (string)
  "STRING (raw parse-tree text) with entities decoded and whitespace runs collapsed to one space, trimmed. The same rule
as introductionText in tests/fedwiki-original-editor/fixture.mjs, which seeds the Wiki Item."
  (let ((words '()) (word (make-string-output-stream)) (any nil))
    (flet ((end-word () (when any (push (get-output-stream-string word) words) (setf any nil))))
      (loop for c across (%decode string)
            do (if (member c '(#\Space #\Tab #\Newline #\Return #\Page))
                   (end-word)
                   (progn (write-char c word) (setf any t))))
      (end-word))
    (format nil "~{~A~^ ~}" (nreverse words))))

(defun %escape (text)
  "TEXT as raw parse-tree text: the parse tree holds source text with entities, which the serializer writes unchanged."
  (%replace-all (%replace-all (%replace-all text "&" "&amp;") "<" "&lt;") ">" "&gt;"))

;;; Identification: the page's file and the first P of its parse tree. Declared, so it is explicit, and not encoded in
;;; the HTML, so the file is not touched.

(defun introduction-paragraph (dom)
  "The introductory paragraph of the page: its first P in document order, or NIL."
  (first (coerce (plump:get-elements-by-tag-name dom "p") 'list)))

(defun association-page-p (page)
  "Whether PAGE is the HTML page this association is declared for: its file name and the name of its directory."
  (let ((file (and (slot-boundp page 'hyperdoc::file) (slot-value page 'hyperdoc::file))))
    (and file
         (let ((pathname (pathname file)))
           (and (equal +file-name+ (file-namestring pathname))
                (equal +directory-name+ (car (last (pathname-directory pathname)))))))))

;;; Reading the persistence. Read only: nothing here opens a file for output.

(defun %read-stored (binding configuration)
  "Observe the Wiki page file once and set the BINDING's stored text, source and problem. Never signals."
  (setf (binding-stored-text binding) nil (binding-source binding) nil (binding-problem binding) nil
        (binding-configuration binding) configuration)
  (cond
    ((null (cfg:configuration-root configuration))
     (setf (binding-problem binding) (cfg:mode-description configuration)))
    (t
     (handler-case
         (let* ((source (lp:observe-local-fedwiki-page-source (cfg:configuration-root configuration) cfg:+paragraph-slug+))
                (item (lp:find-story-item source cfg:+paragraph-item-id+)))
           (cond ((null item)
                  (setf (binding-problem binding)
                        (format nil "The stored page has no Item ~A." cfg:+paragraph-item-id+)))
                 ((not (equal "paragraph" (lp:story-item-type item)))
                  (setf (binding-problem binding)
                        (format nil "Item ~A of the stored page is of type ~S, not paragraph."
                                cfg:+paragraph-item-id+ (lp:story-item-type item))))
                 (t (setf (binding-source binding) source
                          (binding-stored-text binding) (lp:story-item-text item)))))
       (error (condition)
         (setf (binding-problem binding) (format nil "The stored page could not be read: ~A" condition))))))
  binding)

(defun %show-coordinates (element configuration)
  (plump:set-attribute element "data-fedwiki-site" (cfg:configuration-site configuration))
  (plump:set-attribute element "data-fedwiki-slug" cfg:+paragraph-slug+)
  (plump:set-attribute element "data-fedwiki-item-id" cfg:+paragraph-item-id+))

(defun %apply (element binding)
  "Put the stored text into the in-memory parse tree when it differs from what the HTML file says. When equal, the HTML's own
markup (for instance CODE) stays; when different the paragraph shows the Item's plain text. The HTML file is not touched."
  (let ((stored (binding-stored-text binding)))
    (when (and stored (not (equal (plain-text stored) (binding-html-text binding))))
      (plump:clear element)
      (plump:make-text-node element (%escape stored)))))

(defun refresh-from-storage (element &optional (configuration (cfg:editor-configuration)))
  "Read the stored Wiki page again and make the in-memory paragraph show the Item's text. Returns ELEMENT."
  (let ((binding (binding-of element)))
    (%read-stored binding configuration)
    (%show-coordinates element configuration)
    (%apply element binding)
    element))

(defun bind-page (page &optional (configuration (cfg:editor-configuration)))
  "Associate PAGE's introductory paragraph, if PAGE is the declared page. Idempotent; returns the paragraph or NIL."
  (when (association-page-p page)
    (let ((element (introduction-paragraph (hyperdoc::dom-of page))))
      (when element
        (unless (associated-paragraph-p element)
          (change-class element 'associated-paragraph
                        :binding (make-instance 'paragraph-binding
                                                :html-pathname (pathname (slot-value page 'hyperdoc::file))
                                                :html-text (plain-text (plump:text element)))))
        (refresh-from-storage element configuration)))))

(defmethod hyperdoc:load-page :after ((page hyperdoc::html-page))
  (bind-page page))

;;; The Inspector view

(defun %journal-summary (source)
  (let* ((journal (coerce (or (gethash "journal" (lp:page-source-json source)) (vector)) 'list)))
    (format nil "~D Actions; last: ~A" (length journal)
            (if journal (gethash "type" (car (last journal))) "none"))))

(defun %reread-button (element)
  (v:eval-button "Read stored page again"
    (dreyeck/authority-policy:reviewed-thunk "fedwiki-paragraph-association/reread"
      (refresh-from-storage element))))

(v:defview original-paragraph-editor-view (element associated-paragraph)
  (v:html-view :title "Original Wiki editor" :priority 2
    (let* ((binding (binding-of element))
           (configuration (or (binding-configuration binding) (cfg:editor-configuration)))
           (source (binding-source binding))
           (url (and source (cfg:embedded-item-editor-url configuration cfg:+paragraph-slug+ cfg:+paragraph-item-id+
                                                          (lp:page-source-sha256 source)))))
      (v:html
        (:h2 "Original Wiki paragraph editor")
        (:p "This HTML paragraph is associated with the Wiki paragraph Item "
            (:code (v:esc cfg:+paragraph-item-id+)) " of page " (:code (v:esc cfg:+paragraph-slug+))
            " on " (:code (v:esc (cfg:configuration-site configuration))) ".")
        (:table :class "inspector-table"
          (:tr (:th "HTML source (read only)") (:td (:code (v:esc (namestring (binding-html-pathname binding))))))
          (:tr (:th "Text in the HTML file") (:td (v:esc (binding-html-text binding))))
          (:tr (:th "Text in the Wiki Item (authoritative)")
               (:td (v:esc (or (binding-stored-text binding) "not read"))))
          (:tr (:th "Wiki page file")
               (:td (if source (v:html (:code (v:esc (namestring (lp:page-source-pathname source)))))
                         (v:esc "none"))))
          (:tr (:th "Observed SHA-256") (:td (if source (v:html (:code (v:esc (lp:page-source-sha256 source)))) (v:esc "none"))))
          (:tr (:th "Journal") (:td (v:esc (if source (%journal-summary source) "not read")))))
        (when (binding-problem binding)
          (v:html (:p :class "paragraph-association-problem" (v:esc (binding-problem binding)))))
        (cond (url
               (v:html
                 (:iframe :class "original-paragraph-editor" :title "Original Wiki paragraph editor"
                          :src url :sandbox "allow-scripts allow-same-origin"
                          :style "width:100%;height:330px;border:1px solid #aaa;" "")
                 (:p "Activate " (:em "Edit with original Wiki plugin") ", change the text, then click the frame's status "
                     "text outside the Item to save. Then read the stored page again:")))
              (t
               (v:html (:p :class "original-paragraph-editor-withheld"
                           "The embedded editor is not offered. " (v:esc (cfg:mode-description configuration))))))
        (when (cfg:configuration-root configuration)
          (%reread-button element))))))

(dreyeck/authority-policy:register-reviewed-control
 "fedwiki-paragraph-association/reread"
 :effect "Read one configured disposable site's assessing-an-upstream-commit JSON page and replace the children of the one associated paragraph in the in-memory HyperDoc parse tree with the Item's text. The HTML file and the Wiki page are not written; no network."
 :audit "refresh-from-storage in dreyeck/src/fedwiki-paragraph-association.lisp; dreyeck/tests/fedwiki-paragraph-association.lisp checks it against a temporary site and compares the HTML and the Wiki file bytes before and after")
