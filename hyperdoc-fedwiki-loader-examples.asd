(asdf:defsystem #:hyperdoc-fedwiki-loader-examples
  :description "Examples-driven checks for FedWiki loadable asset resolution."
  :depends-on (#:hyperdoc)
  :serial t
  :components
  ((:file "hyperdoc/fedwiki-loader-examples"))
  :perform
  (asdf:test-op (operation component)
    (declare (ignore operation component))
    (let ((result
            (uiop:symbol-call
             :hyperdoc
             :assert-fedwiki-loader-examples-pass)))
      (format t "~&~S~%" result))))
