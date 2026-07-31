;;;; Read-only discovery of possible page-attached ASDF entrypoints.

(in-package :hyperdoc)

(defstruct fedwiki-asdf-asset-candidate
  "One observed Assets story item and its bounded filesystem result."
  story-item-id
  raw-text
  asset-reference
  reference-status
  resolution-status
  resolved-asset-root
  asd-candidates
  diagnostics
  evidence-source)

(defstruct fedwiki-asdf-asset-discovery
  "A completed read-only discovery over one loaded FedWiki page."
  page-site
  page-slug
  page-title
  observed-at
  source-page
  site-root
  site-asset-root
  assets-items
  completion-status)

(defun fedwiki-asdf-discovery-absolute-reference-p (text)
  (and (plusp (length text))
       (char= (char text 0) #\/)))

(defun fedwiki-asdf-discovery-invalid-reference-character-p (character)
  (or (char= character #\\)
      (char= character #\:)
      (char= character #\*)
      (char= character #\?)
      (char< character #\Space)
      (char= character #\Rubout)))

(defun fedwiki-asdf-discovery-parent-segment-p (segments)
  (some (lambda (segment)
          (or (string= segment ".")
              (string= segment "..")))
        segments))

(defun fedwiki-asdf-discovery-normalize-asset-reference (raw-text)
  (let ((trimmed
          (and (stringp raw-text)
               (string-trim '(#\Space #\Tab #\Newline #\Return)
                            raw-text))))
    (cond
      ((or (null trimmed) (zerop (length trimmed)))
       (values nil :invalid-asset-reference :not-attempted
               "The Assets story-item text is empty."))
      ((fedwiki-asdf-discovery-absolute-reference-p trimmed)
       (values nil :invalid-asset-reference
               :asset-reference-outside-site-root
               "An asset reference must be relative to the site asset root."))
      ((find-if #'fedwiki-asdf-discovery-invalid-reference-character-p
                trimmed)
       (values nil :invalid-asset-reference :not-attempted
               "The Assets story-item text is not a safe relative reference."))
      (t
       (let ((segments (uiop:split-string trimmed :separator '(#\/))))
         (cond
           ((some (lambda (segment) (zerop (length segment))) segments)
            (values nil :invalid-asset-reference :not-attempted
                    "The asset reference contains an empty path segment."))
           ((fedwiki-asdf-discovery-parent-segment-p segments)
            (values nil :invalid-asset-reference
                    :asset-reference-outside-site-root
                    "The asset reference contains a dot path segment."))
           (t
            (values (format nil "~{~A~^/~}" segments)
                    :valid-asset-reference :not-attempted nil))))))))

(defun fedwiki-asdf-discovery-site-asset-root (site-root)
  (merge-pathnames
   #P"assets/"
   (uiop:ensure-directory-pathname
    (uiop:ensure-absolute-pathname site-root (uiop:getcwd)))))

(defun fedwiki-asdf-discovery-subpath-p (pathname root)
  (not (null (uiop:subpathp pathname root))))

(defun fedwiki-asdf-discovery-resolve-asset-root
    (asset-reference site-asset-root)
  (let* ((asset-root
           (merge-pathnames
            (uiop:ensure-directory-pathname asset-reference)
            site-asset-root))
         (existing-site-root (uiop:directory-exists-p site-asset-root))
         (existing-asset-root (uiop:directory-exists-p asset-root)))
    (cond
      ((not (fedwiki-asdf-discovery-subpath-p asset-root site-asset-root))
       (values nil :asset-reference-outside-site-root
               "The resolved pathname leaves the configured site asset root."))
      ((and existing-site-root
            existing-asset-root
            (not (fedwiki-asdf-discovery-subpath-p
                  (uiop:resolve-symlinks existing-asset-root)
                  (uiop:resolve-symlinks existing-site-root))))
       (values nil :asset-reference-outside-site-root
               "The existing asset directory leaves the site asset root through a filesystem link."))
      ((null existing-asset-root)
       (values asset-root :asset-root-missing
               "The resolved asset directory does not exist."))
      (t
       (values asset-root :asset-root-resolved nil)))))

(defun fedwiki-asdf-discovery-immediate-asd-files (asset-root)
  (sort
   (loop for file in (uiop:directory-files asset-root)
         when (and (pathname-type file)
                   (string-equal (pathname-type file) "asd"))
           collect file)
   #'string<
   :key #'namestring))

(defun fedwiki-asdf-discovery-last-reference-segment (asset-reference)
  (car (last (uiop:split-string asset-reference :separator '(#\/)))))

(defun fedwiki-asdf-discovery-file-observation (pathname asset-root)
  (handler-case
      (let* ((resolved-root (uiop:resolve-symlinks asset-root))
             (expected-path
               (merge-pathnames (file-namestring pathname) resolved-root))
             (resolved-path (uiop:resolve-symlinks pathname))
             (symbolic-link-p
               (not (uiop:pathname-equal expected-path resolved-path))))
        (values (if symbolic-link-p :symbolic-link :regular-file)
                (and symbolic-link-p resolved-path)
                (if symbolic-link-p
                    :not-validated-for-activation
                    :not-applicable)))
    (error (condition)
      (values :not-determined nil
              (list :observation-failed (princ-to-string condition))))))

(defun fedwiki-asdf-discovery-asd-candidate-records
    (pathnames asset-reference asset-root)
  (let ((conventional-basename
          (fedwiki-asdf-discovery-last-reference-segment asset-reference)))
    (loop for pathname in pathnames
          collect
          (multiple-value-bind (file-kind link-target link-target-status)
              (fedwiki-asdf-discovery-file-observation pathname asset-root)
            (list :pathname pathname
                  :file-kind file-kind
                  :link-target link-target
                  :link-target-status link-target-status
                  :convention-status
                  (if (and (pathname-name pathname)
                           (string= (pathname-name pathname)
                                    conventional-basename))
                      :convention-matching-candidate
                      :no-convention-match))))))

(defun fedwiki-asdf-asset-candidate-candidate-cardinality (candidate)
  (if (eq (fedwiki-asdf-asset-candidate-resolution-status candidate)
          :asset-root-resolved)
      (case (length (fedwiki-asdf-asset-candidate-asd-candidates candidate))
        (0 :no-asd-candidate)
        (1 :single-asd-candidate)
        (otherwise :multiple-asd-candidates))
      :not-observed))

(defun discover-fedwiki-asdf-asset-item (item site-asset-root)
  (let ((raw-text (hyperbook/fedwiki::text-of item))
        (story-item-id (hyperbook/fedwiki::id-of item)))
    (multiple-value-bind
          (asset-reference reference-status initial-resolution-status
           reference-diagnostic)
        (fedwiki-asdf-discovery-normalize-asset-reference raw-text)
      (if (not (eq reference-status :valid-asset-reference))
          (make-fedwiki-asdf-asset-candidate
           :story-item-id story-item-id
           :raw-text raw-text
           :asset-reference nil
           :reference-status reference-status
           :resolution-status initial-resolution-status
           :resolved-asset-root nil
           :asd-candidates nil
           :diagnostics (list reference-diagnostic)
           :evidence-source item)
          (multiple-value-bind (asset-root resolution-status diagnostic)
              (fedwiki-asdf-discovery-resolve-asset-root
               asset-reference site-asset-root)
            (let ((asd-candidates
                    (and (eq resolution-status :asset-root-resolved)
                         (fedwiki-asdf-discovery-asd-candidate-records
                          (fedwiki-asdf-discovery-immediate-asd-files
                           asset-root)
                          asset-reference
                          asset-root))))
              (make-fedwiki-asdf-asset-candidate
               :story-item-id story-item-id
               :raw-text raw-text
               :asset-reference asset-reference
               :reference-status reference-status
               :resolution-status resolution-status
               :resolved-asset-root asset-root
               :asd-candidates asd-candidates
               :diagnostics (and diagnostic (list diagnostic))
               :evidence-source item)))))))

(defun fedwiki-asdf-asset-discovery-assets-item-cardinality (discovery)
  (case (length (fedwiki-asdf-asset-discovery-assets-items discovery))
    (0 :no-assets-item)
    (1 :single-assets-item)
    (otherwise :multiple-assets-items)))

(defun fedwiki-asdf-discovery-single-item (discovery)
  (let ((items (fedwiki-asdf-asset-discovery-assets-items discovery)))
    (and (null (cdr items)) (first items))))

(defun fedwiki-asdf-asset-discovery-asset-reference (discovery)
  (let ((item (fedwiki-asdf-discovery-single-item discovery)))
    (and item (fedwiki-asdf-asset-candidate-asset-reference item))))

(defun fedwiki-asdf-asset-discovery-reference-status (discovery)
  (let ((item (fedwiki-asdf-discovery-single-item discovery)))
    (cond
      (item (fedwiki-asdf-asset-candidate-reference-status item))
      ((null (fedwiki-asdf-asset-discovery-assets-items discovery))
       :not-observed)
      (t :per-assets-item))))

(defun fedwiki-asdf-asset-discovery-resolved-asset-root (discovery)
  (let ((item (fedwiki-asdf-discovery-single-item discovery)))
    (and item (fedwiki-asdf-asset-candidate-resolved-asset-root item))))

(defun fedwiki-asdf-asset-discovery-resolution-status (discovery)
  (let ((item (fedwiki-asdf-discovery-single-item discovery)))
    (cond
      (item (fedwiki-asdf-asset-candidate-resolution-status item))
      ((null (fedwiki-asdf-asset-discovery-assets-items discovery))
       :not-observed)
      (t :per-assets-item))))

(defun fedwiki-asdf-asset-discovery-asd-candidates (discovery)
  (let ((item (fedwiki-asdf-discovery-single-item discovery)))
    (and item (fedwiki-asdf-asset-candidate-asd-candidates item))))

(defun fedwiki-asdf-asset-discovery-candidate-cardinality (discovery)
  (let ((item (fedwiki-asdf-discovery-single-item discovery)))
    (cond
      (item (fedwiki-asdf-asset-candidate-candidate-cardinality item))
      ((null (fedwiki-asdf-asset-discovery-assets-items discovery))
       :not-observed)
      (t :per-assets-item))))

(defun fedwiki-asdf-asset-discovery-selection-basis (discovery)
  (case (fedwiki-asdf-asset-discovery-assets-item-cardinality discovery)
    (:no-assets-item :all-story-items-scanned)
    (:single-assets-item :single-observed-assets-item)
    (:multiple-assets-items :all-assets-items-no-implicit-selection)))

(defun fedwiki-asdf-asset-discovery-diagnostics (discovery)
  (append
   (and (eq (fedwiki-asdf-asset-discovery-assets-item-cardinality discovery)
            :multiple-assets-items)
        (list "Multiple Assets story items were observed; none was selected."))
   (loop for item in (fedwiki-asdf-asset-discovery-assets-items discovery)
         when (fedwiki-asdf-asset-candidate-diagnostics item)
           collect
           (list :story-item-id
                 (fedwiki-asdf-asset-candidate-story-item-id item)
                 :diagnostics
                 (fedwiki-asdf-asset-candidate-diagnostics item)))))

(defun fedwiki-asdf-asset-discovery-evidence (discovery)
  (list :source-page (fedwiki-asdf-asset-discovery-source-page discovery)
        :site-root (fedwiki-asdf-asset-discovery-site-root discovery)
        :site-asset-root
        (fedwiki-asdf-asset-discovery-site-asset-root discovery)
        :filesystem-observation :immediate-directory-entries-only
        :asdf-files-opened-p nil))

(defun discover-fedwiki-asdf-asset-candidates (page &key site-root)
  "Observe Assets story items in loaded PAGE and enumerate bounded .asd files.

SITE-ROOT is an explicit deployment context.  This operation does not open an
.asd file, register it with ASDF, infer a system name, or load a system."
  (check-type page hyperbook/fedwiki::fedwiki-page)
  (unless site-root
    (error "Missing explicit :SITE-ROOT for FedWiki ASDF asset discovery."))
  (let ((story (hyperbook/fedwiki::story-of page)))
    (unless story
      (error "FedWiki page ~A is not loaded; discovery does not fetch it."
             (hyperbook:id-of page)))
    (let* ((observed-at (get-universal-time))
           (absolute-site-root
             (uiop:ensure-directory-pathname
              (uiop:ensure-absolute-pathname site-root (uiop:getcwd))))
           (site-asset-root
             (fedwiki-asdf-discovery-site-asset-root absolute-site-root))
           (assets-items
             (loop for item across story
                   when (eq (hyperbook/fedwiki::item-type-of item) :assets)
                     collect
                     (discover-fedwiki-asdf-asset-item item site-asset-root))))
      (make-fedwiki-asdf-asset-discovery
       :page-site
       (hyperbook/fedwiki::domain-name-of
        (hyperbook/fedwiki::origin-of page))
       :page-slug (hyperbook/fedwiki::origin-id-of page)
       :page-title (hyperbook:title-of page)
       :observed-at observed-at
       :source-page page
       :site-root absolute-site-root
       :site-asset-root site-asset-root
       :assets-items assets-items
       :completion-status :discovery-complete))))
