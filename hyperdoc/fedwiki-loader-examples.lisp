
(in-package :hyperdoc)


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *hyperdoc-root* nil))


(eval-when (:load-toplevel :execute)
  (let* ((root
          (or (ignore-errors (asdf/system:system-source-directory :hyperdoc))
              (ignore-errors (truename #P"/Users/rgb/workspace/hyperdoc/"))
              (uiop/os:getcwd)))
         (loader (merge-pathnames #P"hyperdoc/fedwiki-loader.lisp" root)))
    (when (probe-file loader) (load loader))))


(defun fedwiki-loader-example-temporary-root (name)
  (let ((root
         (merge-pathnames
          (format nil "hyperdoc-fedwiki-loader-examples/~A-~A-~A/" name
                  (get-universal-time) (random 1000000))
          (uiop/stream:temporary-directory))))
    (ensure-directories-exist (merge-pathnames #P"sentinel" root))
    (truename root)))


(defun fedwiki-loader-example-write-file (path contents)
  (ensure-directories-exist path)
  (with-open-file
      (out path :direction :output :if-exists :supersede :if-does-not-exist
       :create)
    (write-string contents out))
  path)


(defun fedwiki-loader-example-pass (id &key given operation then evidence)
  (list :example id :status :pass :given given :when operation :then then
        :evidence evidence))


(defun fedwiki-loader-example-fail
       (id &key given operation expected actual condition evidence)
  (list :example id :status :fail :given given :when operation :expected
        expected :actual actual :condition condition :evidence evidence))


(defun fedwiki-loader-example-result-pass-p (result)
  (eq (getf result :status) :pass))


(defun fedwiki-loader-suite-pass-p (suite)
  (every #'fedwiki-loader-example-result-pass-p (getf suite :examples)))


(defun fedwiki-loader-example-stage-statuses (attempts)
  (mapcar
   (lambda (attempt) (list (getf attempt :stage) (getf attempt :status)))
   attempts))


(defun fedwiki-loader-example-pathname= (left right)
  (string= (namestring (truename left)) (namestring (truename right))))


(defun fedwiki-loader-example-page-attached-asset-hit ()
  (let* ((id :fedwiki-loader/page-attached-asset-hit)
         (logical-path "clog/./tutorial/01-tutorial.lisp")
         (root (fedwiki-loader-example-temporary-root "page-asset-hit"))
         (db-path (merge-pathnames #P"fedwiki-loader.sqlite" root))
         (store (make-default-fedwiki-loader-store :db-path db-path))
         (asset
          (merge-pathnames
           #P"assets/pages/clog-tutorials/tutorial/01-tutorial.lisp" root)))
    (fedwiki-loader-example-write-file asset "(in-package :cl-user)

(setf (get :hyperdoc-fedwiki-loader-example :loaded) :page-asset)
")
    (let ((*hyperdoc-root* root))
      (handler-case
       (let* ((resolved
               (fedwiki-resolve-loadable logical-path :system-name "clog"
                                         :store store))
              (loaded
               (progn
                (setf (get :hyperdoc-fedwiki-loader-example :loaded) nil)
                (load-fedwiki-resolved-file logical-path :system-name "clog"
                                            :store store)
                (get :hyperdoc-fedwiki-loader-example :loaded)))
              (ok
               (and (fedwiki-loader-example-pathname= resolved asset)
                    (eq loaded :page-asset))))
         (if ok
             (fedwiki-loader-example-pass id :given
                                          (list :logical-path logical-path
                                                :system-name "clog" :root root)
                                          :operation
                                          '(fedwiki-resolve-loadable
                                            "clog/./tutorial/01-tutorial.lisp"
                                            :system-name "clog")
                                          :then
                                          (list :resolved (truename asset)
                                                :loaded :page-asset)
                                          :evidence
                                          (list :resolved resolved :loaded
                                                loaded))
             (fedwiki-loader-example-fail id :given
                                          (list :logical-path logical-path
                                                :system-name "clog" :root root)
                                          :operation 'fedwiki-resolve-loadable
                                          :expected
                                          (list :resolved (truename asset)
                                                :loaded :page-asset)
                                          :actual
                                          (list :resolved resolved :loaded
                                                loaded))))
       (condition (condition)
        (fedwiki-loader-example-fail id :given
                                     (list :logical-path logical-path
                                           :system-name "clog" :root root)
                                     :operation 'fedwiki-resolve-loadable
                                     :condition
                                     (princ-to-string condition)))))))


(defun fedwiki-loader-example-missing-loadable-attempts ()
  (let* ((id :fedwiki-loader/missing-loadable-attempts)
         (logical-path "clog/./tutorial/does-not-exist.lisp")
         (root (fedwiki-loader-example-temporary-root "missing-loadable"))
         (db-path (merge-pathnames #P"fedwiki-loader.sqlite" root))
         (store (make-default-fedwiki-loader-store :db-path db-path))
         (expected
          '((:exact-path :miss) (:page-attached-asset :miss)
            (:sqlite-alias :miss))))
    (ensure-fedwiki-loader-schema store)
    (let ((*hyperdoc-root* root))
      (handler-case
       (let ((resolved
              (fedwiki-resolve-loadable logical-path :system-name "clog" :store
                                        store)))
         (fedwiki-loader-example-fail id :given
                                      (list :logical-path logical-path
                                            :system-name "clog" :root root)
                                      :operation 'fedwiki-resolve-loadable
                                      :expected 'fedwiki-loadable-not-found
                                      :actual resolved))
       (fedwiki-loadable-not-found (condition)
        (let* ((attempts (fedwiki-loadable-attempts-of condition))
               (actual (fedwiki-loader-example-stage-statuses attempts)))
          (if (equal actual expected)
              (fedwiki-loader-example-pass id :given
                                           (list :logical-path logical-path
                                                 :system-name "clog" :root
                                                 root)
                                           :operation 'fedwiki-resolve-loadable
                                           :then
                                           (list :attempt-stage-statuses
                                                 expected)
                                           :evidence
                                           (list :logical-path
                                                 (fedwiki-loadable-logical-path-of
                                                  condition)
                                                 :attempts attempts))
              (fedwiki-loader-example-fail id :given
                                           (list :logical-path logical-path
                                                 :system-name "clog" :root
                                                 root)
                                           :operation 'fedwiki-resolve-loadable
                                           :expected expected :actual actual
                                           :evidence
                                           (list :attempts attempts)))))
       (condition (condition)
        (fedwiki-loader-example-fail id :given
                                     (list :logical-path logical-path
                                           :system-name "clog" :root root)
                                     :operation 'fedwiki-resolve-loadable
                                     :condition
                                     (princ-to-string condition)))))))


(defparameter *fedwiki-loader-example-functions*
  '(fedwiki-loader-example-page-attached-asset-hit
    fedwiki-loader-example-missing-loadable-attempts))


(defun run-fedwiki-loader-examples ()
  (let* ((examples
          (mapcar (lambda (name) (funcall (symbol-function name)))
                  *fedwiki-loader-example-functions*))
         (status
          (if (every #'fedwiki-loader-example-result-pass-p examples)
              :pass
              :fail)))
    (list :suite :fedwiki-loader :kind :hyperdoc/examples :status status
          :examples examples)))


(defun assert-fedwiki-loader-examples-pass ()
  (let ((suite (run-fedwiki-loader-examples)))
    (unless (fedwiki-loader-suite-pass-p suite)
      (error "FedWiki loader examples failed: ~S" suite))
    suite))


(defun inspect-fedwiki-loader-examples ()
  (let ((suite (run-fedwiki-loader-examples)))
    (let* ((package (find-package :clog-moldable-inspector))
           (symbol (and package (find-symbol "CLOG-INSPECT" package))))
      (if (and symbol (fboundp symbol))
          (funcall (symbol-function symbol) suite)
          suite))))


(defun fedwiki-loader-example-assert-pass (result)
  (unless (fedwiki-loader-example-result-pass-p result)
    (error "FedWiki loader example failed: ~S" result))
  result)


(defexample fedwiki-loader-page-attached-asset-hit-registered-example
  (:register t :system "hyperdoc-fedwiki-loader-examples" :page
   "FedWiki loader examples" :title
   "Page-attached Lisp asset resolves before SQLite alias fallback"
   :class-or-group "fedwiki-loader" :tags
   '(:kind :example :suite "fedwiki-loader" :resolver :page-attached-asset))
  (fedwiki-loader-example-assert-pass
   (fedwiki-loader-example-page-attached-asset-hit)))


(defexample fedwiki-loader-missing-loadable-attempts-registered-example
  (:register t :system "hyperdoc-fedwiki-loader-examples" :page
   "FedWiki loader examples" :title
   "Missing loadable reports exact path page asset and SQLite miss attempts"
   :class-or-group "fedwiki-loader" :tags
   '(:kind :example :suite "fedwiki-loader" :resolver :missing-loadable))
  (fedwiki-loader-example-assert-pass
   (fedwiki-loader-example-missing-loadable-attempts)))


(defun discover-fedwiki-loader-examples ()
  (discover-examples :system "hyperdoc-fedwiki-loader-examples" :page
                     "FedWiki loader examples"))


(defun run-discovered-fedwiki-loader-examples ()
  (run-examples (discover-fedwiki-loader-examples)))


(defun inspect-discovered-fedwiki-loader-examples ()
  (let ((run (run-discovered-fedwiki-loader-examples)))
    (let* ((package (find-package :clog-moldable-inspector))
           (symbol (and package (find-symbol "CLOG-INSPECT" package))))
      (if (and symbol (fboundp symbol))
          (funcall (symbol-function symbol) run)
          run))))


(export
 '(discover-fedwiki-loader-examples run-discovered-fedwiki-loader-examples
   inspect-discovered-fedwiki-loader-examples))

