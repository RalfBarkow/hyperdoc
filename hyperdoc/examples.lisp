;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Example functions
;;

(see (page "Writing source code pages"))

;; An example is a function of zero arguments.

(defmacro defexample (name &body body)
  "Define an example function NAME with BODY. The syntax is the same as for
DEFUN, except that there is no lambda list because example functions take no
arguments."
  `(defun ,name () ,@body))

;;
;; Convenience functions for inserting assertions into examples
;;

(defun assert-test (fn x y &key (key #'identity))
  (assert (funcall fn (funcall key x) y))
  x)

(defun assert-equalp (x y &key (key #'identity))
  (assert-test #'equalp x y :key key))

(defun assert-equal (x y &key (key #'identity))
  (assert-test #'equal x y :key key))

(defun assert-eql (x y &key (key #'identity))
  (assert-test #'eql x y :key key))

(defun assert-within-tolerance (x y tolerance &key (key #'identity))
  (declare (type number y tolerance))
  (assert-test #'(lambda (x y)
                   (declare (type number x y))
                   (<= (abs (- x y)) tolerance))
               x y :key key))

;;
;; An example example function
;;

(defexample the-answer
  "The answer to the question of life, the universe, and everything."
  (-> 42
      (assert-equal 42)))

;;
;; fedwiki-java translation helpers
;;

(defun fedwiki-java-example-slug-char-p (char)
  (or (alpha-char-p char)
      (digit-char-p char)
      (char= char #\-)))

(defun fedwiki-java-example-slug (text)
  "Approximate the slug logic used in fedwiki-java's Item.links()."
  (coerce (loop for char across text
                for normalized = (if (char= char #\Space) #\- char)
                when (fedwiki-java-example-slug-char-p normalized)
                  collect (char-downcase normalized))
          'string))

(defun fedwiki-java-example-context (journal)
  "Collect distinct site values by walking the journal backward."
  (let (sites)
    (dolist (entry (reverse journal) (nreverse sites))
      (let ((site (getf entry :site)))
        (when (and site (not (member site sites :test #'equal)))
          (push site sites))))))

(defun fedwiki-java-example-resolution-order (origin journal &key item-site)
  "Model the site search order used when following a collaborative link."
  (let ((context (fedwiki-java-example-context journal)))
    (when item-site
      (setf context (remove item-site context :test #'equal))
      (push item-site context))
    (cons origin (remove origin context :test #'equal))))

(defexample fedwiki-java-slug-example
  "Translate a collaborative link label into the slug used for lookup."
  (let* ((input "Collaborative Link")
         (slug (-> input
                   fedwiki-java-example-slug
                   (assert-equal "collaborative-link"))))
    (list :input input
          :slug slug)))

(defexample fedwiki-java-context-example
  "Translate page journal provenance into an ordered context site list."
  (let* ((journal (list (list :site "alpha.example")
                        (list :site nil)
                        (list :site "beta.example")
                        (list :site "alpha.example")
                        (list :site "gamma.example")))
         (context (-> journal
                      fedwiki-java-example-context
                      (assert-equal '("alpha.example" "beta.example" "gamma.example")))))
    (list :journal journal
          :context context)))

(defexample fedwiki-java-resolution-order-example
  "Translate collaborative-link resolution into the ordered site search path."
  (let* ((origin "origin.example")
         (journal (list (list :site "beta.example")
                        (list :site "gamma.example")
                        (list :site "beta.example")))
         (item-site "item.example")
         (order (-> (fedwiki-java-example-resolution-order
                     origin journal :item-site item-site)
                    (assert-equal '("origin.example" "item.example" "beta.example" "gamma.example")))))
    (list :origin origin
          :item-site item-site
          :journal journal
          :resolution-order order)))

;;
;; SD card creation runbook helpers for Playground usage
;;

(defclass sd-card-procedure-step ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (diagnosis :initarg :diagnosis :initform nil :reader diagnosis-of)
   (source-target :initarg :source-target :initform nil :reader source-target-of)
   (patch-target :initarg :patch-target :initform nil :reader patch-target-of)
   (verification :initarg :verification :initform nil :reader verification-of)
   (merge-notes :initarg :merge-notes :initform nil :reader merge-notes-of)
   (commands :initarg :commands :initform nil :reader commands-of)
   (failure-capsule :initarg :failure-capsule :initform nil :reader failure-capsule-of)
   (raw-structure :initarg :raw-structure :initform nil :reader raw-structure-of)))

(defclass sd-card-correction-step (sd-card-procedure-step) ())

(defclass sd-card-runbook-section ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :initform nil :reader summary-of)
   (steps :initarg :steps :reader steps-of)
   (raw-structure :initarg :raw-structure :initform nil :reader raw-structure-of)))

(defclass sd-card-runbook ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (sections :initarg :sections :reader sections-of)
   (raw-structure :initarg :raw-structure :initform nil :reader raw-structure-of)))

(defmethod print-object ((object sd-card-procedure-step) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-runbook-section) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-runbook) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun sd-card-imagesize-correction-step ()
  (let* ((context (kioskberrli-sd-image-failure-context))
         (patch (suggested-patch context))
         (verify (repro-build-command context)))
    (make-instance 'sd-card-correction-step
                   :id "sdimage-imagesize-correction"
                   :title "Correct removed sdImage.imageSize option"
                   :summary "Follow correction path from failing option to patch, verification build, and merge note."
                   :diagnosis
                   "Build fails because current pinned SD-image modules no longer provide sdImage.imageSize."
                   :source-target context
                   :patch-target patch
                   :verification verify
                   :merge-notes
                   "Commit the kiosk.nix correction after successful verification build and integrate through normal branch/merge workflow."
                   :failure-capsule context
                   :commands (list (command-of verify))
                   :raw-structure
                   (list :step :sdimage-imagesize-correction
                         :context context
                         :patch patch
                         :verify verify))))

(defun make-sd-card-runbook-sections
    (&key
       (download-url
        "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")
       (compressed-image "nixos-aarch64.img.zst")
       (raw-image "nixos-aarch64.img")
       (disk "diskN")
       (kioskberrli-root "~/workspace/hauptsache/kioskberrli"))
  (list
   (make-instance 'sd-card-runbook-section
                  :id "path-a-official-prebuilt-image"
                  :title "Path A - Official prebuilt image"
                  :summary "Fetch and verify the official Hydra artifact."
                  :steps
                  (list
                   (make-instance 'sd-card-procedure-step
                                  :id "download-hydra-artifact"
                                  :title "Download artifact from Hydra"
                                  :summary "Download latest aarch64 SD image artifact."
                                  :commands (list (format nil "wget -O ~A \"~A\"" compressed-image download-url))
                                  :raw-structure (list :command (format nil "wget -O ~A \"~A\"" compressed-image download-url)))
                   (make-instance 'sd-card-procedure-step
                                  :id "decompress-image"
                                  :title "Decompress image"
                                  :summary "Decompress the zstd artifact to a raw .img file."
                                  :commands (list (format nil "unzstd -d ~A" compressed-image))
                                  :raw-structure (list :command (format nil "unzstd -d ~A" compressed-image)))
                   (make-instance 'sd-card-procedure-step
                                  :id "verify-checksum"
                                  :title "Verify checksum"
                                  :summary "Verify compressed artifact integrity before flashing."
                                  :commands (list (format nil "shasum -a 256 ~A" compressed-image))
                                  :verification "Checksum must match the published Hydra value."
                                  :raw-structure (list :command (format nil "shasum -a 256 ~A" compressed-image))))
                  :raw-structure
                  (list :section "Path A - Official prebuilt image"))
   (make-instance 'sd-card-runbook-section
                  :id "path-b-build-project-image"
                  :title "Path B - Build project image"
                  :summary "Build kioskberrli SD image from project source."
                  :steps
                  (list
                   (make-instance 'sd-card-procedure-step
                                  :id "build-kioskberrli-sd-image"
                                  :title "Build kioskberrli SD image"
                                  :summary "Run project build for sdImage target."
                                  :commands (list (format nil "cd ~A" kioskberrli-root)
                                                  "nix build .#nixosConfigurations.kioskberrli.config.system.build.sdImage"
                                                  "ls -lah result/sd-image/")
                                  :verification
                                  "result/sd-image must contain the expected artifact."
                                  :raw-structure
                                  (list :command "nix build .#nixosConfigurations.kioskberrli.config.system.build.sdImage"))
                   (sd-card-imagesize-correction-step))
                  :raw-structure
                  (list :section "Path B - Build project image"))
   (make-instance 'sd-card-runbook-section
                  :id "flash-procedure-macos-host"
                  :title "Flash Procedure (macOS host)"
                  :summary "Flash verified raw image to the selected SD-card device."
                  :steps
                  (list
                   (make-instance 'sd-card-procedure-step
                                  :id "flash-image-to-device"
                                  :title "Flash image to SD card device"
                                  :summary "Unmount, dd-write, sync, and eject."
                                  :commands (list "diskutil list"
                                                  (format nil "diskutil unmountDisk /dev/~A" disk)
                                                  (format nil "sudo dd if=~A of=/dev/r~A bs=4m status=progress conv=sync"
                                                          raw-image disk)
                                                  "sync"
                                                  (format nil "diskutil eject /dev/~A" disk))
                                  :diagnosis
                                  "Wrong disk id is destructive. Verify target twice before dd."
                                  :verification "Device ejects cleanly and boots on target hardware."
                                  :raw-structure
                                  (list :command (format nil "sudo dd if=~A of=/dev/r~A bs=4m status=progress conv=sync"
                                                         raw-image disk))))
                  :raw-structure
                  (list :section "Flash Procedure (macOS host)"))
   (make-instance 'sd-card-runbook-section
                  :id "safety-checks"
                  :title "Safety"
                  :summary "Final safeguards before destructive write operations."
                  :steps
                  (list
                   (make-instance 'sd-card-procedure-step
                                  :id "verify-disk-twice"
                                  :title "Verify target disk twice"
                                  :summary "Double-check selected disk identifier before flashing."
                                  :commands (list (format nil "Verify ~A twice before running dd." disk))
                                  :verification "Human confirmation completed before flash."
                                  :raw-structure
                                  (list :command (format nil "Verify ~A twice before running dd." disk))))
                  :raw-structure
                  (list :section "Safety"))))

(defun sd-card-runbook->raw-structure (runbook)
  (loop for section in (sections-of runbook)
        collect
        (list :section (title-of section)
              :commands
              (loop for step in (steps-of section)
                    append (or (commands-of step) '())))))

(defun find-sd-card-runbook-section (runbook section-id)
  (find section-id (sections-of runbook)
        :key #'id-of
        :test #'string=))

(defun find-sd-card-runbook-step (runbook step-id)
  (loop for section in (sections-of runbook)
        thereis (find step-id (steps-of section)
                      :key #'id-of
                      :test #'string=)))

(defun sd-card-creation-command-plan
    (&key
       (download-url
        "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")
       (compressed-image "nixos-aarch64.img.zst")
       (raw-image "nixos-aarch64.img")
       (disk "diskN")
       (kioskberrli-root "~/workspace/hauptsache/kioskberrli"))
  "Return a semantic runbook object for preparing and flashing an aarch64 SD image.
Raw list structure is preserved as a secondary view."
  (let* ((sections (make-sd-card-runbook-sections
                    :download-url download-url
                    :compressed-image compressed-image
                    :raw-image raw-image
                    :disk disk
                    :kioskberrli-root kioskberrli-root))
         (runbook (make-instance 'sd-card-runbook
                                 :id "create-nixos-sd-card-playground-runbook"
                                 :title "Create NixOS SD Card from HyperDoc Playground"
                                 :summary "Correction-path aware runbook object for SD-image preparation, flashing, and integration."
                                 :sections sections)))
    (setf (slot-value runbook 'raw-structure)
          (sd-card-runbook->raw-structure runbook))
    runbook))

(defun sd-card-creation-command-plan-raw (&rest keys &key &allow-other-keys)
  "Backward-compatible raw command-plan list."
  (declare (dynamic-extent keys))
  (sd-card-runbook->raw-structure (apply #'sd-card-creation-command-plan keys)))

(defun sd-card-creation-command-plan-section (section-id)
  (or (find-sd-card-runbook-section (sd-card-creation-command-plan) section-id)
      (error "Unknown SD-card runbook section id: ~A" section-id)))

(defun sd-card-creation-command-plan-step (step-id)
  (or (find-sd-card-runbook-step (sd-card-creation-command-plan) step-id)
      (error "Unknown SD-card runbook step id: ~A" step-id)))

(defun sd-card-creation-dry-run
    (&key (stream *standard-output*)
          (download-url
           "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")
          (compressed-image "nixos-aarch64.img.zst")
          (raw-image "nixos-aarch64.img")
          (disk "diskN")
          (kioskberrli-root "~/workspace/hauptsache/kioskberrli"))
  "Print the SD-card runbook commands without executing shell actions."
  (let ((runbook (sd-card-creation-command-plan
                  :download-url download-url
                  :compressed-image compressed-image
                  :raw-image raw-image
                  :disk disk
                  :kioskberrli-root kioskberrli-root)))
    (format stream "~&SD card creation command plan (dry-run):~%")
    (loop for section in (sections-of runbook)
          do (progn
               (format stream "~&~A~%" (title-of section))
               (loop for step in (steps-of section)
                     for n from 1
                     do (progn
                          (format stream "  ~2D. ~A~%" n (title-of step))
                          (loop for command in (commands-of step)
                                do (format stream "      - ~A~%" command))))))
    (format stream "~&Note: this is a dry-run printout; no shell command was executed.~%")
    runbook))

(defexample sd-card-creation-command-plan-example
  "Return the default command plan used by the SD-card creation runbook page."
  (sd-card-creation-command-plan))

(defexample sd-card-creation-dry-run-example
  "Return a printable dry-run transcript for the default SD-card command plan."
  (with-output-to-string (stream)
    (sd-card-creation-dry-run :stream stream)))

;;
;; hauptsache / kioskberrli reference objects
;;

(defclass kioskberrli-option-existence-evidence ()
  ((option-name :initarg :option-name :reader option-name-of)
   (exists-p :initarg :exists-p :reader exists-p-of)
   (evidence-kind :initarg :evidence-kind :reader evidence-kind-of)
   (explanation :initarg :explanation :reader explanation-of)))

(defmethod print-object ((object kioskberrli-option-existence-evidence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A => ~:[absent~;present~]"
            (option-name-of object)
            (exists-p-of object))))

(defclass kioskberrli-sd-image-failure-context ()
  ((topic :initarg :topic :reader topic-of)
   (flake-lock :initarg :flake-lock :reader flake-lock-of)
   (nixpkgs :initarg :nixpkgs :reader nixpkgs-of)
   (modules :initarg :modules :reader modules-of)
   (removed-option :initarg :removed-option :reader removed-option-of)))

(defmethod print-object ((object kioskberrli-sd-image-failure-context) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (topic-of object)
            (removed-option-of object))))

(defclass kioskberrli-patch-suggestion ()
  ((file :initarg :file :reader file-of)
   (change-kind :initarg :change-kind :reader change-kind-of)
   (target-option :initarg :target-option :reader target-option-of)
   (old-form :initarg :old-form :reader old-form-of)
   (new-form :initarg :new-form :reader new-form-of)
   (explanation :initarg :explanation :reader explanation-of)))

(defmethod print-object ((object kioskberrli-patch-suggestion) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A in ~A"
            (change-kind-of object)
            (file-of object))))

(defclass kioskberrli-build-command ()
  ((command :initarg :command :reader command-of)
   (purpose :initarg :purpose :reader purpose-of)))

(defmethod print-object ((object kioskberrli-build-command) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (command-of object))))

(defclass kioskberrli-correction-path ()
  ((steps :initarg :steps :reader steps-of)
   (summary :initarg :summary :reader summary-of)))

(defmethod print-object ((object kioskberrli-correction-path) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (summary-of object))))

(defun kioskberrli-flake-lock-pathname ()
  #P"/Users/rgb/workspace/hauptsache/kioskberrli/flake.lock")

(defun kioskberrli-nixpkgs-lock-object ()
  (list :input "nixpkgs"
        :flake-lock (kioskberrli-flake-lock-pathname)
        :revision "cf59864ef8aa2e178cccedbe2c178185b0365705"
        :ref "nixos-unstable"
        :repo "NixOS/nixpkgs"))

(defun kioskberrli-sd-image-module-reference (kind)
  (ecase kind
    (:aarch64
     (list :module :sd-image-aarch64
           :relative-path "nixos/modules/installer/sd-card/sd-image-aarch64.nix"))
    (:core
     (list :module :sd-image
           :relative-path "nixos/modules/installer/sd-card/sd-image.nix"))))

(defun kioskberrli-sd-image-module-references ()
  (list (kioskberrli-sd-image-module-reference :aarch64)
        (kioskberrli-sd-image-module-reference :core)))

(defgeneric option-exists? (object)
  (:documentation "Return evidence for whether the context's relevant option
belongs to the pinned upstream API."))

(defgeneric suggested-patch (object)
  (:documentation "Return the next mechanical edit suggested by the failure
context."))

(defgeneric repro-build-command (object)
  (:documentation "Return the build command used to verify the correction."))

(defgeneric correction-path (object)
  (:documentation "Return the correction path from visible failure to merge."))

(defmethod option-exists? ((context kioskberrli-sd-image-failure-context))
  (make-instance 'kioskberrli-option-existence-evidence
                 :option-name (removed-option-of context)
                 :exists-p nil
                 :evidence-kind :failure-context
                 :explanation
                 (format nil
                         "The failure context records ~A as removed or absent in the pinned upstream SD-image API, so setting it should fail option evaluation."
                         (removed-option-of context))))

(defmethod suggested-patch ((context kioskberrli-sd-image-failure-context))
  (make-instance 'kioskberrli-patch-suggestion
                 :file #P"/Users/rgb/workspace/hauptsache/kioskberrli/kiosk.nix"
                 :change-kind :remove-obsolete-option
                 :target-option (removed-option-of context)
                 :old-form "sdImage.imageSize = 4096;"
                 :new-form nil
                 :explanation
                 "Remove the obsolete option from kiosk.nix, then rerun the SD-image build against the pinned flake lock."))

(defmethod repro-build-command ((context kioskberrli-sd-image-failure-context))
  (declare (ignore context))
  (make-instance 'kioskberrli-build-command
                 :command "nix build .#nixosConfigurations.kioskberrli.config.system.build.sdImage"
                 :purpose "Verify that the kiosk SD-image target now evaluates and builds on the pinned module set."))

(defmethod correction-path ((context kioskberrli-sd-image-failure-context))
  (make-instance 'kioskberrli-correction-path
                 :summary "visible error -> patch -> verify -> merge"
                 :steps
                 (list
                  (list :step :visible-error
                        :object context)
                  (list :step :patch
                        :object (suggested-patch context))
                  (list :step :verify
                        :object (repro-build-command context))
                  (list :step :merge
                        :object
                        "After a successful verification build, commit the correction and merge it through the normal repo workflow."))))

(defun kioskberrli-sd-image-failure-context ()
  (make-instance 'kioskberrli-sd-image-failure-context
                 :topic :sdimage-imagesize-failure
                 :flake-lock (kioskberrli-flake-lock-pathname)
                 :nixpkgs (kioskberrli-nixpkgs-lock-object)
                 :modules (kioskberrli-sd-image-module-references)
                 :removed-option "sdImage.imageSize"))

;;
;; journalmatic translation helpers
;;

(defun journalmatic-example-order (story)
  (mapcar #'(lambda (item) (getf item :id)) story))

(defun journalmatic-example-add (story after item)
  (let ((index (if after
                   (1+ (or (position after (journalmatic-example-order story)
                                     :test #'equal)
                           -1))
                   0)))
    (append (subseq story 0 index)
            (list item)
            (subseq story index))))

(defun journalmatic-example-remove (story id)
  (remove id story :key #'(lambda (item) (getf item :id)) :test #'equal))

(defun journalmatic-example-apply-action (page action)
  (let* ((page (copy-tree page))
         (story (copy-list (getf page :story))))
    (setf (getf page :story) story)
    (case (getf action :type)
      (:create
       (let ((item (getf action :item)))
         (when (getf item :title)
           (setf (getf page :title) (getf item :title)))
         (setf (getf page :story) (copy-list (or (getf item :story) '())))))
      (:add
       (setf (getf page :story)
             (journalmatic-example-add (getf page :story)
                                       (getf action :after)
                                       (getf action :item))))
      (:edit
       (let* ((story (getf page :story))
              (id (getf action :id))
              (index (position id story
                               :key #'(lambda (item) (getf item :id))
                               :test #'equal)))
         (if index
             (setf (nth index story) (getf action :item))
             (setf (getf page :story)
                   (append story (list (getf action :item)))))))
      (:remove
       (setf (getf page :story)
             (journalmatic-example-remove (getf page :story)
                                          (getf action :id))))
      (:move
       (let* ((order (getf action :order))
              (id (getf action :id))
              (index (position id order :test #'equal))
              (after (and index (plusp index) (nth (1- index) order)))
              (story (getf page :story))
              (item (find id story :key #'(lambda (entry) (getf entry :id))
                         :test #'equal)))
         (when item
           (setf story (journalmatic-example-remove story id))
           (setf (getf page :story)
                 (journalmatic-example-add story after item)))))
      (otherwise nil))
    page))

(defun journalmatic-example-revision (journal &key title (rev-index (length journal)))
  (let ((page (list :title title :story '())))
    (dolist (action (subseq journal 0 rev-index) page)
      (setf page (journalmatic-example-apply-action page action)))))

(defun journalmatic-example-compare-actions (a b)
  (let ((date-a (getf a :date))
        (date-b (getf b :date)))
    (cond ((and date-a date-b (< date-a date-b)) t)
          ((and date-a date-b (> date-a date-b)) nil)
          (t nil))))

(defun journalmatic-example-sort-journal (journal)
  (sort (copy-list journal) #'journalmatic-example-compare-actions))

(defun journalmatic-example-check (page)
  (let ((results '())
        (story (or (getf page :story) '()))
        (journal (or (getf page :journal) '())))
    (when (and story
               (not (null story))
               (every #'(lambda (item)
                          (or (null item) (null (getf item :type))))
                      story))
      (push :nulls results))
    (when (or (null journal)
              (null (first journal))
              (not (eql (getf (first journal) :type) :create)))
      (push :creation results))
    (loop with previous-date = nil
          for action in journal
          for date = (getf action :date)
          do (when (and previous-date date (> previous-date date))
               (pushnew :chronology results))
             (setf previous-date date))
    (dolist (action journal)
      (case (getf action :type)
        (:create
         (unless (and (getf action :item) (getf action :date))
           (pushnew :malformed results)))
        ((:add :edit)
         (unless (and (getf action :item) (getf action :id) (getf action :date))
           (pushnew :malformed results)))
        (:move
         (unless (and (getf action :order) (getf action :id) (getf action :date))
           (pushnew :malformed results)))
        (:remove
         (unless (and (getf action :id) (getf action :date))
           (pushnew :malformed results)))
        (:fork
         (unless (getf action :date)
           (pushnew :malformed results)))
        (otherwise nil)))
    (let* ((revision-journal (if (member :chronology results)
                                 (journalmatic-example-sort-journal journal)
                                 journal))
           (revised (journalmatic-example-revision revision-journal
                                                   :title (getf page :title))))
      (unless (equal (getf page :story) (getf revised :story))
        (pushnew :revision results)))
    (nreverse results)))

(defun journalmatic-example-fix-chronology (page)
  (let ((page (copy-tree page)))
    (setf (getf page :journal)
          (journalmatic-example-sort-journal (getf page :journal)))
    page))

(defun journalmatic-example-compact-journal (page &key (entry-time-span 300000))
  (let* ((journal-in (journalmatic-example-sort-journal (getf page :journal)))
         (journal-out '())
         (previous-action nil))
    (labels ((flush-previous ()
               (when previous-action
                 (push previous-action journal-out)
                 (setf previous-action nil))))
      (dolist (action journal-in)
        (case (getf action :type)
          (:create
           (flush-previous)
           (push action journal-out))
          (:edit
           (if (null previous-action)
               (setf previous-action action)
               (if (and (equal (getf previous-action :id) (getf action :id))
                        (eql (getf previous-action :type) :edit)
                        (< (- (getf action :date) (getf previous-action :date))
                           entry-time-span))
                   (setf previous-action action)
                   (progn
                     (flush-previous)
                     (setf previous-action action)))))
          ((:add :move :remove)
           (flush-previous)
           (push action journal-out))
          (:fork
           (when (getf action :site)
             (flush-previous)
             (push action journal-out)))
          (otherwise nil)))
      (flush-previous)
      (let ((page (copy-tree page)))
        (setf (getf page :journal) (nreverse journal-out))
        page))))

(defparameter *journalmatic-example-page*
  (list
   :title "Example Journal Page"
   :story (list (list :type :paragraph :id "a1" :text "Alpha revised")
                (list :type :paragraph :id "b1" :text "Beta"))
   :journal
   (list
    (list :type :create
          :item (list :title "Example Journal Page" :story '())
          :date 1000)
    (list :type :add
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha")
          :date 1010)
    (list :type :edit
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha draft")
          :date 1040)
    (list :type :edit
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha revised")
          :date 1050)
    (list :type :add
          :id "b1"
          :item (list :type :paragraph :id "b1" :text "Beta")
          :date 1060))))

(defparameter *journalmatic-example-page-with-chronology-error*
  (list
   :title "Chronology Example"
   :story (list (list :type :paragraph :id "a1" :text "Alpha")
                (list :type :paragraph :id "b1" :text "Beta"))
   :journal
   (list
    (list :type :create
          :item (list :title "Chronology Example" :story '())
          :date 1000)
    (list :type :add
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha")
          :date 1100)
    (list :type :add
          :id "b1"
          :item (list :type :paragraph :id "b1" :text "Beta")
          :date 1050))))

(defexample journalmatic-revision-example
  "Replay a small journal into the current page state."
  (let* ((page *journalmatic-example-page*)
         (revised (journalmatic-example-revision (getf page :journal)
                                                 :title (getf page :title))))
    (assert-equal (getf page :story) (getf revised :story))
    (list :title (getf revised :title)
          :story (getf revised :story))))

(defexample journalmatic-checker-example
  "Report the checker findings for a page with a chronology issue."
  (let* ((page *journalmatic-example-page-with-chronology-error*)
         (results (journalmatic-example-check page)))
    (assert-equal '(:chronology) results)
    (list :title (getf page :title)
          :results results)))

(defexample journalmatic-rectify-chronology-example
  "Sort a page journal by date to remove chronology errors."
  (let* ((page *journalmatic-example-page-with-chronology-error*)
         (fixed (journalmatic-example-fix-chronology page))
         (dates (mapcar #'(lambda (action) (getf action :date))
                        (getf fixed :journal))))
    (assert-equal '(1000 1050 1100) dates)
    (list :title (getf fixed :title)
          :journal-dates dates
          :results (journalmatic-example-check fixed))))

(defexample journalmatic-gentle-compactor-example
  "Keep only the last edit in a short run of edits to the same item."
  (let* ((page *journalmatic-example-page*)
         (compacted (journalmatic-example-compact-journal page))
         (types-and-ids (mapcar #'(lambda (action)
                                    (list (getf action :type) (getf action :id)))
                                (getf compacted :journal))))
    (assert-equal '((:create nil) (:add "a1") (:edit "a1") (:add "b1"))
                  types-and-ids)
    (list :title (getf compacted :title)
          :journal-actions types-and-ids)))
