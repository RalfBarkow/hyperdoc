# Reading typography of the CCNx Federated Wiki pages

How the four pages of the HyperBook `dreyeck/ccnx-federated-wiki` are read in the HyperDoc Inspector, what was found that made them hard to
read, what was changed, and the objects that let one go from a page to a finding and from the finding to the change. It does not
re-examine the CCNx source review; no historical statement, source revision or provenance claim of the pages was changed.

## 1. Theory, and what was and was not available

The brief names two levels of theory and two sources. They are kept apart here, and their status is stated first because it limits what this
document may claim.

| Source | Status in this work |
|---|---|
| Willberg, Hans Peter (1997): "Hinweise zu Schrift und Typographie in Büchern", Leseforum Schweiz, Bulletin 6, p. 26 ff. | **Not read.** `https://www.leseforum.ch/myUploadData/files/06_Bulletin_1997.pdf` answers HTTP 404 (checked with `curl` and with a second fetch tool). The Leseforum's own bulletin page links the file on another host, `leseforum.dev`; that host is outside this session's network allow-list (the proxy answered 502 to CONNECT; not retried). The sections "Der Buchstabe und das Wort", "Laufweite" and "Wort- und Zeilenabstand" were therefore not read. |
| Willberg / Forssman: *Lesetypografie*, Verlag Hermann Schmidt | **Not read.** Only the publisher's product page (`typografie.de/produkt/lesetypografie/`) was read. The one statement of the authors' position that it gives, and the only one used: typography is "in allererster Linie eine Dienstleistung. Am Text. Und am Leser", it is "Handwerk" and "für die Leserinnen und Leser da, nicht für die Gestalter:innen". The chapter "Lesearten" and the chapters on structure, emphasis, setting and tables were not read. |

Consequences, which are binding on the rest of this document and on the objects:

* **Nothing here is attributed to Willberg or Forssman** except the publisher's quotation above. The grounds given for each change are labelled
  *design hypothesis of this reading* (the model refuses to carry the name "Willberg" in a finding's grounds; a test checks it).
* The two levels are kept apart in the model, not filled in from memory:
  * *Schablonen-Theorie*: Willberg's explanation, as the brief states it, of how impressed letter forms and familiar word images are recognised, in
    his 1997 text mainly about children and beginning readers. Its transfer to adult readers of technical hypertext is a **design hypothesis
    that needs a reason, not an established fact**. The mental "template" of a reader is **not modelled**: it is not something a browser can show,
    and no object stands for it. What is modelled are *legibility cases*: a concrete string, the conditions under which it can be confused, and
    what a browser showed.
  * *Lesearten*: the basis for different design tasks. The five **reading tasks** below are this reading's own vocabulary; their `basis` slot says so
    and says that their correspondence to the Lesearten of the book has not been checked. Someone holding the book can fill that slot in without
    changing the structure.
* Not done and left open: summarising the three named sections of the 1997 article, and the Lesearten chapter. If the PDF or the book is supplied, the
  grounds of the findings in section 4 should be checked against it and either attributed (with page) or left as design hypotheses.

## 2. Method and what was observed with

* The four pages were read as HTML source and through the existing Inspector views (Content, Source, Parse tree).
* They were then opened in a real Chromium in the Catalog (`dreyeck/ccnx-federated-wiki/browser-check/serve.lisp`, loopback, no site written) at a
  **wide** desktop (viewport 1500 px, pane 700 px, body 698 px) and a **narrow** one (viewport 520 px, pane 479 px, body 477 px).
* Chromium 153.0.8010.12, headless, Linux. **Fonts are those of this machine.** The Inspector's body face is `'Noto Sans', Tahoma, Verdana, Arial`; Noto Sans
  and Tahoma were not installed, so the browser used Liberation Sans, and "monospace" resolved to DejaVu Sans Mono. Observations about letter shapes hold for
  that font set and say nothing about a Mac.
* Each finding says whether it was **browser-observed** (a measurement or a visible state in `evidence/typography/before-*`) or only **conjectured**.

## 3. The model

Existing objects are reused. The pages are `html-page` objects, their parse trees are plump DOM trees, and the views are Inspector views.

| Object | What it is | Reuses |
|---|---|---|
| `reading-task` | what a reader does with a passage: continuous reading, orienting, following a process, comparing, looking up. Five instances; the `basis` slot says they are this reading's vocabulary. | nothing; plain data |
| `text-unit` | a place in a page: page title, element id, kind. **It stores no text.** The page object, the element and its text are read from the page when asked, so there is no second copy of the page. | the `html-page` object and its DOM (`plump:get-element-by-id`) |
| `legibility-case` | a string, the conditions under which it is confusable or hard to take in, a status (`:browser-observed` or `:conjectured`), and the observation. | a `text-unit` |
| `typography-finding` | a text unit, the reading task it concerns, the observed problem, its status, the observation, the proposed change, the grounds (design hypothesis). | `text-unit`, `reading-task` |
| `presentation-variant` | the change: description, the label of the CSS block (and any page edit) that realises it, before and after evidence, the check. | the style sheet |

Relations, all as object references that the Inspector follows:

```
html-page --"Typography" view--> typography-finding --> text-unit --> html-page, DOM element, its text now
                                      |   |  \--> reading-task --> typography-finding ...
                                      |   \-----> legibility-case --> typography-finding ...
                                      \---------> presentation-variant --> typography-finding
```

In the Inspector: open any of the four pages; it opens on **Content**, the reading. Its **Typography** tab (an additional, analytical view) lists the findings of that page; a finding's view leads to its text unit (and from
there to the page, the element and the text as it is now), its reading task, its legibility cases and its presentation variants.
The code is `dreyeck/src/ccnx-typography.lisp` (objects and data) and `dreyeck/src/ccnx-typography-views.lisp` (views). The data are Lisp lists; the objects are
built from them on first use and rebuilt with `(dreyeck/ccnx-federated-wiki:reset-typography-model)`.

**Content comes first.** Views are ordered by ascending priority and Content has priority 1; the Typography view has priority 20 (`+typography-view-priority+`), so it sits after the core views of a page (Content, Source, Links, Parse tree, Backlinks) and a page never opens on it. A first version gave it priority 1 as well, which made the page open on Typography; that is the fault this note records. The reading has precedence over its analysis, as a rule for HyperDoc pages of this kind.

No second layout framework and no second story-item editor: the style sheet is one file, scoped to the pages (section 5), and nothing is stored about a page that
the page does not already hold, except the ids added to some elements so that a text unit can name them.

## 4. Findings, per page, with the reading task they concern

"Before" is `origin/dreyeck.ch` at `479bdd21`; numbers are from `evidence/typography/before-metrics.json`; screenshots in `evidence/typography/before/`.

| Finding | Page | Reading task | Status | Observation (before) | Change |
|---|---|---|---|---|---|
| F-MEASURE | Plain Text After CCNx | continuous | observed | 80 characters per line in the longest paragraph at 700 px (53 to 64 elsewhere) | running text at most 38 em |
| F-LEADING | Identity, Versions and Signatures | continuous | observed | line height `normal` (about 1.15) in nine-line paragraphs with inline code | line height 1.5 |
| F-HIERARCHY | Reading the CCNx Federated Wiki | orienting | observed | h1, h2, h3 at 20.8, 19.2, 17.6 px | h1 1.55 em, h2 1.28 em with a rule above, h3 1.05 em (it differs from running text by weight and space; its size step is small) |
| F-IDENTIFIERS | One Page From Browser to NDN and Back | looking up | observed | code in generic monospace at 13 px beside 16 px text; in the body face I, l and 1 were not clearly different (specimen) | a monospace stack preferring faces with distinct I, l, 1, 0 (`ui-monospace`, SF Mono, Menlo, Consolas, DejaVu Sans Mono) at 0.9 em with a light background |
| F-BREAKS | Reading the CCNx Federated Wiki | looking up | observed | identifiers split at hyphens and slashes: `docs/ccnx-federated-wiki/SOURCE-REPORT.md`, `ccnx-example.invalid`, `how-to-wiki` at 700 px, more at 479 px | inline code does not wrap unless long (over 28 characters) or holding spaces; `<wbr/>` after slashes in table cells |
| F-SOURCE-REFERENCES | One Page From Browser to NDN and Back | looking up | observed | "pageHandler.coffee L22–L78" broken after the dash | source links do not wrap and are set in the identifier face |
| F-STEPS | One Page From Browser to NDN and Back | following a process | observed | the eight steps were a 2046 px wide table in a 698 px body; the pane scrolled to 2051 px; on the identity page 2474 px | a numbered list; source lines on their own line |
| F-TABLES | Identity, Versions and Signatures | comparing | observed | all ten tables wider than the body (797 to 2474 px), no wrapping, headers in light grey | the real comparisons keep their columns, wrap, have dark headers; each in a box that scrolls on its own |
| F-FIELD-LISTS | One Page From Browser to NDN and Back | looking up | observed | two aligned `<pre>` blocks ran past the pane (a 64-character digest in one line) | `<dl>` field lists, nested ones stacked, values wrap |
| F-EVIDENCE | Reading the CCNx Federated Wiki | orienting | observed | the kinds of statement were marked three ways and one ("Derived, not run") was not defined where the kinds are listed | one label per kind (words plus outline style, so it does not depend on colour); defined on the main page |
| F-REFERENCES | Reading the CCNx Federated Wiki | orienting | **conjectured** | Inspector references were underlined but black, like running text; whether readers miss them was not observed | dark blue thin underline; external links unchanged |

Legibility cases: `L-IL1` (item ids `a1b2c3d4e5f60001`; observed in the specimen), `L-ZEROS` (`1700000000004`, ten zeros; **conjectured**, a dotted or slashed zero
helps against O but does not make counting easier), `L-BREAK-HYPHEN` (observed), `L-DIGEST` (the 64-character digest; observed).

Which tables are real comparisons: *The name* (Main / Prototype), *In one table*, *Semantic compatibility*, *Preserved and lost provenance*, *Historical and present side by side*,
*The Power Of Plain Text* (claim / finding) and *The added fields* (field, value, origin) were kept as tables. *The sources* is a lookup list of three
rows and was kept as a table. The two that were **sequences, not comparisons** (the eight steps; the four numbered statements in "Signatures: checked") became numbered lists.

## 5. What was changed

* **Four pages**: a wrapper `<div class="ccnx-reading">` (the style sheet is scoped to it); the two sequences as `ol.steps`; the two `<pre>` blocks as `dl.fields`;
  each table in `div.table-scroll`; the evidence marks as `span.ev ev-<kind>`; `code.wrap` on long inline code and `<wbr/>` in a few table-cell paths; ids on some elements.
  The visible text was compared word by word with the old pages; the differences are the intended ones (labels, the step numbers and "Lines:" in the lists, section 6).
* **One style sheet**: `dreyeck/ccnx-federated-wiki/assets/ccnx-reading/css/reading.css`. Every rule is under `.ccnx-reading` and names its finding in a comment.
  It reaches only these pages: `dreyeck/src/ccnx-federated-wiki-hyperdoc.lisp` gives this book's pages their own `html-page-assets` (a test shows the generic HyperDoc
  assets do not contain it). The Inspector's own CSS is not touched.
* **One shared fix**: `hyperbook-explorer/rendering.lisp`, `collect-assets`, followed only one step of the `inherit` chain. A book's own assets (which inherit the
  HyperDoc assets, which inherit the HyperBook assets) would have lost the HyperBook level, and with it the page and expression tags. It now follows the chain; the results for the
  existing chains are unchanged.

## 6. Editorial changes (the redaktionelle Inkonsistenz)

* The main page's list of kinds of statement is now "Four kinds of statement" and defines **Derived, not run**: "It follows from implemented statements by reasoning, or by applying the cited
  rules to the example. It is not an observation: nothing was run." The seven short answers use the same labels instead of italic parentheses.
* The answer to question 5, before: "Every object is signed with that one key. The verification code does run, but for a key carried in the object it raises “verified” whatever the result.
  Signatures are not stored. *(Implemented, by the source; not run.)*"
  After: "Every object is signed with that one key. The source calls the verification code, but for a key carried in the object it reports “verified” whatever the verdict. Signatures are not stored.
  `IMPLEMENTED` in the source; see Identity, Versions and Signatures, “Signatures: checked”."
  The statement is the one of the identity page (NDN.js L492–L500: the code verifies, computes a verdict, and reports "verified content" whatever it was). Two things were removed:
  "does run", which could be read as the reading having run the code, and "not run" inside the label, which mixed two kinds of statement (the whole reading is not a run, and says so at the top).
* Question 6's tag "(Implemented; extraction not tried.)" is now `IMPLEMENTED` for the source (which has no export call) and a sentence that taking pages out of a browser profile was not tried.
* On the identity page "What follows (derived from 1–3, not run)" is `DERIVED, NOT RUN` **What follows** (from 1–3).

## 7. Before and after

Same script, same browser, same widths (`evidence/typography/before-metrics.json`, `after-metrics.json`; screenshots in `before/` and `after/`; the specimen in
`before-specimen.png` and `after-specimen.png`). The 91 assertions of the first run: 63 fail before, none after. Nine more were added afterwards (CONTENT-FIRST for eight page/width pairs, TYPOGRAPHY-NAVIGATION); `after-metrics.json` holds the 100 assertions run on the corrected state, none failing, and `content-first-counterproof-metrics.json` the same script run on the state with the Typography view at priority 1: CONTENT-FIRST fails for all eight pairs ("the page opened on Typography") and the navigation fails too. Each describes a property and the reading task it protects.

| Property (assertion) | Reading task | Before | After |
|---|---|---|---|
| NO-SIDEWAYS-SCROLL: the pane body does not scroll sideways | all | scrollWidth 1649, 2051, 2479, 1707 in a 698 px body (same at 477 px) | equals the body width on all pages, both widths |
| TABLES-CONTAINED: a table does not escape the body unless a box of its own scrolls it | comparing | 1, 2, 3, 4 tables escaped on the four pages | none |
| NO-PRE: no aligned `<pre>` | looking up | 2 on the pipeline page | none |
| NO-SPLIT-IDENTIFIER / NO-SPLIT-REFERENCE | looking up | identifiers split: 2, 0, 0, 1 (wide); source links split: 0, 1, 2, 0 (wide), up to 4 (narrow) | none |
| MEASURE-LIMIT: running text at most 38 em | continuous | the container's 43 em | 38 em |
| IDENTIFIER-SIZE: inline code at least 85 % of body size | looking up | 81 % | at least 85 % |
| HEADING-STEPS: h1 > h2 > h3 > body, steps of at least 2 px | orienting | 20.8 / 19.2 / 17.6 px | 24.8 / 20.5 / 16.8 px |
| EVIDENCE-LABELS: every label is one of the four kinds | orienting | no labels | all four, defined on the main page |
| REFERENCES-VISIBLE: references are underlined and not the colour of the text | orienting | same colour as text | underlined, dark blue |
| LINKS-OPEN-TARGETS: every followed `<a page>` and `<a expr>` opens its target | all | opens | opens (not changed; regression) |
| CONTENT-FIRST: Content is the first and the active view of every page when it opens, with no user action; Typography is another view | continuous | (no Typography view) | Content first and active; tabs: Content, Source, Links, Parse tree, Backlinks, Typography, URL, ... |
| TYPOGRAPHY-NAVIGATION: Typography tab -> finding -> presentation variant -> finding -> text unit, by following references | orienting | (none) | each step opens its object |

The existing navigation check (`browser-check/check.mjs`) passes unchanged. A change is not an improvement because a screenshot differs; each row above names the property that was
failing and the reading task it was failing for. **Not tested:** whether any reader reads faster or more accurately. The grounds in the findings are design hypotheses.

## 8. Tests

* `dreyeck/ccnx-federated-wiki/tests` (part of `dreyeck/catalog`): structure (wrapper, no `<pre>`, every table boxed, ids unique, style-sheet selectors scoped), every kind of statement used is defined on the
  main page, every text unit resolves in its page, every finding has a variant tied to a block of the style sheet, the Typography view and the finding views reach the objects, Content is the first view of every page and Typography comes after it (counter-proof: priority 1 fails it), the
  grounds never carry the name Willberg, and the style sheet belongs to this book only. Counter-proofs run: removing the "Derived, not run" definition, and removing an element id, each fail the test.
* `dreyeck/ccnx-federated-wiki/browser-check/typography-check.mjs ORIGIN OUT LABEL [--measure-only]`: the assertions of section 7 and the navigation; `typography-specimen.mjs` the specimen.
  Run against the state before the change it fails 63 assertions, after it none; run against the priority-1 mistake it fails CONTENT-FIRST.

```sh
sbcl --load dreyeck/ccnx-federated-wiki/browser-check/serve.lisp          # a loopback Catalog with the reading, in nix develop
node dreyeck/ccnx-federated-wiki/browser-check/typography-check.mjs http://127.0.0.1:48851 /tmp/out after
```

## 9. Limits

One browser (Chromium 153, Linux) and its fonts; nothing was measured on macOS, in Safari or Firefox. No reader was observed. The 38 em and 1.5 line height are design choices, not
results. The primary literature was not read (section 1). A maximised pane was not observed, so the effect of F-MEASURE there is supposed. The Inspector's table style is overridden
for these pages; other HyperBooks are unchanged.
