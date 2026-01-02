(asdf:load-system :arrow-macros)
(asdf:load-system :lquery)
(asdf:load-system :plump)

(import 'arrow-macros:->)

(defparameter system "hyperdoc")

(defun html-files ()
  (let (pathnames)
    (-> system
      asdf:find-system
      asdf:component-pathname
      (uiop:collect-sub*directories
       (constantly t)
       #'(lambda (subdir)
           (not (equal ".git"
                       (-> subdir
                         pathname-directory
                         last
                         car))))
       #'(lambda (subdir)
           (loop for file in (uiop:directory-files subdir)
                 when (equal (pathname-type file) "html")
                 do (pushnew file pathnames :test #'equal)))))
    pathnames))

(defun update-html-files (patch-fn)
  (dolist (file (html-files))
    (format t "Patching ~A~%" file)
    (let ((dom (plump:parse file)))
      (funcall patch-fn dom)
      (with-open-file (out file
                           :direction :output
                           :if-exists :supersede)
        (let ((plump:*tag-dispatchers* nil))
          (plump:serialize dom out))))))

(defun expr-links-to-functions (dom)
  (lquery:$ dom "a[expr^=#']"
    (map #'(lambda (el)
             (let* ((expr (plump:get-attribute el "expr"))
                    (fn-name (str:substring 2 nil expr)))
               (plump:remove-attribute el "expr")
               (plump:set-attribute el "hyperbook" "lisp-functions")
               (plump:set-attribute el "page" fn-name))))))

(defun expr-links-to-classes (dom)
  (lquery:$ dom "a[expr^=(find-class]"
    (map #'(lambda (el)
             (let* ((expr (plump:get-attribute el "expr"))
                    (class-name (str:substring 1 -1 (second (str:split " " expr)))))
               (plump:remove-attribute el "expr")
               (plump:set-attribute el "hyperbook" "lisp-classes")
               (plump:set-attribute el "page" class-name))))))

(update-html-files #'expr-links-to-functions)
(update-html-files #'expr-links-to-classes)
