;;;; Reading typography of the CCNx Federated Wiki pages: the objects that let one go from a page to a finding about how it is read,
;;;; and from the finding to the change that was made for it.
;;
;; What is modelled, and what is not.
;;
;; A READING-TASK is what a reader does with a passage. A TEXT-UNIT is a place in an existing page: the page object, the id of an element
;; in its parse tree and a kind. It stores no text; the element and its text are read from the page now, so there is no second copy of
;; the page. A LEGIBILITY-CASE is a concrete string and the conditions under which it can be confused or hard to take in. A
;; TYPOGRAPHY-FINDING says which text unit, which problem, which reading task, what change and why. A PRESENTATION-VARIANT is the change:
;; the label of the CSS block (and any page edit) that realises it, before and after screenshots, and the check that was run.
;;
;; Not modelled: the reader's mental template of letter and word forms (Willberg's "Schablone"). It is a hypothesis about readers, not
;; something a browser can show, and nothing here stands for it. A finding records what was seen in a browser (STATUS :BROWSER-OBSERVED)
;; or only supposed (:CONJECTURED), and the grounds for the change are labelled as a design hypothesis of this reading. They are not
;; attributed to Willberg and Forssman: the 1997 Leseforum article was not available when this was written (docs/ccnx-federated-wiki/READING-TYPOGRAPHY.md).

(in-package #:dreyeck/ccnx-federated-wiki)

(defparameter +book-id+ "dreyeck/ccnx-federated-wiki")

(defclass reading-task ()
  ((id :initarg :id :reader reading-task-id-of)
   (name :initarg :name :reader reading-task-name-of)
   (supports :initarg :supports :reader reading-task-supports-of)
   (basis :initarg :basis :reader reading-task-basis-of)))

(defclass text-unit ()
  ((id :initarg :id :reader text-unit-id-of)
   (page-title :initarg :page-title :reader text-unit-page-title-of)
   (element-id :initarg :element-id :reader text-unit-element-id-of)
   (kind :initarg :kind :reader text-unit-kind-of)))

(defclass legibility-case ()
  ((id :initarg :id :reader legibility-case-id-of)
   (unit :initarg :unit :reader legibility-case-unit-of)
   (string :initarg :string :reader legibility-case-string-of)
   (conditions :initarg :conditions :reader legibility-case-conditions-of)
   (status :initarg :status :reader legibility-case-status-of)
   (observation :initarg :observation :reader legibility-case-observation-of)
   (findings :initform nil :accessor legibility-case-findings-of)))

(defclass typography-finding ()
  ((id :initarg :id :reader typography-finding-id-of)
   (unit :initarg :unit :reader typography-finding-unit-of)
   (task :initarg :task :reader typography-finding-task-of)
   (problem :initarg :problem :reader typography-finding-problem-of)
   (status :initarg :status :reader typography-finding-status-of)
   (observation :initarg :observation :reader typography-finding-observation-of)
   (proposal :initarg :proposal :reader typography-finding-proposal-of)
   (rationale :initarg :rationale :reader typography-finding-rationale-of)
   (variants :initform nil :accessor typography-finding-variants-of)
   (cases :initform nil :accessor typography-finding-cases-of)))

(defclass presentation-variant ()
  ((id :initarg :id :reader presentation-variant-id-of)
   (finding :initarg :finding :reader presentation-variant-finding-of)
   (change :initarg :change :reader presentation-variant-change-of)
   (css-label :initarg :css-label :reader presentation-variant-css-label-of)
   (before :initarg :before :reader presentation-variant-before-of)
   (after :initarg :after :reader presentation-variant-after-of)
   (check :initarg :check :reader presentation-variant-check-of)))

;;; Text units resolve against the existing page objects.

(defun %reading-book () (hyperbook:find-hyperbook +book-id+ :signal-error? t))

(defun text-unit-page-of (unit)
  (hyperbook:find-page (%reading-book) (text-unit-page-title-of unit) :signal-error? t))

(defun text-unit-element-of (unit)
  "The element of the page's parse tree this unit stands for, read now. An error if the page has no element with that id."
  (let ((page (text-unit-page-of unit)))
    (hyperdoc::ensure-pages-loaded (%reading-book))
    (or (plump:get-element-by-id (hyperbook::dom-of page) (text-unit-element-id-of unit))
        (error "Page ~S has no element with id ~S." (text-unit-page-title-of unit) (text-unit-element-id-of unit)))))

(defun text-unit-text-of (unit)
  (string-trim '(#\Space #\Newline #\Tab) (plump:text (text-unit-element-of unit))))

;;; The data. A finding is stated as an observation first; STATUS says whether a browser showed it. Grounds are a design hypothesis of
;;; this reading, in the words of the reader's task, never a statement about what a reader's mind does.

(defparameter +reading-task-data+
  '((:continuous "Continuous reading" "following a passage line by line to its end"
     "Design vocabulary of this reading. Whether and how it corresponds to the kinds of reading (Lesearten) in Willberg and Forssman, Lesetypografie, has not been checked against the book.")
    (:orienting "Orienting" "finding out what a page is about and where its parts are, by headings and lead-ins"
     "Design vocabulary of this reading; see above.")
    (:process "Following a process" "taking one step after another in the order they happen"
     "Design vocabulary of this reading; see above.")
    (:comparing "Comparing" "holding two or more things side by side and seeing what differs"
     "Design vocabulary of this reading; see above.")
    (:looking-up "Looking up" "going straight to one item, name or source reference and finding it again"
     "Design vocabulary of this reading; see above."))
  "(id name supports basis)")

(defparameter +typography-data+
  '((:id "F-MEASURE" :page "Plain Text After CCNx" :element "c2-assertion" :kind :paragraph :task :continuous :status :browser-observed
     :problem "Running text had no limit on its measure: in a 700 px pane the longest paragraph set 80 characters per line, others 44 to 64."
     :observation "before-metrics.json, paragraph.charsPerLine: 80 on this page, 53 to 64 on the others, at 700 px; 44 to 57 at 479 px."
     :proposal "Limit running text (paragraphs, lists) to 38 em."
     :rationale "Design hypothesis: a shorter, steadier measure helps a reader keep the line they are on during continuous reading. Not tested with readers.")
    (:id "F-LEADING" :page "Identity, Versions and Signatures" :element "publisher-digest" :kind :paragraph :task :continuous :status :browser-observed
     :problem "Line height was the browser's 'normal' (about 1.15) in paragraphs of up to nine lines that carry inline code."
     :observation "before-metrics.json, paragraph.style.lineHeight: normal; inline code of another face sits in the same lines."
     :proposal "Line height 1.5 for the reading."
     :rationale "Design hypothesis: more room between lines separates the lines of a dense technical paragraph and keeps the code face from touching the line above. Not tested with readers.")
    (:id "F-HIERARCHY" :page "Reading the CCNx Federated Wiki" :element "kinds-of-statement" :kind :heading :task :orienting :status :browser-observed
     :problem "Heading levels h1, h2 and h3 differed by 1.2 px (20.8, 19.2, 17.6 px) and by bold only; the page's structure was hard to take in at a glance."
     :observation "before-metrics.json, h1/h2/h3 fontSize."
     :proposal "A clear size step between levels, space above each heading, and a rule above h2."
     :rationale "Design hypothesis: orientation needs levels that can be told apart without reading them.")
    (:id "F-IDENTIFIERS" :page "One Page From Browser to NDN and Back" :element "example-ids" :kind :paragraph :task :looking-up :status :browser-observed
     :problem "Identifiers were set in the generic 'monospace' at 13 px next to 16 px text; in the running-text face I, l and 1 were not clearly different."
     :observation "before-specimen.json and before-specimen.png: body face Liberation Sans, code face DejaVu Sans Mono at 13 px. In this Chromium on Linux the capital I and the small l of the body face are not clearly different; in the code face they are."
     :proposal "A monospace stack that prefers faces with a distinct I, l, 1 and 0 (ui-monospace, SF Mono, Menlo, Consolas, DejaVu Sans Mono), at 0.9 em, with a light background."
     :rationale "Design hypothesis: an identifier is recognised as a token and compared character by character, so the letters must differ. Fonts differ by machine (the Inspector's 'Noto Sans' was not installed here): the observation holds for this browser and font set only.")
    (:id "F-BREAKS" :page "Reading the CCNx Federated Wiki" :element "source-report-pointer" :kind :paragraph :task :looking-up :status :browser-observed
     :problem "Short identifiers were split across lines at hyphens and slashes (docs/ccnx-federated-wiki/SOURCE-REPORT.md, ccnx-example.invalid, how-to-wiki)."
     :observation "before-metrics.json, inlineCodeBrokenAcrossLines, listed per page."
     :proposal "Inline code does not wrap unless it is long (over 28 characters) or holds spaces; long strings may break and breaking does not change the text."
     :rationale "Design hypothesis: a name broken at a hyphen reads as two names.")
    (:id "F-SOURCE-REFERENCES" :page "One Page From Browser to NDN and Back" :element "prototype-differences" :kind :list :task :looking-up :status :browser-observed
     :problem "A source reference such as 'pageHandler.coffee L22-L78' broke after the dash, so the line range was cut in two."
     :observation "before-one-page-from-browser-to-ndn-and-back-wide.png, 'How the Prototype differs', first item."
     :proposal "Source references do not wrap and are set in the identifier face."
     :rationale "Design hypothesis: a reference is looked up as one token (file and range).")
    (:id "F-STEPS" :page "One Page From Browser to NDN and Back" :element "path-in-main" :kind :list :task :process :status :browser-observed
     :problem "The eight steps were a four-column table set without wrapping: 2046 px wide in a 698 px body, so the column with the source lines was out of sight and the pane scrolled sideways."
     :observation "before-metrics.json: the path table 2046 px and the identity page's 'Signatures: checked' table 2474 px, in a body 698 px wide (477 px narrow); bodyScrollWidth 2051 and 2479."
     :proposal "A numbered list: the step and what happens, with the source lines on a line of their own."
     :rationale "A sequence is not a comparison: it has no columns to compare, so a list serves following it. Design hypothesis, not tested with readers.")
    (:id "F-TABLES" :page "Identity, Versions and Signatures" :element "one-table" :kind :table :task :comparing :status :browser-observed
     :problem "The comparison tables were set without wrapping (the Inspector's table style): wider than the pane at both widths, header text in light grey (#aaa)."
     :observation "before-metrics.json: all 10 tables of the four pages were wider than the 698 px body (797 to 2474 px), whiteSpace nowrap."
     :proposal "Tables that really compare keep their columns, wrap, have dark headers with a rule, and scroll inside their own box if they still do not fit."
     :rationale "Design hypothesis: a comparison is read across rows, so the columns have to stay visible together.")
    (:id "F-FIELD-LISTS" :page "One Page From Browser to NDN and Back" :element "content-object-main" :kind :definition-list :task :looking-up :status :browser-observed
     :problem "Two aligned <pre> blocks ran past the pane (a 64-character digest in one line) and scrolled the whole pane."
     :observation "before-metrics.json, pres[].scrollWidth greater than clientWidth, both pre blocks, at both widths."
     :proposal "Field lists (name, value), nested lists stacked, values wrapping."
     :rationale "Name and value pairs are looked up by name; alignment by spaces does not survive a narrow pane.")
    (:id "F-EVIDENCE" :page "Reading the CCNx Federated Wiki" :element "kinds-of-statement" :kind :list :task :orienting :status :browser-observed
     :problem "The kinds of statement were marked three ways (bold lead-in, italic in parentheses, italic lead-in) and one of them, 'Derived, not run', was not explained where the kinds are listed."
     :observation "before: main-before.html, 'Three kinds of statement' lists three; the other pages and the answers use 'Derived, not run'."
     :proposal "One label per kind, in words, distinguishable in monochrome by outline; 'Derived, not run' defined; the answer about signatures says what is implemented and drops the ambiguous 'does run'."
     :rationale "Design hypothesis: a reader who sorts statements by kind needs the same mark for the same kind. The wording change is an editorial correction recorded in the report.")
    (:id "F-REFERENCES" :page "Reading the CCNx Federated Wiki" :element "reading-order" :kind :list :task :orienting :status :conjectured
     :problem "Inspector references to pages were underlined but black, like running text; external links were blue with an icon."
     :observation "before-metrics.json, linkStyles: black underlined for references, blue underlined for links. Whether readers miss them as links was not observed."
     :proposal "A dark blue, thin underline for Inspector references; external links unchanged."
     :rationale "Design hypothesis: a reference should look like a link without looking like an external one.")))

(defparameter +legibility-data+
  '((:id "L-IL1" :page "One Page From Browser to NDN and Back" :element "example-ids" :kind :inline-code :string "a1b2c3d4e5f60001"
     :conditions "item id of the example; digits 1 and 0 next to letters; running-text face Liberation Sans (this machine), code face DejaVu Sans Mono 13 px before, 14.4 px after"
     :status :browser-observed :observation "specimen: 'Il1 O0' in both faces, before/after-specimen.png" :findings ("F-IDENTIFIERS"))
    (:id "L-ZEROS" :page "One Page From Browser to NDN and Back" :element "added-fields" :kind :table :string "1700000000004"
     :conditions "a run of ten zeros, no grouping; monospace; the digits cannot be grouped without changing the text"
     :status :conjectured :observation "not observed with readers; counting the zeros by eye is supposed to be error-prone" :findings ("F-IDENTIFIERS"))
    (:id "L-BREAK-HYPHEN" :page "Reading the CCNx Federated Wiki" :element "source-report-pointer" :kind :inline-code :string "docs/ccnx-federated-wiki/SOURCE-REPORT.md"
     :conditions "a path of 41 characters at the pane edge; breaks are allowed after / and -"
     :status :browser-observed :observation "before-metrics.json, inlineCodeBrokenAcrossLines of the main page at both widths" :findings ("F-BREAKS"))
    (:id "L-DIGEST" :page "Identity, Versions and Signatures" :element "publisher-digest" :kind :inline-code
     :string "b5506b1aba3da7761b0f8d61a4aa7e3b6d15b426feb5bda82389aca765a3b81c"
     :conditions "64 hexadecimal characters; in a 479 px pane longer than a line, so it breaks inside when it must"
     :status :browser-observed :observation "before: it widened the pane (bodyScrollWidth 2479); after: it breaks inside, without a change to the text" :findings ("F-BREAKS" "F-FIELD-LISTS"))))

(defparameter +variant-data+
  '((:finding "F-MEASURE" :change "reading.css: max-width 38em for p, ul, ol, dl" :css "F-MEASURE, F-LEADING" :check "no line of running text longer than the limit; recorded in after-metrics.json, paragraph.charsPerLine")
    (:finding "F-LEADING" :change "reading.css: line-height 1.5" :css "F-MEASURE, F-LEADING" :check "computed line height in the browser, after-metrics.json")
    (:finding "F-HIERARCHY" :change "reading.css: h1 1.55 em, h2 1.28 em with a rule, h3 1.05 em; space above" :css "F-HIERARCHY" :check "computed sizes differ by level, after-metrics.json")
    (:finding "F-IDENTIFIERS" :change "reading.css: identifier face stack, 0.9 em, light background, slashed zero where the face has it" :css "F-IDENTIFIERS" :check "code font computed in the browser; specimen after-specimen.png")
    (:finding "F-BREAKS" :change "reading.css: code does not wrap; code.wrap (HTML class, long or spaced strings) may; wbr after slashes in table cells" :css "F-IDENTIFIERS" :check "no inline code without class wrap is split across lines at 700 px and 479 px")
    (:finding "F-SOURCE-REFERENCES" :change "reading.css: a[href*=github.com] nowrap, identifier face" :css "F-SOURCE-REFERENCES" :check "no source link is split across lines")
    (:finding "F-STEPS" :change "HTML: ol.steps for the path and for 'Signatures: checked'; reading.css block F-STEPS" :css "F-STEPS" :check "no horizontal scroll of the pane at 700 px and 479 px")
    (:finding "F-TABLES" :change "HTML: div.table-scroll around each table; reading.css block F-TABLES" :css "F-TABLES" :check "no table wider than the pane unless it sits in a scrolling wrapper; pane does not scroll sideways")
    (:finding "F-FIELD-LISTS" :change "HTML: dl.fields instead of pre; reading.css block F-FIELD-LISTS" :css "F-FIELD-LISTS" :check "no pre left; pane does not scroll sideways; the digest text is unchanged")
    (:finding "F-EVIDENCE" :change "HTML: span.ev labels, 'Four kinds of statement', answer 5 reworded; reading.css block F-EVIDENCE" :css "F-EVIDENCE" :check "each kind used on the pages is defined on the main page; page and example links still open the right objects")
    (:finding "F-REFERENCES" :change "reading.css block F-REFERENCES" :css "F-REFERENCES" :check "page and expression links open the same targets as before")))

(defvar *typography-model* nil)

(defun reset-typography-model () (setf *typography-model* nil))

(defun %build-typography-model ()
  (let* ((tasks (loop for (id name supports basis) in +reading-task-data+
                      collect (make-instance 'reading-task :id id :name name :supports supports :basis basis)))
         (units (make-hash-table :test #'equal))
         (findings '()) (cases '()) (variants '()))
    (flet ((unit (page element kind)
             (let ((key (list page element)))
               (or (gethash key units)
                   (setf (gethash key units)
                         (make-instance 'text-unit :id (format nil "~A#~A" page element) :page-title page :element-id element :kind kind)))))
           (task (id) (or (find id tasks :key #'reading-task-id-of) (error "No reading task ~S." id))))
      (dolist (d +typography-data+)
        (push (make-instance 'typography-finding
                             :id (getf d :id) :unit (unit (getf d :page) (getf d :element) (getf d :kind)) :task (task (getf d :task))
                             :problem (getf d :problem) :status (getf d :status) :observation (getf d :observation)
                             :proposal (getf d :proposal) :rationale (getf d :rationale))
              findings))
      (setf findings (nreverse findings))
      (dolist (d +legibility-data+)
        (let ((case (make-instance 'legibility-case
                                   :id (getf d :id) :unit (unit (getf d :page) (getf d :element) (getf d :kind)) :string (getf d :string)
                                   :conditions (getf d :conditions) :status (getf d :status) :observation (getf d :observation))))
          (dolist (id (getf d :findings))
            (let ((finding (or (find id findings :key #'typography-finding-id-of) (error "No finding ~S." id))))
              (push finding (legibility-case-findings-of case))
              (push case (typography-finding-cases-of finding))))
          (setf (legibility-case-findings-of case) (reverse (legibility-case-findings-of case)))
          (push case cases)))
      (setf cases (nreverse cases))
      (dolist (d +variant-data+)
        (let* ((finding (or (find (getf d :finding) findings :key #'typography-finding-id-of) (error "No finding ~S." (getf d :finding))))
               (id (format nil "V-~A" (getf d :finding)))
               (variant (make-instance 'presentation-variant
                                       :id id :finding finding :change (getf d :change) :css-label (getf d :css)
                                       :before (format nil "evidence/typography/before/~A" (getf d :finding))
                                       :after (format nil "evidence/typography/after/~A" (getf d :finding))
                                       :check (getf d :check))))
          (push variant (typography-finding-variants-of finding))
          (push variant variants)))
      (setf variants (nreverse variants))
      (dolist (f findings) (setf (typography-finding-cases-of f) (reverse (typography-finding-cases-of f))))
      (list :tasks tasks :units (loop for u being the hash-values of units collect u) :cases cases :findings findings :variants variants))))

(defun typography-model ()
  (or *typography-model* (setf *typography-model* (%build-typography-model))))

(defun reading-tasks () (getf (typography-model) :tasks))
(defun text-units () (getf (typography-model) :units))
(defun legibility-cases () (getf (typography-model) :cases))
(defun presentation-variants () (getf (typography-model) :variants))

(defun typography-findings (&optional page)
  "All findings, or those whose text unit lies in PAGE (a page object of this book)."
  (let ((all (getf (typography-model) :findings)))
    (if page
        (remove-if-not (lambda (f) (equal (text-unit-page-title-of (typography-finding-unit-of f)) (hyperbook:title-of page))) all)
        all)))

(defun typography-finding-named (id)
  (or (find id (typography-findings) :key #'typography-finding-id-of :test #'equal) (error "No typography finding ~S." id)))
