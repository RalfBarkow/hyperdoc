(:TASK
 (!PRESERVE-SOURCE-STORY-ITEMS :PAGE WHAT-GRAPHVIZ-DOES
  :PRESERVE-EXISTING-ITEM-IDS T :PRESERVE-EXISTING-STORY-ORDER T)
 :PARENT-TASK
 (!VALIDATE-REMOTE-PAGE-STORY-SHAPE-FROM-RETAINED-JSON WHAT-GRAPHVIZ-DOES)
 :STAGE-BOUNDARY
 ((MAY-PRESERVE-SOURCE-STORY-ITEM-CONTRACT T)
  (MAY-WRITE-PRESERVATION-EVIDENCE-ARTIFACT T)
  (MAY-REFETCH-REMOTE-PAGE-JSON NIL) (MAY-CONSTRUCT-FORK-JOURNAL-ACTION NIL)
  (MAY-WRITE-LOCAL-PAGE-JSON-AS-FORK NIL) (MAY-LOAD-MISSING-SOURCE-FILES NIL)
  (MAY-WRITE-PAGE-ATTACHED-ASDF NIL) (MAY-CREATE-SQLITE NIL) (MAY-COMMIT NIL))
 :SOURCE-PAGE
 (:SITE "does.ward.dojo.fed.wiki" :SLUG "what-graphviz-does" :TITLE
  "What Graphviz Does")
 :PRESERVATION-CONTRACT
 (:PRESERVE-EXISTING-ITEM-IDS T :PRESERVE-EXISTING-STORY-ORDER T
  :REWRITE-STORY-ITEM-IDS NIL :REWRITE-STORY-ORDER NIL :NORMALIZE-PLUGIN-ITEMS
  NIL :EXECUTE-GRAPHVIZ NIL :STORY-ITEM-IDS
  (#1="c558c39c83b0a0b9" #2="34e2de627fb48408" #3="6f9382b76ff19154")
  :STORY-ITEM-TYPES (#4="paragraph" #5="paragraph" #6="html") :STORY-ORDER
  ((:INDEX 0 :ID #1#) (:INDEX 1 :ID #2#) (:INDEX 2 :ID #3#))
  :STORY-ITEMS-SUMMARY
  ((:INDEX 0 :ID #1# :TYPE #4# :TEXT-PRESENT-P T :PRESERVE-ID-P T
    :PRESERVE-POSITION-P T)
   (:INDEX 1 :ID #2# :TYPE #5# :TEXT-PRESENT-P T :PRESERVE-ID-P T
    :PRESERVE-POSITION-P T)
   (:INDEX 2 :ID #3# :TYPE #6# :TEXT-PRESENT-P T :PRESERVE-ID-P T
    :PRESERVE-POSITION-P T))
  :PRESERVATION-VALID-P T)
 :READABLE-STORY-COPY
 ((("type" #4#) ("id" #1#)
   ("text"
    "We describe the Graphviz plugin's algorithmic markup in one paragraph. Then break this down by jargon words."))
  (("type" #5#) ("id" #2#)
   ("text"
    "The Graphviz plugin is a mashup of many bits of technology wrapped up in a block-structured markup inspired by python's whitespace rules. It merges this with DOT which is rich in its own right and Regular Expressions as the go-to choice for text matching. The markup is organized as a Visitor borrowing this word from Design Patterns. This is an abstraction of tree traversal where recursion is the natural choice except that we lumped on this the challenge of overlapping network fetches using a work queue which could easily be replaced by async-await had that been available."))
  (("type" #6#) ("id" #3#)
   ("text" "<pre>The Graphviz [[Plugin]]
 is a [[Mashup]]
  of many [[Bits]]
   of [[Technology]]
    wrapped up in a [[Block-Structured]]
     [[Markup]]
      inspired by [[Python]]'s
       [[Whitespace]]
        [[Rules]].
It [[Merges]]
 this with [[DOT]]
  which is [[Rich]]
   in its [[Own Right]]
    and [[Regular Expressions]]
     as the go-to [[Choice]]
      for [[Text Matching]].
The markup is [[Organized]]
 as a [[Visitor]]
  [[Borrowing]]
   this word from [[Design Patterns]].
This is an [[abstraction]]
 of [[Tree Traversal]]
  where [[Recursion]]
   is the [[Natural Choice]]
    except that we [[Lumped]]
     on this the [[Challenge]]
      of [[Overlapping]]
       [[Network]]
        [[Fetches]]
         using a [[Work]]
          [[Queue]]
           which could [[Easily]]
            be [[Replaced]]
             by [[Async-Await]]
              had that been [[Available]].</pre>")))
 :ACCEPTANCE-FOR-CURRENT-TASK
 ((SOURCE-STORY-ITEMS-PRESERVED T) (SOURCE-STORY-ITEM-IDS-RECORDED T)
  (SOURCE-STORY-ORDER-RECORDED T) (NO-STORY-ITEM-IDS-REWRITTEN T)
  (NO-STORY-ORDER-REWRITTEN T) (NO-GRAPHVIZ-EXECUTED T)
  (NO-FORK-ACTION-CONSTRUCTED T) (NO-LOCAL-PAGE-JSON-WRITTEN T)
  (NO-ASDF-WRITTEN T) (NO-SQLITE-CREATED T) (NO-COMMIT-PERFORMED T))
 :NEXT-TASK
 (!CONSTRUCT-EXPLICIT-FORK-JOURNAL-ACTION :PAGE WHAT-GRAPHVIZ-DOES :TYPE "fork"
  :SITE "does.ward.dojo.fed.wiki" :DATE :EXECUTION-TIME-MONOTONIC-EPOCH-MILLIS))
