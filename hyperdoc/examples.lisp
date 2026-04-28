;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Scoped example registrations
;;

(eval-when (:load-toplevel :execute)
  (register-example-check
   'graphviz-story-item-upstream-assimilation-example
   :system "hyperdoc/examples/ops"
   :source-file (asdf:system-relative-pathname
                 :hyperdoc
                 "hyperdoc/git-commit-equivalence.lisp")
   :page "Graphviz story item upstream assimilation example"))

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
   (next-steps :initarg :next-steps :initform nil :reader next-steps-of)
   (continuation-note :initarg :continuation-note :initform nil :reader continuation-note-of)
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
  (declare (ignore compressed-image))
  (list
   (make-instance 'sd-card-runbook-section
                  :id "path-a-official-prebuilt-image"
                  :title "Path A - Official prebuilt image"
                  :summary "Fetch and verify the official Hydra artifact."
                  :continuation-note "Continue with the downstream official workflow after checksum verification."
                  :next-steps (list "official-flash-sd-card"
                                    "official-boot-pi"
                                    "official-connect-pi-over-ssh"
                                    "official-edit-configuration"
                                    "official-first-rebuild-boot"
                                    "official-reboot-new-generation"
                                    "official-switch-later")
                  :steps
                  (list
                   (make-instance 'sd-card-procedure-step
                                  :id "download-hydra-artifact"
                                  :title "Download artifact from Hydra"
                                  :summary "Resolve the exact Hydra build and download its published aarch64 SD image artifact."
                                  :commands (list "# POSIX shell block for sh/bash/zsh. In fish, either run via: bash -lc '...'; or use the fish-native equivalent procedure."
                                                  (format nil "LATEST_URL=\"~A\"" download-url)
                                                  "BUILD_DOWNLOAD_URL=\"$(curl -fsSI \"$LATEST_URL\" | awk 'tolower($1)==\"location:\" {gsub(/\\r/, \"\", $2); print $2; exit}')\""
                                                  "BUILD_URL=\"${BUILD_DOWNLOAD_URL%/download/*}\""
                                                  "BUILD_JSON=\"$(curl -fsS -H 'Accept: application/json' \"$BUILD_URL\")\""
                                                  "PUBLISHED_NAME=\"$(printf '%s' \"$BUILD_JSON\" | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"buildproducts\"][\"1\"][\"name\"])')\""
                                                  "ARTIFACT_URL=\"${BUILD_DOWNLOAD_URL}/$PUBLISHED_NAME\""
                                                  "test ! -e \"$PUBLISHED_NAME\""
                                                  "ARTIFACT=\"$PUBLISHED_NAME\""
                                                  "wget -O \"$ARTIFACT\" \"$ARTIFACT_URL\""
                                                  "test -f \"$ARTIFACT\"")
                                  :raw-structure (list :command "wget -O \"$ARTIFACT\" \"$ARTIFACT_URL\""))
                   (make-instance 'sd-card-procedure-step
                                  :id "decompress-image"
                                  :title "Decompress image"
                                  :summary "Decompress the zstd artifact to a raw .img file."
                                  :commands (list "ARTIFACT=\"${ARTIFACT:?set ARTIFACT to the downloaded Hydra filename}\""
                                                  "unzstd -d \"$ARTIFACT\"")
                                  :raw-structure (list :command "unzstd -d \"$ARTIFACT\""))
                   (make-instance 'sd-card-procedure-step
                                  :id "verify-checksum"
                                  :title "Verify checksum"
                                  :summary "Verify compressed artifact integrity by comparing the local hash to Hydra's published build metadata."
                                  :commands (list "# POSIX shell block for sh/bash/zsh. In fish, either run via: bash -lc '...'; or use the fish-native equivalent procedure."
                                                  "ARTIFACT=\"${ARTIFACT:?set ARTIFACT to the downloaded Hydra filename}\""
                                                  "BUILD_URL=\"${BUILD_URL:?set BUILD_URL to the resolved Hydra build URL}\""
                                                  "BUILD_JSON=\"$(curl -fsS -H 'Accept: application/json' \"$BUILD_URL\")\""
                                                  "EXPECTED_SHA256=\"$(printf '%s' \"$BUILD_JSON\" | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"buildproducts\"][\"1\"][\"sha256hash\"])')\""
                                                  "LOCAL_SHA256=\"$(shasum -a 256 \"$ARTIFACT\" | awk '{print $1}')\""
                                                  "test \"$LOCAL_SHA256\" = \"$EXPECTED_SHA256\"")
                                  :verification "Local SHA-256 must equal the exact Hydra build JSON value at buildproducts[\"1\"][\"sha256hash\"]."
                                  :raw-structure (list :command "test \"$LOCAL_SHA256\" = \"$EXPECTED_SHA256\"")))
                  :raw-structure
                  (list :section "Path A - Official prebuilt image"
                        :continuation-note "Continue with the downstream official workflow after checksum verification."
                        :next-steps (list "official-flash-sd-card"
                                          "official-boot-pi"
                                          "official-connect-pi-over-ssh"
                                          "official-edit-configuration"
                                          "official-first-rebuild-boot"
                                          "official-reboot-new-generation"
                                          "official-switch-later")))
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
         (boot-step
           (make-instance 'sd-card-procedure-step
                          :id "official-boot-pi"
                          :title "Boot Raspberry Pi from flashed card"
                          :summary "Boot Pi 4/400 from the flashed SD image and reach a usable local shell/session."))
         (connect-step
           (make-instance 'sd-card-procedure-step
                          :id "official-connect-pi-over-ssh"
                          :title "Connect to the Pi over SSH"
                          :summary "If the Pi joined the network and remote access is already configured, determine its hostname/IP and open an SSH session; otherwise continue from a local console."
                          :commands (list "PI_HOST_OR_IP=\"${PI_HOST_OR_IP:?set the Pi hostname or IP after confirming it joined the network}\""
                                          "ping -c 1 \"$PI_HOST_OR_IP\""
                                          "SSH_TARGET=\"${SSH_TARGET:?set to user@$PI_HOST_OR_IP once SSH/login credentials are configured}\""
                                          "ssh \"$SSH_TARGET\"")))
         (edit-step
           (make-instance 'sd-card-procedure-step
                          :id "official-edit-configuration"
                          :title "Edit /etc/nixos/configuration.nix"
                          :summary "Adjust host-specific configuration and secrets locally on the running machine."
                          :commands (list "sudoedit /etc/nixos/configuration.nix")))
         (first-rebuild-step
           (make-instance 'sd-card-procedure-step
                          :id "official-first-rebuild-boot"
                          :title "Run first rebuild with nixos-rebuild boot"
                          :summary "Use boot mode first to prepare a reboot-safe generation."
                          :commands (list "sudo nixos-rebuild boot")))
         (reboot-step
           (make-instance 'sd-card-procedure-step
                          :id "official-reboot-new-generation"
                          :title "Reboot into the new generation"
                          :summary "Reboot and confirm the system starts with the freshly built generation."
                          :commands (list "sudo reboot")))
         (switch-step
           (make-instance 'sd-card-procedure-step
                          :id "official-switch-later"
                          :title "Use nixos-rebuild switch only later"
                          :summary "Use switch only after reboot reliability is established."
                          :commands (list "sudo nixos-rebuild switch")
                          :diagnosis "Applying switch too early can hide boot-path issues that only appear on reboot."))
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
                          :verification-note "The inserted step must produce a .img artifact consumed by the flash step."))
         (headless-handoff-defect
           (make-instance 'sd-card-step-handoff-defect
                          :id "official-headless-ssh-connect-handoff-defect"
                          :title "Missing headless-connect handoff between boot and configuration edit"
                          :summary "Booting the Pi does not by itself yield a remote shell; headless continuation needs network reachability, host discovery, and a configured SSH/login path."
                          :from-step boot-step
                          :to-step edit-step
                          :produced-artifact "booted Pi with no remote shell yet"
                          :required-artifact "reachable shell session on the Pi"
                          :missing-transition "network discovery and SSH connection step"))
         (headless-handoff-patch-target
           (make-instance 'sd-card-step-handoff-patch-target
                          :id "official-headless-ssh-connect-handoff-patch-target"
                          :title "Insert explicit headless SSH-connect handoff step"
                          :summary "Patch target is the relation between boot and configuration edit: add an explicit step that confirms network reachability, identifies the Pi on the network, and opens an SSH session when remote access is configured."
                          :defect headless-handoff-defect
                          :inserted-step connect-step
                          :verification-note "The inserted step must produce a reachable SSH shell on the Pi or stop and redirect the user to a local console when SSH/login prerequisites are absent.")))
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
    (setf (slot-value boot-step 'diagnosis)
          "Booting from the flashed card does not by itself guarantee headless continuation. The Pi still needs network reachability, an identifiable hostname/IP, and a configured SSH/login path before remote editing can continue.")
    (setf (slot-value boot-step 'patch-target) headless-handoff-patch-target)
    (setf (slot-value connect-step 'diagnosis)
          "SSH only makes sense after the Pi is reachable on the network and the running image already has SSH plus a usable login path. If those prerequisites are absent, stop here and continue from a directly attached console instead.")
    (setf (slot-value connect-step 'source-target) headless-handoff-defect)
    (setf (slot-value connect-step 'patch-target) headless-handoff-patch-target)
    (setf (slot-value connect-step 'verification) headless-handoff-patch-target)
    (setf (slot-value edit-step 'diagnosis)
          "Headless editing assumes a shell on the Pi already exists, either via an attached console or via the explicit SSH-connect handoff step.")
    (setf (slot-value edit-step 'source-target) headless-handoff-defect)
    (setf (slot-value edit-step 'patch-target) headless-handoff-patch-target)
    (list
     download-step
     decompress-step
     flash-step
     boot-step
     connect-step
     edit-step
     first-rebuild-step
     reboot-step
     switch-step)))

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

(defun official-headless-ssh-connect-handoff-defect ()
  "Return the relation-level defect object for the missing headless-connect transition between boot and configuration edit."
  (or (source-target-of (official-rpi-tutorial-step "official-edit-configuration"))
      (error "Missing source-target defect for official edit step.")))

(defun official-headless-ssh-connect-handoff-patch-target ()
  "Return the patch-target object for the explicit boot -> SSH connect -> configuration edit handoff."
  (or (patch-target-of (official-rpi-tutorial-step "official-boot-pi"))
      (error "Missing patch-target object for official boot step.")))

(defun rpi-first-boot-access-command-plan
    (&key
       (model :official)
       (network-reachable-p t)
       (ssh-login-ready-p nil)
       (host-or-ip "kioskberrli.local")
       (admin-user "rgb"))
  "Return a semantic runbook for first-boot access decisions without executing network actions.

MODEL accepts :OFFICIAL for the stock official SD-image path and :CUSTOM-IMAGE
for the fully headless preconfigured-image path."
  (labels ((make-step (id title summary &key diagnosis commands)
             (make-instance 'sd-card-procedure-step
                            :id id
                            :title title
                            :summary summary
                            :diagnosis diagnosis
                            :commands commands))
           (make-runbook (id title summary section)
             (let ((runbook (make-instance 'sd-card-runbook
                                           :id id
                                           :title title
                                           :summary summary
                                           :sections (list section))))
               (setf (slot-value runbook 'raw-structure)
                     (sd-card-runbook->raw-structure runbook))
               runbook)))
    (ecase model
      (:official
       (let* ((boot-step (official-rpi-tutorial-step "official-boot-pi"))
              (connect-step (official-rpi-tutorial-step "official-connect-pi-over-ssh"))
              (edit-step (official-rpi-tutorial-step "official-edit-configuration"))
              (bootstrap-step
                (make-step "official-local-console-bootstrap"
                           "Continue from local console to establish remote access"
                           "Use a directly attached console once to set a password or authorized key, confirm sshd, and discover hostname/IP before returning to the SSH continuation step."
                           :diagnosis
                           "This is the semi-headless bootstrap path: stock official boot is not assumed to be SSH-ready."
                           :commands
                           (list "sudo systemctl status sshd"
                                 "hostname"
                                 "ip -brief address"
                                 "# set password or install an authorized key through the local console path")))
              (remote-ready-p (and network-reachable-p ssh-login-ready-p))
              (continuation-note
                (cond (remote-ready-p
                       "Remote continuation is valid: the booted official image is reachable and a usable SSH/login path already exists.")
                      (network-reachable-p
                       "Network is reachable, but SSH/login prerequisites are still missing. Use a local console once, then resume remote maintenance over SSH.")
                      (t
                       "No confirmed network path exists yet. Stop remote continuation and continue from a local console.")))
              (steps (if remote-ready-p
                         (list boot-step connect-step edit-step)
                         (list boot-step bootstrap-step connect-step edit-step)))
              (section (make-instance 'sd-card-runbook-section
                                      :id "official-sd-image-first-boot-access"
                                      :title "Official SD image first-boot access"
                                      :summary "Decision path for the stock official Raspberry Pi SD-image workflow."
                                      :steps steps
                                      :continuation-note continuation-note
                                      :raw-structure
                                      (list :section "Official SD image first-boot access"
                                            :model :official
                                            :network-reachable-p network-reachable-p
                                            :ssh-login-ready-p ssh-login-ready-p))))
         (make-runbook "rpi-first-boot-access-official"
                       "Raspberry Pi first-boot access paths"
                       "Stock official SD-image first boot with either remote continuation or one-time local-console bootstrap."
                       section)))
      (:custom-image
       (let* ((preseed-step
                (make-step "custom-image-preseeded-access"
                           "Build a custom image with preseeded access"
                           "Fully headless first boot requires OpenSSH, a normal admin user, and an authorized key already present in the image."
                           :diagnosis
                           "This is a different access path from stock official SD-image boot, but it still converges on the same post-boot maintenance flow."))
              (boot-step
                (make-step "custom-image-boot-pi"
                           "Boot the preconfigured custom image"
                           "Boot the flashed custom image on the Pi and wait for it to join the network with its predeclared access path."))
              (discover-step
                (make-step "custom-image-discover-host"
                           "Discover hostname or IP on the network"
                           "Determine the host or IP that the preconfigured image obtained after boot."
                           :commands
                           (list (format nil "PI_HOST_OR_IP=\"${PI_HOST_OR_IP:-~A}\"" host-or-ip)
                                 "ping -c 1 \"$PI_HOST_OR_IP\"")))
              (connect-step
                (make-step "custom-image-ssh-admin-login"
                           "SSH in as the declared admin user"
                           "Open an SSH session as the normal admin user declared in the custom image."
                           :commands
                           (list (format nil "SSH_TARGET=\"${SSH_TARGET:-~A@$PI_HOST_OR_IP}\"" admin-user)
                                 "ssh \"$SSH_TARGET\"")))
              (edit-step (official-rpi-tutorial-step "official-edit-configuration"))
              (section (make-instance 'sd-card-runbook-section
                                      :id "custom-image-first-boot-access"
                                      :title "Fully headless custom-image first boot"
                                      :summary "Preferred Kioskberrli maintenance path once access is declaratively preseeded into the image."
                                      :steps (list preseed-step
                                                   boot-step
                                                   discover-step
                                                   connect-step
                                                   edit-step)
                                      :continuation-note
                                      "First boot stays headless because the image already includes OpenSSH, a normal admin user, and an authorized key."
                                      :raw-structure
                                      (list :section "Fully headless custom-image first boot"
                                            :model :custom-image
                                            :host-or-ip host-or-ip
                                            :admin-user admin-user))))
         (make-runbook "rpi-first-boot-access-custom-image"
                       "Raspberry Pi first-boot access paths"
                       "Fully headless first boot for a preconfigured custom image with declared SSH access."
                       section))))))

(defun rpi-first-boot-access-dry-run
    (&key
       (stream *standard-output*)
       (model :official)
       (network-reachable-p t)
       (ssh-login-ready-p nil)
       (host-or-ip "kioskberrli.local")
       (admin-user "rgb"))
  "Print the first-boot access logic without executing network or SSH actions."
  (let* ((runbook (rpi-first-boot-access-command-plan
                   :model model
                   :network-reachable-p network-reachable-p
                   :ssh-login-ready-p ssh-login-ready-p
                   :host-or-ip host-or-ip
                   :admin-user admin-user))
         (section (first (sections-of runbook))))
    (format stream "~&Raspberry Pi first-boot access dry-run:~%")
    (ecase model
      (:official
       (format stream "  Access model: stock official SD image~%")
       (format stream "  Booted official image: yes~%")
       (format stream "  Network reachable? ~:[no~;yes~]~%" network-reachable-p)
       (format stream "  SSH/login path already configured? ~:[no~;yes~]~%" ssh-login-ready-p)
       (if (and network-reachable-p ssh-login-ready-p)
           (format stream "  Decision: open SSH session path and continue remotely.~%")
           (progn
             (format stream "  Decision: stop and continue from local console.~%")
             (format stream "  Path: semi-headless bootstrap, then resume SSH continuation.~%"))))
      (:custom-image
       (format stream "  Access model: fully headless custom image~%")
       (format stream "  Custom image includes OpenSSH + authorized key: yes~%")
       (format stream "  Host/IP hint: ~A~%" host-or-ip)
       (format stream "  Admin user: ~A~%" admin-user)
       (format stream "  Decision: boot, discover host/IP, and SSH in as the normal admin user.~%")))
    (format stream "~&~A~%" (title-of section))
    (loop for step in (steps-of section)
          for n from 1
          do (progn
               (format stream "  ~2D. ~A~%" n (title-of step))
               (when (commands-of step)
                 (loop for command in (commands-of step)
                       do (format stream "      - ~A~%" command)))))
    (when (continuation-note-of section)
      (format stream "~&Continuation: ~A~%" (continuation-note-of section)))
    (format stream "~&Note: this is a dry-run printout; no network, SSH, or shell command was executed.~%")
    runbook))

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

(defexample rpi-first-boot-access-dry-run-example
  "Return inspectable dry-run transcripts for the first-boot access paths in this slice."
  (flet ((transcript (title &rest args)
           (let (runbook)
             (let ((text (with-output-to-string (stream)
                           (setf runbook
                                 (apply #'rpi-first-boot-access-dry-run
                                        :stream stream
                                        args)))))
               (make-instance 'sd-card-dry-run-transcript
                              :title title
                              :transcript text
                              :runbook runbook)))))
    (list :official-remote-ready
          (transcript "Stock official SD image with remote continuation (dry-run)"
                      :model :official
                      :network-reachable-p t
                      :ssh-login-ready-p t
                      :host-or-ip "pi.local")
          :official-needs-local-console
          (transcript "Stock official SD image with semi-headless bootstrap (dry-run)"
                      :model :official
                      :network-reachable-p t
                      :ssh-login-ready-p nil
                      :host-or-ip "pi.local")
          :fully-headless-custom-image
          (transcript "Fully headless custom image first boot (dry-run)"
                      :model :custom-image
                      :host-or-ip "kioskberrli.local"
                      :admin-user "rgb"))))

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
                "official-connect-pi-over-ssh"
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

(defexample official-rpi-headless-ssh-connect-handoff-regression-example
  "Regression check: headless continuation is modeled as an explicit boot -> SSH connect -> edit handoff."
  (let* ((inserted-step (official-rpi-tutorial-step "official-connect-pi-over-ssh"))
         (defect (official-headless-ssh-connect-handoff-defect))
         (patch (official-headless-ssh-connect-handoff-patch-target)))
    (assert defect)
    (assert patch)
    (assert-eql 'sd-card-step-handoff-defect (type-of defect))
    (assert-eql 'sd-card-step-handoff-patch-target (type-of patch))
    (assert-equal (id-of inserted-step) (id-of (inserted-step-of patch)))
    (assert-equal "official-boot-pi" (id-of (from-step-of defect)))
    (assert-equal "official-edit-configuration" (id-of (to-step-of defect)))
    (assert-equal "reachable shell session on the Pi" (required-artifact-of defect))
    (assert (commands-of inserted-step))
    (list :inserted-step (id-of inserted-step)
          :from-step (id-of (from-step-of defect))
          :to-step (id-of (to-step-of defect))
          :source-target (id-of defect)
          :patch-target (id-of patch))))

(defexample rpi-first-boot-access-dry-run-regression-example
  "Regression check: first-boot access dry-runs cover stock-remote, semi-headless bootstrap, and fully headless custom-image paths."
  (let (official-remote-runbook official-local-runbook custom-runbook)
    (let* ((official-remote-text
             (with-output-to-string (stream)
               (setf official-remote-runbook
                     (rpi-first-boot-access-dry-run
                      :stream stream
                      :model :official
                      :network-reachable-p t
                      :ssh-login-ready-p t
                      :host-or-ip "pi.local"))))
           (official-local-text
             (with-output-to-string (stream)
               (setf official-local-runbook
                     (rpi-first-boot-access-dry-run
                      :stream stream
                      :model :official
                      :network-reachable-p t
                      :ssh-login-ready-p nil
                      :host-or-ip "pi.local"))))
           (custom-text
             (with-output-to-string (stream)
               (setf custom-runbook
                     (rpi-first-boot-access-dry-run
                      :stream stream
                      :model :custom-image
                      :host-or-ip "kioskberrli.local"
                      :admin-user "rgb")))))
      (assert-eql 'sd-card-runbook (type-of official-remote-runbook))
      (assert-eql 'sd-card-runbook (type-of official-local-runbook))
      (assert-eql 'sd-card-runbook (type-of custom-runbook))
      (assert (search "Access model: stock official SD image" official-remote-text))
      (assert (search "Decision: open SSH session path and continue remotely." official-remote-text))
      (assert (search "SSH/login path already configured? yes" official-remote-text))
      (assert (search "Access model: stock official SD image" official-local-text))
      (assert (search "Decision: stop and continue from local console." official-local-text))
      (assert (search "Path: semi-headless bootstrap, then resume SSH continuation." official-local-text))
      (assert (search "Continue from local console to establish remote access" official-local-text))
      (assert (search "Access model: fully headless custom image" custom-text))
      (assert (search "Custom image includes OpenSSH + authorized key: yes" custom-text))
      (assert (search "Decision: boot, discover host/IP, and SSH in as the normal admin user." custom-text))
      (assert (search "SSH_TARGET=\"${SSH_TARGET:-rgb@$PI_HOST_OR_IP}\"" custom-text))
      (list :official-remote-summary (summary-of official-remote-runbook)
            :official-local-summary (summary-of official-local-runbook)
            :custom-summary (summary-of custom-runbook)))))

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

(defexample rpi-first-boot-access-page-wiring-regression-example
  "Regression check: the Pi first-boot access slice is linked from the edited HyperDoc pages."
  (flet ((page-string (path)
           (uiop:read-file-string (asdf:system-relative-pathname :hyperdoc path))))
    (let* ((specs '(("hyperdoc/official-tutorial-nixos-sd-image-on-raspberry-pi-4-400.html"
                     "hyperbook=\"topics\" page=\"Raspberry Pi first-boot access paths\""
                     "expr=\"(hyperdoc::rpi-first-boot-access-dry-run-example)\"")
                    ("hyperdoc/Prepare the AArch64 image.html"
                     "hyperbook=\"topics\" page=\"Raspberry Pi first-boot access paths\""
                     "expr=\"(hyperdoc::rpi-first-boot-access-dry-run-example)\"")
                    ("hyperdoc/Runbook - Build and Flash NixOS SD Image for Kioskberrli.html"
                     "hyperbook=\"topics\" page=\"Raspberry Pi first-boot access paths\""
                     "expr=\"(hyperdoc::rpi-first-boot-access-dry-run-example)\"")
                    ("hyperdoc/Salon Pi 4 Kiosk Hardening Checklist.html"
                     "hyperbook=\"topics\" page=\"Raspberry Pi first-boot access paths\""
                     "hyperbook=\"topics\" page=\"Kioskberrli preconfigured headless image\"")
                    ("hyperdoc/two-installation-models-sd-image-vs-classic-installer.html"
                     "hyperbook=\"topics\" page=\"Raspberry Pi first-boot access paths\""
                     "expr=\"(hyperdoc::rpi-first-boot-access-dry-run-example)\"")))
           (results
             (loop for (path required-a required-b) in specs
                   for html = (page-string path)
                   do (progn
                        (assert (search required-a html))
                        (assert (search required-b html)))
                   collect (list :page path
                                 :required-a required-a
                                 :required-b required-b))))
      (assert (search "openssh.authorizedKeys.keys"
                      (page-string "hyperdoc/Salon Pi 4 Kiosk Hardening Checklist.html")))
      (list :pages results
            :snippet-page "hyperdoc/Salon Pi 4 Kiosk Hardening Checklist.html"))))

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

;;
;; dreyeck.ch cautious deployment runner
;;

(defparameter *dreyeck-deploy-sequence*
  '(:backup-dreyeck
    :record-dreyeck-generation
    :verify-dreyeck-local-flake
    :dry-activate-dreyeck
    :test-dreyeck
    :verify-dreyeck-http
    :switch-dreyeck))

(defparameter *dreyeck-rehearsal-sequence*
  '(:backup-dreyeck
    :record-dreyeck-generation
    :verify-dreyeck-local-flake
    :dry-activate-dreyeck
    :test-dreyeck
    :verify-dreyeck-http))

(defun normalize-dreyeck-deploy-action (action)
  (let ((keyword (etypecase action
                   (keyword action)
                   (symbol (alexandria:make-keyword (symbol-name action)))
                   (string (alexandria:make-keyword action)))))
    (unless (member keyword
                    '(:backup-dreyeck
                      :record-dreyeck-generation
                      :verify-dreyeck-local-flake
                      :dry-activate-dreyeck
                      :test-dreyeck
                      :verify-dreyeck-http
                      :rehearse-dreyeck
                      :switch-dreyeck
                      :rollback-dreyeck)
                    :test #'eq)
      (error "Unknown dreyeck deployment action: ~A" action))
    keyword))

(defun dreyeck-nixos-rebuild-command (mode &key build-host target-host print-only)
  (when (and (not print-only) (null target-host))
    (error "Action ~A requires :target-host when executing. Use :print-only t to emit placeholders."
           mode))
  (let ((target (or target-host "<ssh-target>")))
    (format nil
            "nixos-rebuild ~A --flake .#dreyeck-ch~@[ --build-host ~A~] --target-host ~A"
            mode
            build-host
            target)))

(defun dreyeck-remote-shell-command (remote-command &key target-host print-only)
  (when (and (not print-only) (null target-host))
    (error "Remote action requires :target-host when executing. Use :print-only t to emit placeholders."))
  (let ((target (or target-host "<ssh-target>")))
    (list :display (format nil "ssh ~A ~S" target remote-command)
          :argv (list "ssh" target remote-command))))

(defun dreyeck-deploy-action-commands
    (action &key build-host target-host print-only)
  (let ((action* (normalize-dreyeck-deploy-action action)))
    (case action*
      (:backup-dreyeck
       (list
        (dreyeck-remote-shell-command
         "sudo mkdir -p /root/pre-hyperdoc-backup"
         :target-host target-host
         :print-only print-only)
        (dreyeck-remote-shell-command
         "sudo tar czf /root/pre-hyperdoc-backup/etc-nixos-$(date +%F-%H%M%S).tar.gz /etc/nixos"
         :target-host target-host
         :print-only print-only)
        (dreyeck-remote-shell-command
         "sudo tar czf /root/pre-hyperdoc-backup/hyperdoc-data-$(date +%F-%H%M%S).tar.gz /var/lib/hyperdoc /home/rgb/workspace/hyperdoc 2>/dev/null || true"
         :target-host target-host
         :print-only print-only)))
      (:record-dreyeck-generation
       (list
        (dreyeck-remote-shell-command
         "sudo sh -c '{ echo \"# $(date -Is)\"; echo; echo \"## generations\"; nixos-rebuild list-generations; echo; echo \"## current-system\"; readlink -f /run/current-system; echo; echo \"## booted-system\"; readlink -f /run/booted-system; } > /root/pre-hyperdoc-backup/rollback-reference.txt'"
         :target-host target-host
         :print-only print-only)))
      (:verify-dreyeck-local-flake
       (list
        "git status --short"
        "nix flake check"
        "nix run .#release-smoke"))
      (:dry-activate-dreyeck
       (list (dreyeck-nixos-rebuild-command
              "dry-activate"
              :build-host build-host
              :target-host target-host
              :print-only print-only)))
      (:test-dreyeck
       (list (dreyeck-nixos-rebuild-command
              "test"
              :build-host build-host
              :target-host target-host
              :print-only print-only)))
      (:verify-dreyeck-http
       (list
        "curl -I https://dreyeck.ch/boot.html"
        "curl -I \"https://dreyeck.ch/584FD-hyperdoc/Official%20Tutorial%3A%20NixOS%20SD%20Image%20on%20Raspberry%20Pi%204%2F400\""
        "curl -I https://dreyeck.ch/hyperbook-server/js/url.js"))
      (:switch-dreyeck
       (list (dreyeck-nixos-rebuild-command
              "switch"
              :build-host build-host
              :target-host target-host
              :print-only print-only)))
      (:rollback-dreyeck
       (list
        "sudo nixos-rebuild switch --rollback"
        "sudo /nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch")))))

(defun run-dreyeck-shell-command (command &key (print-only t) (stream *standard-output*))
  (let* ((display (if (stringp command)
                      command
                      (getf command :display)))
         (argv (if (stringp command)
                   (list "/bin/sh" "-lc" command)
                   (getf command :argv))))
    (unless (and display argv)
      (error "Malformed command descriptor: ~S" command))
    (format stream "~&$ ~A~%" display)
  (finish-output stream)
  (unless print-only
    (let* ((process (uiop:launch-program
                     argv
                     :output *standard-output*
                     :error-output *error-output*
                     :ignore-error-status t))
           (exit-code (uiop:wait-process process)))
      (unless (zerop exit-code)
        (error "Command failed with exit code ~D: ~A" exit-code display))))))

(defun run-dreyeck-deploy-action
    (action &key build-host target-host (print-only t) (stream *standard-output*))
  "Run one cautious deployment action for dreyeck.ch.
When PRINT-ONLY is true, only print commands without executing shell actions."
  (let ((action* (normalize-dreyeck-deploy-action action)))
    (if (eq action* :rehearse-dreyeck)
        (dolist (inner-action *dreyeck-rehearsal-sequence*)
          (run-dreyeck-deploy-action
           inner-action
           :build-host build-host
           :target-host target-host
           :print-only print-only
           :stream stream))
        (dolist (command (dreyeck-deploy-action-commands
                          action*
                          :build-host build-host
                          :target-host target-host
                          :print-only print-only))
          (run-dreyeck-shell-command command :print-only print-only :stream stream)))
    action*))

(defun run-dreyeck-deploy-sequence
    (&key build-host target-host (print-only t) (stream *standard-output*))
  "Run or print the canonical cautious sequence:
backup -> record -> verify-local -> dry-activate -> test -> verify-http -> switch."
  (dolist (action *dreyeck-deploy-sequence*)
    (run-dreyeck-deploy-action
     action
     :build-host build-host
     :target-host target-host
     :print-only print-only
     :stream stream))
  *dreyeck-deploy-sequence*)
