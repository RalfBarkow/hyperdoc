;;;; Inspector views of a local page's file and its story Items: reading only

(in-package #:dreyeck/local-fedwiki-view)

(defun %json-equal (a b)
  (cond ((and (hash-table-p a) (hash-table-p b))
         (and (= (hash-table-count a) (hash-table-count b))
              (loop for key being the hash-keys of a using (hash-value value)
                    always (multiple-value-bind (other present) (gethash key b)
                             (and present (%json-equal value other))))))
        ((and (vectorp a) (vectorp b) (not (stringp a)) (not (stringp b)))
         (and (= (length a) (length b)) (every #'%json-equal a b)))
        (t (equal a b))))

(defun %excerpt (text &optional (limit 70))
  (let ((line (substitute #\Space #\Newline text)))
    (if (<= (length line) limit) line (concatenate 'string (subseq line 0 limit) "…"))))

(defun %timestamp (universal-time)
  (multiple-value-bind (s m h d mo y) (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC" y mo d h m s)))

(defmethod html-inspector-views:text-representation ((item dreyeck/local-fedwiki-page:local-story-item))
  (format nil "~A ~A: ~A" (dreyeck/local-fedwiki-page:story-item-type item)
          (dreyeck/local-fedwiki-page:story-item-id item)
          (%excerpt (dreyeck/local-fedwiki-page:story-item-text item) 50)))

(html-inspector-views:defview 👀page-source (page dreyeck/local-fedwiki-page:local-fedwiki-page)
  (let ((source (handler-case (dreyeck/local-fedwiki-page:local-fedwiki-page-source-of page)
                  (error (condition) condition))))
    (html-inspector-views:html-view :title "Page source" :priority 3
      (if (typep source 'condition)
          (html-inspector-views:html
            (:p "The page file could not be read now: " (html-inspector-views:object-ref source)))
          (let ((items (dreyeck/local-fedwiki-page:source-story-items source)))
            (html-inspector-views:html
              (:p "Read from the page file now; the SHA-256 and the Items come from the same bytes. Nothing is written.")
              (:table :class "inspector-table"
                (:tr (:td "Site root") (:td (:code (html-inspector-views:esc (namestring (dreyeck/local-fedwiki-page:page-source-site-root source))))))
                (:tr (:td "Slug") (:td (:code (html-inspector-views:esc (dreyeck/local-fedwiki-page:page-source-slug source)))))
                (:tr (:td "File") (:td (:code (html-inspector-views:esc (namestring (dreyeck/local-fedwiki-page:page-source-pathname source))))))
                (:tr (:td "SHA-256") (:td (:code (html-inspector-views:esc (dreyeck/local-fedwiki-page:page-source-sha256 source)))))
                (:tr (:td "Octets") (:td (html-inspector-views:esc (princ-to-string (dreyeck/local-fedwiki-page:page-source-octet-count source)))))
                (:tr (:td "Observed") (:td (html-inspector-views:esc (%timestamp (dreyeck/local-fedwiki-page:page-source-observed-at source)))))
                (:tr (:td "Inspected page object")
                     (:td (html-inspector-views:esc
                           (if (%json-equal (hyperbook/fedwiki::raw-json-of page) (dreyeck/local-fedwiki-page:page-source-json source))
                               "holds the same JSON as the file"
                               "holds different JSON: it was read before the file last changed"))))
                (:tr (:td "Journal") (:td (html-inspector-views:esc
                                           (format nil "~D entries"
                                                   (length (or (gethash "journal" (dreyeck/local-fedwiki-page:page-source-json source)) #())))))))
              (:h3 (html-inspector-views:esc (format nil "Story Items (~D)" (length items))))
              (:table :class "inspector-table"
                (:tr (:th "#") (:th "Id") (:th "Type") (:th "Text"))
                (dolist (item items)
                  (html-inspector-views:html
                    (:tr (:td (html-inspector-views:esc (princ-to-string (1+ (dreyeck/local-fedwiki-page:story-item-index item)))))
                         (:td (html-inspector-views:object-ref item :display (dreyeck/local-fedwiki-page:story-item-id item) :select "Story item"))
                         (:td (html-inspector-views:esc (dreyeck/local-fedwiki-page:story-item-type item)))
                         (:td (html-inspector-views:esc (%excerpt (dreyeck/local-fedwiki-page:story-item-text item))))))))))))))

(html-inspector-views:defview 👀local-story-item (item dreyeck/local-fedwiki-page:local-story-item)
  (let* ((source (dreyeck/local-fedwiki-page:story-item-source item))
         (count (length (dreyeck/local-fedwiki-page:source-story-items source))))
    (html-inspector-views:html-view :title "Story item" :priority -1
      (html-inspector-views:html
        (:h2 (html-inspector-views:esc (format nil "Story Item ~A" (dreyeck/local-fedwiki-page:story-item-id item))))
        (:table :class "inspector-table"
          (:tr (:td "Id") (:td (:code (html-inspector-views:esc (dreyeck/local-fedwiki-page:story-item-id item)))))
          (:tr (:td "Type") (:td (html-inspector-views:esc (dreyeck/local-fedwiki-page:story-item-type item))))
          (:tr (:td "Position") (:td (html-inspector-views:esc (format nil "~D of ~D" (1+ (dreyeck/local-fedwiki-page:story-item-index item)) count))))
          (:tr (:td "Page") (:td (:code (html-inspector-views:esc (dreyeck/local-fedwiki-page:page-source-slug source)))
                              " in " (:code (html-inspector-views:esc (namestring (dreyeck/local-fedwiki-page:page-source-site-root source))))))
          (:tr (:td "Source revision") (:td (:code (html-inspector-views:esc (dreyeck/local-fedwiki-page:page-source-sha256 source)))
                                         (html-inspector-views:esc (format nil ", observed ~A" (%timestamp (dreyeck/local-fedwiki-page:page-source-observed-at source)))))))
        (:h3 "Text")
        (:pre (html-inspector-views:esc (dreyeck/local-fedwiki-page:story-item-text item)))
        (:h3 "Item JSON, as observed")
        (:pre (html-inspector-views:esc (shasht:write-json (dreyeck/local-fedwiki-page:story-item-json item) nil)))
        (:p "This view reads; it offers no change.")))))
