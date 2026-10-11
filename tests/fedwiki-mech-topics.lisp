(in-package :hyperbook/fedwiki/tests)

(defun topics-json (name)
  (with-open-file (in (asdf:system-relative-pathname :hyperbook
                       (concatenate 'string "tests/fixtures/mech-topics/" name)))
    (shasht:read-json in)))

(defun topics-page (&optional (mode :ready))
  "Original page/retained Ward sitemap. READY is a controlled origin-only
selection, not the original browser neighborhood. CONTEXT retains the full
original journal context with unavailable sitemaps; never fill those synthetically."
  (let* ((json (topics-json "pattern-machinery.json"))
         (fw::*neighborhood* (make-hash-table :test #'equal)))
    (dolist (domain '("ward.voices.ustawi.wiki" "thompson.patterns.ustawi.wiki" "thompson.fed.wiki"))
      (setf (gethash domain fw::*neighborhood*)
            (make-instance 'fw::fedwiki :id (concatenate 'string "fedwiki:" domain))))
    (let* ((origin (gethash "ward.voices.ustawi.wiki" fw::*neighborhood*))
           (page (fw::make-fedwiki-page origin "pattern-machinery" "Pattern Machinery"))
           (before (shasht:write-json json nil)))
      (setf (slot-value origin 'fw::protocol) "http")
      (fw::fetch-sitemap origin :json-fetcher
        (lambda (url)
          (assert (equal "http://ward.voices.ustawi.wiki/system/sitemap.json" url))
          (topics-json "ward-sitemap.json")))
      (fw::set-page-data page json)
      ;; Explicit test input selection. Original JSON and item text are untouched.
      (unless (eq mode :context) (setf (slot-value page 'fw::context) nil))
      (case mode
        (:missing (setf (slot-value origin 'fw::sitemap-state) :missing))
        (:loading (setf (slot-value origin 'fw::sitemap-state) :loading))
        (:failed (setf (slot-value origin 'fw::sitemap-state)
                       (make-condition 'simple-error :format-control "Trusted topics fixture failure"))))
      (setf (gethash "pattern-machinery" (fw::pages-of origin)) page)
      ;; Offline link skeletons carry no synthesized content or sitemap data.
      (dolist (link (fw::wiki-links-of (hyperbook:links-of page)))
        (let ((slug (fw::target-slug-of link)))
          (unless (gethash slug (fw::pages-of origin))
            (setf (gethash slug (fw::pages-of origin))
                  (fw::make-fedwiki-page origin slug (or (fw::target-title-of link) slug))))))
      (assert (equal before (shasht:write-json (fw::raw-json-of page) nil)))
      page)))

(defun check-topics-contract ()
  (let* ((page (topics-page))
         (item (find :mech (fw::story-of page) :key #'fw::item-type-of))
         (fw::*mech-plugin-host-url* "https://host.fixture.test/")
         (view (story-view page))
         (html (v:view-html view))
         (snapshot (fw::mech-neighborhood-snapshot page)))
    (assert (equal "3a62aa636c883134" (fw::id-of item)))
    (assert (search "WALK 15 topics" (fw::text-of item)))
    (assert (= 1 (length (gethash "sites" snapshot))))
    (assert (= 45 (length (gethash "sitemap" (aref (gethash "sites" snapshot) 0)))))
    (assert (search "No Code item has run" html))
    (assert (member item (mapcar #'cdr (v:view-references view)) :test #'eq)))
  (let ((sites (gethash "sites" (fw::mech-neighborhood-snapshot (topics-page :context)))))
    (assert (= 3 (length sites)))
    (assert (equalp #("ready" "missing" "missing")
                   (map 'vector (lambda (s) (gethash "state" s)) sites))))
  (format t "~&FEDWIKI-MECH-TOPICS-PASS: original page/ID unchanged, explicit loaded-site control and unavailable historical context.~%"))

(defun serve-topics-browser-witness (port host-url stop-file)
  "Fresh offline Inspector for original Pattern Machinery; no production access."
  (setf fw::*mech-plugin-host-url* host-url)
  (clog:initialize (lambda (body) (declare (ignore body))) :port port :host "127.0.0.1")
  (dolist (mode '(:ready :missing :loading :failed :context))
    (let ((page (topics-page mode)))
      (clog:set-on-new-window
       (lambda (body)
         (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
         (let ((inspector (clog-moldable-inspector::create-inspector body :pane-width "700px" :playground? nil)))
           (clog-moldable-inspector::create-pane inspector page :select "Story")))
       :path (concatenate 'string "/" (string-downcase (symbol-name mode))))))
  (format t "~&MECH-TOPICS-BROWSER-READY ~D~%" port)
  (finish-output)
  (unwind-protect
       (loop repeat 2400 until (probe-file stop-file) do (sleep 0.1))
    (clog:shutdown)))
