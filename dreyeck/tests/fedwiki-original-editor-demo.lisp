;;;; The Original Wiki Editor demonstration as a member of the Catalog: once in the membership, from this checkout, rendered
;;;; served without a configured site and without a signalled condition, read-only for a configured site, the editor frame
;;;; only in the isolated loopback mode, and no byte of the site written in any mode.
(defpackage #:dreyeck/fedwiki-original-editor-demo/tests
  (:use #:cl)
  (:local-nicknames (#:demo #:dreyeck/fedwiki-original-editor-demo)
                    (#:cfg #:dreyeck/fedwiki-original-editor-configuration)
                    (#:ct #:dreyeck/fedwiki-original-editor-configuration/tests)
                    (#:hv #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/fedwiki-original-editor-demo/tests)

(defparameter +id+ "dreyeck/fedwiki-original-editor-demo")

(defun served (thunk)
  "THUNK run as the served Catalog runs: a server up, not in development mode."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil))
    (funcall thunk)))

(defun %html-of-views (object)
  "The HTML of each HTML view of OBJECT, as a served visitor gets it, joined."
  (served (lambda ()
            (format nil "~{~A~^~%~}"
                    (loop for view in (hv:all-views object)
                          when (typep view 'hv:html-view) collect (hv:view-html view))))))

(defun %controls-of-views (object)
  "The controls (references with an eval- or action- id, the ones dreyeck/authority-policy contains) of OBJECT's HTML views, served."
  (served (lambda ()
            (loop for view in (hv:all-views object)
                  when (typep view 'hv:html-view)
                    append (progn (hv:view-html view)
                                  (remove-if-not (lambda (reference)
                                                   (and (consp reference) (stringp (car reference))
                                                        (or (uiop:string-prefix-p "eval-" (car reference))
                                                            (uiop:string-prefix-p "action-" (car reference)))))
                                                 (hv:view-references view)))))))

(defun %view-html (object title)
  (let ((view (find title (hv:all-views object) :key #'hv:view-title :test #'string=)))
    (assert view () "~S has no view ~S" object title)
    (served (lambda () (hv:view-html view)))))

(defun %configuration (&rest alist)
  (cfg:read-editor-configuration (lambda (name) (cdr (assoc name alist :test #'equal)))))

(defun %with-environment-unset (function)
  "Call FUNCTION with the demonstration's three variables empty (as unset), restoring them afterwards."
  (let ((saved (mapcar (lambda (name) (cons name (uiop:getenv name)))
                       (list cfg:+root-variable+ cfg:+origin-variable+ cfg:+mode-variable+))))
    (unwind-protect
         (progn (dolist (entry saved) (setf (uiop:getenv (car entry)) ""))
                (funcall function))
      (dolist (entry saved) (setf (uiop:getenv (car entry)) (or (cdr entry) ""))))))

(defparameter +fixture+
  "{\"title\":\"Original Editor Test\",\"story\":[{\"id\":\"1111111111111111\",\"type\":\"paragraph\",\"text\":\"An isolated paragraph; this item stays unchanged.\"},{\"id\":\"2222222222222222\",\"type\":\"code\",\"text\":\"(defun square (x) (* x x))\",\"language\":\"lisp\"}],\"journal\":[{\"type\":\"create\",\"id\":\"3333333333333333\",\"item\":{\"title\":\"Original Editor Test\"},\"date\":1700000000000}]}
"
  "The shape of tests/fedwiki-original-editor/fixture.mjs's page, shortened journal.")

(defun %snapshot (root)
  "Every file under ROOT with its octets: what a write would change."
  (sort (mapcar (lambda (file)
                  (cons (namestring file)
                        (with-open-file (in file :element-type '(unsigned-byte 8))
                          (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8))))
                            (read-sequence octets in) octets))))
                (remove-if #'uiop:directory-pathname-p (directory (merge-pathnames "**/*.*" root))))
        #'string< :key #'car))

(defun %write-fixture (site &optional (text +fixture+))
  (let ((file (merge-pathnames "pages/original-editor-test" (uiop:ensure-directory-pathname site))))
    (ensure-directories-exist file)
    (with-open-file (out file :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string text out))
    file))

(defun check-membership ()
  "Admitted once, from the same tree as dreyeck and hyperbook; loading it again, as HYPERDOC_CATALOG_SYSTEM would, adds nothing."
  (flet ((count-in-catalog () (count +id+ (dreyeck/catalog/tests:catalog-hyperbook-ids) :test #'string=)))
    ;; Declared where the product declares membership: a DEFHYPERDOC of a system in dreyeck/catalog's ASDF closure.
    (assert (find +id+ (dreyeck/catalog/membership:source-hyperdocs) :key (lambda (entry) (getf entry :id)) :test #'equal))
    (assert (= 1 (count-in-catalog)))
    (asdf:load-system +id+)
    (assert (= 1 (count-in-catalog)))
    (assert (member "dreyeck/fedwiki-original-editor-demo" (asdf:system-depends-on (asdf:find-system "dreyeck/catalog"))
                    :test #'equal))
    (assert (equal (truename (asdf:system-source-directory "dreyeck"))
                   (truename (asdf:system-source-directory +id+))))
    (assert (null (getf (dreyeck/catalog/membership:membership-report) :duplicated))))
  t)

(defun check-unconfigured-page ()
  "The page, as a served visitor gets it with nothing configured: it says so, signals nothing, embeds and links nothing."
  (%with-environment-unset
   (lambda ()
     (let* ((book (hyperbook:find-hyperbook +id+ :signal-error? t))
            (page (hyperbook:find-page book "Editing One Isolated Wiki Page" :signal-error? t))
            (html (%html-of-views page)))
       (assert (search "no isolated test site configured" html) () "the unconfigured state is not shown")
       (assert (search "HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT" html))
       (assert (not (search "<iframe" html)))
       (assert (not (search "Open original Wiki client" html)))
       ;; The page's prose names the reread button; what must be absent is the control itself. The only controls left are the
       ;; Inspector's generic Operations, which dreyeck/authority-policy decides again when clicked.
       (let ((controls (%controls-of-views page)))
         (assert (notany (lambda (reference) (typep (cdr reference) 'dreyeck/authority-policy:reviewed-thunk)) controls)
                 () "the unconfigured page offers a reviewed control: ~S" controls)
         (assert (every (lambda (reference) (typep (cdr reference) 'dreyeck/authority-policy:operation-thunk)) controls)
                 () "the unconfigured page offers a control that is not a policy Operation: ~S" controls))
       (assert (not (search "No isolated original-editor test site configured" html)) () "the former error is still signalled")
       (assert (not (search "No original Wiki client origin configured" html)) () "the former error is still signalled")
       ;; The reviewed control, invoked anyway, gives an object that says why, not a condition.
       (let ((observation (demo:read-stored-page)))
         (assert (typep observation 'demo:unavailable-page))
         (assert (search "Not configured" (%view-html observation "Stored Wiki page")))))))
  t)

(defun check-unreadable-site ()
  "A configured directory without the page, or with a page that is not the target, gives a read-only explanation."
  (ct:call-with-site-directory
   (lambda (site)
     (let* ((configuration (%configuration (cons cfg:+root-variable+ site)))
            (observation (demo:read-stored-page configuration)))
       (assert (typep observation 'demo:unavailable-page))
       (assert (search "no readable target page" (demo:unavailable-reason observation)))
       (assert (search "Nothing was written" (%view-html observation "Stored Wiki page"))))
     (%write-fixture site (substitute #\3 #\2 +fixture+))
     (let ((observation (demo:read-stored-page (%configuration (cons cfg:+root-variable+ site)))))
       (assert (typep observation 'demo:unavailable-page))
       (assert (search "not unique" (demo:unavailable-reason observation))))))
  t)

(defun %code-item (observation)
  (find "2222222222222222" (coerce (hyperbook/fedwiki::story-of (demo::page-of observation)) 'list)
        :key #'hyperbook/fedwiki::id-of :test #'equal))

(defun %paragraph-item (observation)
  (find "1111111111111111" (coerce (hyperbook/fedwiki::story-of (demo::page-of observation)) 'list)
        :key #'hyperbook/fedwiki::id-of :test #'equal))

(defun check-paragraph-item-by-identity ()
  "The Paragraph Item of the stored page is an Inspector object chosen by its id, shown in the page's own Story view with its
coordinate, offered the original editor only in isolated-loopback mode, and still found after the story is reordered."
  (ct:call-with-site-directory
   (lambda (site)
     (%write-fixture site)
     (let ((before (%snapshot site)))
       (let* ((read-only (%configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ "http://127.0.0.1:41234")))
              (observation (demo:read-stored-page read-only))
              (item (%paragraph-item observation))
              (story (%view-html (demo::page-of observation) "Story"))
              (stored (%view-html observation "Stored Wiki page")))
         (assert (typep item 'demo::inspector-paragraph-item))
         (assert (typep (%code-item observation) 'demo::inspector-code-item))
         ;; Acceptance 1 and 2: the existing Story view, with the Item's coordinate and a reference to the Item itself.
         ;; (The stored-page view transcludes that Story view; the browser case reads it there.)
         (assert (search "transclusion-" stored))
         (dolist (html (list story))
           (assert (search "An isolated paragraph; this item stays unchanged." html))
           (assert (search "data-fedwiki-item-id='1111111111111111'" (substitute #\' #\" html)) () "no Item id in ~A" html)
           (assert (search "data-fedwiki-slug='original-editor-test'" (substitute #\' #\" html)))
           (assert (search "data-fedwiki-site='fedwiki:original-editor-test.invalid'" (substitute #\' #\" html))))
         ;; Acceptance 3: not offered read-only; its text is not duplicated into an editor of ours.
         (let ((editor (%view-html item "Original Wiki editor")))
           (assert (not (search "<iframe" editor)))
           (assert (search "not offered" editor))
           (assert (search "1111111111111111" editor))))
       (let* ((isolated (%configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ "http://127.0.0.1:41234")
                                        (cons cfg:+mode-variable+ "isolated-loopback")))
              (observation (demo:read-stored-page isolated))
              (item (%paragraph-item observation))
              (editor (%view-html item "Original Wiki editor"))
              (sha (dreyeck/local-fedwiki-page:page-source-sha256 (demo::source-of observation))))
         (assert (= 1 (count-matches "<iframe" editor)))
         (assert (some (lambda (amp)
                         (search (format nil "http://127.0.0.1:41234/view/original-editor-test?hyperdocItem=1111111111111111~Arevision=~A" amp sha)
                                 editor))
                       '("&" "&amp;")))
         (assert (search "original-paragraph-editor" editor)))
       (assert (equalp before (%snapshot site)) () "the demonstration wrote to the site")
       ;; Identity, not position: the same two Items in the other order.
       (let* ((swapped (let* ((json (shasht:read-json +fixture+))
                              (story (gethash "story" json)))
                         (setf (gethash "story" json) (vector (aref story 1) (aref story 0)))
                         (with-output-to-string (out) (shasht:write-json json out)))))
         (%write-fixture site swapped)
         (let* ((observation (demo:read-stored-page (%configuration (cons cfg:+root-variable+ site))))
                (item (%paragraph-item observation)))
           (assert (typep item 'demo::inspector-paragraph-item))
           (assert (typep (%code-item observation) 'demo::inspector-code-item)))))))
  t)

(defun check-modes-and-no-write ()
  "Read-only shows the stored page and withholds the frame; isolated-loopback embeds exactly the configured frame. Neither
writes: the site's files are the same octets afterwards."
  (ct:call-with-site-directory
   (lambda (site)
     (%write-fixture site)
     (let ((before (%snapshot site)))
       (let* ((configuration (%configuration (cons cfg:+root-variable+ site)
                                             (cons cfg:+origin-variable+ "http://127.0.0.1:41234")))
              (observation (demo:read-stored-page configuration))
              (item (%code-item observation))
              (editor (%view-html item "Original Wiki editor")))
         (assert (eq :read-only (cfg:configuration-mode configuration)))
         (assert (typep observation 'demo:stored-page))
         (assert (search "(defun square (x) (* x x))" (%view-html observation "Stored Wiki page")))
         ;; Positive control for %CONTROLS-OF-VIEWS: a configured stored page does offer the reviewed reread.
         (assert (some (lambda (reference) (typep (cdr reference) 'dreyeck/authority-policy:reviewed-thunk))
                       (%controls-of-views observation))
                 () "the configured stored page offers no reread control")
         (assert (not (search "<iframe" editor)))
         (assert (search "not offered" editor))
         (assert (search "fedwiki:original-editor-test.invalid" editor)))
       (let* ((configuration (%configuration (cons cfg:+root-variable+ site)
                                             (cons cfg:+origin-variable+ "http://127.0.0.1:41234")
                                             (cons cfg:+mode-variable+ "isolated-loopback")))
              (observation (demo:read-stored-page configuration))
              (item (%code-item observation))
              (editor (%view-html item "Original Wiki editor"))
              (sha (dreyeck/local-fedwiki-page:page-source-sha256 (demo::source-of observation))))
         (assert (eq :isolated-loopback-editor (cfg:configuration-mode configuration)))
         (assert (search "<iframe" editor))
         (assert (some (lambda (separator)
                         (search (format nil "http://127.0.0.1:41234/view/original-editor-test?hyperdocCodeItem=2222222222222222~Arevision=~A"
                                         separator sha)
                                 editor))
                       '("&" "&amp;"))
                 () "the frame does not name the observed revision of the one item")
         (assert (= 1 (count-matches "<iframe" editor))))
       (assert (equalp before (%snapshot site)) () "the demonstration wrote to the site"))))
  t)

(defun count-matches (needle haystack)
  (loop for start = 0 then (+ at (length needle))
        for at = (search needle haystack :start2 start)
        while at count t))

(defun run-tests ()
  (check-membership)
  (check-unconfigured-page)
  (check-unreadable-site)
  (check-modes-and-no-write)
  (check-paragraph-item-by-identity)
  (format t "~&FEDWIKI-ORIGINAL-EDITOR-DEMO-PASS: admitted once from this checkout, and loading it again adds nothing; served without a configured site the page says so, signals nothing, links and embeds nothing; an unreadable site is explained read-only; read-only withholds the frame; isolated-loopback embeds the one item's frame at the observed revision; the Paragraph Item is an Inspector object chosen by id, shown in the page's own Story view with its coordinate, and found again after the story is reordered; the site's files are unchanged.~%")
  t)
