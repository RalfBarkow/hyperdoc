;;;; Phase 2 probe: HyperDoc's own resolution functions on the fedwiki-java fixtures, offline.
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/fedwiki-link-resolution/evidence/hyperdoc-comparison.lisp
;;;; It changes no implementation file. In this probe image only it adds one recording :AROUND method to
;;;; HYPERBOOK:FIND-PAGE and replaces USOCKET:SOCKET-CONNECT with a recorder that refuses every connection.
(require :asdf)
(asdf:load-asd (merge-pathnames "../../../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "dreyeck/work/fedwiki-link-resolution")
(asdf:load-system "dreyeck/local-fedwiki-page")
(defpackage #:hyperdoc-comparison
  (:use #:cl)
  (:local-nicknames (#:m #:dreyeck/work/fedwiki-link-resolution) (#:fw #:hyperbook/fedwiki)))
(in-package #:hyperdoc-comparison)

(defvar *attempts* '() "Every (HOST PORT) usocket was asked to connect to, newest first.")
(setf (fdefinition 'usocket:socket-connect)
      (lambda (host &optional port &rest arguments)
        (declare (ignore arguments))
        (push (list host port) *attempts*)
        (error 'usocket:ns-host-not-found-error :host-or-ip host)))

(defvar *tracing* nil)
(defvar *trace* '())
(defmethod hyperbook:find-page :around ((wiki fw::fedwiki) id &key signal-error?)
  (declare (ignore signal-error?))
  (when *tracing* (push (list :find-page (fw::domain-name-of wiki) id) *trace*))
  (call-next-method))

(defun out (format &rest args) (let ((*print-pretty* nil)) (format t "~&HYPERDOC-COMPARISON ~?~%" format args)))

;;; H1: journal context, Java Page.context() versus HyperDoc CONTEXT-SITE-REFERENCES.
(dolist (scenario (m:load-scenarios))
  (loop for site being the hash-keys of (gethash "sites" scenario) using (hash-value pages)
        do (loop for slug being the hash-keys of pages using (hash-value page)
                 for journal = (gethash "journal" page)
                 when (and journal (plusp (length journal)))
                   do (let ((java (m:java-page-context (map 'list (lambda (a) (gethash "site" a)) journal)))
                            (hyperdoc (fw::context-site-references (fw::make-journal (fw::copy-page-json journal)))))
                        (when (or java hyperdoc)
                          (out "H1 ~A ~A/~A java=~S hyperdoc=~S ~:[DIFFERENT~;same~]"
                               (gethash "id" scenario) site slug java hyperdoc (equal java hyperdoc)))))))

;;; H2: lookup order on offline FEDWIKI objects (sitemaps from the fixtures; no probe, no plugin fetch).
(defun sitemap (pages)
  (coerce (loop for slug being the hash-keys of pages using (hash-value page)
                collect (let ((spec (make-hash-table :test 'equal)))
                          (setf (gethash "slug" spec) slug (gethash "title" spec) (gethash "title" page))
                          spec))
          'vector))

(defun offline-wiki (name pages)
  (let ((wiki (fw::make-fedwiki name
                                :protocol-probe (constantly "https")
                                :sitemap-fetcher (lambda (w) (fw::fetch-sitemap w :json-fetcher (lambda (url) (declare (ignore url)) (sitemap pages))))
                                :plugin-data-fetcher (lambda (w) (declare (ignore w)) nil))))
    (fw::wait-for-sitemap wiki)
    (setf (gethash name fw::*neighborhood*) wiki)))

(defun lookup (slug page)
  (setf *trace* '())
  (let* ((*tracing* t)
         (found (fw::lookup-slug-in-page-context
                 slug page :plugin-page-resolver (lambda (wiki slug) (push (list :plugin-page (fw::domain-name-of wiki) slug) *trace*) nil))))
    (values (and found (fw::domain-name-of (fw::origin-of found))) (reverse *trace*))))

(dolist (id '("local-first" "context-newest-first" "context-fallthrough" "item-site" "journal-reorder" "not-found"
              "panel-site" "origin-in-context" "attribution-site"))
  (let* ((scenario (find id (m:load-scenarios) :key (lambda (s) (gethash "id" s)) :test #'equal))
         (java (let ((o (m:load-observations)))
                 (find id (coerce (gethash "scenarios" o) 'list) :key (lambda (s) (gethash "id" s)) :test #'equal))))
    (clrhash fw::*neighborhood*)
    (loop for site being the hash-keys of (gethash "sites" scenario) using (hash-value pages)
          do (offline-wiki site pages))
    (let* ((own (gethash "origin" fw::*neighborhood*))
           (page (hyperbook:find-page own "welcome-visitors")))
      (fw::set-page-data page (fw::copy-page-json (gethash "welcome-visitors" (gethash "origin" (gethash "sites" scenario)))))
      (multiple-value-bind (resolved consulted) (lookup (gethash "slug" (elt (gethash "links" scenario) 0)) page)
        (out "H2 ~A link1 hyperdoc-resolved=~S consulted=~S java-lineup=~S java-requests=~S"
             id resolved consulted (map 'list (lambda (e) (elt e 1)) (gethash "lineup" java))
             (map 'list (lambda (r) (elt r 0)) (gethash "page_requests" java)))
        (when (string= id "panel-site")
          (let ((on-s1 (hyperbook:find-page (gethash "s1" fw::*neighborhood*) "remote-page")))
            (fw::set-page-data on-s1 (fw::copy-page-json (gethash "remote-page" (gethash "s1" (gethash "sites" scenario)))))
            (let ((remote (fw::lookup-slug-in-page-context "remote-page" page :plugin-page-resolver (constantly nil))))
              (multiple-value-bind (resolved2 consulted2) (lookup "target" remote)
                (out "H2 ~A link2 from ~A (a ~A held by ~A) hyperdoc-resolved=~S consulted=~S"
                     id (fw::domain-name-of (fw::origin-of remote)) (type-of remote)
                     (fw::domain-name-of (hyperbook:hyperbook-of remote)) resolved2 consulted2))
              ;; The same page opened natively in s1's own HyperBook (not as a proxy held by the origin).
              (multiple-value-bind (resolved3 consulted3) (lookup "target" on-s1)
                (out "H2 ~A link2 from s1's own page (a ~A held by ~A) hyperdoc-resolved=~S consulted=~S"
                     id (type-of on-s1) (fw::domain-name-of (hyperbook:hyperbook-of on-s1)) resolved3 consulted3)))))))))

;;; H3: does a LOCAL-FEDWIKI resolve links locally only?
(let* ((root (uiop:ensure-directory-pathname (merge-pathnames (format nil "hyperdoc-comparison-~D/" (random 1000000))
                                                              (uiop:temporary-directory))))
       (welcome (merge-pathnames "pages/welcome-visitors" root)))
  (ensure-directories-exist welcome)
  (with-open-file (s welcome :direction :output :if-exists :supersede)
    (write-string "{\"title\":\"Welcome Visitors\",\"story\":[{\"type\":\"paragraph\",\"id\":\"a\",\"text\":\"[[Missing Page]]\"}],\"journal\":[{\"type\":\"create\"},{\"type\":\"fork\",\"site\":\"remote.example\"}]}" s))
  (setf *attempts* '())
  (clrhash fw::*neighborhood*)
  (let* ((wiki (dreyeck/local-fedwiki-page::make-local-fedwiki root "fedwiki:local.example"))
         (page (hyperbook:find-page wiki "welcome-visitors")))
    (dolist (w (fw::context-of page)) (fw::wait-for-sitemap w))
    (out "H3 loading the local page: context=~S connection-attempts=~S"
         (mapcar #'fw::domain-name-of (fw::context-of page)) (reverse *attempts*))
    (setf *attempts* '())
    (out "H3 lookup with the default plugin-page resolver: ~A; connection-attempts=~S"
         (handler-case (let ((r (fw::lookup-slug-in-page-context "missing-page" page))) (format nil "returned ~S" r))
           (error (c) (format nil "signalled ~S" (type-of c))))
         (reverse *attempts*))
    (setf *attempts* '() *trace* '())
    (multiple-value-bind (resolved consulted) (lookup "missing-page" page)
      (out "H3 lookup with a NIL plugin-page resolver: resolved=~S consulted=~S connection-attempts=~S"
           resolved consulted (reverse *attempts*))))
  (uiop:delete-directory-tree root :validate t))
(out "DONE")
