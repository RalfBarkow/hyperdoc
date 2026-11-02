;;;; The code ownership inventory of upstream's library paths. Usage (from the repository root, in the development shell):
;;;;
;;;;   sbcl --script scripts/code-ownership.lisp --manifest REF      write docs/code-ownership/manifest.lisp-data from the Git objects of REF (reads Git; writes one file)
;;;;   sbcl --script scripts/code-ownership.lisp --inventory         write docs/code-ownership/inventory.lisp-data from the manifest, decisions.lisp-data and Git history
;;;;   sbcl --script scripts/code-ownership.lisp --check             compare the work tree with the manifest and the inventory; NO Git is used (works on a source snapshot)
;;;;
;;;; --check exits 0 when every difference is inventoried and the inventory is consistent (pending entries are listed, not accepted), 1 on any problem.
;;;; Nothing is loaded from the library paths: they are scanned as syntax.
(require :asdf)
(let ((root (uiop:pathname-directory-pathname (or *load-truename* *default-pathname-defaults*))))
  (setf root (uiop:pathname-parent-directory-pathname root))
  (asdf:initialize-source-registry (list :source-registry (list :tree root) :inherit-configuration))
  (let ((*standard-output* (make-broadcast-stream)) (*error-output* (make-broadcast-stream)))
    (asdf:load-system "dreyeck/workflow/code-ownership"))
  (let* ((args (let ((all sb-ext:*posix-argv*)) (member-if (lambda (a) (and (> (length a) 2) (string= "--" a :end2 2) (member a (quote ("--manifest" "--inventory" "--check")) :test (function string=)))) all))) (dir (merge-pathnames "docs/code-ownership/" root))
         (manifest-file (merge-pathnames "manifest.lisp-data" dir)) (inventory-file (merge-pathnames "inventory.lisp-data" dir))
         (decisions-file (merge-pathnames "decisions.lisp-data" dir)))
    (flet ((call (name &rest arguments) (apply (find-symbol name :dreyeck/code-ownership) arguments)))
      (cond
        ((equal "--manifest" (first args))
         (let* ((repository (funcall (find-symbol "OPEN-REPOSITORY" :dreyeck/upstream-assessment) root))
                (manifest (call "BUILD-MANIFEST" repository (second args))))
           (call "WRITE-MANIFEST" manifest manifest-file)
           (format t "manifest of ~A: ~D files written to ~A~%" (call "MANIFEST-REFERENCE" manifest) (length (call "MANIFEST-FILES" manifest)) manifest-file)))
        ((equal "--inventory" (first args))
         (let* ((repository (funcall (find-symbol "OPEN-REPOSITORY" :dreyeck/upstream-assessment) root))
                (manifest (call "READ-MANIFEST" manifest-file)) (decisions (call "READ-DECISIONS" decisions-file))
                (inventory (call "BUILD-INVENTORY" root repository manifest decisions)))
           (call "WRITE-INVENTORY" inventory inventory-file)
           (format t "inventory: ~D entries written to ~A~%" (length (call "INVENTORY-ENTRIES" inventory)) inventory-file)))
        ((equal "--check" (first args))
         (let* ((report (call "CHECK-LIBRARY-INVENTORY" root (call "READ-MANIFEST" manifest-file) (call "READ-INVENTORY" inventory-file))))
           (call "PRINT-INVENTORY-REPORT" report)
           (sb-ext:exit :code (if (call "INVENTORY-REPORT-OK-P" report) 0 1))))
        (t (format t "usage: --manifest REF | --inventory | --check~%") (sb-ext:exit :code 2))))))
