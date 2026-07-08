(:artifact llm-wiki-note-8892-zettel-xpath-locator-htn-update
 :kind htn-correction
 :status recorded

 :problem
 "The previous source-reading attempt used a naive substring search for <zettel
  and therefore treated the container/root name as if it were a Zettel node.
  The result was an off-by-one source selection: requested 8892 produced the
  text the user identified as Zettel 8891, Provenance Boundaries."

 :correction
 (:do-not
  (:calibrate-display-number-to-entry-position true
   :scan-for-open-tag-substring true
   :match-zettelkasten-container-as-zettel true)

  :use
  (!locate-zkn3-zettel-by-number
   :zkn-file #P"/tmp/hyperdoc-zkn3-read/zknFile.xml"
   :zettel-number ?zettel-number
   :locator :xpath
   :node-expression "(//zettel)[?zettel-number]"))

 :htn-update
 (:existing-operator
  (!locate-zkn3-zettel-entry ?zkn-file ?zettel-id)

  :strengthened-meaning
  "Locate the requested Zettel node by XPath over zettel elements, not by
   substring search and not by inferred calibration."

  :replacement-operator-name
  (!locate-zkn3-zettel-by-number ?zkn-file ?zettel-number)

  :selected-reading-continuation
  (!read-zkn3-zettel-8892
   :mode :source-reading-only
   :locator :xpath
   :then-read-url "https://heise.de/-11332215"
   :then-record-llm-wiki-okf-crosswalk true))

 :xpath-contract
 (:extract-zettel-node "(//zettel)[N]"
  :extract-zknid "string((//zettel)[N]/@zknid)"
  :extract-title "string((//zettel)[N]/title)"
  :extract-content "string((//zettel)[N]/content)"
  :extract-keywords "string((//zettel)[N]/keywords)"
  :extract-manlinks "string((//zettel)[N]/manlinks)"
  :extract-luhmann "string((//zettel)[N]/luhmann)")

 :next
 (!locate-zkn3-zettel-by-number
  :zettel-number "8892"
  :locator :xpath
  :then-read-zettel-text true))
