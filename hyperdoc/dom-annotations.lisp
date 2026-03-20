;;;; DOM relation annotations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass dom-annotation-anchor ()
  ((strategy :initarg :strategy :reader anchor-strategy-of)
   (value :initarg :value :reader anchor-value-of)
   (selector :initarg :selector :initform nil :reader selector-of)
   (label :initarg :label :initform nil :reader label-of)
   (tag-name :initarg :tag-name :initform nil :reader tag-name-of)
   (text-snippet :initarg :text-snippet :initform nil :reader text-snippet-of)
   (object-id :initarg :object-id :initform nil :reader anchor-object-id-of)))

(defclass dom-relation-annotation ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (context-object :initarg :context-object :initform nil
                   :reader context-object-of)
   (context-view-title :initarg :context-view-title :initform nil
                       :reader context-view-title-of)
   (source-anchor :initarg :source-anchor :reader source-anchor-of)
   (target-anchor :initarg :target-anchor :reader target-anchor-of)
   (source-object :initarg :source-object :initform nil
                  :reader source-object-of)
   (target-object :initarg :target-object :initform nil
                  :reader target-object-of)
   (relation-kind :initarg :relation-kind :initform nil
                  :reader relation-kind-of)
   (note :initarg :note :initform nil :reader note-of)
   (matching-patch-target :initarg :matching-patch-target :initform nil
                          :reader matching-patch-target-of)
   (matching-defect :initarg :matching-defect :initform nil
                    :reader matching-defect-of)
   (matching-inserted-step :initarg :matching-inserted-step :initform nil
                           :reader matching-inserted-step-of)))

(defmethod print-object ((object dom-annotation-anchor) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (label-of object)
                            (anchor-value-of object)))))

(defmethod print-object ((object dom-relation-annotation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun dom-annotation-json-keyword (value)
  (intern (string-upcase value) :keyword))

(defun normalize-dom-annotation-json (value)
  (cond
    ((stringp value)
     value)
    ((hash-table-p value)
     (loop for json-key being each hash-key of value
             using (hash-value json-value)
           append (list (dom-annotation-json-keyword json-key)
                        (normalize-dom-annotation-json json-value))))
    ((vectorp value)
     (map 'list #'normalize-dom-annotation-json value))
    ((listp value)
     (mapcar #'normalize-dom-annotation-json value))
    (t
     value)))

(defun parse-dom-annotation-json (json-string)
  (let ((trimmed (and json-string
                      (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   json-string))))
    (when (and trimmed (> (length trimmed) 0))
      (with-input-from-string (stream trimmed)
        (normalize-dom-annotation-json (shasht:read-json stream))))))

(defun anchor-label-for-json (json)
  (or (getf json :label)
      (getf json :textSnippet)
      (getf json :value)
      "<unnamed-anchor>"))

(defun make-dom-annotation-anchor-from-json (json)
  (make-instance 'dom-annotation-anchor
                 :strategy (or (getf json :strategy)
                               "dom-path")
                 :value (or (getf json :value)
                            (getf json :selector)
                            "")
                 :selector (getf json :selector)
                 :label (anchor-label-for-json json)
                 :tag-name (getf json :tagName)
                 :text-snippet (getf json :textSnippet)
                 :object-id (getf json :objectId)))

(defun call-hyperdoc-runtime (symbol-name &rest arguments)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (apply (symbol-function symbol) arguments)))))

(defun maybe-official-step-for-anchor (anchor)
  (let ((step-id (anchor-object-id-of anchor)))
    (when step-id
      (call-hyperdoc-runtime "OFFICIAL-RPI-TUTORIAL-STEP" step-id))))

(defun official-workflow-patch-target-symbol-name (source-id target-id)
  (cond
    ((and (string= source-id "official-download-prebuilt-image")
          (string= target-id "official-decompress-zstd-to-img"))
     "OFFICIAL-HYDRA-LATEST-FILENAME-HANDOFF-PATCH-TARGET")
    ((and (string= source-id "official-download-prebuilt-image")
          (string= target-id "official-flash-sd-card"))
     "OFFICIAL-ZSTD-TO-IMG-HANDOFF-PATCH-TARGET")
    ((and (string= source-id "official-boot-pi")
          (string= target-id "official-edit-configuration"))
     "OFFICIAL-HEADLESS-SSH-CONNECT-HANDOFF-PATCH-TARGET")
    (t
     nil)))

(defun matched-workflow-patch-target-info (source-anchor target-anchor)
  (let* ((source-id (anchor-object-id-of source-anchor))
         (target-id (anchor-object-id-of target-anchor))
         (patch-symbol-name (and source-id
                                 target-id
                                 (official-workflow-patch-target-symbol-name
                                  source-id
                                  target-id)))
         (patch (and patch-symbol-name
                     (call-hyperdoc-runtime patch-symbol-name))))
    (when patch
      (let ((defect (call-hyperdoc-runtime "DEFECT-OF" patch))
            (inserted-step (call-hyperdoc-runtime "INSERTED-STEP-OF" patch)))
        (list :patch-target patch
              :defect defect
              :inserted-step inserted-step
              :relation-kind "matching workflow patch target"
              :note
              (or (ignore-errors (summary-of patch))
                  (ignore-errors (summary-of defect))
                  "This DOM relation matches an already modeled workflow patch target."))))))

(defun slugify-dom-relation-fragment (value)
  (let* ((value (typecase value
                  (null "anchor")
                  (string value)
                  (t (princ-to-string value))))
         (chars (loop for ch across value
                      collect (cond
                                ((alphanumericp ch)
                                 (char-downcase ch))
                                ((member ch '(#\- #\_ #\. #\/) :test #'char=)
                                 #\-)
                                (t
                                 #\-))))
         (collapsed (coerce chars 'string)))
    (string-trim "-"
                 (with-output-to-string (stream)
                   (loop with previous-dash = nil
                         for ch across collapsed
                         do (cond
                              ((char= ch #\-)
                               (unless previous-dash
                                 (write-char ch stream))
                               (setf previous-dash t))
                              (t
                               (write-char ch stream)
                               (setf previous-dash nil))))))))

(defun dom-relation-annotation-id (source-anchor target-anchor)
  (format nil "dom-relation/~A-to-~A"
          (slugify-dom-relation-fragment
           (or (anchor-object-id-of source-anchor)
               (anchor-value-of source-anchor)
               (label-of source-anchor)))
          (slugify-dom-relation-fragment
           (or (anchor-object-id-of target-anchor)
               (anchor-value-of target-anchor)
               (label-of target-anchor)))))

(defun dom-relation-annotation-title (source-anchor target-anchor)
  (format nil "DOM relation annotation: ~A -> ~A"
          (or (label-of source-anchor)
              (anchor-value-of source-anchor))
          (or (label-of target-anchor)
              (anchor-value-of target-anchor))))

(defun dom-relation-annotation-summary (source-anchor target-anchor patch-target)
  (if patch-target
      (format nil "Relation annotation between ~A and ~A within one rendered pane; this anchor pair matches an existing workflow patch target."
              (or (label-of source-anchor)
                  (anchor-value-of source-anchor))
              (or (label-of target-anchor)
                  (anchor-value-of target-anchor)))
      (format nil "Relation annotation between ~A and ~A within one rendered pane."
              (or (label-of source-anchor)
                  (anchor-value-of source-anchor))
              (or (label-of target-anchor)
                  (anchor-value-of target-anchor)))))

(defun make-dom-relation-annotation (&key context-object
                                          context-view-title
                                          source-anchor
                                          target-anchor)
  (let* ((match (matched-workflow-patch-target-info source-anchor target-anchor))
         (patch-target (getf match :patch-target))
         (defect (getf match :defect))
         (inserted-step (getf match :inserted-step))
         (source-object (or (maybe-official-step-for-anchor source-anchor)
                            (and patch-target
                                 (call-hyperdoc-runtime "FROM-STEP-OF" defect))))
         (target-object (or (maybe-official-step-for-anchor target-anchor)
                            (and patch-target
                                 (call-hyperdoc-runtime "TO-STEP-OF" defect)))))
    (make-instance 'dom-relation-annotation
                   :id (dom-relation-annotation-id source-anchor target-anchor)
                   :title (dom-relation-annotation-title source-anchor target-anchor)
                   :summary (dom-relation-annotation-summary
                             source-anchor target-anchor patch-target)
                   :context-object context-object
                   :context-view-title context-view-title
                   :source-anchor source-anchor
                   :target-anchor target-anchor
                   :source-object source-object
                   :target-object target-object
                   :relation-kind (or (getf match :relation-kind)
                                      "unclassified DOM relation")
                   :note (or (getf match :note)
                             "Anchor stability is best when elements expose data-hyperdoc-anchor-id or element ids. Relative DOM-path anchors are limited to the current rendered tree shape.")
                   :matching-patch-target patch-target
                   :matching-defect defect
                   :matching-inserted-step inserted-step)))

(defun make-dom-relation-annotation-from-json (&key context-object
                                                    context-view-title
                                                    source-json
                                                    target-json)
  (let* ((source-data (or (parse-dom-annotation-json source-json)
                          (error "Missing source DOM anchor JSON.")))
         (target-data (or (parse-dom-annotation-json target-json)
                          (error "Missing target DOM anchor JSON.")))
         (source-anchor (make-dom-annotation-anchor-from-json source-data))
         (target-anchor (make-dom-annotation-anchor-from-json target-data)))
    (make-dom-relation-annotation
     :context-object context-object
     :context-view-title context-view-title
     :source-anchor source-anchor
     :target-anchor target-anchor)))
