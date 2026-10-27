(in-package #:topic-maps-deployment-review/tests)

(defun run-collision-tests ()
  "The collision reading: rendering runs nothing, every link reaches its object, the record says what it says, the
claims keep observed apart from derived, inferred and open, and the Workspace relations are warranted."
  (let* ((*checks* nil) (workspace (r:the-workspace)) (projection (tm:topicmap-workspace-projection-of workspace))
         (page (r:review-page "The ASDF Method Collision")) (git-before (git-state)) (loaded-before (asdf:already-loaded-systems))
         (finding (r::asdf-collision-finding)))
    ;; Rendering the page and every new object's views runs, writes and loads nothing.
    (render-all page)
    (dolist (object (append (list finding (r::proposed-correction) (r::method-origins) (r::collision-warrant))
                            (r::asdf-originals) (r::collision-claims)))
      (render-all object))
    ;; ASDF's own methods are in the image again; their source is at the path SBCL was built in, so only their Generic view is rendered.
    (dolist (method (list (r::guard-perform-method) (r::guard-operate-method))) (v:view-html (view method "Generic")))
    (check :collision-rendering-writes-nothing (equal git-before (git-state)))
    (check :collision-rendering-loads-nothing (equal loaded-before (asdf:already-loaded-systems)))
    ;; Every link of the page reaches its object and view; the method links are the very method objects.
    (multiple-value-bind (exprs page-refs) (page-links "The ASDF Method Collision")
      (let ((linked (mapcar (lambda (link) (let ((object (evaluate (first link))))
                                             (check :collision-link-object object)
                                             (when (second link) (check :collision-link-view (view object (second link))))
                                             object))
                            exprs)))
        (check :methods-are-the-native-objects
               (and (member (find-method #'asdf:perform '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:component))) linked :test #'eq)
                    (member (find-method #'asdf:operate '(:before) (list (find-class t) (find-class t))) linked :test #'eq)
                    (member #'asdf:perform linked :test #'eq) (member #'asdf:operate linked :test #'eq)))
        (check :every-collision-claim-linked (every (lambda (c) (member c linked :test #'eq)) (r::collision-claims))))
      (dolist (title page-refs) (check :collision-page-link (r:review-page title))))
    ;; The record says what was observed, and it is about the tested bytes.
    (check :recorded-replacement (r::replacement-recorded-p))
    (let ((guarded (r::collision-record "with-guard")) (baseline (r::collision-record "baseline")))
      ;; The record is of the first version of the guard, kept verbatim; the candidate's file is the corrected one.
      (check :record-is-of-the-first-guard
             (let ((first-version (r::sha256-hex (r::octets-of (merge-pathnames "evidence/catalog-topic-maps-before-correction.lisp"
                                                                                (asdf:system-source-directory "topic-maps-deployment-review-asdf-collision"))))))
               (and (equal (getf guarded :candidate-file-sha256) first-version)
                    (not (equal first-version (r:file-sha256-now (r:file-named "dreyeck/src/catalog-topic-maps.lisp")))))))
      (check :historical-excerpt-is-the-first-guard
             (let ((text (r:excerpt-text (r:excerpt "startup:guard-methods"))))
               (and (search "(defmethod asdf:operate :before" text) (search "(defmethod asdf:perform :before" text)
                    (not (search "(defmethod asdf:operate :before" (uiop:read-file-string (r::root-path "dreyeck/src/catalog-topic-maps.lisp")))))))
      (check :recorded-consequence (and (eq :succeeded (getf baseline :action-relying-on-asdf-for-its-output-directory))
                                        (consp (getf guarded :action-relying-on-asdf-for-its-output-directory))
                                        (eq :succeeded (getf guarded :compile-file-into-a-new-directory)))))
    ;; ASDF's originals are ASDF's text, and the image is asked whose method has their identity now.
    (check :originals-are-asdf-text
           (every (lambda (e) (and (search "(defmethod " (r:excerpt-text e)) (search "asdf.lisp" (namestring (merge-pathnames "asdf.lisp" (r::excerpt-root e))))))
                  (r::asdf-originals)))
    (check :live-check-names-the-current-owner
           (every (lambda (e) (search (cl-who:escape-string
                                       (if (r::candidate-method-p (r::method-at (funcall (r::excerpt-identity e))))
                                           "it is the candidate's" "it is ASDF's own"))
                                      (html e "ASDF source")))
                  (r::asdf-originals)))
    (check :no-general-excerpt-view-for-asdf (notany (lambda (e) (find "Source excerpt" (html-views e) :key #'v:view-title :test #'equal)) (r::asdf-originals)))
    ;; Claims: observed apart from derived, inferred and open; inferred and open ones carry no recorded proof of themselves.
    (let ((classes (mapcar #'r:claim-class (r::collision-claims))))
      (check :all-four-classes (every (lambda (c) (member c classes)) '(:observed :derived :inferred :open))))
    (check :observed-collision-claims-have-the-record
           (every (lambda (c) (or (not (eq :observed (r:claim-class c))) (r:claim-evidence c))) (r::collision-claims)))
    (check :inferred-and-open-have-no-record
           (every (lambda (c) (or (member (r:claim-class c) '(:observed :derived)) (null (r:claim-evidence c)))) (r::collision-claims)))
    (check :proposed-identities-free (every (lambda (entry) (null (r::method-at (second entry)))) (r::proposed-identities)))
    ;; The Workspace: the relation to ASDF carries the record; the new relations are warranted; Point reaches them.
    (check :warrant-to-asdf-carries-the-record (member finding (r:association-evidence (r::collision-warrant))))
    (dolist (id '("asdf-perform-original" "asdf-operate-original" "collision-finding" "correction"))
      (check :collision-topic-present (tm:topicmap-projection-topic-by-id projection id)))
    (check :collision-topics-hold-objects
           (and (eq (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id projection "collision-finding")) finding)
                (eq (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id projection "asdf-perform-original")) (r::asdf-original "asdf:perform-before"))))
    (check :every-relation-still-warranted
           (every (lambda (a) (and (member (r:association-class a) '(:observed :derived :inferred :open))
                                   (or (r:association-provenance a) (r:association-evidence a))
                                   (or (not (eq :observed (r:association-class a))) (r:association-evidence a)
                                       (some (lambda (p) (typep p '(or r::git-observation r::method-origins r::deployment-decision))) (r:association-provenance a)))))
                  (tm:topicmap-projection-associations-of projection)))
    (tm:topicmap-workspace-go-to workspace "asdf")
    (let ((references (refs workspace "Topicmap")))
      (check :point-at-asdf-shows-the-record (and (member (r::collision-warrant) references :test #'eq) (member finding references :test #'eq))))
    (tm:topicmap-workspace-go-to workspace "candidate")
    (format t "~&TOPIC-MAPS-DEPLOYMENT-REVIEW-COLLISION-PASS: ~D assertions; replacement recorded, ~D claims (observed, derived, inferred, open).~%"
            (length *checks*) (length (r::collision-claims)))
    t))
