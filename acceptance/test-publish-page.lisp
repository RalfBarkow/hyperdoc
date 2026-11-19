;;;; Runs only in the private FedWiki instance started by run-publish-page.py.
(asdf:load-system "dreyeck/local-fedwiki-view")
(in-package #:cl-user)

(defun fork-fixture-plan (evidence completed expected)
  (multiple-value-bind (plan facts)
      (shop3-planning-domains/publication:plan-next
       evidence :completed completed :profile :shop3-planning-domains)
    (assert (equal facts (dreyeck/shop3:initial-facts-of plan)))
    (assert (equal (dreyeck/shop3:plans-of plan)
                   (list (list (list 'shop3-planning-domains/publication::!propose-publication-step
                                     expected)))))
    plan))

(defun observed-puts (fixture)
  (with-open-file (log (merge-pathnames "requests.jsonl" fixture))
    (loop for line = (read-line log nil) while line
          count (equal "PUT" (gethash "method" (shasht:read-json line))))))

(defun reject-altered-readbacks (release page)
  ;; Vary one property of the actual HTTP readback at a time.
  (loop for field in '(:title :text :id :order :assets-reference :source-journal
                       :extra-fork :fork-site :fork-date :release-digest)
        for copy = (dreyeck/fedwiki-page-edit-plan::%copy-json page)
        for story = (gethash "story" copy)
        for journal = (gethash "journal" copy)
        for last = (aref journal (1- (length journal)))
        do (ecase field
             (:title (setf (gethash "title" copy) "Different title"))
             (:text (setf (gethash "text" (aref story 0)) "Other text"))
             (:id (setf (gethash "id" (aref story 0)) "other-id"))
             (:order (rotatef (aref story 0) (aref story 1)))
             (:assets-reference (setf (gethash "text" (aref story 2)) "pages/other"))
             (:source-journal (incf (gethash "date" (aref journal 0))))
             (:extra-fork (setf (gethash "journal" copy) (concatenate 'vector journal (vector last))))
             (:fork-site (setf (gethash "site" last) "different.fixture.test"))
             (:fork-date (incf (gethash "date" last)))
             (:release-digest (setf (gethash "releaseSha256" last) "different-release")))
           (assert (not (fedwiki-fork::matches-fork-p release copy)))
        collect field))

(let* ((fixture (truename (uiop:getenv "FORK_FIXTURE")))
       (source (merge-pathnames "source/" fixture))
       (jar (merge-pathnames "owner.jar" fixture))
       (release (fedwiki-fork:read-release source))
       (slug (fedwiki-fork:release-slug release))
       (reference (fedwiki-fork:release-reference release))
       (assets (fedwiki-fork:verify-assets fixture release))
       (page (dreyeck/local-fedwiki-view:make-local-fedwiki-view-page
              source slug :wiki-id "fedwiki:isolated-publish-page-test"))
       (offer (dreyeck/local-fedwiki-view::ensure-page-attached-workspace-offer page))
       (archive (getf (dreyeck/fedwiki-assets:page-attached-asdf-discovery-observation source slug)
                      :asdf-archive))
       (baseline (fedwiki-fork:observe-target fixture release))
       (local (list (list :local-page-present (namestring (merge-pathnames slug (merge-pathnames "pages/" source))))
                    (list :local-content-verified reference)
                    (list :local-attachment-verified (namestring (getf archive :zip)))
                    (list :local-zip-discovery-verified (format nil "~A ~A" (hyperbook:id-of offer) (getf archive :member)))
                    (list :release-reviewed reference)))
       (completed '(:observe-local :fill-local :attach-local :verify-zip-discovery
                    :prepare-release :observe-target :publish-assets))
       (records nil)
       (rejected-fields nil))
  (assert (and assets (equal "workspace:publish-page-test" (hyperbook:id-of offer))))
  (flet ((evidence (revision &optional replacement)
           (append local (list (list :target-ready (fedwiki-fork::ready-reference fixture release revision replacement))
                               (list :public-assets-verified assets))))
         (record (name result expected writes before)
           (assert (eq expected (getf result :status)))
           (assert (= writes (- (observed-puts fixture) before)))
           (assert (eq (eq :public-page-verified (first (getf result :evidence)))
                       (not (null (member expected '(:published :already-published))))))
           (push (list :case name :puts writes :result result) records)
           (format t "~&~A ~S (~D PUT)~%" name expected writes)))
    (let* ((approved (fedwiki-fork:replacement-decision fixture release baseline))
           (offered (fork-fixture-plan (evidence baseline approved) completed :publish-page))
           (before (observed-puts fixture)))
      ;; The existing page differs from the release: no ready target without a decision for it.
      (multiple-value-bind (revision page) (fedwiki-fork:observe-target fixture release)
        (assert (equal '(:target-conflict) (subseq (fedwiki-fork:target-evidence fixture release revision page nil) 0 1)))
        (assert (equal (evidence baseline approved)
                       (append local (list (fedwiki-fork:target-evidence fixture release revision page approved)
                                           (list :public-assets-verified assets))))))
      (record :unapproved-replacement
              (fedwiki-fork:publish-page (fork-fixture-plan (evidence baseline) completed :publish-page)
                                         fixture source baseline :cookie-jar jar)
              :reconcile-target 0 before)
      (record :wrong-plan-binding
              (fedwiki-fork:publish-page offered fixture source "different-revision" :cookie-jar jar
                                         :replacement approved)
              :plan-mismatch 0 before)
      (let* ((wrong (subst '(:release-reviewed "different approved manifest")
                           (assoc :release-reviewed local) (evidence baseline approved)))
             (other-plan (fork-fixture-plan wrong completed :publish-page)))
        (record :wrong-release (fedwiki-fork:publish-page other-plan fixture source baseline :cookie-jar jar
                                                          :replacement approved)
                :plan-mismatch 0 before))
      (record :missing-login (fedwiki-fork:publish-page offered fixture source baseline :replacement approved)
              :unauthorized 1 before)
      (assert (equal baseline (fedwiki-fork:observe-target fixture release)))

      ;; Same exclusive writer, ordinary authorized Wiki edit BETWEEN observation and execution.
      (let* ((item (shasht:read-json
                    "{\"id\":\"c2e7839577a01d01\",\"type\":\"paragraph\",\"text\":\"Separate target revision.\"}"))
             (edit (alexandria:plist-hash-table
                    (list "type" "edit" "id" (gethash "id" item) "item" item "date" (* 1000 (- (get-universal-time) 2208988800)))
                    :test 'equal)))
        (assert (= 200 (fedwiki-fork::request fixture (format nil "/page/~A/action" slug)
                                              :action edit :cookie-jar jar))))
      (let* ((before (observed-puts fixture))
             (changed (fedwiki-fork:observe-target fixture release))
             (conflict (fedwiki-fork:publish-page offered fixture source baseline :cookie-jar jar
                                                  :replacement approved)))
        (assert (not (equal baseline changed)))
        (record :changed-revision conflict :reconcile-target 0 before)
        (fork-fixture-plan (append local (list (getf conflict :evidence)))
                           (remove :publish-assets completed) :reconcile-target)
        (assert (equal changed (fedwiki-fork:observe-target fixture release)))

        ;; A decision for the earlier revision does not cover the changed one.
        (record :stale-replacement
                (fedwiki-fork:publish-page (fork-fixture-plan (evidence changed approved) completed :publish-page)
                                           fixture source changed :cookie-jar jar :replacement approved)
                :reconcile-target 0 before)
        ;; Explicit fixture decision to replace this particular changed revision.
        (let* ((decision (fedwiki-fork:replacement-decision fixture release changed))
               (next (fork-fixture-plan (evidence changed decision) completed :publish-page))
               (published (fedwiki-fork:publish-page next fixture source changed :cookie-jar jar
                                                     :replacement decision))
               (verified (getf published :evidence)))
          (record :authorized-fork published :published 1 before)
          (fork-fixture-plan (append (evidence changed decision) (list verified))
                             (cons :publish-page completed) :verify-publication)
          (let* ((before (observed-puts fixture))
                 (current (fedwiki-fork:observe-target fixture release))
                 (repeated (fedwiki-fork:publish-page next fixture source changed :cookie-jar jar
                                                      :replacement decision)))
            (record :repeat repeated :already-published 0 before)
            (multiple-value-bind (observed target-page) (fedwiki-fork:observe-target fixture release)
              (assert (equal current observed))
              (setf rejected-fields (reject-altered-readbacks release target-page)))
            (assert (equal verified (getf repeated :evidence))))))))
  (with-open-file (out (merge-pathnames "results.json" fixture) :direction :output
                       :if-exists :error :external-format :utf-8)
    (let ((shasht:*write-plist-as-object* t)
          (shasht:*symbol-name-function* (lambda (symbol) (string-downcase (symbol-name symbol)))))
      (shasht:write-json
       (list :fixture (fedwiki-fork:target-origin fixture) :offered :publish-page
             :plan-mode :plan-only :plan-archive (getf ki-plan-test:*source* :sha256)
             :release reference :runs (coerce (nreverse records) 'vector)
             :rejected-readback-fields (coerce rejected-fields 'vector)
             :next-step :verify-publication) out))))
