;;;; The example page of the CCNx Federated Wiki reading, as ordinary local Federated Wiki pages.
;;
;; The reading follows one page through the code of the two historical repositories. Its two forms that are Wiki pages are
;; files of a small local site under dreyeck/ccnx-federated-wiki/example-site/pages/, read by the existing
;; DREYECK/LOCAL-FEDWIKI-PAGE and shown by the existing Story view and Inspector. Nothing here writes them, loads historical
;; code or opens a network connection. The pages are an illustration built for the reading, not pages from either repository;
;; the CCNx form is derived by applying the rules the cited source states (see docs/ccnx-federated-wiki/SOURCE-REPORT.md).

(in-package #:dreyeck/ccnx-federated-wiki)

(defparameter +example-kinds+
  '((:sfw "plain-text-example"
     "The page as a Federated Wiki server stores it: title, story, journal.")
    (:ccnx-record "plain-text-example-ccnx-record"
     "The same page as the code at 8426dc5 leaves it in the browser's IndexedDB after the last action: the same three fields plus page, excludes, favicon and version."))
  "(kind slug description). The page files live under EXAMPLE-SITE-ROOT.")

(defun example-slug (kind)
  (or (second (assoc kind +example-kinds+))
      (error "No example page of kind ~S; the kinds are ~{~S~^, ~}." kind (mapcar #'first +example-kinds+))))

(defun example-site-root ()
  (asdf:system-relative-pathname "dreyeck/ccnx-federated-wiki" "dreyeck/ccnx-federated-wiki/example-site/"))

(defun example-page (&optional (kind :sfw))
  "The example page of KIND (:SFW or :CCNX-RECORD), read from its file now. Its logical site is the reserved, unresolvable
ccnx-example.invalid: the pages hold no link to another page, so showing them triggers no page lookup. (The Story view's header
asks the browser for that origin's favicon; the name never resolves, so the icon stays broken.)"
  (let* ((root (example-site-root))
         (wiki (lp:make-local-fedwiki root "fedwiki:ccnx-example.invalid")))
    (lp:make-local-fedwiki-page root wiki (example-slug kind))))
