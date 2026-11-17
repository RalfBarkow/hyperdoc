(asdf:defsystem "den-v2-delivery-outlook"
  :description "SHOP3 delivery planning for Den v2 (Den on Gen)"
  :version "0.1.7"
  :depends-on ("dreyeck/shop3")
  :serial t
  :components ((:file "delivery-planning")
               (:static-file "README.md")
               (:module "dita"
                :components ((:static-file "den-v2-delivery-outlook.ditamap")
                             (:static-file "delivery-outlook.dita")
                             (:static-file "review-checkpoint.dita")
                             (:static-file "review-release.dita")))))

(asdf:defsystem "den-v2-delivery-outlook/topic"
  :description "Executable HyperDoc installation topic for Den v2"
  :version "0.1.7"
  :depends-on ("hyperdoc/explorer" "hyperbook/server")
  :serial t
  :components ((:file "installation-topic")
               (:module "pages"
                :components ((:static-file "ZIP entpacken und Plansystem laden.html")))))
