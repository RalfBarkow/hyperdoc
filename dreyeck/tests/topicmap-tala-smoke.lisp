;;;; Extend the existing Topicmap tests, including the real repository projection.
(in-package #:dreyeck/topicmap/tests)

(defun tala-real-workspace ()
  (dreyeck/topicmap::make-topicmap-workspace-for-object
   (dreyeck/git:make-current-git-repository-checkout)))

(defun tala-must-fail (thunk)
  (check (handler-case (progn (funcall thunk) nil) (error () t))
         "Expected an explicit TALA boundary error."))

(defun check-tala-input-identities (input projection)
  (let ((topics (dreyeck/topicmap/tala:tala-input-topics input))
        (associations (dreyeck/topicmap/tala:tala-input-associations input)))
    (check (eq projection (dreyeck/topicmap/tala:tala-input-projection input))
           "TALA replaced the input Projection.")
    (check (= (length topics) (length (dreyeck/topicmap:topicmap-projection-topics-of projection)))
           "TALA lost a Topic.")
    (dolist (entry topics)
      (check (dreyeck/topicmap:topicmap-projection-topic-by-id projection (getf entry :id))
             "TALA introduced an unknown Topic.")
      ;; The key leads back to its Topic through the input that assigned
      ;; it. This used to decode the key, which proved a property of a
      ;; string; it now proves the bijection the projection carries,
      ;; which is what any reader of the SVG would actually follow.
      (check (string= (getf entry :id)
                      (dreyeck/topicmap/tala:tala-input-topic-id
                       input (getf entry :d2-id)))
             "A D2 key does not lead back to its Topic.")
      (check (string= (getf entry :d2-id)
                      (dreyeck/topicmap/tala:tala-input-d2-key
                       input (getf entry :id)))
             "A Topic does not lead to its D2 key."))
    (check (= (length topics)
              (length (remove-duplicates topics :test #'string=
                                         :key (lambda (e) (getf e :d2-id)))))
           "Two Topics share a D2 key.")
    (check (= (length associations)
              (length (dreyeck/topicmap:topicmap-projection-associations-of projection)))
           "TALA lost an Association.")
    (dolist (entry associations)
      (let ((association
              (find (getf entry :id)
                    (dreyeck/topicmap:topicmap-projection-associations-of projection)
                    :key #'dreyeck/topicmap:topicmap-association-id-of :test #'string=)))
        (check association "TALA introduced an unknown Association.")
        (check (and (string= (getf entry :from)
                            (dreyeck/topicmap:topicmap-association-from-of association))
                    (string= (getf entry :to)
                            (dreyeck/topicmap:topicmap-association-to-of association)))
               "TALA changed Association endpoints.")))))

(defun run-tala-input-tests ()
  (let* ((workspace (tala-real-workspace))
         (projection (dreyeck/topicmap:topicmap-projection-of workspace))
         (before (dreyeck/topicmap/tala:projection-state projection))
         (point (dreyeck/topicmap:topicmap-workspace-point-of workspace))
         (input (dreyeck/topicmap/tala:projection-tala-input projection))
         (again (dreyeck/topicmap/tala:projection-tala-input projection)))
    (check-tala-input-identities input projection)
    (check (string= (dreyeck/topicmap/tala:tala-input-source input)
                    (dreyeck/topicmap/tala:tala-input-source again))
           "Real projection conversion is not deterministic.")
    (check (equal (dreyeck/topicmap/tala:tala-input-associations input)
                  (dreyeck/topicmap/tala:tala-input-associations again))
           "Association identity map is not deterministic.")
    (check (equal before (dreyeck/topicmap/tala:projection-state projection)) "Input conversion modified Projection.")
    (check (string= point (dreyeck/topicmap:topicmap-workspace-point-of workspace))
           "Input conversion moved Workspace point.")
    (check (null (dreyeck/topicmap:topicmap-workspace-history-of workspace))
           "Input conversion changed Workspace history.")
    (check (eq :native-svg dreyeck/inspector/topicmap:*topicmap-renderer*)
           "TALA became the default renderer.")
    (check (search "dreyeck-topicmap-canvas"
                   (html-inspector-views:view-html (view-named "Topicmap" workspace)))
           "Native rendering is unavailable.")
    (dreyeck/topicmap:topicmap-workspace-go-to
     workspace (dreyeck/topicmap:topicmap-topic-id-of
                (second (dreyeck/topicmap:topicmap-projection-topics-of projection))))
    (check (string= (dreyeck/topicmap/tala:tala-input-source input)
                    (dreyeck/topicmap/tala:tala-input-source
                     (dreyeck/topicmap/tala:projection-tala-input
                      (dreyeck/topicmap:topicmap-projection-of workspace))))
           "Workspace navigation changed layout input topology.")
    (tala-must-fail (lambda () (dreyeck/topicmap/tala:validate-tala-svg input "<svg/>")))
    ;; Keys must stay distinct exactly where a readable scheme is most
    ;; likely to lose them. Sanitizing is not injective — these four
    ;; Topic IDs all reduce to the same candidate — so the assignment is
    ;; asked to keep them apart rather than trusted to.
    (let* ((colliding '("a:b" "a/b" "a b" "a.b"))
           (assignment (dreyeck/topicmap/tala:assign-d2-keys colliding))
           (keys (mapcar #'cdr assignment)))
      (check (= (length colliding) (length assignment))
             "The key assignment dropped a Topic.")
      (check (= (length keys) (length (remove-duplicates keys :test #'string=)))
             "Colliding Topic IDs were silently aliased to ~S." keys)
      (loop for (topic-id . key) in assignment
            do (check (string= topic-id
                               (car (find key assignment :key #'cdr
                                          :test #'string=)))
                      "Key ~S does not lead back to ~S." key topic-id))
      ;; Deterministic: the same input must give the same keys.
      (check (equal assignment (dreyeck/topicmap/tala:assign-d2-keys colliding))
             "The key assignment is not deterministic."))
    ;; Awkward Topic IDs must still produce a usable key.
    (dolist (id '("" "same label" "A:a/b.c[1]" "ä λ 東京" "9lives"))
      (let ((key (cdr (first (dreyeck/topicmap/tala:assign-d2-keys (list id))))))
        (check (plusp (length key)) "Topic ~S produced an empty key." id)
        (check (alpha-char-p (char key 0))
               "Key ~S for Topic ~S does not start with a letter." key id)
        (check (every (lambda (c) (or (alphanumericp c) (char= c #\_))) key)
               "Key ~S for Topic ~S is not D2-safe." key id)))
    (tala-must-fail
     (lambda () (dreyeck/topicmap/tala:projection-tala-input projection :seed "44"))))
  (format t "TALA input tests passed: real projection, deterministic IDs/endpoints, point independence, native availability, invalid output.~%")
  t)

(defun check-tala-comparison-navigation (comparison)
  (let* ((workspace (dreyeck/inspector/topicmap/tala:comparison-workspace comparison))
         (projection (dreyeck/inspector/topicmap/tala:comparison-projection comparison))
         (rendering (dreyeck/inspector/topicmap/tala:comparison-rendering comparison))
         (input (dreyeck/topicmap/tala:tala-rendering-input rendering))
         (view (view-named "Native / TALA" comparison))
         (html (html-inspector-views:view-html view))
         (actions (remove-if-not
                   (lambda (ref)
                     (and (typep (cdr ref) 'html-inspector-views:thunk)
                          (search (format nil "id='~A' class='dreyeck-topicmap-workspace-action "
                                          (car ref)) html)))
                   (html-inspector-views:view-references view)))
         (reached nil))
    (check (eq projection (dreyeck/topicmap/tala:tala-input-projection input))
           "Native and TALA did not use the same Projection object.")
    (check (search "data:image/svg+xml;base64," html) "TALA image is absent.")
    (check (search "non-interactive" html) "Interaction boundary is not visible.")
    (check (not (search "<script" html :test #'char-equal)) "Comparison added JavaScript navigation.")
    (check (= (length actions) (length (dreyeck/topicmap:topicmap-projection-topics-of projection)))
           "Comparison lost native Topic actions.")
    (dolist (ref actions)
      (let* ((old-point (dreyeck/topicmap:topicmap-workspace-point-of workspace))
             (old-history (copy-list (dreyeck/topicmap:topicmap-workspace-history-of workspace)))
             (topic (html-inspector-views:eval-thunk (cdr ref)))
             (id (dreyeck/topicmap:topicmap-topic-id-of topic)))
        (push id reached)
        (check (eq topic (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
               "Existing action did not reach the original Topic object.")
        (check (equal (if (string= old-point id) old-history (cons old-point old-history))
                      (dreyeck/topicmap:topicmap-workspace-history-of workspace))
               "Comparison action did not preserve Workspace go-to history semantics.")))
    (check (= (length reached) (length (remove-duplicates reached :test #'string=)))
           "Native actions did not reach every distinct Topic.")
    ;; Rendering an already-computed comparison needs no D2 process, even after navigation.
    (check (view-named "Native / TALA" comparison) "Comparison cannot be viewed again.")
    (check (eq rendering (dreyeck/inspector/topicmap/tala:comparison-rendering comparison))
           "Navigation replaced cached TALA rendering.")
    (check (string= (dreyeck/topicmap/tala:tala-input-source input)
                    (dreyeck/topicmap/tala:tala-input-source
                     (dreyeck/topicmap/tala:projection-tala-input
                      (dreyeck/topicmap:topicmap-projection-of workspace))))
           "Navigation changed TALA topology.")))

(defun run-tala-integration-tests ()
  (run-topicmap-view-smoke-tests)
  (run-tala-input-tests)
  (let* ((workspace (tala-real-workspace))
         (base (dreyeck/topicmap:topicmap-workspace-projection-of workspace))
         (before (dreyeck/topicmap/tala:projection-state base))
         (point (dreyeck/topicmap:topicmap-workspace-point-of workspace))
         (comparison (dreyeck/inspector/topicmap/tala:compare-workspace-layouts workspace))
         (projection (dreyeck/inspector/topicmap/tala:comparison-projection comparison))
         (rendering (dreyeck/inspector/topicmap/tala:comparison-rendering comparison))
         (input (dreyeck/topicmap/tala:tala-rendering-input rendering))
         (svg (dreyeck/topicmap/tala:tala-rendering-svg rendering)))
    (check-tala-input-identities input projection)
    (check (equal before (dreyeck/topicmap/tala:projection-state base)) "TALA invocation modified the base projection.")
    (check (string= point (dreyeck/topicmap:topicmap-workspace-point-of workspace))
           "TALA invocation moved the Workspace point.")
    (check (null (dreyeck/topicmap:topicmap-workspace-history-of workspace))
           "TALA invocation changed Workspace history.")
    (check (eq (dreyeck/topicmap:topicmap-projection-topics-of base)
               (dreyeck/topicmap:topicmap-projection-topics-of projection))
           "Comparison replaced original topics.")
    (check (eq (dreyeck/topicmap:topicmap-projection-associations-of base)
               (dreyeck/topicmap:topicmap-projection-associations-of projection))
           "Comparison replaced original associations.")
    (check (dreyeck/topicmap/tala:validate-tala-svg input svg)
           "Not every original Topic and Association occurs exactly once.")
    (check (view-named "D2 input" input) "Input is not Inspector-visible.")
    (check (view-named "TALA rendering proof" rendering) "Result is not Inspector-visible.")
    ;; Duplicate/missing/unknown output groups must fail, not be accepted as proof.
    (let* ((dom (plump:parse svg))
           (group (find-if (lambda (g) (string= "svg" (plump:tag-name (plump:parent g))))
                           (plump:get-elements-by-tag-name dom "g")))
           (class (plump:attribute group "class"))
           (position (search class svg)))
      (tala-must-fail
       (lambda () (dreyeck/topicmap/tala:validate-tala-svg
                   input (concatenate 'string (subseq svg 0 position) "unknown"
                                      (subseq svg (+ position (length class))))))))
    (let ((snapshot (dreyeck/topicmap/tala:projection-state projection)))
      (check-tala-comparison-navigation comparison)
      (check (equal snapshot (dreyeck/topicmap/tala:projection-state projection))
             "Comparison navigation modified projection contents."))
    (format t "TALA real-workspace integration passed: D2 ~A, seed ~D, ~D Topics, ~D Associations, exact SVG identity coverage, native Inspector thunks.~%"
            (dreyeck/topicmap/tala:tala-rendering-version rendering)
            (dreyeck/topicmap/tala:tala-input-seed input)
            (length (dreyeck/topicmap/tala:tala-input-topics input))
            (length (dreyeck/topicmap/tala:tala-input-associations input))))
  t)
