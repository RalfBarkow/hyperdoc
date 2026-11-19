;;;; Test-instance executor for the native FedWiki fork. PLAN-NEXT remains plan-only.
(require :asdf)
(asdf:load-system "shop3-planning-domains/publication")
(asdf:load-system "dreyeck/fedwiki-page-edit-plan")
(asdf:load-system "ironclad")
(asdf:load-system "shasht")
(asdf:load-system "babel")
(asdf:load-system "cl-ppcre")
(asdf:load-system "alexandria")

(defpackage #:fedwiki-fork
  (:use #:cl)
  (:export #:read-release #:observe-target #:verify-assets #:release-reference
           #:target-reference #:publish-page #:target-origin #:release-slug))
(in-package #:fedwiki-fork)

(defstruct release id slug page manifest)
(defvar *writer* (sb-thread:make-mutex :name "Isolated FedWiki publication"))

(defun digest (bytes)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 bytes)))

(defun decode (bytes)
  (let ((shasht:*read-default-array-format* :vector)
        (shasht:*read-default-object-format* :hash-table)
        (shasht:*read-default-true-value* :true)
        (shasht:*read-default-false-value* :false)
        (shasht:*read-default-null-value* :null))
    (shasht:read-json (babel:octets-to-string bytes :encoding :utf-8))))

(defun required (object name)
  (multiple-value-bind (value present) (gethash name object)
    (unless present (error "Missing JSON field ~A" name))
    value))

(defun read-release (source)
  "Read reviewed bytes. The plan binds the manifest digest, which covers the page and asset digests."
  (let* ((bytes (alexandria:read-file-into-byte-vector (merge-pathnames "release.json" source)))
         (manifest (decode bytes))
         (slug (required manifest "slug")))
    (assert (equal slug "publish-page-test"))
    (let* ((page-bytes (alexandria:read-file-into-byte-vector
                        (merge-pathnames (format nil "pages/~A" slug) source)))
           (page (decode page-bytes))
           (story (required page "story"))
           (ids (map 'list (lambda (item) (required item "id")) story))
           (assets (remove-if-not (lambda (item) (equal (required item "type") "assets")) story)))
      (assert (equal (digest page-bytes) (required manifest "pageSha256")))
      (assert (and (stringp (required page "title"))
                   (vectorp story) (not (stringp story))
                   (every (lambda (id) (and (stringp id) (plusp (length id)))) ids)
                   (= (length ids) (length (remove-duplicates ids :test #'equal)))
                   (vectorp (required page "journal")) (not (stringp (required page "journal")))
                   (= 1 (length assets))
                   (equal (required (elt assets 0) "id") (required manifest "assetsItem"))
                   (equal (required (elt assets 0) "text") (format nil "pages/~A" slug))
                   (plusp (hash-table-count (required manifest "assets")))
                   (typep (required manifest "forkDate") '(integer 1 *))
                   (plusp (length (required manifest "sourceSite")))))
      (make-release :id (digest bytes) :slug slug :page page :manifest manifest))))

(defun target-origin (fixture)
  (format nil "http://~A.test" (car (last (pathname-directory (truename fixture))))))

(defun request (fixture path &key action cookie-jar)
  "Use only the fixture's private HTTP socket. Never follow redirects or forward a cookie to another origin."
  (uiop:with-temporary-file (:pathname body)
    (let* ((url (concatenate 'string (target-origin fixture) path))
           (args (append (list "/usr/bin/curl" "--disable" "--silent" "--show-error"
                               "--noproxy" "*" "--proto" "=http" "--max-time" "10"
                               "--unix-socket" (namestring (merge-pathnames "wiki.sock" fixture))
                               "--output" (namestring body) "--write-out" "%{http_code}")
                         (when cookie-jar (list "--cookie" (namestring cookie-jar)))
                         (when action (list "--request" "PUT" "--data-urlencode" "action@-"))
                         (list "--" url))))
      (multiple-value-bind (code diagnostic exit)
          (uiop:run-program args
            :input (when action (make-string-input-stream (shasht:write-json action nil)))
            :output :string :error-output :string :external-format :utf-8 :ignore-error-status t)
        (values (if (zerop exit) (parse-integer code) 0)
                (alexandria:read-file-into-byte-vector body)
                diagnostic)))))

(defun observe-target (fixture release)
  "The first value identifies the complete HTTP page representation, including its journal."
  (multiple-value-bind (status bytes diagnostic)
      (request fixture (format nil "/~A.json" (release-slug release)))
    (case status
      (200 (values (digest bytes) (decode bytes)))
      (404 (values :absent nil))
      (otherwise (error "Target read failed: HTTP ~D ~A" status diagnostic)))))

(defun release-reference (release)
  (format nil "manifest-sha256=~A" (release-id release)))

(defun target-reference (fixture release revision)
  (format nil "~A origin=~A slug=~A revision=~A"
          (release-reference release) (target-origin fixture) (release-slug release) revision))

(defun assets-reference (fixture release)
  (format nil "~A assets=~A/assets/pages/~A/ verified-by-sha256"
          (release-reference release) (target-origin fixture) (release-slug release)))

(defun verify-assets (fixture release)
  "Read every asset from the target and compare its bytes with the reviewed manifest."
  (maphash
   (lambda (name sha)
     (unless (cl-ppcre:scan "^[a-z0-9][a-z0-9._-]*\\z" name)
       (error "Invalid asset name ~S" name))
     (multiple-value-bind (status bytes)
         (request fixture (format nil "/assets/pages/~A/~A" (release-slug release) name))
       (unless (and (= 200 status) (equal sha (digest bytes)))
         (return-from verify-assets (values nil (list :asset name :http status :sha256 (digest bytes)))))))
   (required (release-manifest release) "assets"))
  (assets-reference fixture release))

(defun binding-valid-p (plan fixture release revision)
  (let ((facts (dreyeck/shop3:initial-facts-of plan)))
    (and (eq :plan-only (dreyeck/shop3:execution-mode-of plan))
         (equal (dreyeck/shop3:plans-of plan)
                '(((shop3-planning-domains/publication::!propose-publication-step :publish-page))))
         (loop for (key reference) in
               (list (list :release-reviewed (release-reference release))
                     (list :target-ready (target-reference fixture release revision))
                     (list :public-assets-verified (assets-reference fixture release)))
               always (and (member (list 'shop3-planning-domains/publication::observed key)
                                   facts :test #'equal)
                           (equal (loop for (predicate fact value) in facts
                                        when (and (eq predicate 'shop3-planning-domains/publication::evidence-for)
                                                  (eq fact key)) collect value)
                                  (list reference)))))))

(defun fork-action (release)
  (let ((m (release-manifest release)))
    (alexandria:plist-hash-table
     ;; FedWiki retains additional action fields in the journal. This distinguishes
     ;; releases with identical page bytes and fork dates but different asset manifests.
     (list "type" "fork" "site" (required m "sourceSite") "date" (required m "forkDate")
           "releaseSha256" (release-id release)) :test 'equal)))

(defun matches-fork-p (release page)
  ;; Compare the complete approved snapshot with exactly one known action appended.
  (when (hash-table-p page)
    (let ((expected (alexandria:copy-hash-table (release-page release))))
      (setf (gethash "journal" expected)
            (concatenate 'vector (required expected "journal") (vector (fork-action release))))
      (dreyeck/fedwiki-page-edit-plan::%json-equal expected page))))

(defun receipt (release fixture revision target-page status)
  (list :status status :evidence
        (list :public-page-verified (target-reference fixture release revision))
        :title (required target-page "title")
        :item-ids (map 'list (lambda (item) (required item "id")) (required target-page "story"))
        :assets-item (required (release-manifest release) "assetsItem")
        :journal-length (length (required target-page "journal"))
        :fork-site (required (release-manifest release) "sourceSite")
        :fork-date (required (release-manifest release) "forkDate")))

(defun publish-page (plan fixture source expected-revision &key cookie-jar)
  "Consume a native SHOP3 offer. FIXTURE is a private, single-writer test instance.
SOURCE contains the approved release.json and pages/<slug>. Keep its forkDate across retries."
  (sb-thread:with-mutex (*writer*)
    (let ((release (read-release source)))
      (unless (binding-valid-p plan fixture release expected-revision)
        (return-from publish-page (list :status :plan-mismatch)))
      (multiple-value-bind (assets problem) (verify-assets fixture release)
        (unless assets
          (return-from publish-page
            (list :status :reconcile-target :reason problem
                  :evidence (list :target-conflict
                                  (format nil "~A origin=~A changed asset: ~S" (release-reference release)
                                          (target-origin fixture) problem))))))
      (multiple-value-bind (current before) (observe-target fixture release)
        (when (matches-fork-p release before)
          (return-from publish-page (receipt release fixture current before :already-published)))
        (unless (equal current expected-revision)
          (return-from publish-page
            (list :status :reconcile-target :expected expected-revision :observed current
                  :evidence (list :target-conflict (target-reference fixture release current))))))
      (let ((action (fork-action release)))
        (setf (gethash "forkPage" action) (release-page release))
        (let ((status (request fixture (format nil "/page/~A/action" (release-slug release))
                               :action action :cookie-jar cookie-jar)))
          (when (member status '(401 403))
            (return-from publish-page (list :status :unauthorized :http status)))
          ;; A lost response can follow a committed write. Always reread before deciding.
          (multiple-value-bind (revision page) (observe-target fixture release)
            (if (matches-fork-p release page)
                (append (receipt release fixture revision page :published) (list :http status))
                (list :status :unverified :http status :observed revision))))))))
