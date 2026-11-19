;;;; Zettel 11806 review: a target that already holds an unmarked fork BEFORE the first PREPARE.
;;;; Drives the regular lineup (PREPARE, the DITA offer, Play in a browser, Recent Changes)
;;;; against one private FedWiki fixture started by run-publish-page.py --serve.
;;;;
;;;; In `nix develop` at the checkout under test:
;;;;   sbcl --non-interactive --load acceptance/ki-plan-next.lisp --load publication/lineup.lisp \
;;;;        --load acceptance/zettel-11806/first-observation-lineup.lisp \
;;;;        --eval '(z11806-first-observation:run :cases)'      ; or :before at the unchanged PR head
;;;; From SLY, after loading the same three files into the HyperDoc image:
;;;;   (z11806-first-observation:run :cases :keep t)
;;;; :KEEP leaves the private FedWiki fixture running, so the returned lineup and Recent Changes
;;;; URLs stay usable; (z11806-first-observation:stop) ends it.

;;;; :before needs no change of the PR head; it shows what the first PREPARE offers there.
;;;; Environment: PLAYWRIGHT_MODULE for the browser check; Z11806_REPORT, optional s-expression report.
(defpackage #:z11806-first-observation
  (:use #:cl)
  (:local-nicknames (#:lineup #:fork-lineup) (#:fork #:fedwiki-fork) (#:hb #:hyperbook))
  (:export #:run #:stop))
(in-package #:z11806-first-observation)

(defparameter *browser* (merge-pathnames "first-observation-lineup.mjs" *load-truename*))
(defvar *records* nil)

(defun puts (book)
  (with-open-file (log (merge-pathnames "requests.jsonl" (lineup::fixture book)))
    (loop for line = (read-line log nil) while line
          count (equal "PUT" (gethash "method" (shasht:read-json line))))))

(defun note (&rest plist)
  (push plist *records*)
  (let ((*print-right-margin* 160)) (format t "~&Z11806 ~S~%" plist))
  (finish-output))

(defun write-legacy-fork (book)
  "An older client's fork: the reviewed page and fork date, without releaseSha256.
Operator setup outside Play, through the fixture's owner session, like CHANGE-TEST-TARGET."
  (sb-thread:with-mutex (fork::*writer*)
    (let* ((release (fork:read-release (lineup::source book)))
           (manifest (fork::release-manifest release))
           (legacy (alexandria:plist-hash-table
                    (list "type" "fork" "site" (gethash "sourceSite" manifest)
                          "date" (gethash "forkDate" manifest)
                          "forkPage" (fork::release-page release)) :test 'equal)))
      (assert (= 200 (fork::request (lineup::fixture book) (format nil "/page/~A/action" (fork:release-slug release))
                                    :action legacy :cookie-jar (lineup::jar book))))
      (multiple-value-bind (revision page) (fork:observe-target (lineup::fixture book) release)
        (let* ((journal (gethash "journal" page)) (last (aref journal (1- (length journal)))))
          (assert (and (equal "fork" (gethash "type" last)) (not (nth-value 1 (gethash "releaseSha256" last)))
                       (not (fork::matches-fork-p release page)))))
        revision))))

(defun start-with-legacy-fork (&key (port 8080))
  "LINEUP:START step for step, except that the legacy fork is written before the first PREPARE."
  (let* ((script (truename (merge-pathnames "../acceptance/run-publish-page.py" lineup::*directory*)))
         (proc (uiop:launch-program (list "python3" (namestring script) "--serve")
                                    :input :stream :output :stream :error-output :stream))
         (ready (read-line (uiop:process-info-output proc) nil))
         (root (or (and ready (uiop:absolute-pathname-p ready) (uiop:directory-exists-p ready))
                   (error "Testwiki konnte nicht starten. ~A" ready)))
         (book (make-instance 'lineup::publication-book :id "test-fedwiki-publish-page" :fixture root :server proc)))
    (setf (gethash "recent-changes" (lineup::pages book))
          (make-instance 'lineup::recent-changes :id "recent-changes" :hyperbook book))
    (note :setup :legacy-fork-before-first-prepare :revision (write-legacy-fork book) :puts (puts book)
          :fixture (namestring root))
    (unless (clog:is-running-p)
      (hyperbook/server:serve-catalog :host "127.0.0.1" :port port :development nil))
    (lineup::check-local-listener)
    (hb:register book)
    (setf lineup:*book* book)
    book))

(defun offer-facts (offer)
  (let ((plan (lineup::plan offer)))
    (list :offer (lineup:page-url offer) :revision (lineup::revision offer)
          :fact-to-shop3 (find-if (lambda (fact) (member (first fact) '(:target-ready :target-conflict)))
                                  (lineup::evidence offer))
          :shop3-offer (lineup::step-of plan) :execution-mode (dreyeck/shop3:execution-mode-of plan)
          ;; No such reader at the unchanged PR head.
          :replacement (ignore-errors (funcall 'lineup::replacement offer)))))

(defun browser (offer mode)
  (multiple-value-bind (out err code)
      (uiop:run-program (list "node" (namestring *browser*) (lineup:page-url offer)
                              (namestring (lineup::fixture (hb:hyperbook-of offer))) mode)
                        :output :string :error-output :string :ignore-error-status t)
    (unless (eql 0 code) (error "Browser check ~A failed (~D):~%~A~%~A" mode code out err))
    (string-trim '(#\Newline) out)))

(defun prepare-case (case book expected-step)
  (let* ((before (puts book)) (offer (lineup:prepare book)))
    (assert (eq expected-step (lineup::step-of (lineup::plan offer))))
    (note :case case :prepare (offer-facts offer) :puts-during-prepare (- (puts book) before))
    offer))

(defun play-case (case offer mode expected-status expected-puts &optional expected-next)
  (let* ((book (hb:hyperbook-of offer)) (before (puts book))
         (out (browser offer mode)) (run (lineup::result offer)))
    (assert (and run (eq expected-status (getf (lineup::receipt run) :status))))
    (assert (= expected-puts (- (puts book) before) (lineup::put-count run)))
    (when expected-next (assert (eq expected-next (lineup::step-of (lineup::next-plan run)))))
    (note :case case :play (hb:id-of run) :run-url (lineup:page-url run) :status (getf (lineup::receipt run) :status)
          :puts (- (puts book) before) :next (and (lineup::next-plan run) (lineup::step-of (lineup::next-plan run)))
          :next-execution-mode (and (lineup::next-plan run) (dreyeck/shop3:execution-mode-of (lineup::next-plan run)))
          :browser out)
    run))

(defun run-cases (book)
  ;; 1. The legacy fork is there at the first PREPARE; no replacement decision.
  (let* ((first (prepare-case 1 book :reconcile-target)))
    (note :case 1 :browser (browser first "reconcile"))
    ;; The executor binds the decision as well: an offer of the pre-fix kind is not executed.
    (let* ((before (puts book))
           (release (lineup::release-of first))
           (old-offer (shop3-planning-domains/publication:plan-next
                       (append (remove-if (lambda (e) (member (first e) '(:target-conflict)))
                                          (lineup::evidence first))
                               (list (list :target-ready (fork:target-reference (lineup::fixture book) release
                                                                                (lineup::revision first)))
                                     (list :public-assets-verified (fork:verify-assets (lineup::fixture book) release))))
                       :completed lineup::*completed*))
           (receipt (fork:publish-page old-offer (lineup::fixture book) (lineup::source book) (lineup::revision first)
                                       :cookie-jar (lineup::jar book))))
      (assert (and (eq :publish-page (lineup::step-of old-offer)) (eq :reconcile-target (getf receipt :status))
                   (= before (puts book))))
      (note :case 1 :executor-without-decision (getf receipt :status) :puts (- (puts book) before)
            :evidence (getf receipt :evidence)))
    ;; 2. Exactly this target revision is approved for replacement.
    (let ((approved (lineup::approve-replacement first)))
      (assert (eq :publish-page (lineup::step-of (lineup::plan approved))))
      (note :case 2 :prepare (offer-facts approved))
      (play-case 2 approved "publish" :published 1 :verify-publication)))
  ;; 4. The same confirmed release once more: a new offer, Play, nothing written.
  (play-case 4 (prepare-case 4 book :publish-page) "repeat" :already-published 0 :verify-publication)
  ;; 3. A decision for one revision, then the target changes before Play.
  (lineup:change-test-target "Zielstand nach der Publikation geändert." book)
  (let* ((changed (prepare-case 3 book :reconcile-target))
         (approved (lineup::approve-replacement changed)))
    (note :case 3 :prepare (offer-facts approved))
    (lineup:change-test-target "Zielstand nach der Ersetzungsentscheidung erneut geändert." book)
    (play-case 3 approved "conflict" :reconcile-target 0 :reconcile-target)
    (note :case 3 :browser (browser (prepare-case 3 book :reconcile-target) "reconcile")))
  (note :recent-changes (lineup:page-url (gethash "recent-changes" (lineup::pages book)))
        :runs (mapcar (lambda (run) (list (hb:id-of run) (getf (lineup::receipt run) :status) (lineup::put-count run)))
                      (reverse (lineup::runs book)))))

(defun run-before (book)
  "At the unchanged PR head: what the first PREPARE offers, and what Play does."
  (let ((offer (prepare-case :before book :publish-page)))
    (play-case :before offer "before" :published 1 :verify-publication)))

(defun stop (&optional (book lineup:*book*))
  "End the private FedWiki fixture of BOOK. The lineup objects stay readable; Play no longer works."
  (when (and book (uiop:process-alive-p (lineup::server book)))
    (close (uiop:process-info-input (lineup::server book)))
    (uiop:wait-process (lineup::server book))))

(defun run (mode &key keep)
  "Run MODE (:CASES or :BEFORE). Return the lineup and Recent Changes URLs and the runs."
  (setf *records* nil)
  (let ((book (start-with-legacy-fork)) (done nil))
    (unwind-protect
         (progn (ecase mode (:cases (run-cases book)) (:before (run-before book)))
                (setf done t)
                (list :lineup (lineup:page-url book)
                      :recent-changes (lineup:page-url (gethash "recent-changes" (lineup::pages book)))
                      :runs (mapcar (lambda (run) (list (hb:id-of run) (lineup:page-url run)
                                                        (getf (lineup::receipt run) :status) (lineup::put-count run)))
                                    (reverse (lineup::runs book)))
                      :fixture (if (and keep done) :running :stopped)))
      (let ((report (uiop:getenv "Z11806_REPORT")))
        (when (and report (plusp (length report)))
          (with-open-file (out report :direction :output :if-exists :supersede :external-format :utf-8)
            (let ((*print-pretty* t) (*print-right-margin* 160)) (format out "~S~%" (reverse *records*))))))
      (unless (and keep done) (stop book)))))
