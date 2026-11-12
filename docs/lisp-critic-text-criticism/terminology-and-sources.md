# Terminology and sources

> **DRAFT — work-in-progress checkpoint, 12 November 2026.** Not reviewed.
>
> Complete: the list of sources read, with what was read in each. Outstanding:
> the vocabulary comparison across disciplines, the operational definitions, and
> the evaluation of the vocabulary proposed in earlier project discussion. No
> conclusion is drawn here yet.

## Sources read for this work

Each was retrieved on 12 November 2026. The digest is the SHA-256 of the
retrieved octets, first 16 hexadecimal digits. Quotations are from the retrieved
text; where it is OCR text, that is said.

| Source | Retrieved from | Digest | What was read |
|---|---|---|---|
| G. Fischer, "A Critic for LISP", IJCAI-87 | `https://www.ijcai.org/Proceedings/87-1/Papers/034.pdf` | `3076cf667632dce1` | whole paper, as OCR text of the PDF; page numbers not recovered |
| J. F. Ferrier, *Institutes of Metaphysic: The Theory of Knowing and Being*, Edinburgh and London: Blackwood, 1854 | `https://archive.org/download/institutesofmeta00ferruoft/institutesofmeta00ferruoft_djvu.txt` | `0ebc34089b59ea55` | Introduction §§ 54–61, as OCR text |
| Plato, *Theaetetus* 201c–d, tr. H. N. Fowler (Loeb, 1921); Greek ed. J. Burnet (OCT, 1903) | Perseus Digital Library, texts `1999.01.0172` and `1999.01.0171` | `262e5cf52c83b9e1`, `a17d190ac3012534` | section 201c only |
| M. Steup and R. Neta, "Epistemology", *Stanford Encyclopedia of Philosophy*, first published 14 Dec 2005, substantive revision 26 Oct 2024 | `https://plato.stanford.edu/entries/epistemology/` | `76dc24f8e44b9950` | opening section |
| W3C, *PROV-DM: The PROV Data Model*, Recommendation, 30 April 2013 | `https://www.w3.org/TR/prov-dm/` | `5c925c21bc96c285` | abstract; definitions of entity, activity, agent, derivation, attribution |
| B. Meyer, "Applying 'Design by Contract'" | `https://se.inf.ethz.ch/~meyer/publications/computer/contract.pdf` | `bc1bab86f8753e5e` | whole paper, as extracted text; the journal reference is not stated in the file and was not verified |
| Treccani, *Vocabolario*, s.v. "epistemologia", "gnoseologia" | `https://www.treccani.it/vocabolario/…` | `2d336eda2c287a00`, `91a2581629e31927` | the two entries |
| CNRTL / TLFi, "épistémologie", étymologie | `https://www.cnrtl.fr/etymologie/épistémologie` | not recorded | the etymological note |
| DWDS, "Erkenntnistheorie", "epistemisch" | `https://www.dwds.de/wb/…` | not recorded | definitions; the pages carry no etymological note |
| J. Heritage, "Epistemics in Action: Action Formation and Territories of Knowledge", *Research on Language and Social Interaction* 45(1), 2012, 1–29 | Crossref metadata for DOI `10.1080/08351813.2012.646684` | — | **bibliographic data only; the article was not read** |

## Not accessible or not read

Oxford English Dictionary (refused); Diccionario de la lengua española, RAE
(refused); Historisches Wörterbuch der Philosophie (not attempted beyond the
landing page); S. Toulmin, *The Uses of Argument* (1958); A. Aikhenvald,
*Evidentiality* (2004); Heritage 2012 (text); Fischer and Mastaglio 1991;
C. A. R. Hoare 1969; R. Seidl, iX 13/2026 (only the abstract on the article
page was read). Nothing is stated in these documents on the authority of a
source in this list.

## What the sources say (quotations)

**Plato, *Theaetetus* 201c–d (Fowler).** Theaetetus reports having heard someone
say "that knowledge was true opinion accompanied by reason". The Greek has
"μετὰ λόγου". This is the passage usually cited for knowledge as true belief
with an account; the dialogue goes on to examine it. Only this section was read.

**Ferrier 1854, Introduction § 55 (OCR).** "This section of the science is
properly termed the EPISTEMOLOGY — the doctrine or theory of knowing, just as
ontology is the doctrine or theory of being … It answers the general question,
'What is knowing and the known?' — or more shortly, 'What is knowledge?'"
§ 59 introduces a third section, "the agnoiology"; § 61: "1. Epistemology.
2. Agnoiology. 3. Ontology." That Ferrier *coined* the English word is stated by
Treccani ("termine coniato (1854) dal filosofo scozz. J. F. Ferrier"), a
dictionary; it was not checked against the OED. What was observed is the use in
1854, not priority.

**Stanford Encyclopedia (Steup and Neta).** "The term 'epistemology' comes from
the Greek words 'episteme' and 'logos'. 'Episteme' can be translated as
'knowledge' or 'understanding' or 'acquaintance', while 'logos' can be
translated as 'account' or 'argument' or 'reason'. … Although the term
'epistemology' is no more than a couple of centuries old, the field of
epistemology is at least as old as any in philosophy." The phrase "epistemic
status" does not occur in the entry as retrieved.

**CNRTL / TLFi.** *épistémologie*: "1906 « critique des sciences » (Nouv. Lar.
ill. Suppl.). Composé du gr. ἐπιστήμη « science » et de -logie"; "souvent
entendu dans le sens de Philosophie des sciences".

**Treccani.** *epistemologia*: from English *epistemology*; in nineteenth-century
philosophy "la parte della gnoseologia che più in particolare si occupava dei
metodi e dei fondamenti della conoscenza scientifica", now commonly a synonym of
philosophy of science. *gnoseologia*: "dal lat. mod. gnoseologia, termine
coniato dal filosofo ted. A. G. Baumgarten (1714-1762)".

**DWDS.** *Erkenntnistheorie*: "Gebiet der Philosophie, das sich mit den
Bedingungen für Erkenntnisse und Wissen befasst"; see also *Epistemologie*.
*epistemisch* is listed with *epistemologisch* and *erkenntnistheoretisch* as
related expressions (OpenThesaurus), without a definition of its own.

So, as far as these entries go: English *epistemology* and German
*Erkenntnistheorie* name the theory of knowledge, while French *épistémologie*
and Italian *epistemologia* lean towards the philosophy of science, with
*gnoseologia* for the general theory. This is a reading of four dictionary
entries, not a history of the words.

**W3C PROV-DM.** "Provenance is information about entities, activities, and
people involved in producing a piece of data or thing, which can be used to form
assessments about its quality, reliability or trustworthiness." An entity is "a
physical, digital, conceptual, or other kind of thing with some fixed aspects";
an activity "something that occurs over a period of time and acts upon or with
entities"; an agent "something that bears some form of responsibility for an
activity taking place, for the existence of an entity, or for another agent's
activity". "A derivation is a transformation of an entity into another, an
update of an entity resulting in a new one, or the construction of a new entity
based on a pre-existing entity." "Attribution is the ascribing of an entity to
an agent." Provenance, so defined, is something assessments *can be formed
from*; the model does not itself say that what an entity states is true or
justified.

**Meyer, "Applying Design by Contract".** Assertions are preconditions and
postconditions of individual routines and class invariants; "a missing
precondition clause is equivalent to the clause Require True". The paper names
"the research on program proving and systematic program construction pioneered
by Floyd, Hoare, and Dijkstra" as a source. In this sense a contract is a
checkable condition on a routine. The class `lisp-critic-contract` records a
description whose policy slots no code reads; it is not a contract in this
sense.

**Fischer 1987.** Abstract: the LISP-CRITIC "has knowledge about how to improve
LISP programs locally, following a style as defined by its rules. The advice
given is based on the hypothesized knowledge of the user contained in the
system's model of the user. Additional tools (e.g., a knowledge browser and
visualization support) are available to explain and illustrate the advice."
Section 4: suggestions "can make the code either more cognitively efficient
(e.g., more readable and concise) or more machine efficient (e.g., smaller and
faster)"; "the user can inspect the modifications and accept or deny them. On
demand, the system explains and justifies its suggestions"; "The user model …
obtains information from the rules that have fired, from the statistical
analyzer and from the knowledge structures that have been visited. In return,
it determines which rules should fire and what kind of explanations should be
generated"; KAESTLE is used "to illustrate the functioning and validity of
certain rules"; "The critic operates only on the code; the system does not have
any knowledge of specific application areas or algorithms". Acknowledgements:
Boecker "developed many of the original ideas, the set of rules and the
interpreter for it"; Lemke "contributed to the general framework for incremental
learning"; Nieper "developed KAESTLE"; Morel "implemented the explanation
capabilities"; Burns "implemented the statistical analysis package"; Cormack
"analyzed user programs with the statistical package". The OCR text has
recognition errors ("if'Tllrove" for "improve"); quotations are normalized.

Nothing in the paper, or in the engine source read for [rule-base.md](rule-base.md),
connects Fischer's system with Riesbeck's.

## Outstanding

- The comparison of epistemology, conversation analysis (status and stance),
  linguistics (evidentiality), argumentation (claim, grounds, warrant) and
  provenance — only the first and last have a source read above.
- Operational definitions for `observed`, `derived`, `inferred`, `hypothesized`,
  and the question whether "epistemic status" should name them.
- The examination of the vocabulary proposed in earlier project discussion.
