;;;; Inspectable preparation of non-mutating FedWiki story-item transfers

(defpackage :dreyeck/fedwiki-story-item-transfer
  (:use :cl)
  (:import-from :hyperdoc
                #:defexample)
  (:export
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
   #:fedwiki-image-reference-transfer-example))

(in-package :dreyeck/fedwiki-story-item-transfer)

(defstruct (story-item-transfer
            (:constructor %make-story-item-transfer
                (action source-page source-origin story-item target outcome)))
  "Facts retained while preparing one non-mutating story-item transfer.

ACTION is currently :REFERENCE. SOURCE-PAGE contains STORY-ITEM by identity,
and SOURCE-ORIGIN is ORIGIN-OF that page. TARGET is a caller-supplied
diagnostic target, or NIL when no target entity has been selected. For
:REFERENCE, OUTCOME is the identical STORY-ITEM object, making the absence of
copying observable."
  (action nil :type (eql :reference))
  (source-page nil :type hyperbook/fedwiki::fedwiki-page)
  (source-origin nil :type hyperbook/fedwiki::fedwiki)
  (story-item nil :type hyperbook/fedwiki::story-item)
  target
  (outcome nil :type hyperbook/fedwiki::story-item))

(defun %validate-reference-action (action)
  (unless (eq action :reference)
    (error 'type-error
           :datum action
           :expected-type '(eql :reference)))
  action)

(defun %validate-source-story-item (source-page story-item)
  (check-type source-page hyperbook/fedwiki::fedwiki-page)
  (check-type story-item hyperbook/fedwiki::story-item)
  (let ((story (hyperbook/fedwiki::story-of source-page)))
    (unless (and (vectorp story)
                 (find story-item story :test #'eq))
      (error "Story item ~S is not present by identity in the loaded story of ~S."
             story-item source-page)))
  story-item)

(defun prepare-story-item-transfer
    (source-page story-item &key (action :reference) target)
  "Prepare an inspectable, non-mutating transfer representation.

SOURCE-PAGE must already have a loaded story containing STORY-ITEM by EQ.
The operation performs no page loading, network I/O, copying, persistence, or
source mutation. Only :REFERENCE is supported. Its OUTCOME is STORY-ITEM
itself, preserving the source object's identity. TARGET defaults to NIL
because this slice defines no mutable target entity."
  (%validate-reference-action action)
  (%validate-source-story-item source-page story-item)
  (%make-story-item-transfer
   action
   source-page
   (hyperbook/fedwiki::origin-of source-page)
   story-item
   target
   story-item))

(defun %image-story-item-of-transfer (transfer)
  (check-type transfer story-item-transfer)
  (let ((story-item (story-item-transfer-story-item transfer)))
    (unless (eq :image (hyperbook/fedwiki::item-type-of story-item))
      (error 'type-error
             :datum (hyperbook/fedwiki::item-type-of story-item)
             :expected-type '(eql :image)))
    story-item))

(defun story-item-transfer-stored-resource-reference (transfer)
  "Return an image transfer's stored URL value without resolving or copying it."
  (let* ((story-item (%image-story-item-of-transfer transfer))
         (data (hyperbook/fedwiki::data-of story-item)))
    (and data (gethash "url" data))))

(defun story-item-transfer-resolved-resource-url (transfer)
  "Resolve an image transfer's stored URL through its source-page origin.

This delegates to HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL and therefore
introduces no competing resource-address contract."
  (hyperbook/fedwiki::resolve-story-item-url
   (story-item-transfer-stored-resource-reference transfer)
   (story-item-transfer-source-page transfer)))

(defmethod html-inspector-views:text-representation
    ((transfer story-item-transfer))
  (format nil "FedWiki story-item transfer: ~S"
          (story-item-transfer-action transfer)))

(defun %transfer-view-row (label value &key object-reference-p)
  (html-inspector-views:html
    (:tr
     (:td (html-inspector-views:esc label))
     (:td
      (if (and object-reference-p value)
          (html-inspector-views:object-ref value)
          (html-inspector-views:html
            (:code
             (html-inspector-views:esc
              (prin1-to-string value)))))))))

(html-inspector-views:defview story-item-transfer-view
    (transfer story-item-transfer)
  (let ((story-item (story-item-transfer-story-item transfer)))
    (html-inspector-views:html-view
        :title "FedWiki story-item transfer"
        :priority 1
      (html-inspector-views:html
        (:table
         :class "inspector-table"
         (%transfer-view-row
          "Action"
          (story-item-transfer-action transfer))
         (%transfer-view-row
          "Source page"
          (story-item-transfer-source-page transfer)
          :object-reference-p t)
         (%transfer-view-row
          "Source origin"
          (story-item-transfer-source-origin transfer)
          :object-reference-p t)
         (%transfer-view-row
          "Story item"
          story-item
          :object-reference-p t)
         (%transfer-view-row
          "Target"
          (story-item-transfer-target transfer)
          :object-reference-p t)
         (%transfer-view-row
          "Outcome"
          (story-item-transfer-outcome transfer)
          :object-reference-p t))
        (when (eq :image (hyperbook/fedwiki::item-type-of story-item))
          (html-inspector-views:html
            (:h3 (html-inspector-views:esc "Image resource"))
            (:table
             :class "inspector-table"
             (%transfer-view-row
              "Stored resource reference"
              (story-item-transfer-stored-resource-reference transfer)
              :object-reference-p t)
             (%transfer-view-row
              "Resolved resource URL"
              (story-item-transfer-resolved-resource-url transfer)
              :object-reference-p t))))))))

(defun %make-image-reference-transfer-example-source ()
  (let* ((wiki
           (make-instance 'hyperbook/fedwiki::fedwiki
                          :id "fedwiki:hyperdoc.dreyeck.ch"))
         (page
           (hyperbook/fedwiki::make-fedwiki-page
            wiki "wiki-links" "Wiki Links"))
         (page-json (make-hash-table :test #'equal))
         (item-json (make-hash-table :test #'equal)))
    (setf (hyperbook/fedwiki::status-of wiki) t
          (gethash "title" page-json) "Wiki Links"
          (gethash "story" page-json) (vector item-json)
          (gethash "journal" page-json) #()
          (gethash "type" item-json) "image"
          (gethash "id" item-json) "64368aba4c333703"
          (gethash "text" item-json)
          "[https://codeberg.org/rgb/hyperdoc/commit/c4d5825db5e4503193d6220aa2acfef5a7ad0928#diff-3c683a78b769ee09cd5b94252fe3ef1f174ad06a diff]"
          (gethash "size" item-json) "wide"
          (gethash "width" item-json) 399
          (gethash "height" item-json) 129
          (gethash "url" item-json)
          "/assets/plugins/image/4119ed51173a75fc6ccde4cf7f7abc34.jpg")
    (hyperbook/fedwiki::set-page-data page page-json)
    (values page (aref (hyperbook/fedwiki::story-of page) 0))))

(defexample fedwiki-image-reference-transfer-example
  "Prepare a local, deterministic :REFERENCE for the observed image item."
  (multiple-value-bind (source-page story-item)
      (%make-image-reference-transfer-example-source)
    (prepare-story-item-transfer
     source-page story-item :action :reference)))
