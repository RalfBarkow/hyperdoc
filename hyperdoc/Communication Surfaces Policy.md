# Communication Surfaces Policy

<in-package>hyperdoc</in-package>

This policy defines how HyperDoc pages and localhost FedWiki pages are
used together as connected communication surfaces.

## Purpose

Use two surfaces for one collaboration:

 - HyperDoc pages are the durable, inspectable reference surface.
 - localhost FedWiki pages are the fast, journaled working surface.

The goal is navigable connection per topic, not identical content.

## Localhost FedWiki location

For this setup, the localhost FedWiki page store is:

`/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages`

## Decision rule

 - If content is changing quickly, use FedWiki first.
 - If content stabilizes and should guide implementation, ensure a HyperDoc page exists.
 - If both exist, keep title/slug mapping and links aligned.

## What "content stabilizes" means

Stabilized does not mean finalized forever. It means stable enough to
serve as implementation guidance without changing every day.

Use these checks:

 - repeated examples produce the same expected behavior,
 - failure modes are known and described,
 - ownership boundaries are explicit (who owns concept, host, and docs),
 - naming and links are stable enough to reference from other pages.

This is directly related to
<a hyperbook="hyperdoc" page="Where This Functionality Belongs">Where This Functionality Belongs</a>:
before moving guidance into durable docs, verify with examples that the
functionality works, then verify that it is located in the subsystem
that owns the concept.

## Synchronization rule

 - Keep conceptual alignment, not markup identity.
 - Do not overwrite existing FedWiki pages automatically.
 - Prefer additive updates and counterpart creation for missing topics.

## Assistant role

Robot assistants participate in this interaction system by helping maintain:

 - topic counterpart coverage,
 - cross-links between surfaces,
 - extraction of stable material from working pages into reference pages.

## Recorded feedback

Konrad's feedback on how to handle focused communication pages is
documented in
<a page="Konrad Feedback on Communication Pages">Konrad Feedback on Communication Pages</a>.
The daily localhost FedWiki thread for today is
<a hyperbook="fedwiki:wiki.ralfbarkow.ch" page="2026-03-05">2026-03-05</a>.
Operational findings for today's localhost wiki bring-up are documented in
<a page="Localhost Wiki Bring-up Findings 2026-03-05">Localhost Wiki Bring-up Findings 2026-03-05</a>.
The identity question behind "everything in Git?" is documented in
<a page="Everything in Git Identity Across Systems">Everything in Git Identity Across Systems</a>.
