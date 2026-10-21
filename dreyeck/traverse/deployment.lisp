;;;; Records Before and After Deployment

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "What the Deployment Proves" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From Git Revision to Nix Package" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "How TRAVERSE Enters Mech" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From PageFold to Discourse Graph" :hyperbook "dreyeck/traverse/reading"))

(defun served-bundles (http)
  (loop for entry across (gethash "observations" http)
        for js = (gethash "mechJs" entry)
        when (eql 200 (gethash "status" js))
          collect (cons (gethash "host" entry) (gethash "sha256" js))))

(hyperdoc:defexample deployment-evidence
  "Records made before the deployment, the one made after it, and what each establishes."
  (let* ((reading (retained-reading))
         (acceptance (record-of reading "dreyeck/mech-profile-consumer-acceptance-traverse.json"))
         (at9 (record-of reading "predeployment/at9-report.json"))
         (release (record-of reading "predeployment/release-identity.txt"))
         (http (record-of reading "postdeployment/http-observation.json"))
         (run (record-of reading "example-run.json"))
         (recorded (gethash "mech-discourse client/mech.js" (gethash "bundles" (record-value acceptance))))
         (tested (gethash "sha256" (gethash "bundle" (record-value run))))
         (served (served-bundles (record-value http))))
    (list :before-deployment (remove :before-deployment (reading-records reading) :key #'record-phase :test-not #'eq)
          :after-deployment (remove :after-deployment (reading-records reading) :key #'record-phase :test-not #'eq)
          :consumer-acceptance acceptance
          :end-to-end-acceptance at9
          :release-identity release
          :served-state http
          :bundle-recorded-before recorded
          :bundle-of-example-run tested
          :bundles-served-after served
          :same-bundle-throughout (and (equal recorded tested)
                                       served
                                       (every (lambda (entry) (equal recorded (cdr entry))) served))
          :linux-package-built-before-deployment (not (gethash "evaluatedNotBuilt" (gethash "x86_64-linux" (record-value acceptance))))
          :not-established-here (gethash "doesNotEstablish" (record-value http))
          :operator-activation-observation (gethash "operatorActivationObservation" (record-value http)))))
