;;;; FedWiki page slugs: the address of one page in a local site

(in-package #:dreyeck/fedwiki-assets)

;; A page slug names one page of one site, and one file: a direct child of
;; the site's pages/ directory. The rule is wiki-server's own, the one its
;; page routes accept: one or more of a-z, 0-9 and -. A string outside it is
;; refused, never normalized into a slug, and refused before any pathname
;; exists, so no caller reaches a file by skipping a route's check. Local
;; page stores hold only such names as pages; a file named otherwise, such as
;; a backup with a dot in its name, is not a page FedWiki can serve either.
;;
;; This is a lexical and pathname confinement, not a filesystem one: a
;; symbolic link placed inside pages/ by the site's owner is followed like
;; any file, and nothing here inspects where it leads.

(define-condition invalid-fedwiki-page-slug (error)
  ((slug :initarg :slug :reader invalid-fedwiki-page-slug-slug))
  (:report (lambda (condition stream)
             (format stream "~S is not a FedWiki page slug: one or more of a-z, 0-9 ~
and -, naming one page in a site's pages/ directory."
                     (invalid-fedwiki-page-slug-slug condition))))
  (:documentation "Refused before any pathname was made or any file opened."))

(defun fedwiki-page-slug-p (object)
  "Whether OBJECT is a FedWiki page slug: a non-empty string of a-z, 0-9 and -."
  (and (stringp object)
       (plusp (length object))
       (every (lambda (character)
                (or (char<= #\a character #\z)
                    (char<= #\0 character #\9)
                    (char= #\- character)))
              object)))

(defun check-fedwiki-page-slug (slug)
  "SLUG, if it is a FedWiki page slug; otherwise INVALID-FEDWIKI-PAGE-SLUG."
  (unless (fedwiki-page-slug-p slug)
    (error 'invalid-fedwiki-page-slug :slug slug))
  slug)
