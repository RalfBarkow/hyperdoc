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

(defun assert-step-handoff (ids &key step-id required-predecessor forbidden-predecessor)
  "Assert immediate-predecessor invariants for STEP-ID inside ordered IDS.
Returns a small inspectable plist on success."
  (let* ((position (position step-id ids :test #'equal))
         (predecessor (and position
                           (> position 0)
                           (nth (1- position) ids))))
    (assert position)
    (assert (> position 0))
    (assert-equal required-predecessor predecessor)
    (when forbidden-predecessor
      (assert (not (equal forbidden-predecessor predecessor))))
    (list :step-id step-id
          :position position
          :predecessor predecessor)))

(defun assert-immediate-predecessor (ids step-id predecessor-id)
  "Convenience wrapper for required adjacency."
  (assert-step-handoff ids
                       :step-id step-id
                       :required-predecessor predecessor-id))

(defun assert-not-immediate-predecessor (ids step-id forbidden-predecessor-id)
  "Convenience wrapper for forbidden adjacency.
Requires STEP-ID to be present and not first."
  (let* ((position (position step-id ids :test #'equal))
         (predecessor (and position
                           (> position 0)
                           (nth (1- position) ids))))
    (assert position)
    (assert (> position 0))
    (assert (not (equal forbidden-predecessor-id predecessor)))
    (list :step-id step-id
          :position position
          :predecessor predecessor)))

(defun assert-immediate-successor (ids step-id successor-id)
  "Assert that SUCCESSOR-ID immediately follows STEP-ID in ordered IDS."
  (let* ((position (position step-id ids :test #'equal))
         (successor-pos (and position
                             (< position (1- (length ids)))
                             (1+ position)))
         (successor (and successor-pos
                         (nth successor-pos ids))))
    (assert position)
    (assert successor-pos)
    (assert-equal successor-id successor)
    (list :step-id step-id
          :position position
          :successor successor)))

(defun assert-not-immediate-successor (ids step-id forbidden-successor-id)
  "Assert that FORBIDDEN-SUCCESSOR-ID does not immediately follow STEP-ID."
  (let* ((position (position step-id ids :test #'equal))
         (successor-pos (and position
                             (< position (1- (length ids)))
                             (1+ position)))
         (successor (and successor-pos
                         (nth successor-pos ids))))
    (assert position)
    (assert successor-pos)
    (assert (not (equal forbidden-successor-id successor)))
    (list :step-id step-id
          :position position
          :successor successor)))

(defun assert-step-chain (ids &rest chain)
  "Assert that CHAIN forms an immediate-successor chain in ordered IDS.
Every step id in CHAIN must exist, and each element must be immediately
followed by the next. Returns an inspectable plist on success."
  (assert (>= (length chain) 2))
  (dolist (step-id chain)
    (assert (position step-id ids :test #'equal)))
  (let ((pairs (loop for (a b) on chain while b collect (list a b))))
    (dolist (pair pairs)
      (destructuring-bind (a b) pair
        (assert-immediate-successor ids a b)))
    (list :chain chain
          :pairs pairs)))

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

(defclass sd-card-dry-run-transcript ()
  ((title :initarg :title :reader title-of)
   (transcript :initarg :transcript :reader transcript-of)
   (runbook :initarg :runbook :reader runbook-of)))

(defclass sd-card-step-handoff-defect ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (from-step :initarg :from-step :reader from-step-of)
   (to-step :initarg :to-step :reader to-step-of)
   (produced-artifact :initarg :produced-artifact :reader produced-artifact-of)
   (required-artifact :initarg :required-artifact :reader required-artifact-of)
   (missing-transition :initarg :missing-transition :reader missing-transition-of)))

(defclass sd-card-step-handoff-patch-target ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (defect :initarg :defect :reader defect-of)
   (inserted-step :initarg :inserted-step :reader inserted-step-of)
   (verification-note :initarg :verification-note :reader verification-note-of)))

(defgeneric raw-structure (object)
  (:documentation "Return a structural representation of OBJECT suitable for inspector raw-structure views."))

(defmethod raw-structure ((object standard-object))
  "Fallback for objects that expose a raw-structure slot via RAW-STRUCTURE-OF."
  (ignore-errors (raw-structure-of object)))

(defmethod raw-structure ((step sd-card-procedure-step))
  "Compute raw structure from semantic step slots; omit NIL entries."
  (let ((pairs (list (list :id (id-of step))
                     (list :title (title-of step))
                     (list :summary (summary-of step))
                     (list :diagnosis (diagnosis-of step))
                     (list :source-target (source-target-of step))
                     (list :patch-target (patch-target-of step))
                     (list :verification (verification-of step))
                     (list :merge-notes (merge-notes-of step))
                     (list :failure-capsule (failure-capsule-of step))
                     (list :commands (commands-of step)))))
    (loop for (key value) in pairs
          when (or (member key '(:id :title :summary) :test #'eq)
                   value)
            append (list key value))))

(defmethod print-object ((object sd-card-procedure-step) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-runbook-section) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-runbook) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-dry-run-transcript) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-step-handoff-defect) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object sd-card-step-handoff-patch-target) stream)
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

(defun make-official-rpi-tutorial-steps ()
  (let* ((download-step
           (make-instance 'sd-card-procedure-step
                          :id "official-download-prebuilt-image"
                          :title "Download prebuilt aarch64 SD image"
                          :summary "Download latest Hydra artifact and preserve filename by trusting the redirected server URL name."
                          :commands (list "nix-shell -p wget zstd"
                                          "LATEST_URL=\"https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1\""
                                          "wget --trust-server-names \"$LATEST_URL\"")
                          :verification "Result must be a newly downloaded nixos-image-sd-card-*.img.zst artifact (not a file named '1' and no manual rename)."))
         (decompress-step
           (make-instance 'sd-card-procedure-step
                          :id "official-decompress-zstd-to-img"
                          :title "Decompress .zstd image to .img"
                          :summary "Convert the downloaded compressed image artifact into the raw .img artifact required by the flashing step."
                          :commands (list "unzstd -d nixos-image-sd-card-*.img.zst")
                          :verification "Confirm a .img artifact exists and is the flash input; .img.zst and .img may both be present after decompression."))
         (flash-step
           (make-instance 'sd-card-procedure-step
                          :id "official-flash-sd-card"
                          :title "Flash image to SD card"
                          :summary "Write the prepared .img image to the selected SD card device."
                          :commands (list "diskutil list"
                                          "diskutil unmountDisk /dev/diskN"
                                          "sudo dd if=IMAGE.img of=/dev/rdiskN bs=4m status=progress conv=sync"
                                          "sync")))
         (filename-handoff-defect
           (make-instance 'sd-card-step-handoff-defect
                          :id "official-hydra-latest-filename-handoff-defect"
                          :title "Missing filename-preservation handoff for Hydra latest/download/1"
                          :summary "Plain wget can save latest/download/1 as file '1'; decompression expects a named .img.zst artifact."
                          :from-step download-step
                          :to-step decompress-step
                          :produced-artifact "file named 1"
                          :required-artifact "named .img.zst artifact filename"
                          :missing-transition "preserve redirected artifact filename"))
         (filename-handoff-patch-target
           (make-instance 'sd-card-step-handoff-patch-target
                          :id "official-hydra-latest-filename-handoff-patch-target"
                          :title "Preserve redirected Hydra artifact filename in download step"
                          :summary "Patch target is the relation between latest/download/1 and decompression: use wget --trust-server-names so wget adopts the redirected URL filename and step output satisfies decompression precondition."
                          :defect filename-handoff-defect
                          :inserted-step download-step
                          :verification-note "Download output is a named .img.zst artifact carried into decompression."))         
         (handoff-defect
           (make-instance 'sd-card-step-handoff-defect
                          :id "official-zstd-to-img-handoff-defect"
                          :title "Missing decompression handoff between steps 1 and 2"
                          :summary "Step 1 outputs .zstd while step 2 requires .img; the .zstd -> .img transition must be explicit."
                          :from-step download-step
                          :to-step flash-step
                          :produced-artifact ".img.zst"
                          :required-artifact ".img"
                          :missing-transition ".zstd -> .img decompression step"))
         (handoff-patch-target
           (make-instance 'sd-card-step-handoff-patch-target
                          :id "official-zstd-to-img-handoff-patch-target"
                          :title "Insert explicit .zstd -> .img handoff step"
                          :summary "Patch target is the relation between download and flash: add a decompression step so the flashing input precondition is explicit."
                          :defect handoff-defect
                          :inserted-step decompress-step
                          :verification-note "The inserted step must produce a .img artifact consumed by the flash step.")))
    (setf (slot-value download-step 'diagnosis)
          "Plain wget on latest/download/1 can save as file '1'; use --trust-server-names so wget keeps the redirected URL filename for decompression.")
    (setf (slot-value download-step 'source-target) filename-handoff-defect)
    (setf (slot-value download-step 'patch-target) filename-handoff-patch-target)
    (setf (slot-value download-step 'verification) filename-handoff-patch-target)
    (setf (slot-value decompress-step 'diagnosis)
          "A decompression step is missing between the download step and the flashing step.")
    (setf (slot-value decompress-step 'source-target) handoff-defect)
    (setf (slot-value decompress-step 'patch-target) handoff-patch-target)
    (setf (slot-value decompress-step 'verification) handoff-patch-target)
    (list
     download-step
     decompress-step
     flash-step
     (make-instance 'sd-card-procedure-step
                    :id "official-boot-pi"
                    :title "Boot Raspberry Pi from flashed card"
                    :summary "Boot Pi 4/400 from the flashed SD image and reach a usable shell/session.")
     (make-instance 'sd-card-procedure-step
                    :id "official-edit-configuration"
                    :title "Edit /etc/nixos/configuration.nix"
                    :summary "Adjust host-specific configuration and secrets locally on the running machine."
                    :commands (list "sudoedit /etc/nixos/configuration.nix"))
     (make-instance 'sd-card-procedure-step
                    :id "official-first-rebuild-boot"
                    :title "Run first rebuild with nixos-rebuild boot"
                    :summary "Use boot mode first to prepare a reboot-safe generation."
                    :commands (list "sudo nixos-rebuild boot"))
     (make-instance 'sd-card-procedure-step
                    :id "official-reboot-new-generation"
                    :title "Reboot into the new generation"
                    :summary "Reboot and confirm the system starts with the freshly built generation."
                    :commands (list "sudo reboot"))
     (make-instance 'sd-card-procedure-step
                    :id "official-switch-later"
                    :title "Use nixos-rebuild switch only later"
                    :summary "Use switch only after reboot reliability is established."
                    :commands (list "sudo nixos-rebuild switch")
                    :diagnosis "Applying switch too early can hide boot-path issues that only appear on reboot."))))

(defun official-rpi-tutorial-workflow ()
  (let* ((steps (make-official-rpi-tutorial-steps))
         (section (make-instance 'sd-card-runbook-section
                                 :id "official-workflow"
                                 :title "Official workflow"
                                 :summary "Canonical preinstalled SD-image sequence from nix.dev."
                                 :steps steps
                                 :raw-structure (list :section "Official workflow")))
         (runbook (make-instance 'sd-card-runbook
                                 :id "official-rpi-sd-image-workflow"
                                 :title "Official Tutorial Workflow: NixOS SD Image on Raspberry Pi 4/400"
                                 :summary "Step-by-step semantic workflow object for the official SD-image tutorial."
                                 :sections (list section))))
    (setf (slot-value runbook 'raw-structure)
          (sd-card-runbook->raw-structure runbook))
    runbook))

(defun official-rpi-tutorial-step (step-id)
  (or (find-sd-card-runbook-step (official-rpi-tutorial-workflow) step-id)
      (error "Unknown official tutorial step id: ~A" step-id)))

(defun official-zstd-to-img-handoff-defect ()
  "Return the relation-level defect object for the missing transition between official steps 1 and 2."
  (or (source-target-of (official-rpi-tutorial-step "official-decompress-zstd-to-img"))
      (error "Missing source-target defect for official decompression step.")))

(defun official-zstd-to-img-handoff-patch-target ()
  "Return the patch-target object describing insertion of the decompression handoff."
  (or (patch-target-of (official-rpi-tutorial-step "official-decompress-zstd-to-img"))
      (error "Missing patch-target object for official decompression step.")))

(defun official-hydra-latest-filename-handoff-defect ()
  "Return the relation-level defect object for filename preservation between download and decompression."
  (or (source-target-of (official-rpi-tutorial-step "official-download-prebuilt-image"))
      (error "Missing source-target defect for official download step.")))

(defun official-hydra-latest-filename-handoff-patch-target ()
  "Return the patch-target object for preserving redirected Hydra artifact filenames."
  (or (patch-target-of (official-rpi-tutorial-step "official-download-prebuilt-image"))
      (error "Missing patch-target object for official download step.")))

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
  "Return a semantic transcript object for the default SD-card command plan."
  (let (runbook)
    (let ((text (with-output-to-string (stream)
                  (setf runbook (sd-card-creation-dry-run :stream stream)))))
      (make-instance 'sd-card-dry-run-transcript
                     :title "SD card creation command plan (dry-run)"
                     :transcript text
                     :runbook runbook))))

(defexample sd-card-primary-semantic-entrypoints-example
  "Regression check: primary page entrypoints resolve to semantic objects, not raw cons lists."
  (let* ((runbook (sd-card-creation-command-plan))
         (correction (sd-card-creation-command-plan-step "sdimage-imagesize-correction"))
         (raw (sd-card-creation-command-plan-raw)))
    (assert-eql 'sd-card-runbook (type-of runbook))
    (assert-eql 'sd-card-correction-step (type-of correction))
    (assert-eql 'cons (type-of raw))
    (list :primary-runbook-type (type-of runbook)
          :primary-correction-type (type-of correction)
          :raw-type (type-of raw))))

(defexample sd-card-runbook-section-navigation-example
  "Regression check: runbook summary section navigation targets semantic section objects."
  (let* ((runbook (sd-card-creation-command-plan))
         (ids '("path-a-official-prebuilt-image"
                "path-b-build-project-image"
                "flash-procedure-macos-host"
                "safety-checks"))
         (sections (loop for id in ids
                         collect (sd-card-creation-command-plan-section id))))
    (dolist (section sections)
      (assert-eql 'sd-card-runbook-section (type-of section)))
    (list :runbook-type (type-of runbook)
          :section-types (mapcar #'type-of sections)
          :section-titles (mapcar #'title-of sections))))

(defexample official-rpi-tutorial-step-navigation-example
  "Regression check: official tutorial steps resolve to semantic procedure-step objects."
  (let* ((workflow (official-rpi-tutorial-workflow))
         (ids '("official-download-prebuilt-image"
                "official-decompress-zstd-to-img"
                "official-flash-sd-card"
                "official-boot-pi"
                "official-edit-configuration"
                "official-first-rebuild-boot"
                "official-reboot-new-generation"
                "official-switch-later"))
         (steps (loop for id in ids
                      collect (official-rpi-tutorial-step id))))
    (dolist (step steps)
      (assert-eql 'sd-card-procedure-step (type-of step)))
    (list :workflow-type (type-of workflow)
          :step-types (mapcar #'type-of steps)
          :step-titles (mapcar #'title-of steps))))

(defexample official-rpi-zstd-to-img-handoff-regression-example
  "Regression check: missing handoff is modeled as relation defect with explicit inserted step."
  (let* ((inserted-step (official-rpi-tutorial-step "official-decompress-zstd-to-img"))
         (defect (official-zstd-to-img-handoff-defect))
         (patch (official-zstd-to-img-handoff-patch-target)))
    (assert defect)
    (assert patch)
    (assert-eql 'sd-card-step-handoff-defect (type-of defect))
    (assert-eql 'sd-card-step-handoff-patch-target (type-of patch))
    (assert-equal (id-of inserted-step) (id-of (inserted-step-of patch)))
    (assert-equal (id-of defect) (id-of (defect-of patch)))
    (assert-equal ".img.zst" (produced-artifact-of defect))
    (assert-equal ".img" (required-artifact-of defect))
    (assert (commands-of inserted-step))
    (list :inserted-step (id-of inserted-step)
          :source-target (id-of defect)
          :patch-target (id-of patch))))

(defexample official-rpi-hydra-filename-preservation-regression-example
  "Regression check: official download command preserves redirected Hydra artifact filename."
  (let* ((download-step (official-rpi-tutorial-step "official-download-prebuilt-image"))
         (commands (commands-of download-step))
         (defect (official-hydra-latest-filename-handoff-defect))
         (patch (official-hydra-latest-filename-handoff-patch-target)))
    (assert (member "wget --trust-server-names \"$LATEST_URL\"" commands :test #'equal))
    (assert (not (member "wget \"$LATEST_URL\"" commands :test #'equal)))
    (assert-eql 'sd-card-step-handoff-defect (type-of defect))
    (assert-eql 'sd-card-step-handoff-patch-target (type-of patch))
    (assert-equal (id-of defect) (id-of (defect-of patch)))
    (list :step (id-of download-step)
          :command "wget --trust-server-names \"$LATEST_URL\""
          :source-target (id-of defect)
          :patch-target (id-of patch))))

(defexample hydra-filename-outcome-states-example
  "Contrast historical filename-loss with corrected download and post-decompression state progression."
  (let* ((bad-outcome (list :mode :historical-failure
                            :saved-as "1"
                            :provenance :lost-at-download-time))
         (good-filename "nixos-image-sd-card-26.05pre958961.aca4d95fce49-aarch64-linux.img.zst")
         (good-outcome (list :mode :current-expected
                             :saved-as good-filename
                             :timestamp "2026-03-06 14:54:30"
                             :size-bytes 1377718373
                             :provenance :preserved-at-download-time))
         (decompressed-filename "nixos-image-sd-card-26.05pre958961.aca4d95fce49-aarch64-linux.img")
         (decompressed-outcome (list :mode :post-decompression
                                     :produced decompressed-filename
                                     :size-bytes 3490607104
                                     :compressed-still-present t
                                     :compressed-filename good-filename
                                     :compressed-size-bytes 1377718373
                                     :flash-input decompressed-filename
                                     :download-artifact good-filename)))
    (assert-equal "1" (getf bad-outcome :saved-as))
    (assert (let ((name (getf good-outcome :saved-as)))
              (and (>= (length name) (length ".img.zst"))
                   (string= ".img.zst"
                            name
                            :start1 0
                            :end1 (length ".img.zst")
                            :start2 (- (length name) (length ".img.zst"))
                            :end2 (length name)))))
    (assert (search "aarch64-linux" (getf good-outcome :saved-as)))
    (assert (let ((name (getf decompressed-outcome :produced)))
              (and (>= (length name) (length ".img"))
                   (string= ".img"
                            name
                            :start1 0
                            :end1 (length ".img")
                            :start2 (- (length name) (length ".img"))
                            :end2 (length name)))))
    (assert (not (search ".img.zst" (getf decompressed-outcome :produced))))
    (assert (eq t (getf decompressed-outcome :compressed-still-present)))
    (list :historical bad-outcome
          :current-expected good-outcome
          :post-decompression decompressed-outcome)))

(defexample official-rpi-zstd-to-img-handoff-adjacency-regression-example
  "Regression check: flash step must be immediately preceded by the decompression handoff step."
  (let* ((workflow (official-rpi-tutorial-workflow))
         (section (first (sections-of workflow)))
         (ids (mapcar #'id-of (steps-of section)))
         (required (assert-immediate-predecessor
                    ids
                    "official-flash-sd-card"
                    "official-decompress-zstd-to-img"))
         (forbidden (assert-not-immediate-predecessor
                     ids
                     "official-flash-sd-card"
                     "official-download-prebuilt-image")))
    (list :ids ids
          :required required
          :forbidden forbidden)))

(defexample official-rpi-zstd-to-img-handoff-successor-regression-example
  "Regression check: handoff successor constraints hold from both transition endpoints."
  (let* ((workflow (official-rpi-tutorial-workflow))
         (section (first (sections-of workflow)))
         (ids (mapcar #'id-of (steps-of section)))
         (download->decompress (assert-immediate-successor
                                ids
                                "official-download-prebuilt-image"
                                "official-decompress-zstd-to-img"))
         (decompress->flash (assert-immediate-successor
                             ids
                             "official-decompress-zstd-to-img"
                             "official-flash-sd-card"))
         (download-not-flash (assert-not-immediate-successor
                              ids
                              "official-download-prebuilt-image"
                              "official-flash-sd-card")))
    (list :ids ids
          :download-to-decompress download->decompress
          :decompress-to-flash decompress->flash
          :download-not-flash download-not-flash)))

(defexample official-rpi-zstd-to-img-step-chain-regression-example
  "Regression check: local SD-image handoff chain is enforced as one declarative invariant."
  (let* ((workflow (official-rpi-tutorial-workflow))
         (section (first (sections-of workflow)))
         (ids (mapcar #'id-of (steps-of section)))
         (chain-result (assert-step-chain
                        ids
                        "official-download-prebuilt-image"
                        "official-decompress-zstd-to-img"
                        "official-flash-sd-card")))
    (list :ids ids
          :chain-result chain-result)))

(defexample official-rpi-tutorial-step-raw-structure-regression-example
  "Regression check: procedure-step raw structure is computed and includes core keys."
  (let* ((step (official-rpi-tutorial-step "official-reboot-new-generation"))
         (structure (raw-structure step)))
    (assert structure)
    (assert-equal "official-reboot-new-generation" (getf structure :id))
    (assert-equal "Reboot into the new generation" (getf structure :title))
    (assert-equal
     "Reboot and confirm the system starts with the freshly built generation."
     (getf structure :summary))
    (assert (getf structure :commands))
    (list :step-id (id-of step)
          :raw-structure structure)))

(defexample official-rpi-tutorial-expr-quoting-regression-example
  "Regression check: HTML expr string arguments must use &quot; and evaluate to step objects."
  ;; expr-attr models the value seen by Lisp after HTML entity decoding.
  (let* ((expr-attr "(hyperdoc::official-rpi-tutorial-step \"official-download-prebuilt-image\")")
         (good (handler-case
                   (eval (read-from-string expr-attr))
                 (error (c) c)))
         (bad-expr "(hyperdoc::official-rpi-tutorial-step \\\"official-download-prebuilt-image\\\")")
    (bad (handler-case
                  (eval (read-from-string bad-expr))
                (error (c) c))))
    (assert-eql 'sd-card-procedure-step (type-of good))
    (assert (typep bad 'condition))
    (list :expr-attr expr-attr
          :good-type (type-of good)
          :bad-condition-type (type-of bad))))

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

(defparameter +journalmatic-commit-gate-findings+
  '(:creation :chronology :revision :malformed))

(defun journalmatic-commit-gate-findings (page)
  (let ((findings (journalmatic-example-check page)))
    (remove-if-not #'(lambda (finding)
                       (member finding +journalmatic-commit-gate-findings+))
                   findings)))

(defun journalmatic-commit-gate-pass-p (page)
  (null (journalmatic-commit-gate-findings page)))

(defun journalmatic-current-epoch-millis ()
  (* 1000 (- (get-universal-time) 2208988800)))

(defun journalmatic-next-date-like-wiki-client (journal &key (now (journalmatic-current-epoch-millis)))
  (let ((last-date (loop for action in journal
                         for date = (getf action :date)
                         when date maximize date)))
    (if last-date
        (max now (1+ last-date))
        now)))

(defun journalmatic-normalize-dates-monotonic (journal &key (start-now (journalmatic-current-epoch-millis)))
  "Normalize action dates in existing order, forcing monotonic progression."
  (let ((date (1- start-now))
        (normalized '()))
    (dolist (action journal (nreverse normalized))
      (let ((copy (copy-tree action))
            (existing (getf action :date)))
        (setf date (max (1+ date) (or existing 0)))
        (setf (getf copy :date) date)
        (push copy normalized)))))

(defexample journalmatic-commit-gate-script-example
  "Gate FedWiki page commits on creation/chronology/revision/malformed findings."
  (let* ((bad-page *journalmatic-example-page-with-chronology-error*)
         (good-page *journalmatic-example-page*)
         (bad-findings (journalmatic-commit-gate-findings bad-page))
         (good-findings (journalmatic-commit-gate-findings good-page)))
    (assert-equal '(:chronology) bad-findings)
    (assert-equal '() good-findings)
    (list :gate-findings +journalmatic-commit-gate-findings+
          :bad-page (list :title (getf bad-page :title)
                          :findings bad-findings
                          :pass? (journalmatic-commit-gate-pass-p bad-page))
          :good-page (list :title (getf good-page :title)
                           :findings good-findings
                           :pass? (journalmatic-commit-gate-pass-p good-page)))))

(defexample journalmatic-date-origin-example
  "Show Date.now-style millis and monotonic next-date behavior."
  (let* ((journal '((:type :create :date 1000)
                    (:type :add :id "a1" :date 1001)))
         (now 950)
         (next-date (journalmatic-next-date-like-wiki-client journal :now now)))
    (assert-equal 1002 next-date)
    (list :date-origin "epoch-millis"
          :now now
          :last-date 1001
          :next-date next-date)))

(defexample journalmatic-monotonic-normalization-example
  "Normalize out-of-order dates while preserving action order."
  (let* ((journal '((:type :create :date 1000)
                    (:type :add :id "a1" :date 1100)
                    (:type :fork :site "localhost:3000" :date 1050)))
         (normalized (journalmatic-normalize-dates-monotonic journal :start-now 1000))
         (dates (mapcar #'(lambda (action) (getf action :date)) normalized)))
    (assert-equal '(1000 1100 1101) dates)
    (list :before '(1000 1100 1050)
          :after dates)))

(defun journalmatic-make-page-with-journal (title story-items &key start-date fork-site)
  "Reproducible page generator: deterministic ids/date ordering from inputs."
  (let* ((date (or start-date 1000))
         (story (copy-tree story-items))
         (journal (list (list :type :create
                              :item (list :title title :story '())
                              :date date)))
         (after nil))
    (dolist (item story-items)
      (incf date)
      (let ((action (list :type :add
                          :id (getf item :id)
                          :item (copy-tree item)
                          :date date)))
        (when after
          (setf action (append action (list :after after))))
        (push action journal)
        (setf after (getf item :id))))
    (when fork-site
      (incf date)
      (push (list :type :fork :site fork-site :date date) journal))
    (list :title title
          :story story
          :journal (nreverse journal))))

(defun journalmatic-append-add-like-wiki-client (page item &key after (now (journalmatic-current-epoch-millis)))
  "Append an add action using wiki-client style date generation."
  (let* ((page (copy-tree page))
         (journal (or (getf page :journal) '()))
         (story (or (getf page :story) '()))
         (date (journalmatic-next-date-like-wiki-client journal :now now))
         (action (list :type :add
                       :id (getf item :id)
                       :item (copy-tree item)
                       :date date)))
    (when after
      (setf action (append action (list :after after))))
    (setf (getf page :story)
          (journalmatic-example-add story after (copy-tree item)))
    (setf (getf page :journal)
          (append journal (list action)))
    page))

(defexample journalmatic-page-generation-workflow-example
  "Generate a reproducible page JSON shape and verify chronology/fork ordering."
  (let* ((story (list (list :type :paragraph :id "a1" :text "Alpha")
                      (list :type :markdown :id "b1" :text "### Beta")))
         (page (journalmatic-make-page-with-journal "Workflow Example"
                                                    story
                                                    :start-date 1000
                                                    :fork-site "localhost:3000"))
         (dates (mapcar #'(lambda (action) (getf action :date))
                        (getf page :journal)))
         (checked (journalmatic-example-check page)))
    (assert-equal '(1000 1001 1002 1003) dates)
    (assert-equal '() checked)
    (list :title (getf page :title)
          :journal-dates dates
          :results checked)))

(defexample journalmatic-page-generation-wiki-client-style-example
  "Append a story item using max(now, last-date+1) date semantics."
  (let* ((seed (journalmatic-make-page-with-journal
                "Workflow Example"
                (list (list :type :paragraph :id "a1" :text "Alpha"))
                :start-date 1000))
         (now 995)
         (updated (journalmatic-append-add-like-wiki-client
                   seed
                   (list :type :paragraph :id "b1" :text "Beta")
                   :after "a1"
                   :now now))
         (dates (mapcar #'(lambda (action) (getf action :date))
                        (getf updated :journal))))
    (assert-equal '(1000 1001 1002) dates)
    (list :now now
          :journal-dates dates
          :last-date (car (last dates)))))

(defexample wiki-client-blame-operation-example
  "Show reproducible git-blame operations for wiki-client timestamp lines."
  (let ((repo "/Users/rgb/workspace/wiki-client"))
    (list :repo repo
          :commands
          (list (format nil "git -C ~A blame -L 235,235 -- lib/pageHandler.js" repo)
                (format nil "git -C ~A blame -L 283,283 -- lib/page.js" repo)
                (format nil "git -C ~A blame -L 197,197 -- lib/search.js" repo)
                (format nil "git -C ~A blame -L 64,64 -- lib/revision.js" repo))
          :provenance-commit "d4420c72a49305ca52d18ce8203bc95bdd3f59d2")))
