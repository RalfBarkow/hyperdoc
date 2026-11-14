(defpackage #:dreyeck/hyperdoc/library-tests
  (:use #:cl)
  (:export #:run-tests))

(in-package #:dreyeck/hyperdoc/library-tests)

(DEFUN CHECK-FEDWIKI-IMAGE-COMPATIBILITY ()
  (LET* ((WIKI
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::FEDWIKI :ID
                         "fedwiki:example.invalid:8443"))
         (PAGE
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::REMOTE-FEDWIKI-PAGE :ID "image"
                         :ORIGIN WIKI :ORIGIN-ID "image" :HYPERBOOK WIKI))
         (DATA (MAKE-HASH-TABLE :TEST #'EQUAL))
         (ITEM
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::STORY-ITEM :ITEM-TYPE :IMAGE :ID
                         "image" :TEXT "" :DATA DATA)))
    (ASSERT
     (STRING= "example.invalid:8443" (HYPERBOOK/FEDWIKI::DOMAIN-NAME-OF WIKI)))
    (SETF (GETHASH "url" DATA) "/assets/example.png"
          (GETHASH "width" DATA) 640
          (GETHASH "height" DATA) 480
          (GETHASH "size" DATA) "wide")
    (ASSERT
     (EQUAL '(640 480 "wide")
            (MULTIPLE-VALUE-LIST
             (HYPERBOOK/FEDWIKI::STORY-ITEM-IMAGE-PRESENTATION-HINTS ITEM))))
    (ASSERT
     (STRING= "https://example.invalid:8443/assets/example.png"
              (HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL "/assets/example.png"
                                                         PAGE)))
    (DOLIST
        (URL
         '("https://other.invalid/p.png" "//other.invalid/p.png" "image.png"))
      (ASSERT
       (EQUAL URL (HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL URL PAGE))))
    (LET* ((VIEW
            (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE "Image contract"
                                            (HYPERBOOK/FEDWIKI::RENDER-STORY-ITEM
                                             :IMAGE ITEM PAGE)))
           (HTML (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW)))
      (DOLIST
          (MARKER
           '("https://example.invalid:8443/assets/example.png" "640" "480"
             "data-fedwiki-size" "max-width: 100%" "height: auto"
             "figcaption"))
        (ASSERT (SEARCH MARKER HTML))))
    (SETF (GETHASH "width" DATA) -1
          (GETHASH "height" DATA) "480"
          (GETHASH "size" DATA) "")
    (ASSERT
     (EQUAL '(NIL NIL NIL)
            (MULTIPLE-VALUE-LIST
             (HYPERBOOK/FEDWIKI::STORY-ITEM-IMAGE-PRESENTATION-HINTS ITEM)))))
  T)

(defun run-tests ()
  (check-fedwiki-image-compatibility)
  (format t "~&HYPERDOC-LIBRARY-PASS: FedWiki image compatibility verified.~%")
  t)
