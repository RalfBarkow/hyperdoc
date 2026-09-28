(defpackage #:dreyeck/work/deployment-reading/tests
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/work/deployment-reading)
                    (#:views #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/work/deployment-reading/tests)

(defun render-page (book title)
  (let* ((page (hyperbook:find-page book title :signal-error? t))
         (view (find "Content" (views:all-views page)
                     :key #'views:view-title :test #'equal)))
    (assert view)
    (views:view-html view)
    (assert (notany (lambda (reference) (typep (cdr reference) 'condition))
                    (views:view-references view)))
    (values page view)))

(defun run-tests ()
  (let* ((evidence (reading:deployment-evidence))
         (facts (getf evidence :observed))
         (wiki (first facts)) (checkout (second facts)) (service (third facts)))
    (assert (equal (getf evidence :provenance)
                   '(:kind :operator-supplied :observation-time :not-supplied
                     :scope :reported-snapshot :host-probe :not-performed)))
    ;; Exact records guard the minimal witness and keep incidental host data out.
    (assert (equal wiki
                   '(:subject "wiki.ralfbarkow.ch" :kind :deployment-witness
                     :source-commit "b42eb888d6e5d59803667c6320e0779523fc265c"
                     :artifact "/nix/store/q8ppar443gy3ahm33hbbp3b5kwf4j930-wiki-p41-0.41.0-rc.3"
                     :service "wiki.service" :active-state "active" :sub-state "running"
                     :exec-start-program "/nix/store/q8ppar443gy3ahm33hbbp3b5kwf4j930-wiki-p41-0.41.0-rc.3/bin/wiki")))
    (assert (equal checkout
                   '(:subject "dreyeck.ch" :kind :checkout
                     :path "/home/rgb/workspace/hyperdoc"
                     :head "84ee991aa4591a873a63753b89b37737ba5f2efc")))
    (assert (equal service
                   '(:subject "dreyeck.ch" :kind :service
                     :service "hyperdoc.service" :active-state "active" :sub-state "running"
                     :exec-start "nix develop .#tala -c ./scripts/serve-catalog.sh 8080")))
    (assert (= 3 (length facts)))
    (dolist (kind '(:derived :inferred :hypothesized))
      (assert (member kind evidence))
      (assert (null (getf evidence kind))))
    (assert (equal (getf evidence :unresolved)
                   '((:subject "dreyeck.ch" :relation :service-working-directory
                      :status :not-established)
                     (:subject "dreyeck.ch" :relation :service-source-commit
                      :status :not-established))))
    ;; Inspecting or altering a returned snapshot must not change later readings.
    (setf (getf service :active-state) "changed by reader")
    (assert (equal "active" (getf (third (getf (reading:deployment-evidence) :observed))
                                 :active-state))))
  (let* ((book (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t))
         (titles '("Federated Wiki deployment state" "wiki.ralfbarkow.ch deployment"
                   "dreyeck.ch deployment" "Cookie Secret")))
    (assert (equal "Working on HyperDoc" (hyperbook:title-of book)))
    (assert (equal "Work Breakdown" (hyperbook:main-page-id-of book)))
    (assert (null (hyperbook:find-hyperbook "dreyeck/working-on-hyperdoc")))
    (assert (typep (hyperbook:find-page book "Working on HyperDoc" :signal-error? t)
                   'hyperdoc::code-page))
    (multiple-value-bind (landing view) (render-page book "Work Breakdown")
      (declare (ignore landing))
      (dolist (title titles)
        (let* ((page (render-page book title))
               (source (uiop:read-file-string (hyperdoc:file-of page))))
          (assert (member page (mapcar #'cdr (views:view-references view)) :test #'eq))
          (assert (not (search "data-topic=" source)))
          (assert (not (search "data-from=" source))))))
    ;; EXPR must resolve to evidence, not merely render text or a stored condition.
    (multiple-value-bind (page view) (render-page book "Federated Wiki deployment state")
      (declare (ignore page))
      (assert (member (reading:deployment-evidence)
                      (mapcar #'cdr (views:view-references view)) :test #'equal)))
    (let ((source (uiop:read-file-string
                   (hyperdoc:file-of (hyperbook:find-page book "Cookie Secret" :signal-error? t)))))
      (assert (search "Cookie Secret → Session → Session Cookie → wiki-security-friends" source))
      (assert (search "b42eb888d6e5d59803667c6320e0779523fc265c" source)))
    ;; Navigation additions must preserve the existing semantic Work graph.
    (let ((projection (dreyeck/work/reading:work-projection)))
      (assert (= 13 (length (dreyeck/topicmap:topicmap-projection-topics-of projection))))
      (assert (= 14 (length (dreyeck/topicmap:topicmap-projection-associations-of projection))))))
  (format t "~&WORK-DEPLOYMENT-READING-PASS: supplied evidence, separate checkout/service, page navigation and unchanged Work graph.~%")
  t)
