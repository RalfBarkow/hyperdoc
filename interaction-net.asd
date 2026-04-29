(defsystem #:interaction-net
  :description "Sequential interaction-net implementation seed for HyperDoc"
  :author "HyperDoc contributors"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on ()
  :components ((:module "interaction-net"
                :serial t
                :components ((:file "package")
                             (:file "interaction-net")))))
