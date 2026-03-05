;;;; HyperDoc core
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; A HyperDoc instance refers to a collection of pages (text, code, tool).
;; stored in a directory. It also has a title, used for references,
;; and optionally the id of a main page that is shown by default
;; in an inspector.
;;
;; Text pages are stored in HTML or Markdown files. They can be reloaded
;; in order to detect new or deleted pages. Code pages are listed in a
;; system definition, meaning that their list is fixed at load time. Tool
;; pages are created by code, so their list is also fixed at load time.
;;

(defclass hyperdoc (hb:hyperbook)
  ((asdf-system-name :reader asdf-system-name-of :initarg :asdf-system-name)
   (directory :reader directory-of :initarg :directory)
   (writable :reader writable-of :initarg :writable)
   (title :reader title-of :initarg :title)
   (main-page-id :reader main-page-id-of :initarg :main-page-id)
   ;; Slots holding the pages (or their sources) of the HyperDoc
   (text-pages :reader text-pages-of :initarg :text-pages)
   (code-pages :reader code-pages-of :initarg :code-pages)
   (tools :reader tools-of :initarg :tools)
   (data :reader data-of :initarg :data)
   (pages :reader pages-of :initarg :pages)
   ;; The packages used in the HyperDoc are deduced
   ;; from the code files in hyperdoc-explorer.
   (packages :reader packages-of :initform nil)))

;; Accessor for the ASDF system
;; (a generic function to ensure it appears in the "Operations" view)

(defgeneric asdf-system-of (hd)
  (:method ((hd hyperdoc))
    (-> hd
      asdf-system-name-of
      asdf:find-system)))

;;
;; Page classes. text-class is still quite abstract, concrete
;; subclasses for HTML and Markdown pages follow later.
;;

(defclass page (hb:page)
  ((links :reader hb:links-of :initarg :links :initform nil)))

(defclass text-page (page)
  ((file :reader file-of :initarg :file)))

(defclass code-page (page)
  ((file :reader file-of :initarg :file)))

;; Inspectable topic objects used by expr links in HyperDoc pages.
(defclass topic ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (references :reader references-of :initarg :references :initform nil)))

(defun make-topic (&key id title summary references)
  (make-instance 'topic
                 :id id
                 :title title
                 :summary summary
                 :references references))

;; Core topic objects for Concepts/DMX/Topic Maps page.
(defun concept-operational-definition ()
  (make-topic
   :id "concept-operational-definition"
   :title "Concept"
   :summary "A concept is an identifiable subject with stable identity, names, occurrences, and associations."
   :references '("Operational Definition of Subject Identity"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun topic-map-operational-definition ()
  (make-topic
   :id "topic-map-operational-definition"
   :title "Topic Map"
   :summary "A topic map is a graph of topics that separates subject identity from any single document or rendering."
   :references '("Concepts, DMX Topics, and Topic Maps")))

(defun dmx-topic-operational-definition ()
  (make-topic
   :id "dmx-topic-operational-definition"
   :title "DMX Topic"
   :summary "A DMX topic is an addressable runtime topic object with type/value/association structure."
   :references '("Concepts, DMX Topics, and Topic Maps")))

;; Topic objects for AArch64 SD-image preparation flow.
(defun prepare-aarch64-image-topic ()
  (make-topic
   :id "prepare-aarch64-image"
   :title "Prepare the AArch64 image"
   :summary "Preparation phase for obtaining and validating an aarch64 NixOS SD-image artifact before flashing."
   :references '("Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun runbook-build-and-flash-sd-image-topic ()
  (make-topic
   :id "runbook-build-and-flash-sd-image"
   :title "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
   :summary "Operational sequence to build/obtain, flash, boot, and validate the SD image on Pi 4."
   :references '("Prepare the AArch64 image")))

(defun official-rpi-sd-image-tutorial-topic ()
  (make-topic
   :id "official-rpi-sd-image-tutorial"
   :title "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
   :summary "Upstream nix.dev SD-image workflow: preinstalled image, first rebuild with nixos-rebuild boot, then reboot."
   :references '("Prepare the AArch64 image")))

(defun preflight-rpi-sd-image-checklist-topic ()
  (make-topic
   :id "preflight-rpi-sd-image-checklist"
   :title "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
   :summary "Checks before reboot to verify boot partition state, extlinux files, and partition labels."
   :references '("Prepare the AArch64 image")))

(defun two-installation-models-topic ()
  (make-topic
   :id "two-installation-models-sd-vs-classic"
   :title "Two Installation Models: SD Image vs Classic Installer"
   :summary "Distinguishes prebuilt SD-image workflow from classic installer workflow to avoid command-model drift."
   :references '("Prepare the AArch64 image")))

(defun dmx-topic-912138 ()
  (make-topic
   :id "dmx-topic-912138"
   :title "DMX Topic 912138"
   :summary "External DMX topic reference for the AArch64 image preparation context."
   :references '("https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/912102/topic/912138/info")))

;; Command and artifact topics for the tutorial sequence.
(defun nix-shell-topic ()
  (make-topic
   :id "nix-shell"
   :title "nix-shell"
   :summary "Ephemeral environment launcher used to provide wget/zstd for image preparation."
   :references '("Prepare the AArch64 image")))

(defun wget-topic ()
  (make-topic
   :id "wget"
   :title "wget"
   :summary "Downloader used to fetch the selected Hydra SD-image artifact."
   :references '("Prepare the AArch64 image")))

(defun zstd-topic ()
  (make-topic
   :id "zstd"
   :title "zstd"
   :summary "Compression tool used for .img.zst artifacts."
   :references '("Prepare the AArch64 image")))

(defun unzstd-topic ()
  (make-topic
   :id "unzstd-d"
   :title "unzstd -d"
   :summary "Decompression command to convert .img.zst into a flashable .img."
   :references '("Prepare the AArch64 image")))

(defun dmesg-follow-topic ()
  (make-topic
   :id "dmesg-follow"
   :title "dmesg --follow"
   :summary "Kernel log follow mode used to observe SD-card device attach events."
   :references '("Prepare the AArch64 image")))

(defun hydra-latest-job-topic ()
  (make-topic
   :id "hydra-latest-job"
   :title "Hydra latest SD-image job"
   :summary "Hydra unstable job endpoint used to select the latest successful aarch64 SD-image build."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux")))

(defun hydra-build-323111513-topic ()
  (make-topic
   :id "hydra-build-323111513"
   :title "Hydra build 323111513"
   :summary "Concrete chosen build artifact for the current preparation pass."
   :references '("https://hydra.nixos.org/build/323111513")))

(defun hydra-latest-download-link-topic ()
  (make-topic
   :id "hydra-latest-download-link"
   :title "Hydra latest download link"
   :summary "Stable 'latest' download-by-type link for SD-image artifacts."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image"
                 "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")))

(defun hydra-sha256-topic ()
  (make-topic
   :id "hydra-sha256"
   :title "Hydra artifact SHA-256"
   :summary "Integrity hash used to verify the downloaded .img.zst artifact before decompression and flashing."
   :references '("6c0f8bffdac01aa95e66505180d51b3557b04f3ad43cf0900376528837b62d0f")))

;;
;; Create a HyperDoc instance.
;;

(defun make-hyperdoc (&key id title asdf-system-name subdirectory
                           main-page-id tools data)
  "Create a HyperDoc instance with unique identifier ID (a string) and TITLE
for the text and code pages located in SUBDIRECTORY relative to the base
directory for ASDF-SYSTEM-NAME. The main page for the HyperDoc is the
one whose id is MAIN-PAGE-ID.
TOOLS is a list of symbols naming HyperDoc tools. DATA is a list of
(SYMBOL . STRING) cons pairs in which SYMBOL names a global variable
and STRING is the title under which the variable's data is listed in
the HyperDoc's list of datasets.

Note that the recommended way to create and register a HyperDoc is
the macro DEFHYPERDOC."
  (let* ((system (asdf:find-system asdf-system-name))
         (directory (asdf:system-relative-pathname
                     asdf-system-name
                     (concatenate 'string subdirectory "/")))
         (writable (is-writable? directory))
         (component (asdf:find-component system subdirectory))
         (code-files (when component
                       (remove-if-not #'(lambda (c)
                                          (typep c 'asdf:cl-source-file))
                                      (asdf:component-children component))))
         (pages (make-hash-table :test #'equal))
         (code-pages (make-array (length code-files)
                                 :element-type '(or null code-page)
                                 :initial-element nil)))
    (assert (typep id 'string))
    (assert (typep title 'string))
    (assert (typep asdf-system-name '(or string symbol)))
    (assert (typep subdirectory '(or pathname string)))
    (assert (typep main-page-id '(or null string)))
    (assert (typep tools 'list))
    (assert (typep data 'list))
    (let ((hyperdoc (make-instance 'hyperdoc
                                   :id id
                                   :asdf-system-name asdf-system-name
                                   :directory directory
                                   :writable writable
                                   :title title
                                   :main-page-id main-page-id
                                   :code-pages code-pages
                                   :tools tools
                                   :data data
                                   :text-pages (make-hash-table :test #'equal)
                                   :pages pages)))
      ;; Initialize code and tool pages. Text pages are *not* loaded.
      ;; This happens only when they are actually required, via a call
      ;; to ensure-pages-loaded. This avoids both spurious error messages
      ;; and needless resource use for HyperDocs that are loaded for their
      ;; code, without the presence of the HyperDoc explorer machinery that
      ;; manages the user interface.
      (loop for file in code-files
            for index from 0
            do (let ((page (make-code-page hyperdoc file)))
                 (setf (gethash (title-of page) pages) page)
                 (setf (elt code-pages index) page)))
      (dolist (tool-name tools)
        (let* ((tool (get-tool tool-name))
               (title (title-of tool)))
          (setf (slot-value tool 'hyperbook) hyperdoc)
          (setf (gethash title pages) tool)))
      hyperdoc)))

;; This is most probably not the best way to test if the HyperDoc
;; directory is writeable, but Common Lisp doesn't have an obvious
;; good way to do this and I'd like to avoid OS-dependent dependencies
;; such as osicat.
(defun is-writable? (directory)
  (let ((filename (merge-pathnames directory "unlikely-filename.xxx")))
    (handler-case
        (when-let (stream (open filename :direction :output :if-exists nil))
          (close stream)
          (delete-file filename)
          t)
      (file-error nil))))

;;
;; Create page instances
;;

(defun make-text-page (hdoc file)
  "Create a page instance in HyperDoc HDOC for the page stored in FILE."
  (let* ((type (pathname-type file))
         (type-as-kw (alexandria:make-keyword (string-upcase type)))
         (page (make-instance (page-class type-as-kw)
                              :hyperbook hdoc
                              :file file)))
    (load-page page)
    page))

(defun make-code-page (hdoc code-file)
  "Create a page instance in HyperDoc HDOC for CODE-FILE"
  (let ((title (code-file-title code-file)))
    (make-instance 'code-page
                   :hyperbook hdoc
                   :id title
                   :file code-file)))

(defun code-file-title (cl-source-file)
  (->> cl-source-file
    asdf:component-pathname
    uiop:read-file-lines
    first
    (string-left-trim " ;")
    (string-right-trim " ")))


;;
;; The implementations of these generic functions
;; are in hyperdoc/explorer.
;;

(defgeneric page-class (filetype))

(defgeneric load-page (page))

;;
;; Server interface: add named data items
;;

(defmethod hb:lookup-path ((hd hyperdoc) path)
  (and (= 1 (length path))
       (or (find-page hd (first path))
           (loop for (variable . title) in (data-of hd)
                 when (equal title (first path))
                   return (symbol-value variable)))))
