;;;; Local dreyeck.ch integration and communication systems

(defsystem #:dreyeck
  :description "Local dreyeck.ch integration overlay"
  :license "BSD"
  :version "0.0.1")

(defsystem #:dreyeck/wiki-link-contract-demo
  :description "Executable observations of FedWiki title and slug lookup contracts"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/explorer
               #:hyperbook/fedwiki)
  :components ((:file "wiki-link-contract-demo"
                :pathname "dreyeck/wiki-link-contract-demo")
               (:module "dreyeck/pages"
                :pathname "dreyeck/pages/")))
