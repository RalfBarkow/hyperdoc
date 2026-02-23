;;;; Compat shim: njson/jzon backed by com.inuoe.jzon

(asdf:defsystem "njson"
  :description "Compat shim package for njson namespace"
  :author "HyperDoc local shim"
  :license "BSD"
  :serial t
  :depends-on ("com.inuoe.jzon")
  :components ((:module "njson"
                :serial t
                :components ((:file "package")
                             (:file "njson")))))

(asdf:defsystem "njson/jzon"
  :description "Compat shim for njson/jzon backed by com.inuoe.jzon"
  :author "HyperDoc local shim"
  :license "BSD"
  :depends-on ("njson"))
