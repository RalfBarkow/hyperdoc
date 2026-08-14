;; Activate a local FedWiki page-attached HyperDoc

(in-package #:dreyeck/fedwiki-hyperdoc)

(defun pathname-under-directory-p (pathname directory)
  "Return true if existing PATHNAME resolves below existing DIRECTORY.

TRUENAME resolves parent-directory components and symbolic links before
the containment relation is checked."
  (let* ((path
           (truename pathname))
         (root
           (truename
            (uiop:ensure-directory-pathname directory)))
         (path-directory
           (pathname-directory path))
         (root-directory
           (pathname-directory root)))
    (and
     (equal
      (pathname-host path)
      (pathname-host root))
     (equal
      (pathname-device path)
      (pathname-device root))
     (<=
      (length root-directory)
      (length path-directory))
     (equal
      root-directory
      (subseq
       path-directory
       0
       (length root-directory))))))

(defun page-attached-asdf-under-assets-root-p (site-root asd-pathname)
  "Return true if ASD-PATHNAME resolves below SITE-ROOT's assets directory.

This is the trust boundary immediately before a discovered ASD file may
be evaluated as Lisp code."
  (pathname-under-directory-p
   asd-pathname
   (dreyeck/fedwiki-assets:local-fedwiki-assets-root site-root)))

(defun directly-depends-on-system-p (system-designator dependency-name)
  "Return true for a plain direct ASDF dependency named DEPENDENCY-NAME."
  (let ((system
          (asdf:find-system system-designator)))
    (some
     (lambda (dependency)
       (and
        (typep dependency '(or string symbol))
        (string-equal dependency dependency-name)))
     (asdf:system-depends-on system))))

(defun direct-hyperdoc-presentation-candidates (system-names)
  "Return SYSTEM-NAMES having a plain direct dependency on HYPERDOC.

This is a structural candidate rule, not a naming convention."
  (remove-if-not
   (lambda (name)
     (directly-depends-on-system-p
      name
      "hyperdoc"))
   system-names))

(defun hyperdocs-for-asdf-systems (system-names)
  "Return registered HyperDocs whose core ASDF system is in SYSTEM-NAMES."
  (remove-if-not
   (lambda (hyperdoc)
     (let ((system
             (ignore-errors
               (hyperdoc:asdf-system-of hyperdoc))))
       (and
        system
        (member
         (asdf:component-name system)
         system-names
         :test #'string-equal))))
   (dreyeck/page-attached-hyperdoc:registered-hyperdocs)))

(defun activate-local-fedwiki-page-hyperdoc (site-root slug)
  "Discover, register, select, and activate one local page-attached HyperDoc.

The operation starts with the read-only FedWiki asset relation.  It
requires exactly one discovered ASD file, verifies that the ASD resolves
below SITE-ROOT/assets before evaluating it, registers the systems defined
by that ASD, requires exactly one system with a plain direct dependency on
HYPERDOC, loads that presentation system, and finally requires exactly one
registered Runtime HyperDoc whose core ASDF system belongs to the same ASD.

The returned plist retains the observations from each stage."
  (check-type slug string)
  (let* ((discovery
           (dreyeck/fedwiki-assets:page-attached-asdf-discovery-observation
            site-root
            slug))
         (asdf-files
           (getf discovery :asdf-files)))
    (unless (= 1 (length asdf-files))
      (error
       "Expected exactly one page-attached ASD for ~S, got ~D: ~S"
       slug
       (length asdf-files)
       asdf-files))
    (let ((asd
            (truename
             (first asdf-files))))
      (unless
          (page-attached-asdf-under-assets-root-p
           site-root
           asd)
        (error
         "Refusing to evaluate page-attached ASD outside the local assets root: ~A"
         asd))
      (let* ((registration
               (dreyeck/page-attached-asdf:asd-registration-observation
                asd))
             (systems
               (getf registration :systems-after))
             (candidates
               (direct-hyperdoc-presentation-candidates
                systems)))
        (unless (= 1 (length candidates))
          (error
           "Expected exactly one direct HyperDoc presentation candidate for ~S, got ~D: ~S"
           slug
           (length candidates)
           candidates))
        (let* ((presentation-system
                 (first candidates))
               (activation
                 (dreyeck/page-attached-hyperdoc:load-system-and-observe-hyperdocs
                  presentation-system))
               (runtime-hyperdocs
                 (hyperdocs-for-asdf-systems
                  systems)))
          (unless (= 1 (length runtime-hyperdocs))
            (error
             "Expected exactly one Runtime HyperDoc for ~S, got ~D: ~S"
             slug
             (length runtime-hyperdocs)
             runtime-hyperdocs))
          (let ((runtime-hyperdoc
                  (first runtime-hyperdocs)))
            (list
             :slug slug
             :discovery discovery
             :trusted-asd asd
             :registration registration
             :systems-defined-by-asd systems
             :presentation-candidates candidates
             :selected-presentation-system presentation-system
             :activation activation
             :runtime-hyperdoc runtime-hyperdoc
             :runtime-hyperdoc-id
             (hyperbook:id-of runtime-hyperdoc)
             :runtime-hyperdoc-core-system
             (asdf:component-name
              (hyperdoc:asdf-system-of
               runtime-hyperdoc)))))))))
