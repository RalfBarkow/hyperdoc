;;;; Same-origin Common Lisp HyperSpec content for HyperDoc

(in-package :hyperdoc/inspector)

(defparameter +hyperspec-http-root+ "/hyperspec/")

(defparameter +hyperspec-root-environment-variable+
  "HYPERDOC_HYPERSPEC_ROOT")

(defparameter *hyperspec-root-override* :environment
  "Test and diagnostic override for the HyperSpec filesystem root.

The value :ENVIRONMENT selects HYPERDOC_HYPERSPEC_ROOT. Any other value is
validated as the root designator itself; NIL therefore models a missing
configuration without changing process-global environment variables.")

(defun hyperspec-http-root ()
  "Return the same-origin HTTP root used for immutable HyperSpec content."
  +hyperspec-http-root+)

(defun %configured-hyperspec-root-designator ()
  (if (eq :environment *hyperspec-root-override*)
      (uiop:getenv +hyperspec-root-environment-variable+)
      *hyperspec-root-override*))

(defun %complete-hyperspec-root-p (root)
  (and (uiop:directory-exists-p root)
       (uiop:file-exists-p (merge-pathnames "Front/index.htm" root))
       (uiop:file-exists-p (merge-pathnames "Body/m_defmet.htm" root))
       (uiop:directory-exists-p (merge-pathnames "Data/" root))
       (uiop:directory-exists-p (merge-pathnames "Issues/" root))))

(defun hyperspec-root-pathname ()
  "Return the validated HYPERDOC_HYPERSPEC_ROOT directory and a diagnostic.

The first value is NIL when the variable is absent, empty, invalid, or does
not contain the required HyperSpec 7.0 corpus. The second value then explains
the local configuration problem. This function performs filesystem checks
only and never consults an external HyperSpec service."
  (let ((root-designator (%configured-hyperspec-root-designator)))
    (cond
      ((or (null root-designator)
           (and (stringp root-designator)
                (zerop (length root-designator))))
       (values
        nil
        (format nil "~A is not set."
                +hyperspec-root-environment-variable+)))
      (t
       (let ((root
               (ignore-errors
                 (uiop:ensure-directory-pathname root-designator))))
         (if (and root (%complete-hyperspec-root-p root))
             (values root nil)
             (values
              nil
              (format nil
                      "~A does not contain a complete HyperSpec 7.0 corpus: ~A"
                      +hyperspec-root-environment-variable+
                      root-designator))))))))

(defun %hyperspec-asset-root-pathname (root)
  "Return the lowercase CLOG route alias for the validated ROOT corpus."
  (let* ((parent
           (make-pathname
            :name nil
            :type nil
            :directory (butlast (pathname-directory root))
            :defaults root))
         (asset-root (merge-pathnames "hyperspec/" parent)))
    (assert (uiop:directory-exists-p asset-root))
    (assert (equal (truename root) (truename asset-root)))
    asset-root))

(defun %configure-local-hyperspec-url-template ()
  ;; Keep html-inspector-views responsible for symbol lookup. Its existing
  ;; HYPERSPEC-URL function applies this configurable template to the lookup
  ;; result, for example m_defmet -> /hyperspec/Body/m_defmet.htm.
  (setf html-inspector-views/standard::*hyperspec-url-template*
        (concatenate 'string +hyperspec-http-root+ "Body/~A.htm")))

(eval-when (:load-toplevel :execute)
  (%configure-local-hyperspec-url-template))

(defmethod views/standard:👀content
    ((page views/standard::hyperspec-page))
  (multiple-value-bind (root configuration-problem)
      (hyperspec-root-pathname)
    (if root
        (views:html-view :title "Content" :priority 1
          (views:add-asset-path
           +hyperspec-http-root+
           (%hyperspec-asset-root-pathname root))
          (views:html
            (:iframe
             :src (slot-value page 'views/standard::url)
             :title (views:text-representation page)
             :style "border:none;width:100%;height:100%")))
        (views:html-view :title "HyperSpec not configured" :priority 1
          (views:html
            (:div
             :class "hyperspec-not-configured"
             (:h2 (views:esc "HyperSpec not configured"))
             (:p (views:esc configuration-problem))
             (:p
              (views:esc
               "HyperDoc does not fall back to an external HyperSpec."))))))))
