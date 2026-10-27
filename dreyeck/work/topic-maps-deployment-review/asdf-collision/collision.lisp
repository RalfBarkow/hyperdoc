;;;; The ASDF Method Collision
(in-package #:topic-maps-deployment-review)

;;; Found while this reading was built, and since corrected (2026-10-27): the first version of the Project Workspace guard of
;;; dreyeck/src/catalog-topic-maps.lisp, defined two
;;; methods whose identity (generic function, qualifiers, specializers) ASDF's own methods already have, so loading the
;;; candidate replaces those ASDF methods instead of adding to them. This file shows the finding as objects:
;;; the candidate's methods (native method objects, now in the image), ASDF's originals (ASDF's own text, since their
;;; method objects are gone once the candidate is loaded), the recorded probe, the consequences, and the proposed
;;; correction. The probe's record is kept unchanged after any correction; the live checks then say what holds then.

(hyperdoc:see (hyperdoc:page "The ASDF Method Collision" :hyperbook "topic-maps-deployment-review"))

;;; The identities the guard occupies, and identities that are free

(defun perform-before-identity () (list #'asdf:perform '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:component))))
(defun operate-before-identity () (list #'asdf:operate '(:before) (list (find-class t) (find-class t))))
(defun method-at (identity) (apply #'find-method (append identity (list nil))))
(defun guard-perform-method () (method-at (perform-before-identity)))
(defun guard-operate-method () (method-at (operate-before-identity)))
(defun method-defined-in (method)
  (let ((source (and method (sb-introspect:find-definition-source method))))
    (and source (namestring (translate-logical-pathname (sb-introspect:definition-source-pathname source))))))
(defun candidate-method-p (method) (let ((file (method-defined-in method))) (and file (search "catalog-topic-maps.lisp" file) t)))

;;; ASDF's originals: its text, read from the SBCL installation that runs this image

(defclass asdf-source-excerpt (source-excerpt)
  ((identity :initarg :identity :reader excerpt-identity :documentation "A function returning the method identity it defines."))
  (:documentation "ASDF's own definition of a method, as ASDF's source text. Whether that method is still the one ASDF
runs is asked of the image when shown."))
(defun asdf-source-root () (merge-pathnames "contrib/asdf/" (sb-int:sbcl-homedir-pathname)))
(defvar *asdf-originals* nil)
(defun asdf-originals ()
  (or *asdf-originals*
      (setf *asdf-originals*
            (list (make-instance 'asdf-source-excerpt :key "asdf:perform-before" :identity #'perform-before-identity
                                 :title "ASDF's perform :before ((o operation) (c component))" :root (asdf-source-root) :path "asdf.lisp"
                                 :start "  (defmethod perform :before ((o operation) (c component))"
                                 :end "(ensure-all-directories-exist (output-files o c)))")
                  (make-instance 'asdf-source-excerpt :key "asdf:operate-before-abl" :identity #'operate-before-identity
                                 :title "ASDF's operate :before (operation-class system &rest args)" :root (asdf-source-root) :path "asdf.lisp"
                                 :start "    (defmethod operate :before (operation-class system &rest args &key &allow-other-keys)"
                                 :end "call that function where you would otherwise have loaded and configured A-B-L.\"))))")))))
(defun asdf-original (key) (or (find key (asdf-originals) :key #'excerpt-key :test #'string=) (error "No ASDF original ~S." key)))

;; The general excerpt view describes a /nix/store file as the Topic Maps snapshot; ASDF's source is not that, so for
;; ASDF's text only the view below applies.
(v:defview source-excerpt-view (excerpt asdf-source-excerpt) (declare (ignore excerpt)) nil)

(v:defview asdf-source-excerpt-view (excerpt asdf-source-excerpt)
  (v:html-view :title "ASDF source" :priority -11
    (multiple-value-bind (text start end) (excerpt-text excerpt)
      (let* ((identity (funcall (excerpt-identity excerpt))) (method (method-at identity)))
        (v:html
          (:div :style "overflow-wrap:anywhere"
           (:h2 (v:esc (excerpt-title excerpt)))
           (:p (v:esc (format nil "ASDF ~A's own text: ~A, characters ~D–~D." (asdf:asdf-version)
                              (namestring (merge-pathnames (excerpt-path excerpt) (excerpt-root excerpt))) start end)))
           (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc text))
           (:h3 "Is this the method ASDF runs now?")
           (:p (v:esc (format nil "Asked of this image when shown: the method with this identity is defined in ~A, so ~A."
                              (or (method-defined-in method) "no file")
                              (if (candidate-method-p method)
                                  "it is the candidate's, and ASDF's own method is no longer in the image"
                                  "it is ASDF's own"))))
           (:p (v:object-ref method :select "Source code" :display "The method ASDF runs now") " · "
               (v:object-ref (first identity) :select "Methods" :display "All methods of its generic function"))
           (reading-links)))))))

;;; The recorded probe

(defclass collision-finding () ()
  (:documentation "The probe's two records, each from one fresh process: ASDF alone, and after loading the guard."))
(defmethod v:text-representation ((f collision-finding)) "Method collision probe, recorded 2026-10-27")
(defvar *collision-finding* (make-instance 'collision-finding))
(defun asdf-collision-finding () *collision-finding*)
(defun collision-record-pathname (mode) (asdf:system-relative-pathname "topic-maps-deployment-review-asdf-collision" (format nil "evidence/~A.sexp" mode)))
(defun collision-record (mode)
  (with-open-file (in (collision-record-pathname mode) :external-format :utf-8)
    (with-standard-io-syntax (let ((*read-eval* nil) (*package* (find-package :keyword))) (read in)))))
(defun collision-probe-excerpt ()
  (make-instance 'source-excerpt :key "probe" :title "The probe: asdf-collision/probe-asdf-method-collision.lisp"
                                 :root (asdf:system-source-directory "topic-maps-deployment-review-asdf-collision")
                                 :path "probe-asdf-method-collision.lisp" :start nil))

(defun replacement-recorded-p ()
  "Whether the record shows both identities moving from ASDF's file to the candidate's, with operate's method count unchanged."
  (let ((baseline (collision-record "baseline")) (guarded (collision-record "with-guard")))
    (flet ((source (record phase key) (getf (getf (getf record phase) key) :source))
           (count-of (record phase key) (getf (getf (getf record phase) key) :methods-of-generic)))
      (and (every (lambda (key) (and (search "asdf.lisp" (source baseline :after key)) (search "asdf.lisp" (source guarded :before key))
                                     (search "catalog-topic-maps.lisp" (source guarded :after key))))
                  '(:operate-before-t-t :perform-before-operation-component))
           (eql (count-of guarded :before :operate-before-t-t) (count-of guarded :after :operate-before-t-t))))))

(defun source-cell (path)
  "A recorded source file by its name, with the whole path as its title."
  (v:html (:code :title (v:esc path) (v:esc (if path (file-namestring path) "—")))))

(v:defview collision-finding-view (finding collision-finding)
  (v:html-view :title "Record" :priority -10
    (let ((baseline (collision-record "baseline")) (guarded (collision-record "with-guard"))
          (tested (file-tested-sha256 (file-named "dreyeck/src/catalog-topic-maps.lisp"))))
      (flet ((cell (record phase key field) (getf (getf (getf record phase) key) field)))
        (v:html
          (:div :style "overflow-wrap:anywhere"
           (:h2 "The method collision probe")
           (:p (:strong "Recorded run. ") (v:esc (format nil "Two fresh processes, ~A (ASDF alone) and ~A (after loading dreyeck/catalog-topic-maps); ~A, ASDF ~A. Showing this record runs nothing."
                                                         (getf baseline :at) (getf guarded :at) (getf guarded :lisp) (getf guarded :asdf))))
           (:p (v:esc (format nil "The guarded run loaded dreyeck/src/catalog-topic-maps.lisp with SHA-256 ~A, ~:[not the bytes the candidate's tests ran on (~A)~;the bytes the candidate's tests ran on~]."
                              (getf guarded :candidate-file-sha256) (equal tested (getf guarded :candidate-file-sha256)) tested)))
           (:h3 "Observed: which method ASDF runs for each identity")
           (:table :class "inspector-table"
            (:tr (:th "Identity") (:th "ASDF alone") (:th "Guard loaded: before") (:th "Guard loaded: after") (:th "Methods of the generic function, before → after"))
            (dolist (key '(:operate-before-t-t :perform-before-operation-component))
              (v:html (:tr (:td (:code (v:esc (string-downcase key))))
                           (:td (source-cell (cell baseline :after key :source)))
                           (:td (source-cell (cell guarded :before key :source)))
                           (:td (source-cell (cell guarded :after key :source)))
                           (:td (v:esc (format nil "~D → ~D" (cell guarded :before key :methods-of-generic) (cell guarded :after key :methods-of-generic))))))))
           (:p (v:esc (if (replacement-recorded-p)
                          "Both identities move from ASDF's file to the candidate's. operate keeps 7 methods: one was replaced, none added. (perform's count grows because loading adds other systems' perform methods; it shows nothing either way.) ASDF's file is named by the path SBCL was built in."
                          "The record does not show the replacement.")))
           (:h3 "Observed: one consequence, on a probe action")
           (:p (v:esc (format nil "An action that relies on ASDF to create its output directory: ASDF alone ~(~S~); guard loaded ~(~S~)."
                              (getf baseline :action-relying-on-asdf-for-its-output-directory)
                              (getf guarded :action-relying-on-asdf-for-its-output-directory))))
           (:p (v:esc (format nil "Compiling a file into a directory that does not yet exist (uiop:compile-file*): ASDF alone ~(~S~); guard loaded ~(~S~). This is why the candidate's recorded runs, which only compile and load, did not notice."
                              (getf baseline :compile-file-into-a-new-directory) (getf guarded :compile-file-into-a-new-directory))))
           (:h3 "Procedure")
           (:p (v:object-ref (collision-probe-excerpt) :select "Source excerpt" :display "The probe") " · records "
               (:code (v:esc (namestring (collision-record-pathname "baseline")))) " and " (:code (v:esc (namestring (collision-record-pathname "with-guard")))))
           (:p "This record stays as it is after a correction. What holds then is asked of the image by "
               (v:object-ref (method-origins) :select "Method origins" :display "the live check") ".")
           (reading-links)))))))

;;; Consequences, the invariant and the correction, as claims

(defvar *collision-claims* nil)
(defun collision-claims ()
  (or *collision-claims*
      (setf *collision-claims*
            (flet ((claim (id class statement evidence sources &optional limit)
                     (make-instance 'review-claim :id id :class class :page "The ASDF Method Collision" :statement statement
                                    :evidence evidence :sources sources :limit limit)))
              (let ((finding (list (asdf-collision-finding))) (originals (asdf-originals)))
                (list
                 (claim "collision-replacement" :observed
                        "Loading the first version of dreyeck/catalog-topic-maps replaced ASDF's operate :before (operation-class system &rest args) and perform :before ((o operation) (c component)) with the guard's two methods."
                        finding (append (list (excerpt "startup:guard-methods")) originals (list (method-origins))))
                 (claim "collision-invariant" :derived
                        "Invariant: code that adds a refusal to ASDF must add methods, never define one with an identity (generic function, qualifiers, specializers) that ASDF's own methods have. defmethod replaces a method of the same identity. The first version of the guard violated this; the corrected guard defines no method on an ASDF generic function."
                        nil (append (list (excerpt "startup:guard-methods")) originals))
                 (claim "collision-scope" :derived
                        "It held in every image that loaded the first version of dreyeck/catalog-topic-maps: the packaged variant once its main had loaded, its check, this reading, and the review's tests."
                        nil (list (excerpt "asd:catalog-topic-maps") (excerpt "main:host") #'c:main))
                 (claim "collision-directories" :observed
                        "After loading the first guard, ASDF no longer created an action's output directories: a probe action relying on it succeeded without the guard and failed with it."
                        finding (list (first originals) (collision-probe-excerpt)) "Observed on the probe's own action.")
                 (claim "collision-tests-missed" :observed
                        "The candidate's recorded runs could not notice: they compile and load, and uiop:compile-file* created the output directory itself, with or without the guard."
                        (append finding (list (evidence "package-check/lisp.log"))) (list (collision-probe-excerpt)))
                 (claim "collision-affected-actions" :inferred
                        "Which real actions were affected is not known. Any action in such an image that writes its output files without creating their directories would fail, for example a bundle or a program operation."
                        nil (list (first originals)) "No real HyperDoc or deployment action was found failing; none was tried.")
                 (claim "collision-abl-check" :inferred
                        "ASDF's refusal to run together with ASDF-BINARY-LOCATIONS was gone. It would have mattered only in an image that loads ASDF-BINARY-LOCATIONS, which nothing here does."
                        nil (list (second originals)))
                 (claim "collision-correction" :observed
                        "The correction is applied: the guard is an explicit check of the Catalog's startup and defines no method on any ASDF generic function. A fresh-process test finds every ASDF method object, and the behaviour the probe action and the ASDF-BINARY-LOCATIONS check give, the same before and after loading it, and it fails for a colliding method it defines on purpose."
                        (list (evidence "after-guard-correction/asdf-methods.log")) (list (proposed-correction) (excerpt "startup:guard") (file-named "scripts/test-asdf-method-preservation.lisp"))
                        "Run by hand with the pinned SBCL in a fresh process. Not run in a Nix sandbox build: see the claim on the Nix check.")
                 (claim "collision-nix-check" :open
                        "The correction's test is part of the package contract in Nix (nix/catalog-topic-maps-check.nix); whether that contract passes in a completed Nix sandbox build is not shown here."
                        nil (list (file-named "nix/catalog-topic-maps-check.nix")) "See Tested and Unverified for what was built and where.")))))))
(defun collision-claim (id) (or (find id (collision-claims) :key #'claim-id :test #'string=) (error "No collision claim ~S." id)))

(defclass proposed-correction () ()
  (:documentation "The correction of the collision as applied, and what shows that it holds."))
(defmethod v:text-representation ((c proposed-correction)) "The correction (applied 2026-10-27)")
(defvar *proposed-correction* (make-instance 'proposed-correction))
(defun proposed-correction () *proposed-correction*)
(defun proposed-identities ()
  (list (list "operate :before ((operation asdf:operation) (component asdf:system))"
              (list #'asdf:operate '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:system))))
        (list "perform :before ((operation asdf:operation) (component asdf:child-component))"
              (list #'asdf:perform '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:child-component))))))

(v:defview proposed-correction-view (correction proposed-correction)
  (v:html-view :title "Correction" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "The correction, as applied on 2026-10-27")
       (:p "The invariant it restores: " (v:object-ref (collision-claim "collision-invariant") :select "Claim" :display "add methods, never take an identity ASDF's own methods have") ". It does so by defining no method on ASDF at all.")
       (:h3 "The change")
       (:p "In " (v:object-ref (file-named "dreyeck/src/catalog-topic-maps.lisp") :select "Candidate file") " the two methods and their flag are gone. The guard is an explicit check that the executable's "
           (v:object-ref #'c:main :select "Source code") " makes before the Catalog starts: " (v:object-ref (excerpt "startup:guard") :select "Source excerpt" :display "the check")
           ". It reads the definition of the system the Catalog is asked to load and of its dependencies, and refuses the Project Workspace and the page-attached system loader before anything is loaded. "
           "The first version's text is kept: " (v:object-ref (excerpt "startup:guard-methods") :select "Historical source" :display "historical source") ".")
       (:h3 "What it does not do")
       (:p "It does not define differently specialized methods to avoid the collision. Those identities are still free in this image, because nothing defines them:")
       (:table :class "inspector-table"
        (:tr (:th "Identity a differently specialized method would have taken") (:th "Free in this image now?"))
        (dolist (entry (proposed-identities))
          (destructuring-bind (label identity) entry
            (let ((taken (method-at identity)))
              (v:html (:tr (:td (:code (v:esc label)))
                           (:td (if taken (v:html "taken by " (v:object-ref taken :select "Source code")) (v:esc "free: no method has it")))))))))
       (:p "What it gives up: it is made once, at startup, and does not refuse a later load by other means (" (v:object-ref (claim "guard-scope") :select "Claim" :display "the guard's scope") ").")
       (:h3 "What accompanies it, in fresh processes")
       (:ol
        (:li "Method preservation and behaviour: " (v:object-ref (file-named "scripts/test-asdf-method-preservation.lisp") :select "Candidate file")
             ", its record " (v:object-ref (evidence "after-guard-correction/asdf-methods.log") :select "Record") ". A colliding method defined on purpose makes it fail.")
        (:li "Project Workspace and page-attached loader exclusion: the package contract's startup suite, " (v:object-ref (evidence "after-guard-correction/contract-lisp.log") :select "Record") ", and the executable's refusal before it listens, " (v:object-ref (evidence "after-guard-correction/executable.log") :select "Record") ".")
        (:li "Catalog isolation: hyperdoc-catalog unchanged apart from HyperDoc's source, " (v:object-ref (evidence "after-guard-correction/derivations-unchanged-x86_64-linux.json") :select "Record") ", and loopback only."))
       (:p "The tested files of the candidate are tested anew, so their SHA-256 is that of the corrected runs. "
           (v:object-ref (asdf-collision-finding) :select "Record" :display "The probe's record of the defect") " and the first runs' evidence stay as they are.")
       (reading-links)))))

;;; In the existing Workspace: ASDF's originals, the probe and the correction as Topics, with their warrants

(defun collision-warrant ()
  "The existing relation from the guard to ASDF."
  (find "once replaced two methods of" (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of (the-workspace)))
        :key #'tm:topicmap-association-type-of :test #'string=))

(defun extend-workspace ()
  (let* ((workspace (the-workspace)) (projection (tm:topicmap-workspace-projection-of workspace)) (finding (asdf-collision-finding)))
    (unless (tm:topicmap-projection-topic-by-id projection "collision-finding")
      (let ((topics nil) (associations nil) (counter 100))
        (flet ((topic (id label kind status object x y)
                 (push (tm:make-topicmap-topic :id id :type kind :label label :object object
                                               :view-properties (list :x x :y y :visible t :pinned t :kind kind :status status))
                       topics))
               (relate (from type to class provenance evidence &optional note)
                 (push (make-instance 'warranted-association :id (format nil "r~3,'0D" (incf counter)) :type type :from from :to to
                                                             :class class :provenance provenance :evidence evidence :note note)
                       associations)))
          (topic "asdf-perform-original" "perform :before (ASDF's)" "ASDF method" "replaced by the first guard; ASDF's own now" (asdf-original "asdf:perform-before") 1300 480)
          (topic "asdf-operate-original" "operate :before (ASDF's)" "ASDF method" "replaced by the first guard; ASDF's own now" (asdf-original "asdf:operate-before-abl") 1300 120)
          (topic "collision-finding" "Method collision probe" "test execution" "recorded 2026-10-27, of the first guard" finding 1000 120)
          (topic "correction" "The correction" "applied correction" "applied 2026-10-27" (proposed-correction) 700 600)
          (relate "asdf" "defines" "asdf-perform-original" :derived (list (asdf-original "asdf:perform-before")) nil)
          (relate "asdf" "defines" "asdf-operate-original" :derived (list (asdf-original "asdf:operate-before-abl")) nil)
          (relate "guard" "replaced" "asdf-perform-original" :observed (list (excerpt "startup:guard-methods")) (list finding)
                  "Observed in the probe's record, of the first version of the guard.")
          (relate "guard" "replaced" "asdf-operate-original" :observed (list (excerpt "startup:guard-methods")) (list finding)
                  "Observed in the probe's record, of the first version of the guard.")
          (relate "collision-finding" "records the replacement by" "guard" :observed (list (collision-probe-excerpt)) (list finding))
          (relate "correction" "changed" "guard" :observed (list (proposed-correction) (excerpt "startup:guard")) (list (evidence "after-guard-correction/asdf-methods.log"))
                  "Applied 2026-10-27: an explicit check of the Catalog's startup instead of two ASDF methods.")
          (relate "correction" "preserves" "asdf-perform-original" :observed (list (proposed-correction)) (list (evidence "after-guard-correction/asdf-methods.log")))
          (relate "correction" "preserves" "asdf-operate-original" :observed (list (proposed-correction)) (list (evidence "after-guard-correction/asdf-methods.log"))))
        (tm:topicmap-workspace-reproject
         workspace (tm:make-topicmap-projection :topics (append (tm:topicmap-projection-topics-of projection) (reverse topics))
                                                :associations (append (tm:topicmap-projection-associations-of projection) (reverse associations))
                                                :view-properties (tm:topicmap-projection-view-properties-of projection)))))
    ;; The existing relation from the guard to ASDF gets the recorded probe as its evidence.
    (let ((warrant (collision-warrant)))
      (unless (member finding (association-evidence warrant))
        (setf (slot-value warrant 'evidence) (append (association-evidence warrant) (list finding)))))
    workspace))
(extend-workspace)
