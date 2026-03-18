
(:INPUT
 (:SOURCE-PATH #P"tools/testdata/article-allegation-slice/minab-example.lisp" :SLICE-ID
  "minab-school-strike" :MODE :ARTICLE-ALLEGATION :INCIDENT-TITLE "Minab school strike allegations"
  :INCIDENT-SUMMARY
  "Reported school strike case used to document stale targeting data, disputed attribution, civilian-harm accountability, and AI-assisted targeting responsibility."
  :SOURCE-LABEL "user-provided article summary" :SOURCE-DESCRIPTION "user-provided article summary"
  :SOURCE-TYPE :NEWS-ARTICLE :SOURCE-PROVENANCE NIL :ARTICLE-DATE NIL :INCIDENT-DATE "2026-03-13"
  :INCIDENT-FEDWIKI-SLUG "minab-school-strike-allegations" :EPISTEMIC-STATUS :DISPUTED
  :ATTRIBUTION-STATUS :DISPUTED :LEGAL-STATUS-SENSITIVE-P T :VERIFIED-LEGAL-ATTRIBUTION-P NIL
  :AI-INVOLVEMENT-P NIL :COMMAND-ACCOUNTABILITY-P NIL :INCLUDE-INCIDENT-TOPIC-P NIL
  :INCIDENT-PAGE-REFERENCE? T :KNOWN-UNCERTAINTIES
  ("The underlying article text is preserved here as a claim source rather than as independently verified fact."
   "Strike responsibility, the stale-coordinate hypothesis, and the later forensic reconstruction remain allegation-qualified unless stronger source metadata is supplied.")
  :SUGGESTED-SECTION-HEADINGS
  (:CLAIMED-SEQUENCE "Claimed sequence of events" :REPORTED-ATTRIBUTION "Reported attribution"
   :FORENSIC-CLAIMS "Investigative or forensic claims" :ACCOUNTABILITY "Accountability questions"
   :UNCERTAINTIES "Open uncertainties" :RELATED "Related concepts")
  :REQUIRE-OPEN-UNCERTAINTIES-P T :GENERATE-FEDWIKI-TWINS-P T :GENERATE-DAILY-ANCHOR-P T
  :DAILY-ANCHOR-DATE "2026-03-13" :DAILY-ANCHOR-HEADING
  "Minab school strike allegations article-allegation slice" :DAILY-ANCHOR-NOTE
  "Dry-run sample for the reusable article-allegation-slice scaffolding routine."
  :DRY-RUN-START-DATE 1773393295339 :EXPECTED-HYPERDOC-BRANCH "hauptsache" :EXPECTED-FEDWIKI-BRANCH
  "localhost" :HYPERDOC-REPO-ROOT #P"/Users/rgb/workspace/hyperdoc/" :HYPERDOC-PAGES-DIRECTORY
  #P"/Users/rgb/workspace/hyperdoc/hyperdoc/" :FEDWIKI-REPO-ROOT
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/" :FEDWIKI-PAGES-DIRECTORY
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/" :FEDWIKI-SITE-ID "wiki.ralfbarkow.ch" :CONCEPTS
  ((:TITLE "Stale target coordinates" :TOPIC-ID "stale-target-coordinates" :SUMMARY
    "Stale target coordinates is scaffolded here as a reusable failure mode for allegation-qualified incident documentation."
    :KIND :FAILURE-MODE :TOPIC-FUNCTION-NAME "stale-target-coordinates-topic" :FEDWIKI-SLUG
    "stale-target-coordinates" :REFERENCES NIL :RELATED-TITLES
    ("Target validation" "Precision weapons and wrong-target failure"))
   (:TITLE "Precision weapons and wrong-target failure" :TOPIC-ID "precision-weapon-mistargeting"
    :SUMMARY
    "Precision weapons and wrong-target failure is scaffolded here as a reusable failure mode for allegation-qualified incident documentation."
    :KIND :FAILURE-MODE :TOPIC-FUNCTION-NAME "precision-weapon-mistargeting-topic" :FEDWIKI-SLUG
    "precision-weapon-mistargeting" :REFERENCES NIL :RELATED-TITLES
    ("Stale target coordinates" "Target validation"))
   (:TITLE "Target validation" :TOPIC-ID "target-validation" :SUMMARY
    "Target validation is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation."
    :KIND :PROCESS-FAILURE :TOPIC-FUNCTION-NAME "target-validation-topic" :FEDWIKI-SLUG
    "target-validation" :REFERENCES NIL :RELATED-TITLES
    ("Stale target coordinates" "Civilian harm accountability"))
   (:TITLE "Civilian harm accountability" :TOPIC-ID "civilian-harm-accountability" :SUMMARY
    "Civilian harm accountability is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation."
    :KIND :ACCOUNTABILITY-MODEL :TOPIC-FUNCTION-NAME "civilian-harm-accountability-topic"
    :FEDWIKI-SLUG "civilian-harm-accountability" :REFERENCES NIL :RELATED-TITLES
    ("Target validation" "Human responsibility in AI-assisted targeting"))
   (:TITLE "Public attribution after disputed airstrikes" :TOPIC-ID "disputed-strike-attribution"
    :SUMMARY
    "Public attribution after disputed airstrikes is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation."
    :KIND :ATTRIBUTION-METHOD :TOPIC-FUNCTION-NAME "disputed-strike-attribution-topic"
    :FEDWIKI-SLUG "disputed-strike-attribution" :REFERENCES NIL :RELATED-TITLES
    ("Civilian harm accountability" "Human responsibility in AI-assisted targeting"))
   (:TITLE "Human responsibility in AI-assisted targeting" :TOPIC-ID "human-in-the-loop-targeting"
    :SUMMARY
    "Human responsibility in AI-assisted targeting is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation."
    :KIND :HUMAN-AI-BOUNDARY :TOPIC-FUNCTION-NAME "human-in-the-loop-targeting-topic" :FEDWIKI-SLUG
    "human-in-the-loop-targeting" :REFERENCES NIL :RELATED-TITLES
    ("Civilian harm accountability" "Target validation"))))
 :DRY-RUN-ROOT NIL :HYPERDOC-FILES
 ((:TITLE "Minab school strike allegations" :RELATIVE-PATH
   "hyperdoc/Minab school strike allegations.html" :TARGET-PATH
   #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Minab school strike allegations.html" :CONTENT
   "<h1>Minab school strike allegations</h1>

<in-package>hyperdoc</in-package>

<p>
  This page scaffolds an allegation-qualified documentation slice from user-provided article summary. HyperDoc keeps the concrete event claims here at the level of reported, alleged, or cited claims unless stronger verification metadata is explicitly supplied to the routine.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Stale target coordinates\"><tt>Stale target coordinates</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Precision weapons and wrong-target failure\"><tt>Precision weapons and wrong-target failure</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Target validation\"><tt>Target validation</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Civilian harm accountability\"><tt>Civilian harm accountability</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Public attribution after disputed airstrikes\"><tt>Public attribution after disputed airstrikes</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Human responsibility in AI-assisted targeting\"><tt>Human responsibility in AI-assisted targeting</tt></a></li>
</ul>
<h2>Claimed sequence of events</h2>

<p>
  According to the cited account, Reported school strike case used to document stale targeting data, disputed attribution, civilian-harm accountability, and AI-assisted targeting responsibility.. This scaffold preserves that sequence as article-reported reconstruction rather than silently upgrading it into settled repository fact.
</p>
<h2>Reported attribution</h2>

<p>
  The input marks the incident's epistemic status as <tt>disputed</tt>. The incident page therefore uses formulations such as <i>the article reports</i>, <i>according to the cited account</i>, and <i>the case is presented as</i> unless stronger verification metadata is explicitly supplied.
</p>
<h2>Investigative or forensic claims</h2>

<p>
  If the reported reconstruction is correct, the case may turn on forensic or investigative materials such as video, imagery, fragment analysis, launch-envelope reasoning, or inventory knowledge. This section exists to separate evidentiary reconstruction from immediate public narrative.
</p>
<h2>Accountability questions</h2>

<p>
  The incident raises questions about target validation, civilian-harm review, organizational mitigation capacity, and command responsibility. This scaffold does not emit flat legal conclusions such as <i>war crime</i> by default.
</p>
<h2>Human/AI decision boundary</h2>

<p>
  The input marks AI or automation discourse as relevant. This scaffold therefore keeps AI language at the level of decision support, review acceleration, automation-bias risk, and human final responsibility, not as a flat claim that AI caused the incident.
</p>
<h2>Open uncertainties</h2>

<ul>
  <li>The underlying article text is preserved here as a claim source rather than as independently verified fact.</li>
  <li>Strike responsibility, the stale-coordinate hypothesis, and the later forensic reconstruction remain allegation-qualified unless stronger source metadata is supplied.</li>
</ul>
<h2>Related concepts</h2>

<ul>
  <li><a page=\"Stale target coordinates\">Stale target coordinates</a></li>
  <li><a page=\"Precision weapons and wrong-target failure\">Precision weapons and wrong-target failure</a></li>
  <li><a page=\"Target validation\">Target validation</a></li>
  <li><a page=\"Civilian harm accountability\">Civilian harm accountability</a></li>
  <li><a page=\"Public attribution after disputed airstrikes\">Public attribution after disputed airstrikes</a></li>
  <li><a page=\"Human responsibility in AI-assisted targeting\">Human responsibility in AI-assisted targeting</a></li>
</ul>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"minab-school-strike-allegations\">minab-school-strike-allegations</a>.
</p>
")
  (:TITLE "Stale target coordinates" :RELATIVE-PATH "hyperdoc/Stale target coordinates.html"
   :TARGET-PATH #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Stale target coordinates.html" :CONTENT
   "<h1>Stale target coordinates</h1>

<in-package>hyperdoc</in-package>

<p>
  Stale target coordinates is scaffolded here as a reusable failure mode for allegation-qualified incident documentation. HyperDoc uses this page for a reusable failure mode rather than for a one-off incident verdict.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Stale target coordinates\"><tt>Stale target coordinates</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Target validation\"><tt>Target validation</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Precision weapons and wrong-target failure\"><tt>Precision weapons and wrong-target failure</tt></a></li>
</ul>
<h2>Core distinction</h2>

<p>
  Stale target coordinates is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.
</p>
<h2>Operational notes</h2>

<ul>
  <li>stale or obsolete target data persists into a later strike package</li>
  <li>a system remains precise in delivery while wrong in target representation</li>
  <li>upstream classification or mapping assumptions survive longer than the underlying site reality</li>
</ul>
<h2>Why this remains reusable</h2>

<p>
  A system can therefore look precise while remaining dangerously wrong about what the coordinates represent.
</p>
<h2>Boundary</h2>

<p>
  This page does not imply weapon malfunction. It distinguishes a wrong target representation from a guidance failure.
</p>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"stale-target-coordinates\">stale-target-coordinates</a>.
</p>
<h2>Related</h2>

<ul>
  <li><a page=\"Target validation\">Target validation</a></li>
  <li><a page=\"Precision weapons and wrong-target failure\">Precision weapons and wrong-target failure</a></li>
  <li><a page=\"Minab school strike allegations\">Minab school strike allegations</a></li>
</ul>
")
  (:TITLE "Precision weapons and wrong-target failure" :RELATIVE-PATH
   "hyperdoc/Precision weapons and wrong-target failure.html" :TARGET-PATH
   #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Precision weapons and wrong-target failure.html"
   :CONTENT "<h1>Precision weapons and wrong-target failure</h1>

<in-package>hyperdoc</in-package>

<p>
  Precision weapons and wrong-target failure is scaffolded here as a reusable failure mode for allegation-qualified incident documentation. HyperDoc uses this page for a reusable failure mode rather than for a one-off incident verdict.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Precision weapons and wrong-target failure\"><tt>Precision weapons and wrong-target failure</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Stale target coordinates\"><tt>Stale target coordinates</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Target validation\"><tt>Target validation</tt></a></li>
</ul>
<h2>Core distinction</h2>

<p>
  Precision weapons and wrong-target failure is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.
</p>
<h2>Operational notes</h2>

<ul>
  <li>stale or obsolete target data persists into a later strike package</li>
  <li>a system remains precise in delivery while wrong in target representation</li>
  <li>upstream classification or mapping assumptions survive longer than the underlying site reality</li>
</ul>
<h2>Why this remains reusable</h2>

<p>
  A system can therefore look precise while remaining dangerously wrong about what the coordinates represent.
</p>
<h2>Boundary</h2>

<p>
  This page does not imply weapon malfunction. It distinguishes a wrong target representation from a guidance failure.
</p>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"precision-weapon-mistargeting\">precision-weapon-mistargeting</a>.
</p>
<h2>Related</h2>

<ul>
  <li><a page=\"Stale target coordinates\">Stale target coordinates</a></li>
  <li><a page=\"Target validation\">Target validation</a></li>
  <li><a page=\"Minab school strike allegations\">Minab school strike allegations</a></li>
</ul>
")
  (:TITLE "Target validation" :RELATIVE-PATH "hyperdoc/Target validation.html" :TARGET-PATH
   #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Target validation.html" :CONTENT
   "<h1>Target validation</h1>

<in-package>hyperdoc</in-package>

<p>
  Target validation is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation. HyperDoc uses this page to separate a process failure from any one article's reconstruction.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Target validation\"><tt>Target validation</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Stale target coordinates\"><tt>Stale target coordinates</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Civilian harm accountability\"><tt>Civilian harm accountability</tt></a></li>
</ul>
<h2>Core distinction</h2>

<p>
  Target validation is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation.
</p>
<h2>Operational notes</h2>

<ul>
  <li>current site status is not rechecked before launch</li>
  <li>older intelligence handoff is trusted without fresh validation</li>
  <li>review gates exist formally but do not surface or stop the mismatch</li>
</ul>
<h2>Why this remains reusable</h2>

<p>
  The process layer matters because stale information becomes operational only when later actors inherit it without adequate challenge.
</p>
<h2>Boundary</h2>

<p>
  This page does not claim that every disputed strike reflects a process failure. It records where process review would matter if stale or mistaken data is alleged.
</p>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"target-validation\">target-validation</a>.
</p>
<h2>Related</h2>

<ul>
  <li><a page=\"Stale target coordinates\">Stale target coordinates</a></li>
  <li><a page=\"Civilian harm accountability\">Civilian harm accountability</a></li>
  <li><a page=\"Minab school strike allegations\">Minab school strike allegations</a></li>
</ul>
")
  (:TITLE "Civilian harm accountability" :RELATIVE-PATH
   "hyperdoc/Civilian harm accountability.html" :TARGET-PATH
   #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Civilian harm accountability.html" :CONTENT
   "<h1>Civilian harm accountability</h1>

<in-package>hyperdoc</in-package>

<p>
  Civilian harm accountability is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation. HyperDoc uses this page to keep accountability questions visible without forcing premature legal closure.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Civilian harm accountability\"><tt>Civilian harm accountability</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Target validation\"><tt>Target validation</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Human responsibility in AI-assisted targeting\"><tt>Human responsibility in AI-assisted targeting</tt></a></li>
</ul>
<h2>Core distinction</h2>

<p>
  Civilian harm accountability is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation.
</p>
<h2>Operational notes</h2>

<ul>
  <li>what should have been checked before authorization</li>
  <li>who had authority to slow, stop, or review the strike package</li>
  <li>whether organizational practice created foreseeable civilian-harm risk</li>
</ul>
<h2>Why this remains reusable</h2>

<p>
  Unintended harm does not end accountability analysis when the harm may have followed preventable review, staffing, or doctrine failures.
</p>
<h2>Boundary</h2>

<p>
  This page does not declare liability by default. It preserves the questions that should remain visible when civilian harm is reported.
</p>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"civilian-harm-accountability\">civilian-harm-accountability</a>.
</p>
<h2>Related</h2>

<ul>
  <li><a page=\"Target validation\">Target validation</a></li>
  <li><a page=\"Human responsibility in AI-assisted targeting\">Human responsibility in AI-assisted targeting</a></li>
  <li><a page=\"Minab school strike allegations\">Minab school strike allegations</a></li>
</ul>
")
  (:TITLE "Public attribution after disputed airstrikes" :RELATIVE-PATH
   "hyperdoc/Public attribution after disputed airstrikes.html" :TARGET-PATH
   #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Public attribution after disputed airstrikes.html"
   :CONTENT "<h1>Public attribution after disputed airstrikes</h1>

<in-package>hyperdoc</in-package>

<p>
  Public attribution after disputed airstrikes is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation. HyperDoc uses this page for a reusable attribution method, not for a single fixed political narrative.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Public attribution after disputed airstrikes\"><tt>Public attribution after disputed airstrikes</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Civilian harm accountability\"><tt>Civilian harm accountability</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Human responsibility in AI-assisted targeting\"><tt>Human responsibility in AI-assisted targeting</tt></a></li>
</ul>
<h2>Core distinction</h2>

<p>
  Public attribution after disputed airstrikes is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation.
</p>
<h2>Operational notes</h2>

<ul>
  <li>video, imagery, or fragment evidence</li>
  <li>inventory and launch-envelope reasoning</li>
  <li>separation of public accusation from forensic confidence</li>
</ul>
<h2>Why this remains reusable</h2>

<p>
  Public certainty and evidentiary confidence are different things; this page exists to keep them distinct.
</p>
<h2>Boundary</h2>

<p>
  This page does not promise certainty in every case. It preserves the method boundary between rhetoric and reconstruction.
</p>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"disputed-strike-attribution\">disputed-strike-attribution</a>.
</p>
<h2>Related</h2>

<ul>
  <li><a page=\"Civilian harm accountability\">Civilian harm accountability</a></li>
  <li><a page=\"Human responsibility in AI-assisted targeting\">Human responsibility in AI-assisted targeting</a></li>
  <li><a page=\"Minab school strike allegations\">Minab school strike allegations</a></li>
</ul>
")
  (:TITLE "Human responsibility in AI-assisted targeting" :RELATIVE-PATH
   "hyperdoc/Human responsibility in AI-assisted targeting.html" :TARGET-PATH
   #P"/Users/rgb/workspace/hyperdoc/hyperdoc/Human responsibility in AI-assisted targeting.html"
   :CONTENT "<h1>Human responsibility in AI-assisted targeting</h1>

<in-package>hyperdoc</in-package>

<p>
  Human responsibility in AI-assisted targeting is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation. HyperDoc uses this page for the human/AI decision boundary and the difference between formal approval and substantive accountability.
</p>
<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook=\"topics\" page=\"Human responsibility in AI-assisted targeting\"><tt>Human responsibility in AI-assisted targeting</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Civilian harm accountability\"><tt>Civilian harm accountability</tt></a></li>
  <li><a hyperbook=\"topics\" page=\"Target validation\"><tt>Target validation</tt></a></li>
</ul>
<h2>Core distinction</h2>

<p>
  Human responsibility in AI-assisted targeting is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation.
</p>
<h2>Operational notes</h2>

<ul>
  <li>decision support and ranking do not remove human responsibility</li>
  <li>compressed review windows can amplify automation bias</li>
  <li>human in the loop must mean more than a final signature</li>
</ul>
<h2>Why this remains reusable</h2>

<p>
  Formal human approval does not by itself prove meaningful human oversight if time pressure, opaque rankings, or organizational incentives dominate the workflow.
</p>
<h2>Boundary</h2>

<p>
  This page does not claim that software autonomously caused a strike unless that stronger verified input is explicitly supplied.
</p>
<h2>Localhost FedWiki twin</h2>

<p>
  Twin page:
  <a hyperbook=\"fedwiki:wiki.ralfbarkow.ch\" page=\"human-in-the-loop-targeting\">human-in-the-loop-targeting</a>.
</p>
<h2>Related</h2>

<ul>
  <li><a page=\"Civilian harm accountability\">Civilian harm accountability</a></li>
  <li><a page=\"Target validation\">Target validation</a></li>
  <li><a page=\"Minab school strike allegations\">Minab school strike allegations</a></li>
</ul>
"))
 :TOPICS-TARGET-PATH #P"/Users/rgb/workspace/hyperdoc/hyperdoc/topics.lisp" :TOPICS-SNIPPET
 ";; Article allegation slice topics for Minab school strike allegations.

(defun stale-target-coordinates-topic ()
  (make-topic
   :id \"stale-target-coordinates\"
   :title \"Stale target coordinates\"
   :summary \"Stale target coordinates is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.\"
   :references '(\"Stale target coordinates\" \"Minab school strike allegations\")))

(defun precision-weapon-mistargeting-topic ()
  (make-topic
   :id \"precision-weapon-mistargeting\"
   :title \"Precision weapons and wrong-target failure\"
   :summary \"Precision weapons and wrong-target failure is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.\"
   :references '(\"Precision weapons and wrong-target failure\"
                 \"Minab school strike allegations\")))

(defun target-validation-topic ()
  (make-topic
   :id \"target-validation\"
   :title \"Target validation\"
   :summary \"Target validation is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation.\"
   :references '(\"Target validation\" \"Minab school strike allegations\")))

(defun civilian-harm-accountability-topic ()
  (make-topic
   :id \"civilian-harm-accountability\"
   :title \"Civilian harm accountability\"
   :summary \"Civilian harm accountability is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation.\"
   :references '(\"Civilian harm accountability\"
                 \"Minab school strike allegations\")))

(defun disputed-strike-attribution-topic ()
  (make-topic
   :id \"disputed-strike-attribution\"
   :title \"Public attribution after disputed airstrikes\"
   :summary \"Public attribution after disputed airstrikes is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation.\"
   :references '(\"Public attribution after disputed airstrikes\"
                 \"Minab school strike allegations\")))

(defun human-in-the-loop-targeting-topic ()
  (make-topic
   :id \"human-in-the-loop-targeting\"
   :title \"Human responsibility in AI-assisted targeting\"
   :summary \"Human responsibility in AI-assisted targeting is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation.\"
   :references '(\"Human responsibility in AI-assisted targeting\"
                 \"Minab school strike allegations\")))

"
 :TOPIC-DEFINITIONS
 ((:FUNCTION-NAME "stale-target-coordinates-topic" :TITLE "Stale target coordinates" :TOPIC-ID
   "stale-target-coordinates")
  (:FUNCTION-NAME "precision-weapon-mistargeting-topic" :TITLE
   "Precision weapons and wrong-target failure" :TOPIC-ID "precision-weapon-mistargeting")
  (:FUNCTION-NAME "target-validation-topic" :TITLE "Target validation" :TOPIC-ID
   "target-validation")
  (:FUNCTION-NAME "civilian-harm-accountability-topic" :TITLE "Civilian harm accountability"
   :TOPIC-ID "civilian-harm-accountability")
  (:FUNCTION-NAME "disputed-strike-attribution-topic" :TITLE
   "Public attribution after disputed airstrikes" :TOPIC-ID "disputed-strike-attribution")
  (:FUNCTION-NAME "human-in-the-loop-targeting-topic" :TITLE
   "Human responsibility in AI-assisted targeting" :TOPIC-ID "human-in-the-loop-targeting"))
 :FEDWIKI-FILES
 ((:TITLE "Minab school strike allegations" :SLUG "minab-school-strike-allegations" :TARGET-PATH
   #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/minab-school-strike-allegations" :PAGE
   (:TITLE "Minab school strike allegations" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000100000001" :TEXT
      "Reported school strike case used to document stale targeting data, disputed attribution, civilian-harm accountability, and AI-assisted targeting responsibility.")
     (:TYPE :MARKDOWN :ID "0000000100000002" :TEXT "### References
- [[Minab school strike allegations]]
- [[Stale target coordinates]]
- [[Precision weapons and wrong-target failure]]
- [[Target validation]]
- [[Civilian harm accountability]]
- [[Public attribution after disputed airstrikes]]
- [[Human responsibility in AI-assisted targeting]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Minab school strike allegations" :STORY NIL) :DATE
      1773393295339)
     (:TYPE :ADD :ID "0000000100000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000100000001" :TEXT
       "Reported school strike case used to document stale targeting data, disputed attribution, civilian-harm accountability, and AI-assisted targeting responsibility.")
      :DATE 1773393295340)
     (:TYPE :ADD :ID "0000000100000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000100000002" :TEXT "### References
- [[Minab school strike allegations]]
- [[Stale target coordinates]]
- [[Precision weapons and wrong-target failure]]
- [[Target validation]]
- [[Civilian harm accountability]]
- [[Public attribution after disputed airstrikes]]
- [[Human responsibility in AI-assisted targeting]]
")
      :DATE 1773393295341 :AFTER "0000000100000001"))))
  (:TITLE "Stale target coordinates" :SLUG "stale-target-coordinates" :TARGET-PATH
   #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/stale-target-coordinates" :PAGE
   (:TITLE "Stale target coordinates" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000200000001" :TEXT
      "Stale target coordinates is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.")
     (:TYPE :MARKDOWN :ID "0000000200000002" :TEXT "### References
- [[Stale target coordinates]]
- [[Minab school strike allegations]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Stale target coordinates" :STORY NIL) :DATE 1773393295341)
     (:TYPE :ADD :ID "0000000200000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000200000001" :TEXT
       "Stale target coordinates is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.")
      :DATE 1773393295342)
     (:TYPE :ADD :ID "0000000200000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000200000002" :TEXT "### References
- [[Stale target coordinates]]
- [[Minab school strike allegations]]
")
      :DATE 1773393295343 :AFTER "0000000200000001"))))
  (:TITLE "Precision weapons and wrong-target failure" :SLUG "precision-weapon-mistargeting"
   :TARGET-PATH #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/precision-weapon-mistargeting" :PAGE
   (:TITLE "Precision weapons and wrong-target failure" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000300000001" :TEXT
      "Precision weapons and wrong-target failure is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.")
     (:TYPE :MARKDOWN :ID "0000000300000002" :TEXT "### References
- [[Precision weapons and wrong-target failure]]
- [[Minab school strike allegations]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Precision weapons and wrong-target failure" :STORY NIL) :DATE
      1773393295342)
     (:TYPE :ADD :ID "0000000300000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000300000001" :TEXT
       "Precision weapons and wrong-target failure is scaffolded here as a reusable failure mode for allegation-qualified incident documentation.")
      :DATE 1773393295343)
     (:TYPE :ADD :ID "0000000300000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000300000002" :TEXT "### References
- [[Precision weapons and wrong-target failure]]
- [[Minab school strike allegations]]
")
      :DATE 1773393295344 :AFTER "0000000300000001"))))
  (:TITLE "Target validation" :SLUG "target-validation" :TARGET-PATH
   #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/target-validation" :PAGE
   (:TITLE "Target validation" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000400000001" :TEXT
      "Target validation is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation.")
     (:TYPE :MARKDOWN :ID "0000000400000002" :TEXT "### References
- [[Target validation]]
- [[Minab school strike allegations]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Target validation" :STORY NIL) :DATE 1773393295343)
     (:TYPE :ADD :ID "0000000400000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000400000001" :TEXT
       "Target validation is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation.")
      :DATE 1773393295344)
     (:TYPE :ADD :ID "0000000400000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000400000002" :TEXT "### References
- [[Target validation]]
- [[Minab school strike allegations]]
")
      :DATE 1773393295345 :AFTER "0000000400000001"))))
  (:TITLE "Civilian harm accountability" :SLUG "civilian-harm-accountability" :TARGET-PATH
   #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/civilian-harm-accountability" :PAGE
   (:TITLE "Civilian harm accountability" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000500000001" :TEXT
      "Civilian harm accountability is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation.")
     (:TYPE :MARKDOWN :ID "0000000500000002" :TEXT "### References
- [[Civilian harm accountability]]
- [[Minab school strike allegations]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Civilian harm accountability" :STORY NIL) :DATE 1773393295344)
     (:TYPE :ADD :ID "0000000500000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000500000001" :TEXT
       "Civilian harm accountability is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation.")
      :DATE 1773393295345)
     (:TYPE :ADD :ID "0000000500000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000500000002" :TEXT "### References
- [[Civilian harm accountability]]
- [[Minab school strike allegations]]
")
      :DATE 1773393295346 :AFTER "0000000500000001"))))
  (:TITLE "Public attribution after disputed airstrikes" :SLUG "disputed-strike-attribution"
   :TARGET-PATH #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/disputed-strike-attribution" :PAGE
   (:TITLE "Public attribution after disputed airstrikes" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000600000001" :TEXT
      "Public attribution after disputed airstrikes is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation.")
     (:TYPE :MARKDOWN :ID "0000000600000002" :TEXT "### References
- [[Public attribution after disputed airstrikes]]
- [[Minab school strike allegations]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Public attribution after disputed airstrikes" :STORY NIL) :DATE
      1773393295345)
     (:TYPE :ADD :ID "0000000600000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000600000001" :TEXT
       "Public attribution after disputed airstrikes is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation.")
      :DATE 1773393295346)
     (:TYPE :ADD :ID "0000000600000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000600000002" :TEXT "### References
- [[Public attribution after disputed airstrikes]]
- [[Minab school strike allegations]]
")
      :DATE 1773393295347 :AFTER "0000000600000001"))))
  (:TITLE "Human responsibility in AI-assisted targeting" :SLUG "human-in-the-loop-targeting"
   :TARGET-PATH #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/human-in-the-loop-targeting" :PAGE
   (:TITLE "Human responsibility in AI-assisted targeting" :STORY
    ((:TYPE :PARAGRAPH :ID "0000000700000001" :TEXT
      "Human responsibility in AI-assisted targeting is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation.")
     (:TYPE :MARKDOWN :ID "0000000700000002" :TEXT "### References
- [[Human responsibility in AI-assisted targeting]]
- [[Minab school strike allegations]]
"))
    :JOURNAL
    ((:TYPE :CREATE :ITEM (:TITLE "Human responsibility in AI-assisted targeting" :STORY NIL) :DATE
      1773393295346)
     (:TYPE :ADD :ID "0000000700000001" :ITEM
      (:TYPE :PARAGRAPH :ID "0000000700000001" :TEXT
       "Human responsibility in AI-assisted targeting is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation.")
      :DATE 1773393295347)
     (:TYPE :ADD :ID "0000000700000002" :ITEM
      (:TYPE :MARKDOWN :ID "0000000700000002" :TEXT "### References
- [[Human responsibility in AI-assisted targeting]]
- [[Minab school strike allegations]]
")
      :DATE 1773393295348 :AFTER "0000000700000001")))))
 :DAILY-PAGE
 (:TITLE "2026-03-13" :TARGET-PATH #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/2026-03-13" :PAGE
  (:TITLE "2026-03-13" :STORY
   ((:TYPE :MARKDOWN :ID "0000006300000001" :TEXT
     "### Minab school strike allegations article-allegation slice
- [[Minab school strike allegations]]
- [[Stale target coordinates]]
- [[Precision weapons and wrong-target failure]]
- [[Target validation]]
- [[Civilian harm accountability]]
- [[Public attribution after disputed airstrikes]]
- [[Human responsibility in AI-assisted targeting]]
- Dry-run sample for the reusable article-allegation-slice scaffolding routine."))
   :JOURNAL
   ((:TYPE :CREATE :ITEM (:TITLE "2026-03-13" :STORY NIL) :DATE 1773393295438)
    (:TYPE :ADD :ID "0000006300000001" :ITEM
     (:TYPE :MARKDOWN :ID "0000006300000001" :TEXT
      "### Minab school strike allegations article-allegation slice
- [[Minab school strike allegations]]
- [[Stale target coordinates]]
- [[Precision weapons and wrong-target failure]]
- [[Target validation]]
- [[Civilian harm accountability]]
- [[Public attribution after disputed airstrikes]]
- [[Human responsibility in AI-assisted targeting]]
- Dry-run sample for the reusable article-allegation-slice scaffolding routine.")
     :DATE 1773393295439))))
 :VALIDATION-COMMANDS
 ("nix develop --command sbcl --no-userinit --non-interactive --eval '(require :asdf)' --eval '(let* ((root (uiop:ensure-directory-pathname (uiop:getcwd))) (flake-deps (uiop:ensure-directory-pathname (merge-pathnames \".flake-deps/\" root))) (cache (uiop:ensure-directory-pathname (merge-pathnames \".cache/asdf/\" root))) (src-pattern (list root #P\"**/*.*\")) (dst-pattern (list cache #P\"**/*.*\"))) (ensure-directories-exist cache) (asdf:initialize-source-registry (list :source-registry (list :tree root) (list :tree flake-deps) :inherit-configuration)) (asdf:initialize-output-translations (list :output-translations (list src-pattern dst-pattern) :ignore-inherited-configuration)))' --eval '(asdf:load-asd (truename \"hyperbook.asd\"))' --eval '(asdf:load-asd (truename \"hyperdoc.asd\"))' --eval '(asdf:load-system :hyperdoc)' --quit"
  "nix develop --command sbcl --no-userinit --non-interactive --eval '(require :asdf)' --eval '(let* ((root (uiop:ensure-directory-pathname (uiop:getcwd))) (flake-deps (uiop:ensure-directory-pathname (merge-pathnames \".flake-deps/\" root))) (cache (uiop:ensure-directory-pathname (merge-pathnames \".cache/asdf/\" root))) (src-pattern (list root #P\"**/*.*\")) (dst-pattern (list cache #P\"**/*.*\"))) (ensure-directories-exist cache) (asdf:initialize-source-registry (list :source-registry (list :tree root) (list :tree flake-deps) :inherit-configuration)) (asdf:initialize-output-translations (list :output-translations (list src-pattern dst-pattern) :ignore-inherited-configuration)))' --eval '(asdf:load-asd (truename \"hyperbook.asd\"))' --eval '(asdf:load-asd (truename \"hyperdoc.asd\"))' --eval '(asdf:load-system :hyperdoc)' --eval '(uiop:quit (if (every #'fboundp (list (quote hyperdoc::stale-target-coordinates-topic) (quote hyperdoc::precision-weapon-mistargeting-topic) (quote hyperdoc::target-validation-topic) (quote hyperdoc::civilian-harm-accountability-topic) (quote hyperdoc::disputed-strike-attribution-topic) (quote hyperdoc::human-in-the-loop-targeting-topic))) 0 1))' --quit"
  "nix develop --command sbcl --no-userinit --non-interactive --load tools/check-topic-coverage.lisp -- \"hyperdoc/Minab school strike allegations.html\" \"hyperdoc/Stale target coordinates.html\" \"hyperdoc/Precision weapons and wrong-target failure.html\" \"hyperdoc/Target validation.html\" \"hyperdoc/Civilian harm accountability.html\" \"hyperdoc/Public attribution after disputed airstrikes.html\" \"hyperdoc/Human responsibility in AI-assisted targeting.html\""
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/minab-school-strike-allegations >/tmp/minab-school-strike-allegations.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/stale-target-coordinates >/tmp/stale-target-coordinates.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/precision-weapon-mistargeting >/tmp/precision-weapon-mistargeting.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/target-validation >/tmp/target-validation.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/civilian-harm-accountability >/tmp/civilian-harm-accountability.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/disputed-strike-attribution >/tmp/disputed-strike-attribution.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/human-in-the-loop-targeting >/tmp/human-in-the-loop-targeting.json"
  "python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/2026-03-13 >/tmp/2026-03-13.json"
  "nix develop --command sbcl --script tools/journal-gate.lisp /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/minab-school-strike-allegations /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/stale-target-coordinates /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/precision-weapon-mistargeting /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/target-validation /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/civilian-harm-accountability /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/disputed-strike-attribution /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/human-in-the-loop-targeting /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/2026-03-13")
 :SLICE-METADATA
 (:SLICE-ID "minab-school-strike" :MODE :ARTICLE-ALLEGATION :GENERATED-BY :ARTICLE-ALLEGATION-SLICE
  :SOURCE-TYPE :NEWS-ARTICLE :SOURCE-LABEL "user-provided article summary" :EPISTEMIC-STATUS
  :DISPUTED :INCIDENT-PAGE-TITLE "Minab school strike allegations" :INCIDENT-PAGE
  "hyperdoc/Minab school strike allegations.html" :CONCEPT-PAGE-TITLES
  ("Stale target coordinates" "Precision weapons and wrong-target failure" "Target validation"
   "Civilian harm accountability" "Public attribution after disputed airstrikes"
   "Human responsibility in AI-assisted targeting")
  :CONCEPT-PAGES
  ("hyperdoc/Stale target coordinates.html"
   "hyperdoc/Precision weapons and wrong-target failure.html" "hyperdoc/Target validation.html"
   "hyperdoc/Civilian harm accountability.html"
   "hyperdoc/Public attribution after disputed airstrikes.html"
   "hyperdoc/Human responsibility in AI-assisted targeting.html")
  :TOPIC-HANDLES
  ("stale-target-coordinates-topic" "precision-weapon-mistargeting-topic" "target-validation-topic"
   "civilian-harm-accountability-topic" "disputed-strike-attribution-topic"
   "human-in-the-loop-targeting-topic")
  :INCIDENT-FEDWIKI-SLUG "minab-school-strike-allegations" :CONCEPT-FEDWIKI-SLUGS
  ("stale-target-coordinates" "precision-weapon-mistargeting" "target-validation"
   "civilian-harm-accountability" "disputed-strike-attribution" "human-in-the-loop-targeting")
  :FEDWIKI-PAGES
  ("fedwiki-pages/minab-school-strike-allegations" "fedwiki-pages/stale-target-coordinates"
   "fedwiki-pages/precision-weapon-mistargeting" "fedwiki-pages/target-validation"
   "fedwiki-pages/civilian-harm-accountability" "fedwiki-pages/disputed-strike-attribution"
   "fedwiki-pages/human-in-the-loop-targeting")
  :DAILY-ANCHOR-TARGET "2026-03-13" :DAILY-ANCHOR "fedwiki-pages/2026-03-13"))
