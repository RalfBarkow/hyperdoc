;;;; With registered project dependencies. Run Java comparator separately first.
(require :asdf)
(asdf:load-asd (merge-pathnames "../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:test-system "dreyeck/work/link-resolution/tests")
(asdf:test-system "dreyeck/work/link-resolution/reading/tests")
(format t "~&JAVA-DERIVED-LINK-RESOLUTION-ACCEPTANCE-PASS~%")
