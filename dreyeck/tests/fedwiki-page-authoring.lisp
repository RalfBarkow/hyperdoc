;;;; FedWiki page authoring (M0): capability, refusals, serialization.
;;;;
;;;; Every site here is a temporary directory made and removed by the test.
;;;; Races are placed, not waited for: a barrier holds each worker right
;;;; after it has read the page, so the interleaving a lock must prevent is
;;;; the one that happens.

(defpackage #:dreyeck/fedwiki-page-authoring/tests
  (:use #:cl)
  (:local-nicknames (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:fa #:dreyeck/fedwiki-assets)
                    (#:mat #:dreyeck/fedwiki-page-materialization)
                    (#:bt #:bordeaux-threads)
                    (#:views #:html-inspector-views))
  (:export #:run-fedwiki-page-authoring-tests))

(in-package #:dreyeck/fedwiki-page-authoring/tests)

;;; Pages

(defun obj (&rest plist)
  (let ((object (make-hash-table :test #'equal)))
    (loop for (key value) on plist by #'cddr do (setf (gethash key object) value))
    object))

(defun json (value) (let ((*print-pretty* nil)) (shasht:write-json value nil)))

(defvar *next-id* 0)
(defun next-id () (format nil "~(~16,'0X~)" (incf *next-id*)))

(defun topic (topic label kind page)
  (obj "id" (next-id) "type" "work-topic" "topic" topic "label" label "kind" kind "status" "draft" "page" page))

(defun rel (from relation to)
  (obj "id" (next-id) "type" "work-relationship" "from" from "relation" relation "to" to
       "text" (format nil "~A ~A ~A." from relation to)))

(defun work-items ()
  (list (obj "id" (next-id) "type" "paragraph" "text" "A Work slice.")
        (topic "interaction" "Interaction" "area" "Interaction")
        (topic "operations" "Operations and change" "area" "Operations and Change")
        (topic "connect" "Connect / Associations" "area" "Connect and Associations")
        (topic "work:relation/informs" "informs" "relation" "Relation Contract: informs")
        (topic "work:relation/requires" "requires" "relation" "Relation Contract: informs")
        (rel "interaction" "work:relation/informs" "operations")
        (rel "operations" "work:relation/informs" "connect")))

(defun make-site ()
  "A temporary site root: an empty pages/ and, beside it, a synthetic
status/ file that no page operation may reach."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "dreyeck-page-authoring-~A/" (symbol-name (gensym "RUN-")))
                                (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "pages/" root))
    (ensure-directories-exist (merge-pathnames "status/" root))
    (with-open-file (out (merge-pathnames "status/outside.json" root) :direction :output :external-format :utf-8)
      (write-string "{\"title\":\"Outside pages/\"}" out))
    root))

(defmacro with-site ((root) &body body)
  `(let ((,root (make-site)))
     (unwind-protect (progn ,@body)
       (uiop:delete-directory-tree ,root :validate t))))

(defun make-page (root slug items)
  (mat:materialize-fedwiki-page-json
   (obj "title" slug "story" (coerce items 'vector)
        "journal" (vector (obj "type" "create" "id" (next-id)
                               "item" (obj "title" slug "story" (coerce items 'vector))
                               "date" 1790000000000)))
   root slug :if-exists :supersede))

(defun page (root slug) (fa:read-local-fedwiki-page root slug))
(defun page-bytes (root slug) (uiop:read-file-string (fa:local-fedwiki-page-pathname root slug) :external-format :utf-8))
(defun story (page) (coerce (gethash "story" page) 'list))
(defun journal (page) (coerce (gethash "journal" page) 'list))
(defun rel-item (page from)
  (find-if (lambda (item) (and (equal "work-relationship" (gethash "type" item)) (equal from (gethash "from" item))))
           (story page)))
(defun item-with (page id) (find id (story page) :key (lambda (item) (gethash "id" item)) :test #'equal))

(defun edit-action (item &rest changes)
  (let ((new (alexandria:copy-hash-table item)))
    (loop for (key value) on changes by #'cddr do (setf (gethash key new) value))
    (obj "type" "edit" "id" (gethash "id" item) "item" new "date" (+ 1790000000000 (incf *next-id*)))))

(defun keys (object) (loop for key being the hash-keys of object collect key))

(defun pages-directory-entries (root)
  (mapcar #'file-namestring (uiop:directory-files (merge-pathnames "pages/" root))))

(defun refusal (thunk)
  "The refusal reason THUNK signals, :INVALID-SLUG for a slug refusal, or NIL."
  (handler-case (progn (funcall thunk) nil)
    (pa:fedwiki-page-edit-refused (condition) (pa:page-edit-refusal-reason condition))
    (fa:invalid-fedwiki-page-slug () :invalid-slug)))

;;; A barrier after each worker's first read

(defvar *await-read* nil "Bound in a worker thread: hold its next page read at the barrier.")

(defun call-with-read-barrier (parties timeout thunk)
  "Call THUNK with each worker's first page read held until PARTIES workers
have read or TIMEOUT seconds pass. Returns how many workers met the others."
  (let ((original (fdefinition 'fa:read-local-fedwiki-page))
        (lock (bt:make-lock "read barrier")) (arrived 0) (met 0))
    (setf (fdefinition 'fa:read-local-fedwiki-page)
          (lambda (site-root slug)
            (prog1 (funcall original site-root slug)
              (when *await-read*
                (setf *await-read* nil)
                (bt:with-lock-held (lock) (incf arrived))
                (let ((deadline (+ (get-internal-real-time) (* timeout internal-time-units-per-second))))
                  (loop until (or (>= arrived parties) (> (get-internal-real-time) deadline))
                        do (sleep 0.001))
                  (when (>= arrived parties) (bt:with-lock-held (lock) (incf met))))))))
    (unwind-protect (funcall thunk)
      (setf (fdefinition 'fa:read-local-fedwiki-page) original))
    met))

(defun run-workers (thunks)
  "Run each thunk in its own thread with the read barrier armed; return
their values or conditions, in order."
  (mapcar #'bt:join-thread
          (mapcar (lambda (thunk)
                    (bt:make-thread (lambda () (let ((*await-read* t))
                                                 (handler-case (funcall thunk) (error (condition) condition))))))
                  thunks)))

;;; Tests

(defun test-an-edit ()
  (with-site (root)
    (make-page root "work" (work-items))
    (let* ((capability (pa:make-fedwiki-page-authoring-capability root '("work")))
           (before (page root "work"))
           (a1 (rel-item before "interaction"))
           (action (edit-action a1 "relation" "work:relation/requires"))
           (action-text (json action))
           (expected-text (json a1))
           (edit (pa:edit-fedwiki-page-item capability "work" a1 action))
           (after (page root "work"))
           (stored (item-with after (gethash "id" a1))))
      (assert (equal "work:relation/requires" (gethash "relation" stored)))
      (assert (string= (json (gethash "item" action)) (json stored)))
      (assert (equal (mapcar (lambda (item) (gethash "id" item)) (story before))
                     (mapcar (lambda (item) (gethash "id" item)) (story after))))
      (loop for old in (story before) for new in (story after)
            unless (eq old a1) do (assert (string= (json old) (json new))))
      ;; The journal gained exactly the ordinary Action.
      (assert (= (1+ (length (journal before))) (length (journal after))))
      (assert (string= action-text (json (car (last (journal after))))))
      ;; Ordinary FedWiki, with no validation evidence stored.
      (assert (equal '("title" "story" "journal") (keys after)))
      (dolist (entry (journal after)) (assert (equal '("type" "id" "item" "date") (keys entry))))
      (assert (not (search "expected" (page-bytes root "work") :test #'char-equal)))
      (assert (not (search "capability" (page-bytes root "work") :test #'char-equal)))
      ;; The caller's objects are as they were.
      (assert (string= action-text (json action)))
      (assert (string= expected-text (json a1)))
      ;; The result says what happened.
      (assert (equal "work" (pa:page-edit-slug edit)))
      (assert (equal (gethash "id" a1) (pa:page-edit-item-id edit)))
      (assert (string= expected-text (json (pa:page-edit-previous-item edit))))
      (assert (string= action-text (json (pa:page-edit-action edit))))
      ;; Only the page file is in pages/; the status namespace is untouched.
      (assert (equal '("work") (pages-directory-entries root)))
      (assert (string= "{\"title\":\"Outside pages/\"}"
                       (uiop:read-file-string (merge-pathnames "status/outside.json" root))))
      edit)))

(defun test-refusals ()
  (with-site (root)
    (make-page root "work" (work-items))
    (make-page root "dups" (let ((items (work-items))) (append items (list (alexandria:copy-hash-table (car (last items)))))))
    (let* ((capability (pa:make-fedwiki-page-authoring-capability root '("work" "dups" "absent-page")))
           (page (page root "work"))
           (a2 (rel-item page "operations"))
           (dup (car (last (story (page root "dups"))))))
      (flet ((changed (item key value) (let ((copy (alexandria:copy-hash-table item))) (setf (gethash key copy) value) copy))
             (refused (reason slug thunk)
               (let ((bytes (page-bytes root slug)))
                 (assert (eq reason (refusal thunk)) () "Expected ~S." reason)
                 (assert (string= bytes (page-bytes root slug))))))
        (refused :stale "work" (lambda () (pa:edit-fedwiki-page-item capability "work" (changed a2 "text" "old")
                                                                     (edit-action a2 "text" "new"))))
        (refused :stale "work" (lambda () (pa:edit-fedwiki-page-item capability "work" (changed a2 "relation" "requires")
                                                                     (edit-action a2 "text" "new"))))
        (refused :absent-id "work" (lambda () (let ((action (edit-action a2 "text" "new")))
                                                (setf (gethash "id" action) "ffffffffffffffff"
                                                      (gethash "id" (gethash "item" action)) "ffffffffffffffff")
                                                (pa:edit-fedwiki-page-item capability "work" a2 action))))
        (refused :duplicate-id "dups" (lambda () (pa:edit-fedwiki-page-item capability "dups" dup (edit-action dup "text" "new"))))
        (refused :id-mismatch "work" (lambda () (let ((action (edit-action a2 "text" "new")))
                                                  (setf (gethash "id" (gethash "item" action)) "ffffffffffffffff")
                                                  (pa:edit-fedwiki-page-item capability "work" a2 action))))
        (refused :no-change "work" (lambda () (pa:edit-fedwiki-page-item capability "work" a2 (edit-action a2))))
        (refused :malformed "work" (lambda () (pa:edit-fedwiki-page-item capability "work" nil (edit-action a2 "text" "new"))))
        (refused :no-capability "work" (lambda () (pa:edit-fedwiki-page-item nil "work" a2 (edit-action a2 "text" "new"))))
        (refused :outside-capability "work"
                 (lambda () (pa:edit-fedwiki-page-item (pa:make-fedwiki-page-authoring-capability root '("other"))
                                                       "work" a2 (edit-action a2 "text" "new"))))
        (refused :action-not-permitted "work"
                 (lambda () (pa:edit-fedwiki-page-item (pa:make-fedwiki-page-authoring-capability root '("work") :actions '())
                                                       "work" a2 (edit-action a2 "text" "new"))))
        (refused :action-not-permitted "work"
                 (lambda () (let ((action (edit-action a2 "text" "new")))
                              (setf (gethash "type" action) "remove")
                              (pa:edit-fedwiki-page-item capability "work" a2 action))))
        (refused :invalid-slug "work" (lambda () (pa:edit-fedwiki-page-item capability "../status/outside.json" a2
                                                                            (edit-action a2 "text" "new"))))
        (assert (eq :no-page (refusal (lambda () (pa:edit-fedwiki-page-item capability "absent-page" a2
                                                                            (edit-action a2 "text" "new"))))))
        ;; A capability is made only for page slugs and the edit Action.
        (assert (eq :invalid-slug (refusal (lambda () (pa:make-fedwiki-page-authoring-capability root '("../status"))))))
        (assert (handler-case (progn (pa:make-fedwiki-page-authoring-capability root '("work") :actions '("remove")) nil)
                  (error () t)))
        ;; Nothing was added to the page store, and the status namespace is untouched.
        (assert (equal '("dups" "work") (sort (pages-directory-entries root) #'string<)))
        (assert (string= "{\"title\":\"Outside pages/\"}"
                         (uiop:read-file-string (merge-pathnames "status/outside.json" root))))))))

(defun same-page-rounds (root slug capability rounds)
  "ROUNDS rounds of two concurrent edits to Items A and B of SLUG, each with
its own expected Item, both read before either writes if the lock allows it.
Returns the number of rounds that lost an edit."
  (loop repeat rounds
        for round from 0
        count (let* ((page (page root slug)) (a (rel-item page "interaction")) (b (rel-item page "operations"))
                     (action-a (edit-action a "text" (format nil "A ~D" round)))
                     (action-b (edit-action b "text" (format nil "B ~D" round))))
                (call-with-read-barrier
                 2 0.2 (lambda () (run-workers (list (lambda () (pa:edit-fedwiki-page-item capability slug a action-a))
                                                     (lambda () (pa:edit-fedwiki-page-item capability slug b action-b))))))
                (let ((after (page root slug)))
                  (not (and (equal (format nil "A ~D" round) (gethash "text" (rel-item after "interaction")))
                            (equal (format nil "B ~D" round) (gethash "text" (rel-item after "operations")))
                            (= (+ 2 (length (journal page))) (length (journal after)))
                            (subsetp (list (json action-a) (json action-b))
                                     (mapcar #'json (last (journal after) 2)) :test #'string=)))))))

(defun test-same-page-concurrency ()
  (with-site (root)
    (make-page root "shared" (work-items))
    (make-page root "unlocked" (work-items))
    (let ((capability (pa:make-fedwiki-page-authoring-capability root '("shared" "unlocked"))))
      ;; With the page lock, both edits of every round survive.
      (assert (zerop (same-page-rounds root "shared" capability 5)))
      ;; The journal replays to the story it describes.
      (let* ((page (page root "shared"))
             (story (coerce (gethash "story" (gethash "item" (first (journal page)))) 'list)))
        (assert (= 11 (length (journal page))))
        (dolist (entry (rest (journal page)))
          (setf story (substitute-if (gethash "item" entry)
                                     (lambda (item) (equal (gethash "id" item) (gethash "id" entry)))
                                     story)))
        (assert (every (lambda (a b) (string= (json a) (json b))) story (story page))))
      ;; Positive control: without the lock the same rounds lose an edit.
      (let ((original (fdefinition 'pa::%call-with-page-lock)))
        (setf (fdefinition 'pa::%call-with-page-lock)
              (lambda (site-root slug thunk) (declare (ignore site-root slug)) (funcall thunk)))
        (unwind-protect (assert (= 3 (same-page-rounds root "unlocked" capability 3)))
          (setf (fdefinition 'pa::%call-with-page-lock) original))))))

(defun test-different-pages-concurrently ()
  (with-site (root)
    (make-page root "first" (work-items))
    (make-page root "second" (work-items))
    (let* ((capability (pa:make-fedwiki-page-authoring-capability root '("first" "second")))
           (first (page root "first")) (second (page root "second"))
           (a (rel-item first "interaction")) (b (rel-item second "operations"))
           (results nil)
           (met (call-with-read-barrier
                 2 5 (lambda ()
                       (setf results (run-workers
                                      (list (lambda () (pa:edit-fedwiki-page-item capability "first" a (edit-action a "text" "first")))
                                            (lambda () (pa:edit-fedwiki-page-item capability "second" b (edit-action b "text" "second"))))))))))
      ;; Both were inside their transactions at once: the locks are per page.
      (assert (= 2 met))
      (assert (every (lambda (result) (typep result 'pa:fedwiki-page-edit)) results))
      (let ((first-after (page root "first")) (second-after (page root "second")))
        (assert (equal "first" (gethash "text" (rel-item first-after "interaction"))))
        (assert (equal "second" (gethash "text" (rel-item second-after "operations"))))
        (assert (string= (json (rel-item first "operations")) (json (rel-item first-after "operations"))))
        (assert (string= (json (rel-item second "interaction")) (json (rel-item second-after "interaction"))))
        (assert (= (1+ (length (journal first))) (length (journal first-after))))
        (assert (= (1+ (length (journal second))) (length (journal second-after)))))
      (assert (equal '("first" "second") (sort (pages-directory-entries root) #'string<))))))

(defun test-concurrent-materialization-of-one-page ()
  "Writers of one page file, with no page lock, each get a temporary file of
their own: every write succeeds and none is left behind. Each round releases
all writers together, so they ask for a temporary file at the same moment."
  (with-site (root)
    (let* ((writers 8) (rounds 25) (written nil) (lock (bt:make-lock)) (arrived 0)
           (threads (loop for writer below writers
                          collect (let ((writer writer))
                                    (bt:make-thread
                                     (lambda ()
                                       (handler-case
                                           (loop for round below rounds
                                                 for title = (format nil "writer ~D round ~D" writer round)
                                                 do (bt:with-lock-held (lock) (incf arrived))
                                                    (loop until (>= arrived (* writers (1+ round))) do (sleep 0.0001))
                                                    (mat:materialize-fedwiki-page-json
                                                     (obj "title" title "story" (vector) "journal" (vector))
                                                     root "contested" :if-exists :supersede)
                                                    (bt:with-lock-held (lock) (push title written))
                                                 finally (return t))
                                         (error (condition)
                                           ;; Let the others pass the barrier, and report.
                                           (bt:with-lock-held (lock) (incf arrived (* writers rounds)))
                                           condition))))))))
      (let ((results (mapcar #'bt:join-thread threads)))
        (assert (every (lambda (result) (eq t result)) results) () "A writer failed: ~S" results))
      (assert (= (* writers rounds) (length written)))
      (assert (member (gethash "title" (page root "contested")) written :test #'equal))
      (assert (equal '("contested") (pages-directory-entries root))))))

(defun test-inspection (edit)
  (flet ((view-of (object title)
           (let ((view (find title (views:all-views object) :key #'views:view-title :test #'equal)))
             (assert view)
             (values (views:view-html view) (views:view-references view)))))
    (multiple-value-bind (html references) (view-of (pa:page-edit-capability edit) "FedWiki page-authoring capability")
      (dolist (text '("Site root" "Pages" "work" "Allowed Actions" "edit" "not a login"))
        (assert (search text html) () "The capability view lacks ~S." text))
      (assert (null references)))
    (multiple-value-bind (html references) (view-of edit "FedWiki page edit")
      (dolist (text (list "Page" "Item id" (pa:page-edit-item-id edit) "relation"
                          "work:relation/informs" "work:relation/requires" "Verified"))
        (assert (search text html) () "The edit view lacks ~S." text))
      (assert (notany (lambda (entry) (or (eql 0 (search "action-" (car entry))) (eql 0 (search "eval-" (car entry)))))
                      references)))))

(defun test-no-http-and-no-authoring ()
  (let ((direct (mapcar #'asdf:coerce-name (asdf:system-depends-on (asdf:find-system "dreyeck/fedwiki-page-authoring")))))
    (dolist (name '("clog" "clack" "lack" "hunchentoot" "drakma" "quri" "dreyeck/workflow/authoring"))
      (assert (not (member name direct :test #'string-equal))))))

(defun run-fedwiki-page-authoring-tests ()
  (let ((edit (test-an-edit)))
    (test-refusals)
    (test-same-page-concurrency)
    (test-different-pages-concurrently)
    (test-concurrent-materialization-of-one-page)
    (test-inspection edit)
    (test-no-http-and-no-authoring))
  (format t "~&FEDWIKI-PAGE-AUTHORING-PASS: a capability-scoped edit replaces one Item and ~
journals the ordinary Action, verified by reread; stale, absent, duplicate, ~
mismatched and no-change edits and missing or narrower capabilities are ~
refused with no byte changed; concurrent edits of one page both survive, and ~
the unlocked control loses one every round; two pages edit concurrently; ~
concurrent writers of one file each get their own temporary file.~%")
  t)
