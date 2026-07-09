(:TASK
 (!ADAPT-FEDWIKI-MATERIALIZATION-ENTRY-FOR-REMOTE-FORK-PAGE WHAT-GRAPHVIZ-DOES)
 :PARENT-TASK
 (!RETAIN-HYPERDOC-ONLY-FORK-PROVENANCE :PAGE WHAT-GRAPHVIZ-DOES :SOURCE-SLUG
  "what-graphviz-does" :TARGET-SITE "wiki.ralfbarkow.ch" :TARGET-SLUG
  "what-graphviz-does")
 :STAGE-BOUNDARY
 ((MAY-ADAPT-FEDWIKI-MATERIALIZATION-ENTRY-FOR-REMOTE-FORK-PAGE T)
  (MAY-RETAIN-LOCAL-FORK-PAGE-CANDIDATE T)
  (MAY-WRITE-ADAPTATION-EVIDENCE-ARTIFACT T) (MAY-REFETCH-REMOTE-PAGE-JSON NIL)
  (MAY-CONSTRUCT-FORK-JOURNAL-ACTION NIL)
  (MAY-WRITE-LOCAL-PAGE-JSON-AS-FORK NIL) (MAY-LOAD-MISSING-SOURCE-FILES NIL)
  (MAY-WRITE-PAGE-ATTACHED-ASDF NIL) (MAY-CREATE-SQLITE NIL) (MAY-COMMIT NIL))
 :SOURCE-PAGE-SUMMARY
 (:TITLE #1="What Graphviz Does" :STORY-ITEM-IDS
  (#2="c558c39c83b0a0b9" #3="34e2de627fb48408" #4="6f9382b76ff19154")
  :JOURNAL-COUNT 12)
 :LOCAL-FORK-PAGE-CANDIDATE-SUMMARY
 (:TITLE #1# :STORY-ITEM-IDS (#2# #3# #4#) :JOURNAL-COUNT 13
  :LAST-JOURNAL-ACTION
  ((#5="type" . #6="fork") (#7="site" . #8="does.ward.dojo.fed.wiki")
   (#9="date" . 1783525442000))
  :STORY-PRESERVED-P T :JOURNAL-COUNT-VALID-P T :FORK-ACTION-APPENDED-P T
  :CANONICAL-PAGE-CLEAN-P T :ADAPTATION-VALID-P T)
 :MATERIALIZATION-ENTRY
 (:PAGE :WHAT-GRAPHVIZ-DOES :TARGET-SITE "wiki.ralfbarkow.ch" :TARGET-SLUG
  "what-graphviz-does" :TARGET-PAGE-FILE
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/what-graphviz-does"
  :CANONICAL-PAGE-JSON-VARIABLE *WGD-LOCAL-FORK-PAGE-JSON-CANDIDATE*
  :CANONICAL-READABLE-PAGE-JSON-VARIABLE *WGD-LOCAL-FORK-PAGE-JSON-READABLE*
  :WRITE-POLICY
  (:WRITE-LOCAL-PAGE-JSON NIL :WRITE-PAGE-ATTACHED-ASDF NIL :CREATE-SQLITE NIL
   :COMMIT NIL))
 :READABLE-LOCAL-FORK-PAGE-JSON
 (("title" . #1#)
  ("story"
   (("type" . "paragraph") ("id" . #2#)
    ("text"
     . "We describe the Graphviz plugin's algorithmic markup in one paragraph. Then break this down by jargon words."))
   (("type" . "paragraph") ("id" . #3#)
    ("text"
     . "The Graphviz plugin is a mashup of many bits of technology wrapped up in a block-structured markup inspired by python's whitespace rules. It merges this with DOT which is rich in its own right and Regular Expressions as the go-to choice for text matching. The markup is organized as a Visitor borrowing this word from Design Patterns. This is an abstraction of tree traversal where recursion is the natural choice except that we lumped on this the challenge of overlapping network fetches using a work queue which could easily be replaced by async-await had that been available."))
   (("type" . "html") ("id" . #4#)
    ("text" . "<pre>The Graphviz [[Plugin]]
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
  ("journal"
   (("type" . "create") ("item" ("title" . "What Graphviz Does") ("story"))
    ("date" . 1783377976152))
   (("item" ("type" . "factory") ("id" . "c558c39c83b0a0b9"))
    ("id" . "c558c39c83b0a0b9") ("type" . "add") ("date" . 1783377977913))
   (("type" . "edit") ("id" . "c558c39c83b0a0b9")
    ("item" ("type" . "paragraph") ("id" . "c558c39c83b0a0b9")
     ("text"
      . "We describe the Graphviz plugin's algorithmic markup in one paragraph. The break this down by jargon words."))
    ("date" . 1783378016941))
   (("id" . "34e2de627fb48408") ("type" . "add")
    ("item" ("type" . "paragraph") ("id" . "34e2de627fb48408")
     ("text"
      . "The Graphviz plugin is a mashup of many bits of technology wrapped up in a block-structured markup inspired by python's whitespace rules. It merges this with DOT which is rich in its own right and Regular Expressions as the go-to choice for text matching. The markup is organized as a Visitor borrowing this word from Design Patterns. This is an abstraction of tree traversal where recursion is the natural choice except that we lumped on this the challenge of overlapping network fetches using a work queue which could easily be replaced by async-await had that been available."))
    ("after" . "c558c39c83b0a0b9") ("attribution" ("page" . "Ward Cunningham"))
    ("date" . 1783378024683))
   (("item" ("type" . "factory") ("id" . "6f9382b76ff19154"))
    ("id" . "6f9382b76ff19154") ("type" . "add") ("after" . "34e2de627fb48408")
    ("date" . 1783378050406))
   (("type" . "edit") ("id" . "6f9382b76ff19154")
    ("item" ("type" . "code") ("id" . "6f9382b76ff19154")
     ("text" . "The Graphviz plugin
 is a mashup
  of many bits
   of technology
    wrapped up in a block-structured
     markup
      inspired by python's
       whitespace
        rules.
It merges
 this with DOT
  which is rich
   in its own right
    and Regular Expressions
     as the go-to choice for text matching.
The markup is organized
 as a Visitor
  borrowing
   this word from Design Patterns.
This is an abstraction
 of tree traversal
  where recursion
   is the natural choice
    except that we lumped
     on this the challenge
      of overlapping
       network
        fetches
         using a work
          queue
           which could easily
            be replaced
             by async-await
              had that been available.
"))
    ("date" . 1783378057658))
   (("type" . "edit") ("id" . "6f9382b76ff19154")
    ("item" ("type" . "factory") ("id" . "6f9382b76ff19154")
     ("text" . "<pre>The Graphviz plugin
 is a mashup
  of many bits
   of technology
    wrapped up in a block-structured
     markup
      inspired by python's
       whitespace
        rules.
It merges
 this with DOT
  which is rich
   in its own right
    and Regular Expressions
     as the go-to choice for text matching.
The markup is organized
 as a Visitor
  borrowing
   this word from Design Patterns.
This is an abstraction
 of tree traversal
  where recursion
   is the natural choice
    except that we lumped
     on this the challenge
      of overlapping
       network
        fetches
         using a work
          queue
           which could easily
            be replaced
             by async-await
              had that been available.
"))
    ("date" . 1783378094754))
   (("type" . "edit") ("id" . "6f9382b76ff19154")
    ("item" ("type" . "html") ("id" . "6f9382b76ff19154")
     ("text" . "<pre>The Graphviz [[Plugin]]
 is a mashup
  of many bits
   of technology
    wrapped up in a block-structured
     markup
      inspired by python's
       whitespace
        rules.
It merges
 this with DOT
  which is rich
   in its own right
    and Regular Expressions
     as the go-to choice for text matching.
The markup is organized
 as a Visitor
  borrowing
   this word from Design Patterns.
This is an abstraction
 of tree traversal
  where recursion
   is the natural choice
    except that we lumped
     on this the challenge
      of overlapping
       network
        fetches
         using a work
          queue
           which could easily
            be replaced
             by async-await
              had that been available.
"))
    ("date" . 1783378151260))
   (("type" . "edit") ("id" . "6f9382b76ff19154")
    ("item" ("type" . "html") ("id" . "6f9382b76ff19154")
     ("text" . "<pre>The Graphviz [[[Plugin]]]]
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
          [[Eueue]]
           which could [[Easily]]
            be [[Replaced]]
             by [[Async-Await]]
              had that been [[Available]].</pre>"))
    ("date" . 1783378925592))
   (("type" . "edit") ("id" . "6f9382b76ff19154")
    ("item" ("type" . "html") ("id" . "6f9382b76ff19154")
     ("text" . "<pre>The Graphviz [[Plugin]]
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
          [[Eueue]]
           which could [[Easily]]
            be [[Replaced]]
             by [[Async-Await]]
              had that been [[Available]].</pre>"))
    ("date" . 1783380790441))
   (("type" . "edit") ("id" . "6f9382b76ff19154")
    ("item" ("type" . "html") ("id" . "6f9382b76ff19154")
     ("text" . "<pre>The Graphviz [[Plugin]]
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
              had that been [[Available]].</pre>"))
    ("date" . 1783472116151))
   (("type" . "edit") ("id" . "c558c39c83b0a0b9")
    ("item" ("type" . "paragraph") ("id" . "c558c39c83b0a0b9")
     ("text"
      . "We describe the Graphviz plugin's algorithmic markup in one paragraph. Then break this down by jargon words."))
    ("date" . 1783522915032))
   ((#5# . #6#) (#7# . #8#) (#9# . 1783525442000))))
 :ACCEPTANCE-FOR-CURRENT-TASK
 ((LOCAL-FORK-PAGE-CANDIDATE-CONSTRUCTED T) (SOURCE-STORY-ITEM-IDS-PRESERVED T)
  (SOURCE-STORY-ORDER-PRESERVED T)
  (SOURCE-JOURNAL-PRESERVED-WITH-FORK-ACTION-APPENDED T)
  (CANONICAL-FORK-ACTION-APPENDED T)
  (HYPERDOC-ONLY-PROVENANCE-NOT-IN-CANONICAL-PAGE-JSON T)
  (NO-LOCAL-PAGE-JSON-WRITTEN T) (NO-ASDF-WRITTEN T) (NO-SQLITE-CREATED T)
  (NO-COMMIT-PERFORMED T))
 :NEXT-TASK (!WRITE-REMOTE-FORK-MATERIALIZATION-ENTRY WHAT-GRAPHVIZ-DOES))
