(defpackage #:dreyeck.zettelkasten
  (:use #:cl)
  (:export
   #:*default-zkn3-work-directory*
   #:zkn3-container-p
   #:extract-zkn3-member
   #:parse-zkn-file-xml
   #:resolve-zkn3-zettel-reference
   #:extract-zkn3-zettel-text
   #:read-through-zkn3-zettel
   #:zkn3-result-status
   #:zkn3-result-next-task))
