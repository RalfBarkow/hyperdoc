;;;; Reproducible browser-runner artifact and comparative inspector surface.

(in-package #:hyperdoc-graham-roots-of-lisp)

(defparameter *roots-lynn-runner-public-path*
  "/roots-of-lisp-lynn/lambda/lisp.html")

(defparameter *roots-lynn-runner-route-pattern*
  "^/roots-of-lisp-lynn/")

(defparameter *roots-lynn-compiler-source-commit*
  "a1f1c47c9bb3ff6a45a0735ced84984396560535")

(defclass roots-lynn-runner-asset ()
  ((relative-path
    :reader roots-lynn-asset-relative-path-of
    :initarg :relative-path)
   (upstream-url
    :reader roots-lynn-asset-upstream-url-of
    :initarg :upstream-url)
   (sha256
    :reader roots-lynn-asset-sha256-of
    :initarg :sha256)))

(defclass roots-lynn-runner-asset-check ()
  ((asset
    :reader roots-lynn-asset-check-asset-of
    :initarg :asset)
   (pathname
    :reader roots-lynn-asset-check-pathname-of
    :initarg :pathname)
   (status
    :reader roots-lynn-asset-check-status-of
    :initarg :status)
   (actual-sha256
    :reader roots-lynn-asset-check-actual-sha256-of
    :initarg :actual-sha256
    :initform nil)))

(defclass roots-lynn-runner-artifact ()
  ((public-path
    :reader roots-lynn-runner-public-path-of
    :initarg :public-path)
   (asset-root
    :reader roots-lynn-runner-asset-root-of
    :initarg :asset-root)
   (manifest
    :reader roots-lynn-runner-manifest-of
    :initarg :manifest)
   (provenance
    :reader roots-lynn-runner-provenance-of
    :initarg :provenance)
   (trust-classification
    :reader roots-lynn-runner-trust-classification-of
    :initarg :trust-classification)
   (direct-open-fallback
    :reader roots-lynn-runner-direct-open-fallback-of
    :initarg :direct-open-fallback)))

(defclass roots-lynn-runner-status ()
  ((artifact
    :reader roots-lynn-runner-artifact-of
    :initarg :artifact)
   (ready-p
    :reader roots-lynn-runner-ready-p-of
    :initarg :ready-p)
   (route-ready-p
    :reader roots-lynn-runner-route-ready-p-of
    :initarg :route-ready-p)
   (asset-checks
    :reader roots-lynn-runner-asset-checks-of
    :initarg :asset-checks)
   (failures
    :reader roots-lynn-runner-failures-of
    :initarg :failures)))

(defclass roots-lynn-runner-surface ()
  ((artifact
    :reader roots-lynn-runner-artifact-of
    :initarg :artifact)
   (fedwiki-page
    :reader roots-lynn-runner-fedwiki-page-of
    :initarg :fedwiki-page)
   (native-page
    :reader roots-lynn-runner-native-page-of
    :initarg :native-page)
   (common-lisp-report
    :reader roots-lynn-runner-common-lisp-report-of
    :initarg :common-lisp-report)))

(defparameter *roots-lynn-runner-manifest*
  (mapcar
   (lambda (entry)
     (destructuring-bind (relative-path upstream-url sha256) entry
       (make-instance 'roots-lynn-runner-asset
                      :relative-path relative-path
                      :upstream-url upstream-url
                      :sha256 sha256)))
   '(("lambda/lisp.html"
      "https://crypto.stanford.edu/~blynn/lambda/lisp.html"
      "c48fb166c933a97545f849e1d2b36005af5f1644be1b154332a160f7b4267e01")
     ("compiler/reply.js"
      "https://crypto.stanford.edu/~blynn/compiler/reply.js"
      "23bd1f5930c557655ab1e71fcda2ebe20d8d4ef4947cada9cb6648c0d0a0283a")
     ("compiler/runme.js"
      "https://crypto.stanford.edu/~blynn/compiler/runme.js"
      "e29a6f288a1d25f6cb252e63d11381900d8d9c607a1d5d5cfd20782fed7e34a6")
     ("compiler/runme.css"
      "https://crypto.stanford.edu/~blynn/compiler/runme.css"
      "5989600e3006d13960807049e727cb8e4104421fe44e2db4df5b07ee37901cd3")
     ("compiler/doh.wasm"
      "https://crypto.stanford.edu/~blynn/compiler/doh.wasm"
      "a8e2634f5c980549537ad412486a9e3c8cf98cb1057997483fcb1872f1efd409")
     ("compiler/Charser.ob"
      "https://crypto.stanford.edu/~blynn/compiler/Charser.ob"
      "860a1bda35c93d8fb249bedd3518a63fc51b0f8fa2ea8ad118bdcebaa8d1e650"))))

(defparameter *roots-lynn-runner-provenance*
  `((:upstream-page
     . "https://crypto.stanford.edu/~blynn/lambda/lisp.html")
    (:compiler-repository . "https://github.com/blynn/compiler")
    (:compiler-source-commit . ,*roots-lynn-compiler-source-commit*)
    (:license . "BSD-3-Clause; Copyright 2019 Ben Lynn")
    (:retrieval
     . "Nix fetchurl pins each deployed URL by SHA-256; a runCommand assembles the fixed relative layout.")
    (:source-correspondence
     . "reply.js, runme.js, and runme.css match the cited compiler Git commit.")
    (:binary-provenance-boundary
     . "doh.wasm and Charser.ob are deployed build artifacts absent from the inspected compiler Git tree; this slice does not claim to reproduce them from source.")))

(defun roots-lynn-default-asset-root ()
  (let ((value (uiop:getenv "HYPERDOC_ROOTS_LYNN_ASSET_ROOT")))
    (when (and value (plusp (length value)))
      (uiop:ensure-directory-pathname value))))

(defun make-roots-lynn-runner-artifact (&key (asset-root (roots-lynn-default-asset-root)))
  "Construct the fixed Lynn runner artifact. ASSET-ROOT may relocate only the
pinned local directory; public and upstream URLs are intentionally not inputs."
  (make-instance
   'roots-lynn-runner-artifact
   :public-path *roots-lynn-runner-public-path*
   :asset-root asset-root
   :manifest (copy-list *roots-lynn-runner-manifest*)
   :provenance (copy-tree *roots-lynn-runner-provenance*)
   :trust-classification :trusted-local-development-demonstration
   :direct-open-fallback *roots-lynn-runner-public-path*))

(defparameter *roots-lynn-runner-artifact*
  (make-roots-lynn-runner-artifact))

(defvar *roots-lynn-runner-surface* nil)

(defun roots-lynn-runner-local-public-url
    (&optional (artifact *roots-lynn-runner-artifact*))
  (format nil "~A~A"
          (string-right-trim "/" (hyperbook/server:canonical-route-origin))
          (roots-lynn-runner-public-path-of artifact)))

(defun roots-lynn-asset-pathname (artifact asset)
  (let ((root (roots-lynn-runner-asset-root-of artifact)))
    (and root
         (merge-pathnames (roots-lynn-asset-relative-path-of asset) root))))

(defun roots-lynn-first-token (string)
  (let* ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return)
                               (or string "")))
         (end (position-if (lambda (character)
                             (member character
                                     '(#\Space #\Tab #\Newline #\Return)))
                           trimmed)))
    (if end (subseq trimmed 0 end) trimmed)))

(defun roots-lynn-program-output (command)
  (handler-case
      (uiop:run-program command
                        :output :string
                        :error-output :output
                        :ignore-error-status t)
    (condition () nil)))

(defun roots-lynn-file-sha256 (pathname)
  (when (and pathname (probe-file pathname))
    (let ((namestring (namestring (truename pathname))))
      (loop for command in (list (list "shasum" "-a" "256" namestring)
                                 (list "sha256sum" namestring))
            for digest = (roots-lynn-first-token
                          (roots-lynn-program-output command))
            when (= (length digest) 64)
              return (string-downcase digest)))))

(defun roots-lynn-check-asset (artifact asset)
  (let* ((pathname (roots-lynn-asset-pathname artifact asset))
         (actual-sha256 (roots-lynn-file-sha256 pathname))
         (status
           (cond
             ((or (null pathname) (not (probe-file pathname))) :missing)
             ((null actual-sha256) :hash-unavailable)
             ((string= actual-sha256 (roots-lynn-asset-sha256-of asset)) :ok)
             (t :hash-mismatch))))
    (make-instance 'roots-lynn-runner-asset-check
                   :asset asset
                   :pathname pathname
                   :status status
                   :actual-sha256 actual-sha256)))

(defun roots-lynn-route-mount-root (artifact)
  (let ((asset-root (roots-lynn-runner-asset-root-of artifact)))
    (and asset-root
         (uiop:pathname-parent-directory-pathname asset-root))))

(defun roots-lynn-pathname-equal (left right)
  (and left right
       (let ((left* (ignore-errors (truename left)))
             (right* (ignore-errors (truename right))))
         (and left* right*
              (string= (namestring left*) (namestring right*))))))

(defun roots-lynn-route-ready-p (artifact)
  (roots-lynn-pathname-equal
   (gethash *roots-lynn-runner-route-pattern*
            clog-connection::*plugin-paths*)
   (roots-lynn-route-mount-root artifact)))

(defun roots-lynn-runner-readiness
    (&optional (artifact *roots-lynn-runner-artifact*))
  (let* ((checks (mapcar (lambda (asset)
                           (roots-lynn-check-asset artifact asset))
                         (roots-lynn-runner-manifest-of artifact)))
         (asset-failures
           (remove :ok checks
                   :key #'roots-lynn-asset-check-status-of
                   :test #'eq))
         (route-ready-p (roots-lynn-route-ready-p artifact))
         (failures
           (append asset-failures
                   (unless route-ready-p
                     (list (list :status :route-not-ready
                                 :public-path
                                 (roots-lynn-runner-public-path-of artifact)))))))
    (make-instance 'roots-lynn-runner-status
                   :artifact artifact
                   :ready-p (null failures)
                   :route-ready-p route-ready-p
                   :asset-checks checks
                   :failures failures)))

(defun register-roots-lynn-runtime-asset-path
    (&optional (artifact *roots-lynn-runner-artifact*))
  "Mount the verified fixed asset output in CLOG's existing static server."
  (let* ((status (roots-lynn-runner-readiness artifact))
         (asset-failures
           (remove :ok
                   (roots-lynn-runner-asset-checks-of status)
                   :key #'roots-lynn-asset-check-status-of
                   :test #'eq))
         (mount-root (roots-lynn-route-mount-root artifact)))
    (if (or asset-failures (null mount-root))
        status
        (progn
          (clog-connection:add-plugin-path
           *roots-lynn-runner-route-pattern*
           mount-root)
          (roots-lynn-runner-readiness artifact)))))

(defun roots-lynn-frame-item-text
    (&optional (artifact *roots-lynn-runner-artifact*))
  (format nil "~A~%HEIGHT 720"
          (roots-lynn-runner-local-public-url artifact)))

(defun roots-lynn-json-object (&rest pairs)
  (let ((object (make-hash-table :test #'equal)))
    (loop for (key value) on pairs by #'cddr
          do (setf (gethash key object) value))
    object))

(defun roots-lynn-unix-time-milliseconds ()
  (* 1000 (- (get-universal-time) 2208988800)))

(defun roots-lynn-fedwiki-reference-text (reference)
  (if (or (uiop:string-prefix-p "https://" reference)
          (uiop:string-prefix-p "http://" reference))
      (format nil "[~A ~A]" reference reference)
      (format nil "[[~A]]" reference)))

(defun roots-lynn-fedwiki-page-data
    (&optional (artifact *roots-lynn-runner-artifact*))
  (let* ((topic (roots-lynn-runner-topic))
         (date (roots-lynn-unix-time-milliseconds))
         (frame-item
           (roots-lynn-json-object
            "id" "roots-lynn-runner-frame"
            "type" "frame"
            "text" (roots-lynn-frame-item-text artifact)))
         (summary-item
           (roots-lynn-json-object
            "id" "roots-lynn-runner-summary"
            "type" "paragraph"
            "text" (summary-of topic)))
         (references-item
           (roots-lynn-json-object
            "id" "roots-lynn-runner-references"
            "type" "paragraph"
            "text"
            (format nil "References~%~%~{~A~^~%~}"
                    (mapcar #'roots-lynn-fedwiki-reference-text
                            (references-of topic))))))
    (roots-lynn-json-object
     "title" (title-of topic)
     "story" (list summary-item frame-item references-item)
     "journal"
     (list
      (roots-lynn-json-object "type" "create" "date" date)
      (roots-lynn-json-object "type" "add" "date" (1+ date)
                              "id" "roots-lynn-runner-summary"
                              "item" summary-item)
      (roots-lynn-json-object "type" "add" "date" (+ date 2)
                              "id" "roots-lynn-runner-frame"
                              "item" frame-item)
      (roots-lynn-json-object "type" "add" "date" (+ date 3)
                              "id" "roots-lynn-runner-references"
                              "item" references-item)))))

(defun roots-lynn-fedwiki-page
    (&optional (artifact *roots-lynn-runner-artifact*))
  "Return an in-memory, source-faithful FedWiki page fixture; never writes the
user's live wiki store."
  (let* ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                              :id "fedwiki:roots-of-lisp-lynn.fixture"))
         (topic (roots-lynn-runner-topic))
         (page (hyperbook/fedwiki::make-fedwiki-page
                wiki
                (id-of topic)
                (title-of topic))))
    ;; Keep the in-memory fixture offline while preserving normal [[Page]]
    ;; references through the existing FedWiki link resolver.
    (setf (gethash (id-of topic) (hyperbook/fedwiki::pages-of wiki)) page)
    (dolist (reference (references-of topic))
      (unless (or (uiop:string-prefix-p "https://" reference)
                  (uiop:string-prefix-p "http://" reference))
        (let ((slug (hyperbook/fedwiki::slug reference)))
          (setf (gethash slug (hyperbook/fedwiki::pages-of wiki))
                (hyperbook/fedwiki::make-fedwiki-page
                 wiki slug reference)))))
    (hyperbook/fedwiki::set-page-data
     page
     (roots-lynn-fedwiki-page-data artifact))
    page))

(defun roots-lynn-fedwiki-page-json
    (&optional (artifact *roots-lynn-runner-artifact*))
  "Return copy-pasteable page JSON for deliberate later installation."
  (with-output-to-string (stream)
    (shasht:write-json (roots-lynn-fedwiki-page-data artifact) stream)))

(defun roots-lynn-native-page-pathname ()
  (roots-system-relative-pathname
   "pages/Roots of Lisp runner comparison.html"))

(defun make-roots-lynn-runner-surface
    (&key (artifact *roots-lynn-runner-artifact*)
          (common-lisp-report (roots-direct-subst-report :event-limit 2000)))
  (make-instance
   'roots-lynn-runner-surface
   :artifact artifact
   :fedwiki-page (roots-lynn-fedwiki-page artifact)
   :native-page (roots-lynn-native-page-pathname)
   :common-lisp-report common-lisp-report))

(defmethod html-inspector-views:text-representation
    ((asset roots-lynn-runner-asset))
  (roots-lynn-asset-relative-path-of asset))

(defmethod html-inspector-views:text-representation
    ((check roots-lynn-runner-asset-check))
  (format nil "~A: ~A"
          (roots-lynn-asset-relative-path-of
           (roots-lynn-asset-check-asset-of check))
          (roots-lynn-asset-check-status-of check)))

(defmethod html-inspector-views:text-representation
    ((artifact roots-lynn-runner-artifact))
  "Ben Lynn Roots of Lisp browser runner")

(defmethod html-inspector-views:text-representation
    ((status roots-lynn-runner-status))
  (if (roots-lynn-runner-ready-p-of status)
      "Ben Lynn runner: ready"
      "Ben Lynn runner: inspectable failure"))

(defmethod html-inspector-views:text-representation
    ((surface roots-lynn-runner-surface))
  "Roots of Lisp runner side-by-side comparison")

(defun roots-render-runner-failure (status)
  (html-inspector-views:html
   (:div :class "roots-lynn-runner-failure"
         (:h3 "Runner unavailable")
         (:p "The iframe is withheld because fixed assets or the stable route failed validation.")
         (:p "Inspect failure: "
             (html-inspector-views:object-ref status))
         (:ul
          (loop for failure in (roots-lynn-runner-failures-of status)
                do (html-inspector-views:html
                    (:li (html-inspector-views:object-ref failure))))))))

(defun roots-render-runner-artifact (artifact &key (instance "native"))
  (let* ((status (roots-lynn-runner-readiness artifact))
         (url (roots-lynn-runner-local-public-url artifact)))
    (if (roots-lynn-runner-ready-p-of status)
        (html-inspector-views:html
         (:div :class "roots-lynn-runner"
               :data-roots-lynn-instance instance
               (:p :class "roots-lynn-trust-boundary"
                   (:b "Trust boundary: ")
                   "trusted local-development demonstration. The iframe is not a compute sandbox; same-origin script execution is required by the pinned runner.")
               (:iframe :src url
                        :title "Ben Lynn Roots of Lisp browser runner"
                        :width "100%"
                        :height "720"
                        :sandbox "allow-scripts allow-same-origin"
                        :loading "eager"
                        :style "border:1px solid #aebdca;border-radius:.4rem;background:white;")
               (:p (:a :href url
                       :target "_blank"
                       :rel "noopener noreferrer"
                       "Open the local runner directly"))))
        (roots-render-runner-failure status))))

(defun roots-render-provenance-table (artifact)
  (html-inspector-views:html
   (:table :class "inspector-table"
           (loop for (key . value) in (roots-lynn-runner-provenance-of artifact)
                 do (html-inspector-views:html
                     (:tr (:th (html-inspector-views:esc
                                (string-capitalize
                                 (substitute #\Space #\-
                                             (symbol-name key)))))
                          (:td (html-inspector-views:esc value))))))))

(defun roots-render-asset-table (artifact)
  (let ((status (roots-lynn-runner-readiness artifact)))
    (html-inspector-views:html
     (:p "Local asset root: "
         (html-inspector-views:object-ref
          (or (roots-lynn-runner-asset-root-of artifact) "not configured")))
     (:p "Route ready: "
         (html-inspector-views:esc
          (if (roots-lynn-runner-route-ready-p-of status) "yes" "no")))
     (:table :class "inspector-table"
             (:tr (:th "Asset") (:th "Expected SHA-256")
                  (:th "Actual SHA-256") (:th "Status"))
             (loop for check in (roots-lynn-runner-asset-checks-of status)
                   for asset = (roots-lynn-asset-check-asset-of check)
                   do (html-inspector-views:html
                       (:tr
                        (:td (html-inspector-views:object-ref asset))
                        (:td (:code (html-inspector-views:esc
                                    (roots-lynn-asset-sha256-of asset))))
                        (:td (:code (html-inspector-views:esc
                                    (or (roots-lynn-asset-check-actual-sha256-of check)
                                        "unavailable"))))
                        (:td (html-inspector-views:object-ref check)))))))))

(defun roots-render-source-relation (artifact)
  (declare (ignore artifact))
  (html-inspector-views:html
   (:h3 "Two execution paths")
   (:table :class "inspector-table"
           (:tr (:th "Lynn browser path")
                (:td "lisp.html → reply.js/runme.js → doh.wasm → compiled Haskell interpreter → Charser.ob"))
           (:tr (:th "HyperDoc path")
                (:td "roots-read-form → roots-evaluate/roots-session-evaluate → roots-evaluation and trace events")))
   (:h3 "Inspectable source")
   (:ul
    (:li "Fixed-output assembly: "
         (html-inspector-views:object-ref
          (roots-system-relative-pathname
           "../nix/roots-of-lisp-lynn-assets.nix")))
    (:li "Runner artifact and views: "
         (html-inspector-views:object-ref
          (roots-system-relative-pathname "src/lynn-runner.lisp")))
    (:li "Common Lisp evaluator: "
         (html-inspector-views:object-ref
          (roots-system-relative-pathname "src/evaluator.lisp")))
    (:li "Evaluation reports: "
         (html-inspector-views:object-ref
          (roots-system-relative-pathname "src/examples.lisp")))
    (:li "Native HyperDoc page: "
         (html-inspector-views:object-ref
          (roots-lynn-native-page-pathname))))))

(html-inspector-views:defview roots-lynn-runner-view
    (artifact roots-lynn-runner-artifact)
  (html-inspector-views:html-view
   :title "Runner" :priority 1
   (roots-render-runner-artifact artifact)))

(html-inspector-views:defview roots-lynn-provenance-view
    (artifact roots-lynn-runner-artifact)
  (html-inspector-views:html-view
   :title "Provenance" :priority 2
   (roots-render-provenance-table artifact)))

(html-inspector-views:defview roots-lynn-assets-view
    (artifact roots-lynn-runner-artifact)
  (html-inspector-views:html-view
   :title "Assets" :priority 3
   (roots-render-asset-table artifact)))

(html-inspector-views:defview roots-lynn-source-relation-view
    (artifact roots-lynn-runner-artifact)
  (html-inspector-views:html-view
   :title "Source relation" :priority 4
   (roots-render-source-relation artifact)))

(html-inspector-views:defview roots-lynn-status-view
    (status roots-lynn-runner-status)
  (html-inspector-views:html-view
   :title "Status" :priority 1
   (roots-render-asset-table (roots-lynn-runner-artifact-of status))))

(defun roots-render-fedwiki-representation (surface)
  (let ((page (roots-lynn-runner-fedwiki-page-of surface)))
    (html-inspector-views:html
     (:div :class "roots-lynn-fedwiki-page hyperbook-page"
           :data-roots-lynn-representation "fedwiki-frame"
           (:h2 (html-inspector-views:esc (hyperbook:title-of page)))
           (loop for item across (hyperbook/fedwiki::story-of page)
                 do (html-inspector-views:html
                     (:div :class "roots-lynn-fedwiki-story-item"
                           :data-story-item-type
                           (string-downcase
                            (symbol-name
                             (hyperbook/fedwiki::item-type-of item)))
                           (hyperbook/fedwiki::render-story-item
                            (hyperbook/fedwiki::item-type-of item)
                            item
                            page))))
           (:details
            (:summary "Source-faithful frame item")
            (:pre (html-inspector-views:esc
                   (roots-lynn-frame-item-text
                    (roots-lynn-runner-artifact-of surface)))))))))

(defun roots-render-native-representation (surface)
  (let ((artifact (roots-lynn-runner-artifact-of surface)))
    (html-inspector-views:html
     (:div :class "roots-lynn-native-page hyperbook-page"
           :data-roots-lynn-representation "native-hyperdoc"
           (:h2 "Roots of Lisp runner comparison")
           (:p "This native HyperDoc representation embeds the pinned local Lynn runner while keeping HyperDoc's Common Lisp evaluation report separate and inspectable.")
           (:p "Native page source: "
               (html-inspector-views:object-ref
                (roots-lynn-runner-native-page-of surface)))
           (roots-render-runner-artifact artifact :instance "native-side-by-side")))))

(defun roots-render-side-by-side-surface (surface)
  (html-inspector-views:html
   (:style ".roots-lynn-comparison{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:12px}.roots-lynn-panel{min-width:0;border:1px solid #c8d4df;border-radius:.55rem;padding:.75rem;background:#f8fbfd}.roots-lynn-panel h1{font-size:1rem}@media(max-width:900px){.roots-lynn-comparison{grid-template-columns:1fr}}")
   (:div :class "roots-lynn-comparison"
         (:section :class "roots-lynn-panel"
                   :data-roots-lynn-panel "fedwiki"
                   (:h1 "Federated Wiki frame representation")
                   (roots-render-fedwiki-representation surface))
         (:section :class "roots-lynn-panel"
                   :data-roots-lynn-panel "native"
                   (:h1 "Native HyperDoc runner representation")
                   (roots-render-native-representation surface)))))

(html-inspector-views:defview roots-lynn-side-by-side-browser-view
    (surface roots-lynn-runner-surface)
  (html-inspector-views:html-view
   :title "Browser" :priority 1
   (roots-render-side-by-side-surface surface)))

(html-inspector-views:defview roots-lynn-common-lisp-report-view
    (surface roots-lynn-runner-surface)
  (html-inspector-views:html-view
   :title "Common Lisp report" :priority 2
   (html-inspector-views:html
    (:p "This is HyperDoc's Common Lisp evaluator path, not the Lynn browser evaluator.")
    (:p "Direct SUBST evaluation and semantic trace: "
        (html-inspector-views:object-ref
         (roots-lynn-runner-common-lisp-report-of surface)))
    (:p "The object-language EVAL. report remains available from "
        (html-inspector-views:object-ref
         (roots-system-relative-pathname
          "pages/The Surprise as an evaluation trace.html"))))))

(html-inspector-views:defview roots-lynn-fedwiki-source-view
    (surface roots-lynn-runner-surface)
  (html-inspector-views:html-view
   :title "FedWiki source" :priority 3
   (html-inspector-views:html
    (:p "In-memory fixture; no live wiki store is mutated.")
    (:pre :style "white-space:pre-wrap;"
          (html-inspector-views:esc
           (roots-lynn-fedwiki-page-json
            (roots-lynn-runner-artifact-of surface)))))))

(hyperdoc:defhyperdoc *roots-hyperdoc*
  :title "Roots of Lisp"
  :id "hyperdoc-graham-roots-of-lisp"
  :asdf-system-name "hyperdoc-graham-roots-of-lisp"
  :subdirectory "hyperdoc-graham-roots-of-lisp/pages"
  :code-subdirectory "src"
  :main-page-id "The Roots of Lisp")

(eval-when (:load-toplevel :execute)
  (hyperbook/server:register-server-startup-hook
   'register-roots-lynn-runtime-asset-path)
  ;; Also refresh the mount when this subsystem is reloaded into an already
  ;; running coherent image.
  (register-roots-lynn-runtime-asset-path))
