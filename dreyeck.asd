;;;; Local dreyeck.ch integration and communication systems

(asdf:defsystem #:dreyeck
  :description "Local dreyeck.ch integration overlay"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :components
  ((:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :serial t
    :components
    ((:file "dreyeck-hyperdoc-deployment-inventory")))))

(asdf:defsystem #:dreyeck/wiki-link
  :description "Examples of FedWiki title and slug lookup contracts"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/explorer
               #:hyperbook/fedwiki)
  :components
  ((:module "dreyeck/pages"
    :pathname "dreyeck/pages/")

   (:module "dreyeck/src"
    :pathname "dreyeck/src/"
    :serial t
    :components
    ((:file "wiki-link")))))
