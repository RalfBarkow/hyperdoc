;;;; Minimal REPL session for the McDermott 2000 page-attached ASDF artifact.

(require :asdf)
(asdf:load-system "the-1998-ai-planning-systems-competition")

(in-package #:the-1998-ai-planning-systems-competition)

(inspect-artifact)

(schema-status)

(materialize-reading-artifact)

(validate-reconstruction-idempotence)

(ensure-inspector-views)

(asdf:test-system "the-1998-ai-planning-systems-competition/test")
