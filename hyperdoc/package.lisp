;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc (:use :cl)
            (:import-from :alexandria :if-let :when-let :compose)
            (:import-from :arrow-macros :-> :-<> :->> :-<>> :<> :some->
                          :some->>)
            (:import-from :hyperbook #:id #:hyperbook #:id-of #:hyperbook-of
                          #:title-of #:main-page-id-of #:links-of #:catalog
                          #:*catalog* #:register #:find-backlink-sources
                          #:find-link-sources #:find-page #:find-hyperbook
                          #:lookup-failure #:page-lookup-failure
                          #:hyperbook-lookup-failure)
            (:export #:defhyperdoc #:make-hyperdoc #:data-of #:load-page
                     #:page-class #:see #:page #:hyperdoc #:defexample
                     #:assert-test #:assert-equalp #:assert-equal #:assert-eql
                     #:assert-within-tolerance #:deftool #:html #:markdown
                     #:html-generator #:defplayground #:*catalog*
                     #:hyperdocs-of #:title-of #:directory-of #:asdf-system-of
                     #:pages-of #:hyperdoc-of #:file-of
                     #:*hyperdoc-html-page-assets* #:*hyperdoc*))

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperdoc)
