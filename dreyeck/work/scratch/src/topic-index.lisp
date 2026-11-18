(defpackage #:hyperdoc-scratch
  (:use #:cl)
  (:export #:*hyperdoc* #:*topics* #:*sources* #:*relations*
           #:find-topic #:sources-for-topic #:topic-map-pathname))

(in-package #:hyperdoc-scratch)

(defparameter *topics*
  '(
    (:id :solo :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/solo"
     :title "Solo" :bereich "Solo, Trails und Graphviz"
     :beschreibung "FedWiki-Plugin, in dem Ward und andere Trails zeichnen und Graphen anzeigen."
     :bezug :explizit :quellen (:m01 :m02 :solo))
    (:id :trail :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/trail"
     :title "Trail" :bereich "Solo, Trails und Graphviz"
     :beschreibung "Gezeichneter Verlauf über Graphknoten. In der Abbildung verläuft die rote Kurve von Ecology über Role in Richtung Result."
     :bezug :explizit :quellen (:m01 :image :solo))
    (:id :typed-nodes :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/typed-nodes"
     :title "Typisierte Knoten" :bereich "Solo, Trails und Graphviz"
     :beschreibung "Gleich beschriftete Platzhalter werden durch Typnamen unterschieden. Die Abbildung zeigt unter anderem Ecology, Role, Person und Result mit einem Fragezeichen."
     :bezug :explizit :quellen (:m01 :image :solo))
    (:id :graph-schema :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/graph-schema"
     :title "Graphschema im Gebrauch" :bereich "Solo, Trails und Graphviz"
     :beschreibung "Ward liest Marcs Beispiel als Schema. Beziehungen und Knotentypen stehen bereits fest genug, um einen Trail zu skizzieren, während die Knoten im Gebrauch weiter konkretisiert werden können."
     :bezug :explizit :quellen (:m01 :image))
    (:id :graphviz-layout :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/graphviz-layout"
     :title "Graphviz und Layoutstabilität" :bereich "Solo, Trails und Graphviz"
     :beschreibung "Wie lässt sich ein Trail sichtbar machen, ohne die Knotenanordnung des bestehenden Graphen zu verschieben? Das Replay in Zettel 11727 prüft den früheren Layoutfall."
     :bezug :explizit :quellen (:m02 :image :trails :solo))
    (:id :solo-release :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/solo-release"
     :title "Solo 0.1.32-4" :bereich "Solo, Trails und Graphviz"
     :beschreibung "Ward ordnet die Korrektur für typisierte Knoten und die Layoutverbesserung derselben Version zu. Der Versionscommit und der Stand des Dialogs sind verlinkt."
     :bezug :explizit :quellen (:m02 :release :solo))
    (:id :kapow :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/kapow"
     :title "KAPOW" :bereich "Wikimedia, Bot-Erkennung und Öffentlichkeit"
     :beschreibung "Wikimedias System zur Klassifikation automatisierter und menschlicher Zugriffe."
     :bezug :explizit :quellen (:m03 :m04 :wikitech))
    (:id :pageviews :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/pageviews"
     :title "Pageviews als klassifizierte Messgrösse" :bereich "Wikimedia, Bot-Erkennung und Öffentlichkeit"
     :beschreibung "Die Bot-Klassifikation beeinflusst, welche Zugriffe in die Seitenaufrufstatistik eingehen."
     :bezug :explizit :quellen (:m03 :wikitech))
    (:id :visibility :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/visibility"
     :title "Sichtbarkeit von Infrastrukturdetails" :bereich "Wikimedia, Bot-Erkennung und Öffentlichkeit"
     :beschreibung "Ward hebt die Grenze zwischen öffentlicher Beschreibung und eingeschränkter Einsicht in Code, Detaildokumentation und Ausgabedaten hervor."
     :bezug :explizit :quellen (:m04 :wikitech))
    (:id :heterogeneous-hardware :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/heterogeneous-hardware"
     :title "Heterogene Hardware und Codegenerierung" :bereich "Mojo, Lisp und heterogene Hardware"
     :beschreibung "Lattners Keynote behandelt eine gemeinsame Systemsprache für unterschiedliche Prozessoren und Beschleuniger."
     :bezug :explizit :quellen (:m05 :m06 :m10 :splash))
    (:id :mojo :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/mojo"
     :title "Mojo" :bereich "Mojo, Lisp und heterogene Hardware"
     :beschreibung "Das SPLASH-Abstract nennt parametrisierte Metaprogrammierung und ein Ownership-Modell auf Grundlage von Origins."
     :bezug :explizit :quellen (:m06 :m08 :m12 :splash))
    (:id :application-accelerators :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/application-accelerators"
     :title "Application Accelerators" :bereich "Mojo, Lisp und heterogene Hardware"
     :beschreibung "Ward bringt die FedWiki-Seite unmittelbar nach der Keynote-Diskussion ein. Die konkrete Beziehung zu Mojo bleibt offen."
     :bezug :explizit :quellen (:m11))
    (:id :lisp-hardware-economics :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/lisp-hardware-economics"
     :title "Lisp, Hardware und wirtschaftliche Anreize" :bereich "Mojo, Lisp und heterogene Hardware"
     :beschreibung "Wards rückblickende Vermutung über eine frühere Gelegenheit, samt möglichen technischen und ökonomischen Bedingungen."
     :bezug :zugeschriebene-these :quellen (:m07))
    (:id :swift :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/swift"
     :title "Swift und Erfahrungen aus dem Sprachstart" :bereich "Mojo, Lisp und heterogene Hardware"
     :beschreibung "Ward verweist auf Swift im Keynote-Q&A und im zweiten, separaten Interview."
     :bezug :explizit :quellen (:m09 :m12))
    (:id :language-innovation :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/language-innovation"
     :title "Sprachinnovation und Programmverständnis" :bereich "Sprachinnovation, Softwarearbeit und Personen"
     :beschreibung "Der von Ward markierte Interviewausschnitt um Minute 55 dient als Einstieg zur Frage, wie Sprachen das Sprechen über Programme verändern."
     :bezug :explizit :quellen (:m13))
    (:id :ai-and-software-work :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/ai-and-software-work"
     :title "KI-Agenten, Vibe Coding und Softwarearbeit" :bereich "Sprachinnovation, Softwarearbeit und Personen"
     :beschreibung "Zur Interviewankündigung gehören die Auswahl dessen, was sich zu bauen lohnt, und der Druck auf Open-Source-Maintainer."
     :bezug :explizit :quellen (:m12))
    (:id :lattner :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/lattner"
     :title "Chris Lattner" :bereich "Sprachinnovation, Softwarearbeit und Personen"
     :beschreibung "Keynote-Sprecher und Interviewgast. Wards Vergleich nennt Lattner neben Bostock."
     :bezug :explizit :quellen (:m05 :m06 :m09 :m12 :m14 :lattner :splash))
    (:id :bostock :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/bostock"
     :title "Mike Bostock" :bereich "Sprachinnovation, Softwarearbeit und Personen"
     :beschreibung "Ward nennt Bostock als zweite Person neben Lattner. Die Verbindung zu Solo über D3 ist als eigene Ableitung erfasst."
     :bezug :explizit :quellen (:m14 :bostock))
    (:id :d3 :subject-identifier "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/topic/d3"
     :title "D3 und die Trail-Kurve" :bereich "Sprachinnovation, Softwarearbeit und Personen"
     :beschreibung "Mögliche Verbindung von Bostock zu Solo. Solo erzeugt die rote Kurve mit D3, dessen Urheber Bostock ist."
     :bezug :abgeleitet :quellen (:solo :d3))
    ))

(defparameter *sources*
  '(
    (:id :m01 :title "Ein Trail durch Marcs Solo-Beispiel"
     :notiz "Beim Zeichnen eines Trails im Call scheiterte die Zuordnung bei verschieden typisierten Knoten. In Marcs Beispiel unterscheiden sich die Platzhalter durch ihre Typen. Ward beschreibt den Graphen als Schema, das sich im Gebrauch weiter ausarbeiten lässt."
     :anzeigezeit "2026-11-16 · 23:50" :autor "Ward")
    (:id :m02 :title "Solo 0.1.32-4"
     :notiz "Ward meldet, dass typisierte Knoten im Trail und das stabilere Layout gemeinsam ausgeliefert wurden und der Quellcode auf GitHub steht."
     :anzeigezeit "2026-11-16 · 23:56" :autor "Ward")
    (:id :m03 :title "KAPOW und Pageviews"
     :notiz "Ward verweist auf Wikimedias Bot-Erkennung. Die Einordnung von Zugriffen als automatisiert oder menschlich wirkt sich auf die Seitenaufrufstatistik aus."
     :anzeigezeit "2026-11-17 · 17:09" :autor "Ward"
     :url "https://wikitech.wikimedia.org/wiki/KAPOW_(bot_detection_system)")
    (:id :m04 :title "Öffentliche Beschreibung, interne Details"
     :notiz "Ward hebt hervor, dass Wikimedia aus Gründen des Infrastrukturschutzes Code, Detaildokumentation und Ausgabedaten von KAPOW intern hält. Für Phabricator-Tickets gilt eine fallweise Sichtbarkeit."
     :anzeigezeit "2026-11-17 · 17:11" :autor "Ward")
    (:id :m05 :title "Codegenerierung für CPUs und Beschleuniger"
     :notiz "Ward kündigt Lattners Vortrag als Blick auf das Programmieren für verschiedene Prozessoren und Beschleuniger an. Ein Bild zur Ankündigung ist im Auszug erwähnt."
     :anzeigezeit "2026-11-17 · 22:10" :autor "Ward")
    (:id :m06 :title "SPLASH’26: Mojo"
     :notiz "Ward nennt die Keynote „Mojo: Towards One Systems Language for All Hardware“ und berichtet, dass sich der Videolink über SPLASH schwer teilen liess."
     :anzeigezeit "2026-11-17 · 22:13" :autor "Ward")
    (:id :m07 :title "Lisp und die verpasste Gelegenheit"
     :notiz "Ward vermutet, dass Lisp-Programmierer Ähnliches früher hätten tun können. Er nennt die damalige Hardware und die wirtschaftlichen Anreize als mögliche Bedingungen und beschreibt seine eigene Abkehr."
     :anzeigezeit "2026-11-17 · 22:31" :autor "Ward")
    (:id :m08 :title "Link zur SPLASH-Keynote"
     :notiz "Robert reicht den YouTube-Link nach."
     :anzeigezeit "2026-11-17 · 22:35" :autor "Robert Sterbal"
     :url "https://youtu.be/9-97SB5XJh4?is=LUyoGU09tUPBvmn1")
    (:id :m09 :title "Keynote-Q&A und Swift"
     :notiz "Ward bestätigt das Video und hebt den Q&A-Teil hervor, insbesondere Lattners Rückblick auf Swift bei Apple."
     :anzeigezeit "2026-11-17 · 23:02" :autor "Ward")
    (:id :m10 :title "Die Zukunft des Programmierens"
     :notiz "Ward beschreibt Vortragsdichte und Fachjargon und sieht darin einen Bezugsrahmen für künftige Programmiersprachen."
     :anzeigezeit "2026-11-17 · 23:04" :autor "Ward")
    (:id :m11 :title "Application Accelerators"
     :notiz "Ward stellt den Link zur FedWiki-Seite in die Diskussion."
     :anzeigezeit "2026-11-17 · 23:16" :autor "Ward"
     :url "http://code.fed.wiki.org/application-accelerators.html")
    (:id :m12 :title "Lattner-Interview über KI, Mojo und Softwarearbeit"
     :notiz "Ward teilt ein Interview zu KI-Agenten und Vibe Coding, Entscheidungen darüber, was sich zu bauen lohnt, Mojo, Erfahrungen mit dem Swift-Start und dem Druck auf Open-Source-Maintainer."
     :anzeigezeit "2026-11-18 · 03:03" :autor "Ward"
     :url "https://www.youtube.com/watch?v=VHZUeM1BduQ")
    (:id :m13 :title "Sprachinnovation bei Minute 55"
     :notiz "Ward markiert ungefähr Minute 55 im Interview. Dort geht es laut Ward darum, wie Sprachinnovation verändert, wie wir über das Verhalten von Programmen sprechen."
     :anzeigezeit "2026-11-18 · 03:35" :autor "Ward"
     :url "https://www.youtube.com/watch?v=VHZUeM1BduQ&t=3300s")
    (:id :m14 :title "Die richtige Person zur richtigen Zeit"
     :notiz "Ward nennt Chris Lattner und Mike Bostock als zwei Personen, die für die Zukunft der Software zur richtigen Zeit an den richtigen Fragen arbeiten könnten."
     :anzeigezeit "2026-11-18 · 03:47" :autor "Ward")
    (:id :image :title "Angehängte Graphviz-Abbildung"
     :notiz "Die rote Kurve beginnt bei Ecology, biegt bei Role ab und endet mit einer Pfeilspitze bei Result. Die meisten Knoten tragen ein Fragezeichen unter ihrem Typnamen. Kreuzen und Überdecken von Knoten oder Kanten verrät keine zusätzlichen Trail-Stationen. Unter den sichtbaren Legenden stehen EIP Graphviz Decorations und Spring Layout."
     :datei "evidence/typed-trail.png" :sha256 "7b6deaea6533c64c581f6dc9113b588a84962604b9daca3860a2839729e83dbe")
    (:id :release :title "Solo-Commit 0.1.32-4"
     :notiz "Im Quellrepo nachgesehener Versionscommit."
     :url "https://github.com/WardCunningham/wiki-plugin-solo/commit/cd2c43356e4ce2ba6092bda991bd73158d076aa0")
    (:id :solo :title "Solo-Quelltext von 0.1.32-4"
     :notiz "Der Quelltext verwendet dotlabel für die Zuordnung von Trail-Knoten zu SVG-Text und übernimmt Hervorhebungen in die reguläre Knotendeklaration. Er importiert D3 und verwendet curveNatural für die rote Kurve."
     :url "https://github.com/WardCunningham/wiki-plugin-solo/blob/cd2c43356e4ce2ba6092bda991bd73158d076aa0/client/dialog/index.html")
    (:id :trails :title "How Trails Travel · Zettel 11727"
     :notiz "HyperDoc-Replay zur Layoutstabilität mit Dewey Alexander Trail und Solo 0.1.32-3."
     :url "https://github.com/RalfBarkow/hyperdoc/pull/50")
    (:id :wikitech :title "Wikitech · KAPOW"
     :notiz "Wikimedia dokumentiert den Einfluss auf Pageviews und die Sichtbarkeit interner Details."
     :url "https://wikitech-static.wikimedia.org/wiki/KAPOW_%28bot_detection_system%29.html")
    (:id :splash :title "ACM SPLASH 2026 · Keynote-Abstract"
     :notiz "Das Programm nennt parametrisierte Metaprogrammierung und ein Ownership-Modell auf Grundlage von Origins als Schwerpunkte der Keynote."
     :url "https://2026.splashcon.org/details/splash-2026-splash-keynotes/2/TBA")
    (:id :lattner :title "Chris Lattner"
     :notiz "Von Ward verlinktes Personenprofil."
     :url "https://en.wikipedia.org/wiki/Chris_Lattner")
    (:id :bostock :title "Mike Bostock"
     :notiz "Von Ward verlinktes Personenprofil."
     :url "https://en.wikipedia.org/wiki/Mike_Bostock")
    (:id :d3 :title "Mike Bostock bei Observable"
     :notiz "Bostock nennt D3 als sein Projekt."
     :url "https://observablehq.com/@mbostock")
    ))

(defparameter *relations*
  '(
    (:id :r01 :subjekt :solo :beziehung :zeichnet :objekt :trail
     :geltung :belegt :quellen (:m01 :solo))
    (:id :r02 :subjekt :trail :beziehung :adressiert :objekt :typed-nodes
     :geltung :belegt :quellen (:m01 :image :solo))
    (:id :r03 :subjekt :typed-nodes :beziehung :unterscheidet-knoten-im :objekt :graph-schema
     :geltung :belegt :quellen (:m01 :image))
    (:id :r04 :subjekt :solo-release :beziehung :bündelt-änderung-für :objekt :typed-nodes
     :geltung :gemeldet :quellen (:m02 :release :solo))
    (:id :r05 :subjekt :solo-release :beziehung :bündelt-änderung-für :objekt :graphviz-layout
     :geltung :gemeldet :quellen (:m02 :release :solo))
    (:id :r06 :subjekt :kapow :beziehung :beeinflusst :objekt :pageviews
     :geltung :belegt :quellen (:m03 :wikitech))
    (:id :r07 :subjekt :kapow :beziehung :konkretisiert :objekt :visibility
     :geltung :belegt :quellen (:m04 :wikitech))
    (:id :r08 :subjekt :mojo :beziehung :zielt-auf :objekt :heterogeneous-hardware
     :geltung :belegt :quellen (:m06 :splash))
    (:id :r09 :subjekt :application-accelerators :beziehung :folgt-im-gespräch-auf :objekt :heterogeneous-hardware
     :geltung :belegt :quellen (:m10 :m11))
    (:id :r10 :subjekt :lisp-hardware-economics :beziehung :kommentiert :objekt :heterogeneous-hardware
     :geltung :zugeschriebene-these :quellen (:m05 :m07))
    (:id :r11 :subjekt :lattner :beziehung :wird-genannt-mit :objekt :bostock
     :geltung :belegt :quellen (:m14))
    (:id :r12 :subjekt :bostock :beziehung :entwickelte :objekt :d3
     :geltung :belegt :quellen (:d3))
    (:id :r13 :subjekt :d3 :beziehung :wird-verwendet-von :objekt :solo
     :geltung :belegt :quellen (:solo))
    (:id :r14 :subjekt :bostock :beziehung :ist-vermittelt-verbunden-mit :objekt :solo
     :geltung :abgeleitet :quellen (:solo :d3))
    ))

(defun find-topic (id)
  "Liefere den Topic-Datensatz zur lokalen Keyword-ID ID."
  (find id *topics* :key (lambda (topic) (getf topic :id))))

(defun sources-for-topic (id)
  "Liefere die Fundstellen des Topics ID in der Reihenfolge des Index."
  (let ((topic (find-topic id)))
    (unless topic
      (error "Unbekanntes Scratch-Topic ~S." id))
    (loop for source-id in (getf topic :quellen)
          collect (find source-id *sources*
                        :key (lambda (source) (getf source :id))))))

(defun topic-map-pathname ()
  "Liefere den lokalen Pfad der CTM-Datei dieses Systems."
  (asdf:system-relative-pathname "scratch" "scratch.ctm"))
