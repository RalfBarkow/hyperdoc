;;;; HyperDoc authored topic family for the inspector Reel/carousel contract.

(in-package :hyperdoc)

(defun the-reel-as-accessible-carousel-topic ()
  (make-topic
   :id "the-reel-as-accessible-carousel"
   :title "The Reel as Accessible Carousel"
   :summary "HyperDoc inspector panes use Every Layout's Reel as the layout primitive and BBC GEL's carousel guidance as the accessibility contract for user-controlled horizontal pane navigation."
   :references '("The Reel as Accessible Carousel"
                 "assets/hyperdoc/css/hyperdoc-reel.css"
                 "assets/hyperdoc/js/hyperdoc-reel.js"
                 "tests/playwright/reel-accessible-carousel.spec.js")))

(defun inspector-pane-surface-topic ()
  (make-topic
   :id "inspector-pane-surface"
   :title "Inspector pane surface"
   :summary "The horizontally navigable CLOG inspector pane row that remains browser-native while HyperDoc progressively enhances controls, boundary state, and pane inertness."
   :references '("The Reel as Accessible Carousel"
                 "hyperbook-server/inspector-performance.lisp"
                 "hyperbook-server/inspector-dom-association.lisp"
                 "tests/playwright/html-source-pane-layout.spec.js")))

(defun accessible-reel-carousel-contract-topic ()
  (make-topic
   :id "accessible-reel-carousel-contract"
   :title "Accessible Reel carousel contract"
   :summary "Contract that horizontal inspector navigation has no autoplay, keeps native scrolling, reveals real buttons only after JavaScript initializes, and prevents obscured panes from trapping focus."
   :references '("The Reel as Accessible Carousel"
                 "assets/hyperdoc/js/hyperdoc-reel.js"
                 "assets/hyperdoc/css/hyperdoc-reel.css")))

(defun reel-progressive-enhancement-state-model-topic ()
  (make-topic
   :id "reel-progressive-enhancement-state-model"
   :title "Reel progressive enhancement state model"
   :summary "SCXML sketch for the inspector Reel lifecycle from uninitialized native scrolling to enhanced button and inertness updates."
   :references '("The Reel as Accessible Carousel"
                 "hyperdoc/reel-accessible-carousel.scxml"
                 "tests/reel-accessible-carousel-smoke.lisp")))

(defun reel-as-accessible-carousel-plan-topic ()
  (make-topic
   :id "reel-as-accessible-carousel-plan"
   :title "Reel as Accessible Carousel plan"
   :summary "SHOP3-like planning object for applying the accessible Reel/carousel pattern to HyperDoc inspector panes."
   :references '("The Reel as Accessible Carousel"
                 "hyperdoc/reel-accessible-carousel.lisp"
                 "tests/reel-accessible-carousel-smoke.lisp")))
