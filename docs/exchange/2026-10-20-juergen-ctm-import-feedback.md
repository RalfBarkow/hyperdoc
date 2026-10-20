# Juergen's feedback on importing the project CTM

A record of an external report. It is not a source of the project CTM, and it states nothing that this repository has checked. The review of
it is `docs/project-ctm-exchange-review.md`.

## Provenance

- **Author:** Juergen. The message below is his, quoted verbatim as the user supplied it.
- **Date:** the date of Juergen's own message is not known here. The user supplied the text in a Claude Code session on 2026-10-20; that
  is the date of the relay, not of the message.
- **What it reports:** Juergen imported the project CTM into his own CTM editor. The import and what he saw there are his observations,
  not observed in this repository.
- **The remarks.** His message gives five remarks on the model under the heading "Claudes Anmerkungen zum Modell", Claude's remarks on the
  model. As he presents them, they come from a Claude he worked with, and he relays them. Nothing more about their origin is known here.
- **The image** his message refers to ("siehe unten", "Im Bild sind nicht alle Topics aufgedeckt") was supplied by the user in the same
  session on 2026-10-20. It is not stored in this repository.
- **Not received:** the TMCL schema he offers to send: 17 Topic types, 30 Association types, *plays-role*, *has-occurrence*, *may-reify*.
  It is not in this repository and has not been read or validated.

## What the image shows

This is Claude Code's reading of the image, not Juergen's words. As his message says, the view shows a part of the Topics, not all of them.

**Topics shown as labelled signs:**
- the pages *Work Breakdown*, *Implementation Assignments*, *CTM Plan Page WBS Dictionary*, *HyperDoc Project Workspace* and *Authoring the
  CTM Plan Page*;
- the HyperBook *Working on HyperDoc*;
- *Connections example* and *HyperDoc dogfooding*;
- the proposed Deliverable *Exchangeable CTM of HyperDoc's declared project work*;
- the proposed work package *A record of acceptance, distinct from work status*;
- the assignments *Claude Code: Read the complete project CTM in practical time* and *Claude Code: Project Work as an Exchangeable CTM
  Topic Map*;
- the two Relation Contract Topics *depends on* and *decomposes into*.

**Edges,** labelled with Association type names: *declared on*, *contains page*, *proposed on*, *carried by*, *decomposes into*, *reads
source*, *changes source* and *current-work*.

**Contract Topics as content.** *depends on* and *decomposes into* appear as Topics of their own, connected to *Authoring the CTM Plan Page*
by *carried by* and *declared on*. This fits his third remark: a Relation Contract is content and, elsewhere, an Association type.

## Juergen's message

> Der Import hat ok-isch funktioniert. (siehe unten)  :-).  Im Bild sind nicht alle Topics aufgedeckt.  Ich habe die Datei als eigenen
> Korpus in meinen CTM-Editor übernommen: deinen Schema-Abschnitt unverändert als Vokabular, Topics und Assoziationen als Inhalt. Dass
> jedes Topic einen Subject Identifier hat, hilft sehr. Neue Versionen von dir kann ich einspielen, ohne dass die Topics bei mir ihre
> Identität verlieren.
>
> Claudes Anmerkungen zum Modell
>
> Gleiche Namen für verschiedene Topics: „work item“, „work package“, „plan step“ und „precondition“ heißen sowohl die Topic-Typen
> (s:kind-…) als auch die Rollentypen (s:work-item usw.). In Auswahllisten sind sie nur über den Identifier zu unterscheiden. Eigene Namen
> für die Rollen, etwa „work item (role)“, würden helfen.
>
> Rollentypen je Relation: Jede der 16 reifizierten Relationen hat ein eigenes Rollenpaar („source of informs“ / „target of informs“ …),
> zusammen also 32 Rollentypen. Zwei allgemeine Rollen „source“ und „target“ würden reichen; was sie bedeuten, ergibt sich aus dem
> Assoziationstyp bzw. dem Relation Contract.
>
> Relationswörter in zwei Formen: 12 Relationen sind s:relation-word-* im Schema-Abschnitt, 4 weitere sind w:work:relation/* im Inhalt
> (isa s:kind-relation, mit Status und eigener Seite). Ist diese Trennung gewollt? Dass ein Topic zugleich Inhalt und Assoziationstyp ist,
> ist zulässiges CTM, und mein Editor kommt damit zurecht. Es ist aber ungewöhnlich.
>
> Kein Schema: Die Typen haben weder isa tmcl:topic-type noch TMCL-Regeln. Ich habe aus der tatsächlichen Nutzung ein großzügiges
> TMCL-Schema abgeleitet: 17 Topic-Typen, 30 Assoziationstypen, plays-role, has-occurrence, may-reify. Wenn es dich interessiert, schicke
> ich es dir.
>
> Datentypen: Alle Vorkommen sind Strings, auch issued (ein Datum) und source-sha256. Mit xsd:date bzw. einem eigenen Datentyp ließen sie
> sich prüfen.
>
> Aber schon ganz cool!
>
> Viele Grüße
> Juergen
