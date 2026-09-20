(in-package #:dreyeck/page-attached-system-projection/tests)

;;;; What a page-attached definition must be for a Workspace to be
;;;; reconstructed from it.
;;;;
;;;; These tests deliberately assert no fixed topic or association
;;;; counts. The reconstruction used to require exactly three topics and
;;;; two associations, which said only that the first definition it was
;;;; written against defines two systems. A genuine page-attached
;;;; definition with one system was refused although every step of the
;;;; reconstruction worked for it.

(defparameter +contract-projection+ :dreyeck/page-attached-system-projection)

(defun contract-check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun page-asset-directories ()
  (directory (merge-pathnames ".wiki/wiki.ralfbarkow.ch/assets/pages/*/"
                              (user-homedir-pathname))))

(defun with-page-assets-registered (thunk)
  "Run THUNK with the local page assets visible to ASDF, and only then."
  (let ((asdf/system-registry:*central-registry*
          (append (page-asset-directories)
                  asdf/system-registry:*central-registry*)))
    (funcall thunk)))

(defun eligibility-of (designator)
  (uiop:symbol-call +contract-projection+
                    :page-attached-workspace-eligibility designator))

(defun reconstruct (designator)
  (uiop:symbol-call +contract-projection+
                    :reconstruct-page-attached-workspace designator))

(defun refuses-p (designator)
  "Whether reconstruction refuses DESIGNATOR, and with what reason."
  (handler-case (progn (reconstruct designator) nil)
    (error (condition) (princ-to-string condition))))

(defun check-reconstructed (designator)
  "A reconstruction must produce a workspace standing at its definition."
  (let* ((witness (reconstruct designator))
         (base (getf witness :base-projection))
         (workspace (getf witness :workspace-projection)))
    (contract-check (eq :fresh-image-runner (getf witness :ready-for))
                    "~A reconstructed but is not ready for the runner."
                    designator)
    (contract-check (getf witness :workspace)
                    "~A produced no workspace." designator)
    (contract-check (not (eq workspace (getf witness :materialized-projection)))
                    "~A materialized into the same projection." designator)
    (contract-check
     (string= (format nil "asd:~A" (namestring (getf witness :asd)))
              (getf witness :current-topic-id))
     "~A stands at ~S rather than at its definition."
     designator (getf witness :current-topic-id))
    ;; Shape, not size. The workspace projection adds exactly one topic
    ;; and one association, whatever the definition defines.
    (contract-check
     (= (1+ (length (dreyeck/topicmap:topicmap-projection-topics-of base)))
        (length (dreyeck/topicmap:topicmap-projection-topics-of workspace)))
     "~A added ~D topics instead of one." designator
     (- (length (dreyeck/topicmap:topicmap-projection-topics-of workspace))
        (length (dreyeck/topicmap:topicmap-projection-topics-of base))))
    (contract-check
     (= (1+ (length (dreyeck/topicmap:topicmap-projection-associations-of base)))
        (length (dreyeck/topicmap:topicmap-projection-associations-of workspace)))
     "~A added more than one association." designator)
    witness))

(defun run-page-attached-workspace-contract-tests ()
  ;; Both witnesses are pages in a local wiki, not files in this
  ;; repository. Where that wiki is not mounted there is nothing to hold
  ;; the contract against, and saying so is better than failing as
  ;; though the contract had broken.
  (unless (page-asset-directories)
    (format t "~&PAGE-ATTACHED-WORKSPACE-CONTRACT-SKIPPED: no local page ~
assets are mounted, so neither witness is present.~%")
    (return-from run-page-attached-workspace-contract-tests :skipped))
  (with-page-assets-registered
    (lambda ()
      ;; 1. The old positive case: a definition with a principal and a
      ;;    test system. It must keep working.
      (let ((witness (check-reconstructed "related-topics-for-topic")))
        (contract-check (= 2 (length (getf witness :defined-systems)))
                        "The two-system witness now defines ~D systems."
                        (length (getf witness :defined-systems))))
      ;; 2. The case the old contract refused: one principal system, no
      ;;    test system, genuinely attached to a page.
      (let ((witness (check-reconstructed "a-critic-for-lisp")))
        (contract-check (= 1 (length (getf witness :defined-systems)))
                        "The one-system witness defines ~D systems."
                        (length (getf witness :defined-systems))))
      ;; A test system is therefore not required.
      (contract-check
       (getf (eligibility-of "a-critic-for-lisp") :eligible-p)
       "A page-attached definition without a test system is ineligible.")
      ;; 3. A repository-wide definition must not qualify. Under the old
      ;;    contract it failed only by counting wrong, which would have
      ;;    become a pass the moment the counts were relaxed.
      (let ((refusal (refuses-p "dreyeck/topicmap")))
        (contract-check refusal
                        "The repository-wide definition was accepted as a ~
page-attached workspace.")
        (contract-check (search "page" refusal :test #'char-equal)
                        "The repository-wide definition was refused for a ~
reason unrelated to page attachment: ~A" refusal))
      (contract-check
       (not (getf (eligibility-of "dreyeck/topicmap") :page-attached-p))
       "dreyeck.asd is being treated as a page's own definition.")
      ;; 4. A system with no definition file at all is refused, and says
      ;;    so rather than failing inside a projection.
      (let ((refusal (refuses-p "uiop")))
        (contract-check refusal "A system with no source file was accepted.")
        (contract-check (search "source file" refusal)
                        "A system with no source file was refused with: ~A"
                        refusal))))
  (format t "~&PAGE-ATTACHED-WORKSPACE-CONTRACT-PASS: one-system and ~
two-system page definitions reconstruct; repository-wide and built-in ~
systems do not.~%")
  t)
