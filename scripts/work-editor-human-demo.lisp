;;;; Authoring-capable loopback demo; all effects stay on a temporary fixture.
(require :asdf)
(asdf:load-system "dreyeck/work/authoring/tests")
(dreyeck/work/editor/tests:run-human-editor-demo :port 18091)
