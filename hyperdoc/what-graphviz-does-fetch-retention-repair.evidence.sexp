(:TASK
 (!REPAIR-FETCH-RESULT-RETENTION-FOR-STORY-SHAPE-VALIDATION WHAT-GRAPHVIZ-DOES)
 :PARENT-TASK (!DIAGNOSE-FETCH-EVIDENCE-RETENTION WHAT-GRAPHVIZ-DOES)
 :STAGE-BOUNDARY
 ((MAY-REFETCH-REMOTE-PAGE-JSON-FOR-RETENTION-REPAIR T)
  (MAY-RETAIN-LIVE-PAGE-JSON-VARIABLE T)
  (MAY-WRITE-READABLE-FETCH-RETENTION-EVIDENCE T)
  (MAY-CONSTRUCT-FORK-JOURNAL-ACTION NIL)
  (MAY-WRITE-LOCAL-PAGE-JSON-AS-FORK NIL) (MAY-LOAD-MISSING-SOURCE-FILES NIL)
  (MAY-WRITE-PAGE-ATTACHED-ASDF NIL) (MAY-CREATE-SQLITE NIL) (MAY-COMMIT NIL))
 :REPAIR-REASON
 "Previous fetch evidence contained unreadable #<HASH-TABLE ...> printed data and no retained *WGD-REMOTE-PAGE-JSON* variable."
 :FETCH-ROUTE :EXISTING-FETCH-PAGE-JSON-OPERATOR :FETCH-OPERATOR
 #A((34) BASE-CHAR . "HYPERBOOK/FEDWIKI::FETCH-PAGE-JSON") :RETAINED-BINDINGS
 ((*WGD-REMOTE-PAGE-JSON* :LIVE-PAGE-OBJECT)
  (*WGD-REMOTE-PAGE-JSON-READABLE* :READABLE-NORMALIZED-COPY))
 :PAGE-SUMMARY
 (:TITLE #1="What Graphviz Does" :TITLE-MATCHES-EXPECTED-P T :STORY-COUNT 3
  :JOURNAL-COUNT 12 :SOURCE-JOURNAL-LAST-DATE 1783522915032
  :ALL-STORY-ITEMS-HAVE-IDS-P T :ALL-STORY-ITEMS-HAVE-TYPES-P T
  :STORY-ITEMS-SUMMARY
  ((:INDEX 0 :ID #2="c558c39c83b0a0b9" :TYPE #3="paragraph" :TEXT-PRESENT-P T
    :HAS-ID-P T :HAS-TYPE-P T)
   (:INDEX 1 :ID #4="34e2de627fb48408" :TYPE #5="paragraph" :TEXT-PRESENT-P T
    :HAS-ID-P T :HAS-TYPE-P T)
   (:INDEX 2 :ID #6="6f9382b76ff19154" :TYPE #7="html" :TEXT-PRESENT-P T
    :HAS-ID-P T :HAS-TYPE-P T))
  :RETENTION-VALID-P T)
 :READABLE-PAGE-JSON
 (:OBJECT
  (("title" . #1#)
   ("story" :ARRAY
    ((:OBJECT
      (("type" . #3#) ("id" . #2#)
       ("text"
        . "We describe the Graphviz plugin's algorithmic markup in one paragraph. Then break this down by jargon words.")))
     (:OBJECT
      (("type" . #5#) ("id" . #4#)
       ("text"
        . "The Graphviz plugin is a mashup of many bits of technology wrapped up in a block-structured markup inspired by python's whitespace rules. It merges this with DOT which is rich in its own right and Regular Expressions as the go-to choice for text matching. The markup is organized as a Visitor borrowing this word from Design Patterns. This is an abstraction of tree traversal where recursion is the natural choice except that we lumped on this the challenge of overlapping network fetches using a work queue which could easily be replaced by async-await had that been available.")))
     (:OBJECT
      (("type" . #7#) ("id" . #6#)
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
              had that been [[Available]].</pre>")))))
   ("journal" :ARRAY
    ((:OBJECT
      (("type" . "create")
       ("item" :OBJECT (("title" . "What Graphviz Does") ("story" :ARRAY NIL)))
       ("date" . 1783377976152)))
     (:OBJECT
      (("item" :OBJECT (("type" . "factory") ("id" . "c558c39c83b0a0b9")))
       ("id" . "c558c39c83b0a0b9") ("type" . "add") ("date" . 1783377977913)))
     (:OBJECT
      (("type" . "edit") ("id" . "c558c39c83b0a0b9")
       ("item" :OBJECT
        (("type" . "paragraph") ("id" . "c558c39c83b0a0b9")
         ("text"
          . "We describe the Graphviz plugin's algorithmic markup in one paragraph. The break this down by jargon words.")))
       ("date" . 1783378016941)))
     (:OBJECT
      (("id" . "34e2de627fb48408") ("type" . "add")
       ("item" :OBJECT
        (("type" . "paragraph") ("id" . "34e2de627fb48408")
         ("text"
          . "The Graphviz plugin is a mashup of many bits of technology wrapped up in a block-structured markup inspired by python's whitespace rules. It merges this with DOT which is rich in its own right and Regular Expressions as the go-to choice for text matching. The markup is organized as a Visitor borrowing this word from Design Patterns. This is an abstraction of tree traversal where recursion is the natural choice except that we lumped on this the challenge of overlapping network fetches using a work queue which could easily be replaced by async-await had that been available.")))
       ("after" . "c558c39c83b0a0b9")
       ("attribution" :OBJECT (("page" . "Ward Cunningham")))
       ("date" . 1783378024683)))
     (:OBJECT
      (("item" :OBJECT (("type" . "factory") ("id" . "6f9382b76ff19154")))
       ("id" . "6f9382b76ff19154") ("type" . "add")
       ("after" . "34e2de627fb48408") ("date" . 1783378050406)))
     (:OBJECT
      (("type" . "edit") ("id" . "6f9382b76ff19154")
       ("item" :OBJECT
        (("type" . "code") ("id" . "6f9382b76ff19154")
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
")))
       ("date" . 1783378057658)))
     (:OBJECT
      (("type" . "edit") ("id" . "6f9382b76ff19154")
       ("item" :OBJECT
        (("type" . "factory") ("id" . "6f9382b76ff19154")
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
")))
       ("date" . 1783378094754)))
     (:OBJECT
      (("type" . "edit") ("id" . "6f9382b76ff19154")
       ("item" :OBJECT
        (("type" . "html") ("id" . "6f9382b76ff19154")
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
")))
       ("date" . 1783378151260)))
     (:OBJECT
      (("type" . "edit") ("id" . "6f9382b76ff19154")
       ("item" :OBJECT
        (("type" . "html") ("id" . "6f9382b76ff19154")
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
              had that been [[Available]].</pre>")))
       ("date" . 1783378925592)))
     (:OBJECT
      (("type" . "edit") ("id" . "6f9382b76ff19154")
       ("item" :OBJECT
        (("type" . "html") ("id" . "6f9382b76ff19154")
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
              had that been [[Available]].</pre>")))
       ("date" . 1783380790441)))
     (:OBJECT
      (("type" . "edit") ("id" . "6f9382b76ff19154")
       ("item" :OBJECT
        (("type" . "html") ("id" . "6f9382b76ff19154")
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
       ("date" . 1783472116151)))
     (:OBJECT
      (("type" . "edit") ("id" . "c558c39c83b0a0b9")
       ("item" :OBJECT
        (("type" . "paragraph") ("id" . "c558c39c83b0a0b9")
         ("text"
          . "We describe the Graphviz plugin's algorithmic markup in one paragraph. Then break this down by jargon words.")))
       ("date" . 1783522915032)))))))
 :ACCEPTANCE-FOR-CURRENT-TASK
 ((RETENTION-REPAIR-FETCH-PERFORMED T)
  (REMOTE-PAGE-JSON-RETAINED-IN-LIVE-VARIABLE T)
  (READABLE-PAGE-JSON-RETAINED T) (READABLE-EVIDENCE-ARTIFACT-WRITTEN T)
  (RETENTION-VALID-FOR-STORY-SHAPE-VALIDATION T) (NO-FORK-ACTION-CONSTRUCTED T)
  (NO-LOCAL-PAGE-JSON-WRITTEN T) (NO-ASDF-WRITTEN T) (NO-SQLITE-CREATED T)
  (NO-COMMIT-PERFORMED T))
 :NEXT-TASK
 (!VALIDATE-REMOTE-PAGE-STORY-SHAPE-FROM-RETAINED-JSON WHAT-GRAPHVIZ-DOES))
