;;;; Installing TRAVERSE in the Discourse Entry

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "How TRAVERSE Enters Mech" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From Git Revision to Nix Package" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From PageFold to Discourse Graph" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What the Deployment Proves" :hyperbook "dreyeck/traverse/reading"))

(defun installs-traverse-p (entry-source)
  "Read from the retained entry text: does this entry import and call installDiscourseTraverse?"
  (let ((text (n:source-text entry-source)))
    (and (search "import { installDiscourseTraverse" text)
         (search "installDiscourseTraverse(blocks)" text)
         t)))

(hyperdoc:defexample traverse-entry
  "The sources through which TRAVERSE enters Mech's block catalog, and the profile that does not contain it."
  (let* ((reading (retained-reading))
         (entry (source-by-key reading "composition:discourse-entry"))
         (upstream-entry (source-by-key reading "composition:upstream-entry")))
    (list :discourse-entry entry
          :discourse-entry-installs-traverse (installs-traverse-p entry)
          :upstream-entry upstream-entry
          :upstream-entry-installs-traverse (installs-traverse-p upstream-entry)
          :install-discourse (source-by-key reading "composition:installDiscourse")
          :install-traverse (source-by-key reading "composition:installDiscourseTraverse")
          :traverse-block (source-by-key reading "composition:traverse_emit")
          :upstream-catalog (source-by-key reading "upstream:blocks")
          :upstream-dispatcher (source-by-key reading "upstream:run")
          :upstream-revision (revision-of reading "upstream")
          :composition-revision (revision-of reading "composition"))))
