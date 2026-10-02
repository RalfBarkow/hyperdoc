;;;; Explicit live witness; every authoring effect uses temporary source copies.
(require :asdf)
(asdf:load-system "dreyeck/work/authoring/tests")
(dreyeck/work/addresses/tests:run-live-addresses-witness :port 18092 :linger 30)
