;;;; FedWiki namespace support.

(defsystem #:fedwiki
    :description "FedWiki namespace system for generic HyperDoc/FedWiki runtime support"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/fedwiki
                 #:hyperbook/fedwiki)
    :components nil)
