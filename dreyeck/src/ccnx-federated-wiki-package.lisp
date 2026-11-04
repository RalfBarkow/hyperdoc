;;;; Package for the reading "The CCNx Federated Wiki and the Power of Plain Text".

(defpackage #:dreyeck/ccnx-federated-wiki
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:hv #:html-inspector-views))
  (:export #:example-page #:example-site-root #:example-slug #:+example-kinds+
           ;; The reading typography: objects that let a page lead to a finding, and a finding to its change.
           #:reading-task #:text-unit #:legibility-case #:typography-finding #:presentation-variant
           #:typography-model #:reading-tasks #:text-units #:legibility-cases #:typography-findings #:typography-finding-named
           #:presentation-variants #:reset-typography-model
           #:reading-task-id-of #:reading-task-name-of #:reading-task-supports-of #:reading-task-basis-of
           #:text-unit-id-of #:text-unit-page-of #:text-unit-element-of #:text-unit-text-of #:text-unit-kind-of #:text-unit-page-title-of
           #:legibility-case-id-of #:legibility-case-unit-of #:legibility-case-string-of #:legibility-case-conditions-of
           #:legibility-case-status-of #:legibility-case-observation-of #:legibility-case-findings-of
           #:typography-finding-id-of #:typography-finding-unit-of #:typography-finding-task-of #:typography-finding-problem-of
           #:typography-finding-status-of #:typography-finding-observation-of #:typography-finding-proposal-of
           #:typography-finding-rationale-of #:typography-finding-variants-of #:typography-finding-cases-of
           #:presentation-variant-id-of #:presentation-variant-finding-of #:presentation-variant-change-of
           #:presentation-variant-css-label-of #:presentation-variant-before-of #:presentation-variant-after-of
           #:presentation-variant-check-of))
