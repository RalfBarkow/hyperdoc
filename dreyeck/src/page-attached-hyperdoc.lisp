;; Observe HyperDocs registered by loading an ASDF system

(in-package #:dreyeck/page-attached-hyperdoc)

(defun registered-hyperdocs ()
  "Return a fresh list of HyperDocs registered in the global HyperBook catalog."
  (remove-if-not
   (lambda (hyperbook)
     (typep hyperbook 'hyperdoc:hyperdoc))
   (copy-list
    (hyperbook:hyperbooks-of
     hyperdoc:*catalog*))))

(defun load-system-and-observe-hyperdocs (system-designator)
  "Load SYSTEM-DESIGNATOR and report its effect on the HyperBook catalog.

The operation is intentionally effectful: ASDF:LOAD-SYSTEM evaluates the
system's load-time code.  The returned observation distinguishes the
HyperDocs already registered before loading from those registered as a
result of the load."
  (let* ((system
           (asdf:find-system system-designator))
         (name
           (asdf:component-name system))
         (before
           (registered-hyperdocs)))
    (asdf:load-system system)
    (let* ((after
             (registered-hyperdocs))
           (new
             (set-difference
              after
              before
              :test #'eq)))
      (list
       :system name
       :hyperdocs-before before
       :hyperdocs-after after
       :newly-registered-hyperdocs new))))
