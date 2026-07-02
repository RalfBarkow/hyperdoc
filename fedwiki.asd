;;;; FedWiki page-system definitions for HyperDoc-owned descriptors.

(defsystem #:fedwiki
    :description "FedWiki namespace system for page-system reload boundaries"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/fedwiki
                 #:hyperbook/fedwiki)
    :components nil)

(defsystem #:fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc
    :description "FedWiki page system for mobile-progressive-chrome-in-hyperdoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:fedwiki)
    :components ((:module "hyperdoc/page-systems"
                          :serial t
                          :components ((:file "fedwiki-mobile-progressive-chrome")))))

(defsystem #:fedwiki/page/wiki.ralfbarkow.ch/shop3
    :description "FedWiki page system for SHOP3"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:fedwiki
                 #:hyperdoc/shop3)
    :components ((:module "hyperdoc/page-systems"
                          :serial t
                          :components ((:file "fedwiki-shop3")))))

(defsystem #:fedwiki/page/wiki.ralfbarkow.ch/the-1998-ai-planning-systems-competition
    :description "FedWiki page system for the McDermott 2000 AIPS Planning Competition page-attached ASDF system"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:fedwiki)
    :components ((:module "hyperdoc/page-systems"
                          :serial t
                          :components ((:file "fedwiki-the-1998-ai-planning-systems-competition")))))
