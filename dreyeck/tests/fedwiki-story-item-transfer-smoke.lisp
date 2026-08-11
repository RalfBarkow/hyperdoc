;;;; Deterministic tests for inspectable FedWiki story-item transfers.

(defpackage #:dreyeck/fedwiki-story-item-transfer/tests
  (:use #:cl)
  (:import-from #:dreyeck/fedwiki-story-item-transfer
                #:story-item-transfer
                #:story-item-transfer-action
                #:story-item-transfer-source-page
                #:story-item-transfer-source-origin
                #:story-item-transfer-story-item
                #:story-item-transfer-target
                #:story-item-transfer-outcome
                #:prepare-story-item-transfer
                #:story-item-transfer-stored-resource-reference
                #:story-item-transfer-resolved-resource-url
                #:fedwiki-image-reference-transfer-example)
  (:export #:run-fedwiki-story-item-transfer-tests))

(in-package #:dreyeck/fedwiki-story-item-transfer/tests)

(defparameter +caption+
  "[https://codeberg.org/rgb/hyperdoc/commit/c4d5825db5e4503193d6220aa2acfef5a7ad0928#diff-3c683a78b769ee09cd5b94252fe3ef1f174ad06a diff]")

(defparameter +stored-image-reference+
  "/assets/plugins/image/4119ed51173a75fc6ccde4cf7f7abc34.jpg")

(defparameter +resolved-image-url+
  "https://hyperdoc.dreyeck.ch/assets/plugins/image/4119ed51173a75fc6ccde4cf7f7abc34.jpg")

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun make-initialized-wiki (site-reference)
  (let ((wiki
          (make-instance 'hyperbook/fedwiki::fedwiki
                         :id (concatenate 'string
                                          "fedwiki:"
                                          site-reference))))
    (setf (hyperbook/fedwiki::status-of wiki) t)
    wiki))

(defun install-story-item-fixture
    (page type text &key
                      (id "story-item-fixture")
                      url width height size)
  (let ((page-json (make-hash-table :test #'equal))
        (item-json (make-hash-table :test #'equal)))
    (setf (gethash "title" page-json) "Fixture page"
          (gethash "story" page-json) (vector item-json)
          (gethash "journal" page-json) #()
          (gethash "type" item-json) (string-downcase (symbol-name type))
          (gethash "id" item-json) id
          (gethash "text" item-json) text)
    (when url
      (setf (gethash "url" item-json) url))
    (when width
      (setf (gethash "width" item-json) width))
    (when height
      (setf (gethash "height" item-json) height))
    (when size
      (setf (gethash "size" item-json) size))
    (hyperbook/fedwiki::set-page-data page page-json)
    (aref (hyperbook/fedwiki::story-of page) 0)))

(defun transfer-slot-names ()
  (mapcar
   (lambda (slot)
     (intern (symbol-name (closer-mop:slot-definition-name slot)) :keyword))
   (closer-mop:class-slots (find-class 'story-item-transfer))))

(defun run-story-item-reference-transfer-test ()
  (let* ((origin (make-initialized-wiki "hyperdoc.dreyeck.ch"))
         (source-page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "wiki-links" "Wiki Links"))
         (story-item
           (install-story-item-fixture
            source-page :image +caption+
            :id "64368aba4c333703"
            :url +stored-image-reference+
            :width 399
            :height 129
            :size "wide"))
         (source-story (hyperbook/fedwiki::story-of source-page))
         (source-data (hyperbook/fedwiki::data-of story-item))
         (target (list :hyperdoc-page "diagnostic target"))
         (transfer
           (prepare-story-item-transfer
            source-page story-item :action :reference :target target)))
    (check (typep transfer 'story-item-transfer)
           "REFERENCE did not produce a STORY-ITEM-TRANSFER: ~S."
           transfer)
    (check (equal '(:action :source-page :source-origin
                    :story-item :target :outcome)
                  (transfer-slot-names))
           "Transfer stores redundant or missing facts: ~S."
           (transfer-slot-names))
    (check (eq :reference (story-item-transfer-action transfer))
           "Transfer action is ~S instead of :REFERENCE."
           (story-item-transfer-action transfer))
    (check (eq source-page (story-item-transfer-source-page transfer))
           "Transfer did not preserve the source-page object.")
    (check (eq origin (story-item-transfer-source-origin transfer))
           "Transfer did not retain ORIGIN-OF the source page.")
    (check (eq story-item (story-item-transfer-story-item transfer))
           "REFERENCE did not retain story-item identity.")
    (check (eq target (story-item-transfer-target transfer))
           "Transfer did not retain the diagnostic target.")
    (check (eq story-item (story-item-transfer-outcome transfer))
           "REFERENCE outcome is not the identical story-item object.")
    (check (eq source-story (hyperbook/fedwiki::story-of source-page))
           "REFERENCE replaced the source story vector.")
    (check (eq story-item (aref source-story 0))
           "REFERENCE replaced the story item in its source story.")
    (check (eq source-data (hyperbook/fedwiki::data-of story-item))
           "REFERENCE replaced the story-item data object.")
    (check (= 399 (gethash "width" source-data))
           "REFERENCE changed image width metadata.")
    (check (= 129 (gethash "height" source-data))
           "REFERENCE changed image height metadata.")
    (check (string= "wide" (gethash "size" source-data))
           "REFERENCE changed image size metadata.")
    (check (string= +caption+ (hyperbook/fedwiki::text-of story-item))
           "REFERENCE changed the story-item caption.")
    (check (string= +stored-image-reference+
                    (story-item-transfer-stored-resource-reference transfer))
           "Stored image resource reference differs.")
    (check (string= +resolved-image-url+
                    (story-item-transfer-resolved-resource-url transfer))
           "Resolved image resource URL differs."))
  t)

(defun run-remote-page-origin-test ()
  (let* ((containing-wiki (make-initialized-wiki "dreyeck.ch"))
         (origin-wiki (make-initialized-wiki "hyperdoc.dreyeck.ch"))
         (source-page
           (make-instance 'hyperbook/fedwiki::remote-fedwiki-page
                          :hyperbook containing-wiki
                          :id "hyperdoc.dreyeck.ch/wiki-links"
                          :title "Wiki Links"
                          :origin origin-wiki
                          :origin-id "wiki-links"))
         (story-item
           (install-story-item-fixture
            source-page :image "Remote image"
            :url +stored-image-reference+))
         (transfer
           (prepare-story-item-transfer source-page story-item)))
    (check (eq origin-wiki (story-item-transfer-source-origin transfer))
           "Remote transfer used its containing wiki instead of its origin.")
    (check (not (eq containing-wiki
                    (story-item-transfer-source-origin transfer)))
           "Remote transfer collapsed source origin into HYPERBOOK-OF.")
    (check (string= +resolved-image-url+
                    (story-item-transfer-resolved-resource-url transfer))
           "Remote transfer did not resolve against the actual origin."))
  t)

(defun run-absolute-resource-url-test ()
  (let* ((origin (make-initialized-wiki "hyperdoc.dreyeck.ch"))
         (source-page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "absolute-image" "Absolute image"))
         (absolute-url "https://assets.example/image.jpg")
         (story-item
           (install-story-item-fixture
            source-page :image "Absolute image" :url absolute-url))
         (transfer
           (prepare-story-item-transfer source-page story-item)))
    (check (string= absolute-url
                    (story-item-transfer-resolved-resource-url transfer))
           "Absolute image URL changed during transfer preparation."))
  t)

(defun signals-condition-p (condition-type thunk)
  (handler-case
      (progn (funcall thunk) nil)
    (condition (caught)
      (check (typep caught condition-type)
             "Expected ~S, but caught ~S."
             condition-type caught)
      t)))

(defun run-generic-reference-contract-test ()
  (let* ((origin (make-initialized-wiki "offline.example"))
         (source-page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "paragraph" "Paragraph"))
         (story-item
           (install-story-item-fixture
            source-page :paragraph "A generic story item."))
         (foreign-page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "foreign" "Foreign"))
         (foreign-item
           (install-story-item-fixture
            foreign-page :paragraph "Not in the source story."))
         (transfer
           (prepare-story-item-transfer source-page story-item)))
    (check (eq :paragraph (hyperbook/fedwiki::item-type-of story-item))
           "Generic fixture is unexpectedly image-specific.")
    (check (eq story-item (story-item-transfer-outcome transfer))
           "Generic REFERENCE did not preserve story-item identity.")
    (check (signals-condition-p
            'error
            (lambda ()
              (prepare-story-item-transfer source-page foreign-item)))
           "A foreign story item was accepted for the source page.")
    (check (signals-condition-p
            'type-error
            (lambda ()
              (prepare-story-item-transfer
               source-page story-item :action :copy)))
           ":COPY was accepted despite its deliberately deferred contract."))
  t)

(defun reference-value-present-p (value view)
  (find value
        (html-inspector-views:view-references view)
        :key #'cdr
        :test #'eq))

(defun run-example-and-inspector-view-test ()
  (check (fboundp 'fedwiki-image-reference-transfer-example)
         "The image transfer DEFEXAMPLE is not fbound.")
  (let* ((transfer (fedwiki-image-reference-transfer-example))
         (view
           (find "FedWiki story-item transfer"
                 (html-inspector-views:all-views transfer)
                 :key #'html-inspector-views:view-title
                 :test #'string=)))
    (check (typep transfer 'story-item-transfer)
           "The DEFEXAMPLE did not return a STORY-ITEM-TRANSFER.")
    (check (eq :reference (story-item-transfer-action transfer))
           "The DEFEXAMPLE action is not :REFERENCE.")
    (check view "The transfer's specialized inspector view is absent.")
    (html-inspector-views:view-html view)
    (check (reference-value-present-p
            (story-item-transfer-source-page transfer) view)
           "Source page is not an inspector OBJECT-REF.")
    (check (reference-value-present-p
            (story-item-transfer-source-origin transfer) view)
           "Source origin is not an inspector OBJECT-REF.")
    (check (reference-value-present-p
            (story-item-transfer-story-item transfer) view)
           "Story item is not an inspector OBJECT-REF.")
    (check (string= +resolved-image-url+
                    (story-item-transfer-resolved-resource-url transfer))
           "The DEFEXAMPLE derives a different image resource URL."))
  t)

(defun substrings-between (string opening closing)
  (loop with position = 0
        for open = (search opening string :start2 position)
        while open
        for content-start = (+ open (length opening))
        for close = (search closing string :start2 content-start)
        do (check close "Unclosed ~A tag in the transfer page." opening)
        collect (subseq string content-start close)
        do (setf position (+ close (length closing)))))

(defun normalize-whitespace (string)
  (format nil "~{~A~^ ~}"
          (remove-if
           (lambda (part) (zerop (length part)))
           (uiop:split-string
            string :separator '(#\Space #\Tab #\Newline #\Return)))))

(defun run-hyperdoc-page-test ()
  (let* ((page-path
           (asdf:system-relative-pathname
            :dreyeck/wiki-link
            "dreyeck/pages/FedWiki story-item transfer as an inspectable operation.html"))
         (html (uiop:read-file-string page-path))
         (normalized-html (normalize-whitespace html))
         (dom (plump:parse page-path))
         (function-names
           (substrings-between html
                               "<source-of-function>"
                               "</source-of-function>")))
    (check (search
            "We first materialize the transfer operation. Browser gestures can be added later as ways to invoke it."
            normalized-html)
           "The HyperDoc page does not state the operation-first boundary.")
    (check (search "future IMPORT" html)
           "The HyperDoc page does not retain the import architecture question.")
    (check (equal '("fedwiki-image-reference-transfer-example")
                  function-names)
           "Executable example references differ: ~S."
           function-names)
    (let ((*package*
            (find-package :dreyeck/fedwiki-story-item-transfer))
          (expression-count 0))
      (dolist (element (plump:get-elements-by-tag-name dom "a"))
        (let ((expression (plump:attribute element "expr")))
          (when expression
            (incf expression-count)
            (check (eval (read-from-string expression))
                   "HyperDoc source expression ~S does not resolve."
                   expression))))
      (check (= 3 expression-count)
             "The HyperDoc page has ~D source links instead of three."
             expression-count)))
  t)

(defun run-fedwiki-story-item-transfer-tests ()
  (run-story-item-reference-transfer-test)
  (run-remote-page-origin-test)
  (run-absolute-resource-url-test)
  (run-generic-reference-contract-test)
  (run-example-and-inspector-view-test)
  (run-hyperdoc-page-test)
  (format t "FedWiki story-item transfer tests passed.~%")
  t)
