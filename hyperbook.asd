;;;; System definitions for HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperbook
  :description "Hyperbook interface"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:alexandria
               #:arrow-macros
               #:puri)
  :components ((:module "hyperbook"
                        :serial t
                        :components ((:file "package")
                                     (:file "hyperbooks")
                                     (:file "catalog")
                                     (:file "html-books")))))

(defsystem #:hyperbook/explorer
  :description "Explorer for HyperBooks"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperbook
               #:html-inspector-views
               #:html-inspector-views/standard
               #:alexandria
               #:arrow-macros
               #:cl-who
               #:lquery
               #:trivial-package-local-nicknames
               #:asdf #:uiop)
  :components ((:module "hyperbook-explorer"
                :serial t
                :components ((:file "package")
                             (:file "links")
                             (:file "link-views")
                             (:file "link-redirection")
                             (:file "explorer")
                             (:file "catalog")
                             (:file "rendering")
                             (:file "html-books")
                             (:file "hyperbook-the-book")
                             (:file "asdf-systems")
                             (:file "lisp-functions")
                             (:file "lisp-classes")))))

(defsystem #:hyperbook/server
  :description "Web server for HyperBooks"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperbook
               #:hyperbook/explorer
               #:html-inspector-views
               #:babel
               #:clog
               #:clog-moldable-inspector
               #:hunchentoot
               #:cl-slug
               #:sha1
               #:trivial-package-local-nicknames)
  :components ((:module "hyperbook-server"
                :serial t
                :components ((:file "package")
                             (:file "server")))))

(defsystem #:hyperbook/wikipedia
  :description "HyperBook interface to Wikipedia"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperbook
               #:hyperbook/explorer
               #:html-inspector-views
               #:clog
               #:plump
               #:plump-inspector-views
               #:lquery
               #:alexandria
               #:arrow-macros
               #:drakma
               #:hunchentoot ;; for url-decode
               #:shasht
               #:str
               #:trivial-package-local-nicknames)
  :components ((:module "hyperbook-wikipedia"
                :serial t
                :components ((:file "package")
                             (:file "wikipedia-editions")
                             (:file "wikipedia")))))

(defsystem #:hyperbook/fedwiki
  :description "HyperBook interface to Federated Wiki"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperbook
               #:hyperbook/explorer
               #:html-inspector-views
               #:plump
               #:plump-inspector-views
               #:lquery
               #:alexandria
               #:arrow-macros
               #:bordeaux-threads
               #:cl-ppcre
               #:cl-who
               #:drakma #:usocket
               #:local-time
               #:shasht
               #:str
               #:trivial-package-local-nicknames)
  :components ((:module "hyperbook-fedwiki"
                :serial t
                :components ((:file "package")
                             (:file "utilities")
                             (:file "pages")
                             (:file "story-items")
                             (:file "fedwiki")
                             (:file "wiki-links")
                             (:file "plugins")
                             (:file "views")))))
