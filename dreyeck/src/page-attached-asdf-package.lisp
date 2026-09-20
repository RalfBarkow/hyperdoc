(defpackage #:dreyeck/page-attached-asdf
  (:use #:cl)
  (:export #:page-attached-asd-p #:systems-defined-by-asd #:register-asd-systems
 #:call-with-asd-source-authority #:component-primary-asd-pathname
 #:run-asd-test-system-in-fresh-process))

(in-package #:dreyeck/page-attached-asdf)
