;;;; System definitions
;;
;;;; Copyright (c) 2024-2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(asdf:defsystem #:html-inspector-views
  :description "Infrastructure for defining views for moldable HTML-based inspectors"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/html-inspector-views/"
  :source-control (:git "https://codeberg.org/khinsen/html-inspector-views.git")
  :serial t
  :depends-on (#:cl-who
               #:cl-base32
               #:flexi-streams
               #:closer-mop
               #:str)
  :components ((:file "package")
               (:file "thunks")
               (:file "html")
               (:file "title-bar")
               (:file "views")
               (:file "view-contracts")
               (:file "view-support")
               (:file "gui-class")))

(asdf:defsystem #:html-inspector-views/templates
  :description "HTML templates for inspector views"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/html-inspector-views/"
  :source-control (:git "https://codeberg.org/khinsen/html-inspector-views.git")
  :serial t
  :depends-on (#:html-inspector-views
               #:eco)
  :components ((:file "package-templates")
               (:file "templates")))

(asdf:defsystem #:html-inspector-views/standard
  :description "HTML inspector views for standard Common Lisp objects"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/html-inspector-views/"
  :source-control (:git "https://codeberg.org/khinsen/html-inspector-views.git")
  :serial t
  :depends-on (#:html-inspector-views
               #:alexandria
               #:arrow-macros
               #:babel
               #:cffi
               #:cl-base64
               #:cl-slug
               #:cl-who
               #:closer-mop
               #:dissect
               #:eclector-concrete-syntax-tree
               #:fset
               #:local-time
               #:s-graphviz
               #:sha1
               #:str
               #:swank
               #:trivial-clipboard
               #:asdf #:uiop)
  :components ((:file "package-standard")
               (:file "svg")
               (:file "basic")
               (:file "pathnames")
               (:file "numbers")
               (:file "characters")
               (:file "strings")
               (:file "symbols")
               (:file "lists")
               (:file "arrays")
               (:file "hash-tables")
               (:file "swank")
               (:file "functions")
               (:file "classes")
               (:file "packages")
               (:file "image")
               (:file "systems")
               (:file "conditions")
               (:file "views-on-views")
               #+quicklisp (:file "quicklisp")
               (:file "s-graphviz")
               (:file "fset")
               (:file "web-pages")
               (:file "hyperspec")
               (:file "lisp-parser")
               (:file "lisp-code")
               (:file "playgrounds")
               (:file "json")))

(asdf:defsystem #:html-inspector-views/reactive
  :description "Interactive inspector views"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/html-inspector-views/"
  :source-control (:git "https://codeberg.org/khinsen/html-inspector-views.git")
  :serial t
  :depends-on (#:html-inspector-views
               #:alexandria
               #:arrow-macros
               #:cl-who
               #:lwcells)
  :components ((:file "package-reactive")
               (:file "reactive")
               (:file "cell-views")))
