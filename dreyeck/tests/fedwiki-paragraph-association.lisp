;;;; The association of the introductory paragraph of "Assessing an Upstream Commit" with a Wiki paragraph Item, against a
;;;; temporary site and a temporary HTML file: the paragraph becomes an Inspector object, the stored Item's text reaches the
;;;; parse tree after a reread, and neither the HTML file nor the Wiki page is written by HyperDoc.
;;;; (The original editor's own write, with the Item id and the edit Action, is witnessed in a browser by
;;;; tests/fedwiki-original-editor/paragraph-witness.mjs; here a stand-in for the original server changes the file.)
(defpackage #:dreyeck/fedwiki-paragraph-association/tests
  (:use #:cl)
  (:local-nicknames (#:pa #:dreyeck/fedwiki-paragraph-association)
                    (#:cfg #:dreyeck/fedwiki-original-editor-configuration)
                    (#:ct #:dreyeck/fedwiki-original-editor-configuration/tests)
                    (#:hv #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/fedwiki-paragraph-association/tests)

(defparameter +html+
  (format nil "<h1>Assessing an Upstream Commit</h1>~%<in-package>cl-user</in-package>~%<p>~%Observing says where it stands; <code>dreyeck.ch</code> &amp; the rest.~%</p>~%<p>Second.</p>~%"))
(defparameter +html-text+ "Observing says where it stands; dreyeck.ch & the rest.")

(defclass fake-page ()
  ((hyperdoc::file :initarg :file)
   (dom :initarg :dom :reader fake-dom)))
(defmethod hyperdoc::dom-of ((page fake-page)) (fake-dom page))

(defun %octets (file)
  (with-open-file (in file :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence octets in) octets)))

(defun %write (file text)
  (ensure-directories-exist file)
  (with-open-file (out file :direction :output :if-exists :supersede :external-format :utf-8) (write-string text out)))

(defun %wiki-json (text &optional (actions ""))
  (format nil "{\"title\":\"Assessing an Upstream Commit\",\"story\":[{\"id\":\"~A\",\"type\":\"paragraph\",\"text\":~S}],\"journal\":[{\"type\":\"create\",\"id\":\"6\",\"item\":{\"title\":\"x\"},\"date\":1}~A]}"
          cfg:+paragraph-item-id+ text actions))

(defun %page (directory-name file-name)
  (let* ((file (merge-pathnames (format nil "~A/~A" directory-name file-name)
                                (uiop:ensure-directory-pathname (uiop:temporary-directory))))
         (dom (let ((plump:*tag-dispatchers* plump:*html-tags*)) (plump:parse +html+))))
    (make-instance 'fake-page :file file :dom dom)))

(defun %configuration (&rest alist)
  (cfg:read-editor-configuration (lambda (name) (cdr (assoc name alist :test #'equal)))))

(defun %serialized (element) (with-output-to-string (s) (plump:serialize element s)))

(defun %view-html (object title)
  (let ((view (find title (hv:all-views object) :key #'hv:view-title :test #'string=)))
    (assert view () "~S has no view ~S" object title)
    (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil))
      (hv:view-html view))))

(defun check-identification ()
  "Only the declared page, and only its first P, becomes the associated object; any other file name is left alone."
  (let ((other (%page "upstream-intake" "Observing an Upstream Commit.html"))
        (wrong-directory (%page "elsewhere" "Assessing an Upstream Commit.html"))
        (declared (%page "upstream-intake" "Assessing an Upstream Commit.html")))
    (assert (null (pa:bind-page other (%configuration))))
    (assert (null (pa:bind-page wrong-directory (%configuration))))
    (assert (notany #'pa:associated-paragraph-p (plump:get-elements-by-tag-name (hyperdoc::dom-of other) "p")))
    (let ((element (pa:bind-page declared (%configuration)))
          (second (second (coerce (plump:get-elements-by-tag-name (hyperdoc::dom-of declared) "p") 'list))))
      (assert (pa:associated-paragraph-p element))
      (assert (not (pa:associated-paragraph-p second)))
      (assert (equal +html-text+ (pa:binding-html-text (pa:binding-of element))))
      (assert (search "Not configured" (pa:binding-problem (pa:binding-of element))))
      ;; Unconfigured: nothing is replaced, and the paragraph keeps its own markup.
      (assert (search "<code>dreyeck.ch</code>" (%serialized element)))))
  t)

(defun check-reread-shows-persisted-text ()
  "Unchanged Item: the HTML paragraph keeps its markup. Changed Item (by the original server's write): the reread puts the
Item's text into the parse tree, shows the coordinates, escapes markup characters, and writes neither the Wiki file nor the HTML."
  (ct:call-with-site-directory
   (lambda (site)
     (let* ((page (%page "upstream-intake" "Assessing an Upstream Commit.html"))
            (html-file (slot-value page 'hyperdoc::file))
            (wiki-file (merge-pathnames (format nil "pages/~A" cfg:+paragraph-slug+) (uiop:ensure-directory-pathname site)))
            (configuration (%configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ "http://127.0.0.1:41234")
                                           (cons cfg:+mode-variable+ "isolated-loopback"))))
       (%write html-file +html+)
       (%write wiki-file (%wiki-json +html-text+))
       (unwind-protect
            (let* ((html-before (%octets html-file))
                   (element (pa:bind-page page configuration))
                   (binding (pa:binding-of element)))
              (assert (null (pa:binding-problem binding)) () "~A" (pa:binding-problem binding))
              (assert (search "<code>dreyeck.ch</code>" (%serialized element)) () "an unchanged Item replaced the HTML markup")
              (assert (equal (list cfg:+paragraph-item-id+ cfg:+paragraph-slug+)
                             (list (plump:attribute element "data-fedwiki-item-id") (plump:attribute element "data-fedwiki-slug"))))
              ;; The frame names the observed revision and only this Item.
              (let ((editor (%view-html element "Original Wiki editor")))
                (assert (search "<iframe" editor))
                (assert (some (lambda (amp) (search (format nil "/view/assessing-an-upstream-commit?hyperdocItem=5555555555555555~Arevision=~A"
                                                            amp (dreyeck/local-fedwiki-page:page-source-sha256 (pa:binding-source binding)))
                                                    editor))
                              '("&" "&amp;"))))
              ;; What the original server does: the same Item id, a new text, one appended edit Action.
              (let ((wiki-before nil))
                (%write wiki-file (%wiki-json "Changed <in> the editor & saved."
                                              (format nil ",{\"type\":\"edit\",\"id\":\"~A\",\"item\":{\"id\":\"~A\",\"type\":\"paragraph\",\"text\":\"Changed <in> the editor & saved.\"},\"date\":2}"
                                                      cfg:+paragraph-item-id+ cfg:+paragraph-item-id+)))
                (setf wiki-before (%octets wiki-file))
                (assert (eq element (pa:refresh-from-storage element configuration)))
                (assert (equalp wiki-before (%octets wiki-file)) () "the reread wrote the Wiki page")
                (assert (equalp html-before (%octets html-file)) () "the reread wrote the HTML source"))
              (let ((shown (%serialized element)))
                (assert (search "Changed &lt;in&gt; the editor &amp; saved." shown) () "~S" shown)
                (assert (not (search "<code>" shown))))
              (assert (equal "Changed <in> the editor & saved." (pa:binding-stored-text binding)))
              (assert (search "2 Actions; last: edit" (%view-html element "Original Wiki editor"))))
         (uiop:delete-file-if-exists html-file)))))
  t)

(defun check-unreadable-keeps-html ()
  "An unreadable or wrong Item leaves the HTML paragraph as it is and says why."
  (ct:call-with-site-directory
   (lambda (site)
     (let* ((page (%page "upstream-intake" "Assessing an Upstream Commit.html"))
            (configuration (%configuration (cons cfg:+root-variable+ site)))
            (element (pa:bind-page page configuration)))
       (assert (search "could not be read" (pa:binding-problem (pa:binding-of element))))
       (assert (search "<code>dreyeck.ch</code>" (%serialized element)))
       (%write (merge-pathnames (format nil "pages/~A" cfg:+paragraph-slug+) (uiop:ensure-directory-pathname site))
               (substitute #\7 #\5 (%wiki-json "x")))
       (pa:refresh-from-storage element configuration)
       (assert (search "no Item" (pa:binding-problem (pa:binding-of element))))
       (assert (search "<code>dreyeck.ch</code>" (%serialized element))))))
  t)

(defun run-tests ()
  (check-identification)
  (check-reread-shows-persisted-text)
  (check-unreadable-keeps-html)
  (format t "~&FEDWIKI-PARAGRAPH-ASSOCIATION-PASS: only the declared page's first paragraph is associated; an unchanged Item keeps the HTML markup; a changed Item's text reaches the parse tree after a reread; the HTML file and the Wiki page are not written; unreadable storage keeps the HTML and says why.~%")
  t)
