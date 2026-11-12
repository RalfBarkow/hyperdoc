;;;; Acceptance test for the native TMDM merge; never executes SHOP3 or writes sources.
(defpackage #:dreyeck/work/paul-2026/tests
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/work/paul-2026)
                    (#:m #:topic-maps.tmdm)
                    (#:cx #:topic-maps.cxtm))
  (:export #:run-tests))
(in-package #:dreyeck/work/paul-2026/tests)

(defun native-connection-p (map first-subject second-subject)
  "Follow actual Association and Role Items, never labels or a projected edge."
  (let ((one (r:find-subject map first-subject))
        (two (r:find-subject map second-subject)))
    (and one two
         (some (lambda (association)
                 (let ((roles (m:association-roles association)))
                   (and (some (lambda (role)
                                (and (eq one (m:association-role-player role))
                                     (eq association (m:association-role-parent role))
                                     (member role (m:topic-roles-played one) :test #'eq)))
                              roles)
                        (some (lambda (role)
                                (and (eq two (m:association-role-player role))
                                     (eq association (m:association-role-parent role))
                                     (member role (m:topic-roles-played two) :test #'eq)))
                              roles))))
               (m:topic-map-associations map)))))

(defun run-tests ()
  (multiple-value-bind (target source) (r:read-source-maps)
    (let* ((subject r:+shared-shop3-subject+)
           (old-target (r:find-subject target subject))
           (old-source (r:find-subject source subject))
           (source-before
             (cx:canonicalize-octets
              source
              :base-locator "https://dreyeck.ch/topic-maps/paul-2026/paul-2026.ctm"))
           (source-count (length (m:topic-map-topics source))))
      (assert (and old-source old-target (not (eq old-source old-target))))
      (multiple-value-bind (merged resolve)
          (m:import-map-content target source)
        (assert (eq merged target))
        (assert (eq old-target (r:find-subject merged subject)))
        (assert (eq old-target (funcall resolve old-source)))
        (assert (eq source (m:topic-parent old-source)))
        (assert (= source-count (length (m:topic-map-topics source))))
        (assert (equalp source-before
                        (cx:canonicalize-octets
                         source
                         :base-locator "https://dreyeck.ch/topic-maps/paul-2026/paul-2026.ctm")))
        (assert (r:find-subject merged "urn:hyperdoc:page:planning-with-shop3"))
        (assert (r:find-subject merged "urn:hyperdoc:paul-2026:domain:worksworld-2h"))
        (assert (native-connection-p
                 merged
                 "urn:hyperdoc:paul-2026:domain:worksworld-2h" subject))))
    (multiple-value-bind (merged source resolve) (r:read-merged-map)
      (declare (ignore source resolve))
      (assert (typep merged 'm:topic-map))
      (assert (r:find-subject merged r:+shared-shop3-subject+)))
    t))
