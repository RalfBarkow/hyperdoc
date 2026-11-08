;;;; Resolution-only extraction from PR #32 e1ab2f570ee793e301c5af706cbcf2fc984c02a9.
;;;; Fork preparation is deliberately absent; PR #33 remains its only authority.
;;;; Adaptations: explicit own-site distinct from Java origin; modeled candidates only at own-site.
(defpackage #:dreyeck/work/local-only-resolution (:use #:cl))
(in-package #:dreyeck/work/local-only-resolution)
(defparameter +reference-revision+ "b58fb43e7ffbbbda66685363dcda1facbd2a46a1")

(defun reference-url (lines)
  (format nil "https://github.com/RalfBarkow/fedwiki-java/blob/~A/Main.java#~A" +reference-revision+ lines))

;;; The candidate order, mirroring Main.java statement by statement. Pure list functions; no I/O.

(defun java-page-context (journal-sites)
  "Page.context(), Main.java L289-L295. JOURNAL-SITES: each journal action's SITE field (or NIL), oldest first.
Walks newest to oldest and keeps the first occurrence of each site. Attribution sites are not read."
  (let ((sites '()))
    (dolist (site (reverse journal-sites) (nreverse sites))
      (when (and site (not (member site sites :test #'equal)))
        (push site sites)))))

(defun java-panel-context (panel-site origin journal-sites)
  "Panel.context(), Main.java L266-L273: a panel from a site other than the origin puts that site first."
  (let ((context (java-page-context journal-sites)))
    (if (equal panel-site origin)
        context
        (cons panel-site (remove panel-site context :test #'equal)))))

(defun java-link-candidates (&key origin panel-site item-site journal-sites)
  "Panel.load(Panel from, String slug), Main.java L225-L255: the origin first, then the item's site, then the panel
context. Returns ((SITE . SOURCE) ...) in request order; SOURCE is :ORIGIN, :ITEM, :PANEL or :JOURNAL, the reason for
the position. The origin is not removed from the context, so it can occur twice (observed: origin-in-context)."
  (let ((context (java-panel-context panel-site origin journal-sites)))
    (when item-site
      (setf context (cons item-site (remove item-site context :test #'equal))))
    (cons (cons origin :origin)
          (mapcar (lambda (site)
                    (cons site (cond ((equal site item-site) :item)
                                     ((and (equal site panel-site) (not (equal panel-site origin))) :panel)
                                     (t :journal))))
                  context))))

(defun candidate-facts (request candidates)
  "SHOP3 facts for CANDIDATES of REQUEST: (CANDIDATE request position site source), the successor relation, the end."
  (append (loop for (site . source) in candidates
                for position from 0
                collect `(candidate ,request ,position ,site ,source)
                collect `(candidate-after ,request ,position ,(1+ position)))
          `((candidates-end ,request ,(length candidates)))))

;;; The domain. Observations: PAGE-AVAILABLE (HTTP 200), PAGE-UNAVAILABLE with its status (any other status),
;;; REQUEST-ERROR (no HTTP answer). A missing observation is unknown and no method treats it as absence.
;;; Every alternative is its own :METHOD, so :WHICH :ALL would expose overlapping alternatives.

(shop3:defdomain (fedwiki-link-resolution :noset t)
  ((:- (availability-conflict ?site ?slug)
    available-and-unavailable ((page-available ?site ?slug) (page-unavailable ?site ?slug ?_status))
    available-and-error ((page-available ?site ?slug) (request-error ?site ?slug))
    unavailable-and-error ((page-unavailable ?site ?slug ?_status) (request-error ?site ?slug)))

   ;; Primitive steps: planned, never performed.
   (:operator (!request ?request ?site ?slug ?source)
    () () ((planned-request ?request ?site ?slug ?source)))
   (:operator (!open-panel ?request ?site ?slug ?source)
    ((page-available ?site ?slug))
    () ((planned-panel ?request ?site ?slug ?source)))
   (:operator (!use-modeled-page ?request ?site ?slug)
    ((modeled-local-page ?site ?slug))
    () ((planned-hypothetical-panel ?request ?site ?slug)))
   (:operator (!conclude-unresolved ?request ?slug ?policy)
    () () ((planned-unresolved ?request ?slug ?policy)))
   (:operator (!abort-resolution ?request ?site ?slug)
    ((request-error ?site ?slug))
    () ((planned-abort ?request ?site ?slug)))
   ;; A. Collaborative resolution: walk the candidates in Main.java's order.
   (:method (resolve ?request ?slug collaborative)
    walk-candidates ((candidate ?request 0 ?_site ?_source))
    ((try-candidate ?request ?slug 0)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-has-modeled-page
    ((own-site ?site) (candidate ?request ?position ?site ?_source) (modeled-local-page ?site ?slug) (not (page-available ?site ?slug)))
    ((!use-modeled-page ?request ?site ?slug)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-available
    ((candidate ?request ?position ?site ?source) (page-available ?site ?slug) (not (availability-conflict ?site ?slug)))
    ((!request ?request ?site ?slug ?source) (!open-panel ?request ?site ?slug ?source)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-unavailable-next
    ((candidate ?request ?position ?site ?source) (page-unavailable ?site ?slug ?_status)
     (not (modeled-local-page ?site ?slug)) (not (availability-conflict ?site ?slug))
     (candidate-after ?request ?position ?next))
    ((!request ?request ?site ?slug ?source) (try-candidate ?request ?slug ?next)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-request-error
    ((candidate ?request ?position ?site ?source) (request-error ?site ?slug) (not (availability-conflict ?site ?slug)))
    ((!request ?request ?site ?slug ?source) (!abort-resolution ?request ?site ?slug)))
   (:method (try-candidate ?request ?slug ?position)
    candidates-exhausted
    ((candidates-end ?request ?position))
    ((!conclude-unresolved ?request ?slug collaborative)))

   ;; B. Local-only resolution: the own site and nothing else; no method reaches TRY-CANDIDATE.
   (:method (resolve ?request ?slug local-only)
    own-site-only ((own-site ?own))
    ((try-own-site ?request ?own ?slug)))
   (:method (try-own-site ?request ?own ?slug)
    observed-local
    ((page-available ?own ?slug) (not (availability-conflict ?own ?slug)))
    ((!request ?request ?own ?slug own-site) (!open-panel ?request ?own ?slug own-site)))
   (:method (try-own-site ?request ?own ?slug)
    modeled-local
    ((modeled-local-page ?own ?slug) (not (page-available ?own ?slug)))
    ((!use-modeled-page ?request ?own ?slug)))
   (:method (try-own-site ?request ?own ?slug)
    missing-locally
    ((page-unavailable ?own ?slug ?_status) (not (modeled-local-page ?own ?slug)) (not (availability-conflict ?own ?slug)))
    ((!request ?request ?own ?slug own-site) (!conclude-unresolved ?request ?slug local-only)))
   (:method (try-own-site ?request ?own ?slug)
    own-request-error
    ((request-error ?own ?slug) (not (availability-conflict ?own ?slug)))
    ((!request ?request ?own ?slug own-site) (!abort-resolution ?request ?own ?slug)))

))
