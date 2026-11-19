;;;; SLY: load this file from the HyperDoc development environment.
(require :asdf)

(defpackage #:ki-plan-test
  (:use #:cl)
  (:export #:*source* #:inputs #:run))
(in-package #:ki-plan-test)

(defparameter *source*
  (let* ((zip (truename (merge-pathnames "../shop3-planning-domains.zip" *load-truename*)))
         (root (uiop:ensure-directory-pathname
                (uiop:run-program '("/usr/bin/mktemp" "-d" "/private/tmp/ki-shop3.XXXXXXXX")
                                  :output '(:string :stripped t))))
         (copy (merge-pathnames "plan.zip" root))
         (asd (merge-pathnames "shop3-planning-domains/shop3-planning-domains.asd" root))
         (primary "shop3-planning-domains")
         (publication "shop3-planning-domains/publication"))
    (uiop:copy-file zip copy)
    (let ((sha (first (uiop:split-string
                       (uiop:run-program (list "/usr/bin/shasum" "-a" "256" (namestring copy))
                                         :output :string)
                       :separator '(#\Space)))))
      (assert (string= sha "e4f3612f0d80c87571e37b99d1f927144fea9de28dd47a82a7567aee52fb33ff"))
      (uiop:run-program (list "/usr/bin/unzip" "-q" (namestring copy) "-d" (namestring root)))
      (asdf:load-asd asd)
      (dolist (name (list primary publication))
        (assert (equal (truename asd) (truename (asdf:system-source-file name))))
        (asdf:load-system name))
      (list :archive zip :sha256 sha
            :primary-asd (asdf:system-source-file primary)
            :primary-version (asdf:component-version (asdf:find-system primary))
            :publication-asd (asdf:system-source-file publication)
            :publication-version (asdf:component-version (asdf:find-system publication))
            :shop3-asd (asdf:system-source-file "shop3")))))

;; Each case projects the same local release. Evidence strings are planner inputs.
(defparameter *local-evidence*
  '((:local-site-root-observed "Source http://localhost:3000, store /Users/rgb/.wiki/wiki.ralfbarkow.ch/ (recorded).")
    (:local-page-present "pages/ki-risikokapital-und-weltkapital SHA-256 1bbc3f69ff518b7af0483a859c9a41cf291fb1c641bcbf777f4e4a24422bd00b")
    (:local-content-verified "Fixture: reviewed the 24 ordered story items and assets item 4b8d9298c55b9601 of this local page.")
    (:local-attachment-verified "Local ZIP SHA-256 b3e6b02794a4f1f9c20e89cb009092165320c551a06221c9a6aae0f4ab0bbe99")
    (:local-zip-discovery-verified "Fixture: workspace:ki-risikokapital-und-weltkapital; member ki-risikokapital-und-weltkapital/ki-risikokapital-und-weltkapital.asd")
    (:release-reviewed "TESTFAKT Freigabe: KI 1.0.2, local page 1bbc3f69ff518b7af0483a859c9a41cf291fb1c641bcbf777f4e4a24422bd00b and ZIP b3e6b02794a4f1f9c20e89cb009092165320c551a06221c9a6aae0f4ab0bbe99.")))

(defparameter *local-completed*
  '(:resolve-local-site-root :observe-local :fill-local :attach-local
    :verify-zip-discovery :prepare-release :observe-target))

(defparameter *ready*
  '(:target-ready "TESTFAKT: de.dreyeck.ch target ready for this reviewed release."))
(defparameter *conflict*
  '(:target-conflict "KI target JSON SHA-256 1a5616b66118b44af1e89d7ca8097454d81729233c413f91065f98575e278565. After fork from localhost:3000, journal edits 41f3e2058cb2ee5c, 38604807788708d5, 2e283832045a76b6."))
(defparameter *assets*
  '(:public-assets-verified "de.dreyeck.ch/assets/pages/ki-risikokapital-und-weltkapital/ readback SHA-256: ZIP b3e6b02794a4f1f9c20e89cb009092165320c551a06221c9a6aae0f4ab0bbe99; CTM eaf986abdb171d1c600e449903d80280e1ddba979e8da148cf6400268e49902d; PDF 29a602e7dcc758106015152388541287f6f1771a590fe52c4ccf3378f4bb85a7."))
(defparameter *page*
  '(:public-page-verified "TESTFAKT: target reread matches the reviewed KI story and assets item of the release named in :release-reviewed."))
(defparameter *view*
  '(:public-view-verified "TESTFAKT: public page, ZIP and workspace offer verified for that release and catalog revision."))

(defun inputs (case)
  "Return EVIDENCE and COMPLETED for a direct PLAN-NEXT call."
  (multiple-value-bind (evidence completed)
      (ecase case
        (1 (values (list *ready* *assets*) '(:publish-assets)))
        (2 (values (list *ready*) nil))
        (:asset-marked-complete (values (list *ready*) '(:publish-assets)))
        (3 (values (list *conflict*) nil))
        (4 (values (list *ready* *assets* *page*) '(:publish-assets :publish-page)))
        (:verified (values (list *ready* *assets* *page* *view*)
                           '(:publish-assets :publish-page :verify-publication))))
    (values (append *local-evidence* evidence) (append *local-completed* completed))))

(defun run (case)
  "Return the two original PLAN-NEXT values: plan result and complete initial facts."
  (multiple-value-bind (evidence completed) (inputs case)
    (shop3-planning-domains/publication:plan-next
     evidence :completed completed :profile :shop3-planning-domains
     :source-origin "http://localhost:3000")))
