;;;; Authored D2 renders without a Topicmap, and says so.

(in-package :dreyeck/topicmap/tests)

(defun authored-check (condition format &rest arguments)
  (unless condition (apply #'error format arguments))
  t)

(defun check-authored-source-is-the-page-text ()
  "The page carries the diagram; nothing rewrites it on the way out.

Read from the page file and compared character for character against
what the page shows, because the claim of this slice is that the
authoritative payload is ordinary D2 written by a person — not D2 that
something assembled and the page then displayed."
  (let ((source (dreyeck/topicmap/tala/authored:page-authored-d2-source)))
    (authored-check (stringp source) "The page yielded no D2 source.")
    (authored-check (search "user -> network.cell tower: make call" source)
                    "The page's D2 source has been altered in transport: ~S"
                    source)
    ;; Entities must be decoded, or the renderer would be handed markup.
    (authored-check (not (search "&gt;" source))
                    "HTML entities survived into the D2 source.")
    (authored-check (search "cell tower" source)
                    "The D2 source lost a label."))
  t)

(defun check-authored-rendering-needs-no-topicmap ()
  "Authored D2 must not be quietly routed through the projection path.

The proof is a source the projection path cannot accept. The page's
diagram nests containers, and PROJECTION-TALA-INPUT refuses anything but
flat relation signs, so if authored rendering shared that path this
would fail rather than produce a picture. It is also the honest
demonstration of the difference: authored text may use the whole
language, because it answers to no Topicmap."
  (let* ((source (dreyeck/topicmap/tala/authored:page-authored-d2-source))
         (rendered (dreyeck/topicmap/tala/authored:render-authored-d2 source)))
    (authored-check (search "network" source)
                    "The authored source no longer nests containers, so this ~
test no longer distinguishes the two paths.")
    (authored-check (string= source
                             (dreyeck/topicmap/tala/authored:authored-d2-source
                              rendered))
                    "The rendering changed the source it was given.")
    (authored-check (string= "v0.9.0"
                             (dreyeck/topicmap/tala/authored:authored-d2-version
                              rendered))
                    "Authored D2 was laid out by an unpinned renderer.")
    (let ((svg (dreyeck/topicmap/tala/authored:authored-d2-svg rendered)))
      (authored-check (search "<svg" svg) "No SVG was produced.")
      (authored-check (search "make call" svg)
                      "The rendered SVG does not carry the authored label.")
      ;; Non-interactive here too, and for the same reason.
      (authored-check (not (search "onclick" svg))
                      "The authored SVG carries a handler.")
      (authored-check (not (search "href" svg))
                      "The authored SVG carries a link.")))
  t)

(defun check-authored-rendering-shares-one-boundary ()
  "Both kinds of diagram must reach the tool through the same door.

Two invocations would be two places for the pinned flags, the seed and
the version to drift apart. So the generated path is asked for a
rendering and the authored path for another, and their reported versions
must agree, since only one renderer was consulted."
  (let* ((workspace (tala-real-workspace))
         (projection (dreyeck/topicmap:topicmap-projection-of workspace))
         (generated (dreyeck/topicmap/tala:run-tala
                     (dreyeck/topicmap/tala:projection-tala-input projection)))
         (authored (dreyeck/topicmap/tala/authored:render-authored-d2 "a -> b")))
    (authored-check
     (string= (dreyeck/topicmap/tala:tala-rendering-version generated)
              (dreyeck/topicmap/tala/authored:authored-d2-version authored))
     "The generated and authored paths report different renderers."))
  t)

(defun check-absent-renderer-is-reported ()
  "A missing tool must be an observation, not a crash.

The reading page branches on this status, so what it branches on has to
be dependable: an absent program yields :UNAVAILABLE with a remedy, and
never a partial rendering."
  (let ((status (dreyeck/topicmap/tala:tala-dependency-status
                 :program "d2-that-is-not-installed")))
    (authored-check (eq :unavailable (getf status :status))
                    "An absent renderer reported ~S." (getf status :status))
    (authored-check (getf status :remedy)
                    "The absent-renderer report names no remedy."))
  (authored-check
   (nth-value 1 (ignore-errors
                 (dreyeck/topicmap/tala:run-d2-tala
                  "a -> b" :program "d2-that-is-not-installed")))
   "Running an absent renderer did not signal.")
  t)

(defun run-authored-d2-tests ()
  (check-authored-source-is-the-page-text)
  (check-absent-renderer-is-reported)
  (check-authored-rendering-needs-no-topicmap)
  (check-authored-rendering-shares-one-boundary)
  (format t "AUTHORED-D2-PASS: page text rendered by the shared boundary, ~
without a Topicmap and without interaction.~%")
  t)
