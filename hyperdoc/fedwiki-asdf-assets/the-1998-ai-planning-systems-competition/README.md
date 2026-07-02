# The 1998 AI Planning Systems Competition

This is a FedWiki-attached ASDF reading artifact for Drew V. McDermott,
"The 1998 AI Planning Systems Competition," AI Magazine 21(2), 2000.

The authoritative local basis is:

`assets/the-1998-ai-planning-systems-competition.dmx.sqlite`

The FedWiki page JSON is a projection from that database:

`pages/the-1998-ai-planning-systems-competition.json`

The artifact stores bibliography, source anchors, short excerpts, topic
summaries, associations, and the reconstruction story. It does not copy the
paper.

## REPL

```lisp
(asdf:load-system "the-1998-ai-planning-systems-competition")

(in-package #:the-1998-ai-planning-systems-competition)

(inspect-artifact)
(schema-status)
(materialize-reading-artifact)
(validate-reconstruction-idempotence)
(asdf:test-system "the-1998-ai-planning-systems-competition/test")
```

The smoke tests are local-first and do not require a live DMX server, a live
FedWiki server, or network access.
