;;;; SHOP3 manual topic extraction for the optional HyperDoc SHOP3 planning layer
;;;
;;;; This file intentionally contains a small, local HTML-fragment parser.  It is
;;;; for copied manual fragments such as https://shop-planner.github.io/#Introduction,
;;;; not for network fetching and not for general browser-grade HTML parsing.

(in-package #:dreyeck/shop3)

(defparameter *shop3-introduction-source-url*
  "https://shop-planner.github.io/#Introduction")

(defun %replace-all-strings (string replacements)
  (let ((result string))
    (dolist (pair replacements result)
      (let ((old (car pair))
            (new (cdr pair)))
        (setf result
              (with-output-to-string (out)
                (loop with start = 0
                      for pos = (search old result
                                        :start2 start
                                        :test #'char-equal)
                      do (if pos
                             (progn
                               (write-string result out
                                             :start start
                                             :end pos)
                               (write-string new out)
                               (setf start (+ pos (length old))))
                             (progn
                               (write-string result out
                                             :start start)
                               (return))))))))))

(defun %html-decode-basic (string)
  (%replace-all-strings
   string
   '(("&nbsp;" . " ")
     ("&amp;" . "&")
     ("&lt;" . "<")
     ("&gt;" . ">")
     ("&quot;" . "\"")
     ("&#39;" . "'")
     ("&rsquo;" . "'")
     ("&lsquo;" . "'")
     ("&ldquo;" . "\"")
     ("&rdquo;" . "\"")
     ("<small>" . "")
     ("</small>" . ""))))

(defun %whitespace-char-p (char)
  (member char '(#\Space #\Tab #\Newline #\Return #\Page)
          :test #'char=))

(defun %collapse-whitespace (string)
  (with-output-to-string (out)
    (loop with previous-space? = t
          for char across string
          do (cond
               ((%whitespace-char-p char)
                (unless previous-space?
                  (write-char #\Space out))
                (setf previous-space? t))
               (t
                (write-char char out)
                (setf previous-space? nil))))))

(defun %strip-html-tags (string)
  (%collapse-whitespace
   (%html-decode-basic
    (with-output-to-string (out)
      (loop with inside-tag? = nil
            for char across string
            do (cond
                 ((char= char #\<)
                  (setf inside-tag? t)
                  (write-char #\Space out))
                 ((char= char #\>)
                  (setf inside-tag? nil)
                  (write-char #\Space out))
                 ((not inside-tag?)
                  (write-char char out))))))))

(defun %blank-string-p (string)
  (every #'%whitespace-char-p string))

(defun %html-element-contents (tag html)
  (let ((results '())
        (position 0)
        (start-token (format nil "<~A" tag))
        (end-token (format nil "</~A>" tag)))
    (loop
      for start = (search start-token html
                          :start2 position
                          :test #'char-equal)
      while start
      for open-end = (position #\> html :start start)
      while open-end
      for content-start = (1+ open-end)
      for end = (search end-token html
                        :start2 content-start
                        :test #'char-equal)
      while end
      do (push (subseq html content-start end) results)
         (setf position (+ end (length end-token))))
    (nreverse results)))

(defun %text-of-html-elements (tag html)
  (remove-if #'%blank-string-p
             (mapcar #'%strip-html-tags
                     (%html-element-contents tag html))))

(defun %slugify (string)
  (let ((raw
          (with-output-to-string (out)
            (loop with last-hyphen? = nil
                  for char across (string-downcase string)
                  do (cond
                       ((alphanumericp char)
                        (write-char char out)
                        (setf last-hyphen? nil))
                       ((not last-hyphen?)
                        (write-char #\- out)
                        (setf last-hyphen? t)))))))
    (string-trim "-" raw)))

(defun %first-sentence-title (text)
  (let ((dot (position #\. text)))
    (if dot
        (subseq text 0 dot)
        text)))

(defun %paragraph-topic-title (text)
  (cond
    ((search "means-ends reasoning" text :test #'char-equal)
     "AI planning as means-ends reasoning")
    ((and (search "domain" text :test #'char-equal)
          (search "problem" text :test #'char-equal)
          (search "objective" text :test #'char-equal))
     "Domain, problem, objective, and plan")
    ((or (search "ordered task decomposition" text :test #'char-equal)
         (search "Hierarchical Task Network" text :test #'char-equal))
     "SHOP3 as ordered task decomposition")
    ((search "Computer Science Department of the University of Maryland" text
             :test #'char-equal)
     "SHOP lineage and stewardship")
    ((and (search "unifier" text :test #'char-equal)
          (search "theorem-prover" text :test #'char-equal))
     "Unifier and theorem-prover subsystems")
    ((search "European Lisp Symposium" text :test #'char-equal)
     "Goldman and Kuter 2019 citation")
    (t
     (%first-sentence-title text))))

(defun %feature-topic-title (text)
  (cond
    ((search "current state-of-the-world" text :test #'char-equal)
     "State-aware planning process")
    ((search "mixed symbolic/numeric computations" text :test #'char-equal)
     "Expressive mixed symbolic and numeric preconditions")
    ((search "domain-specific planning algorithms" text :test #'char-equal)
     "Domain-specific planning algorithms")
    ((search "incorporates many features from" text :test #'char-equal)
     "PDDL feature incorporation")
    ((and (search ":unordered" text :test #'char-equal)
          (search ":ordered" text :test #'char-equal))
     "Ordered and unordered task networks")
    ((search "less expressive than full HTN planners" text :test #'char-equal)
     "Expressiveness boundary versus full HTN planners")
    ((search "branch-and-bound optimization" text :test #'char-equal)
     "Plan-cost optimization")
    ((search "adds support for the Planner Domain Description Language" text
             :test #'char-equal)
     "PDDL support and domain engineering")
    (t
     (%first-sentence-title text))))

(defun %infer-shop3-topic-tags (text kind)
  (remove-duplicates
   (append
    (list :shop3 :planning kind)
    (when (search "HTN" text :test #'char-equal)
      (list :htn))
    (when (search "PDDL" text :test #'char-equal)
      (list :pddl))
    (when (search "Common Lisp" text :test #'char-equal)
      (list :common-lisp))
    (when (search "theorem-prover" text :test #'char-equal)
      (list :theorem-prover))
    (when (search "unifier" text :test #'char-equal)
      (list :unifier)))
   :test #'eq))

(defun %make-shop3-introduction-topic
    (index kind title text &key parent section source-url)
  (list :id (format nil "shop3-introduction/~2,'0D-~A"
                    index
                    (%slugify title))
        :title title
        :kind kind
        :parent parent
        :source-url source-url
        :source-section section
        :tags (%infer-shop3-topic-tags text kind)
        :text text))

(defun parse-shop3-introduction-topics
    (html &key
            (source-url *shop3-introduction-source-url*)
            (root-id "shop3-introduction/root"))
  "Parse the copied SHOP3 manual Introduction HTML fragment into topic plists.

The result is intentionally plain data: a root topic followed by paragraph-derived
concept topics and list-item-derived distinctive-characteristic topics. The
function performs no network access and no file writes."
  (let* ((headings (%text-of-html-elements "h2" html))
         (paragraphs (%text-of-html-elements "p" html))
         (features (%text-of-html-elements "li" html))
         (root-title (or (first headings)
                         "SHOP3 Manual Introduction"))
         (topics
           (list
            (list :id root-id
                  :title root-title
                  :kind :source-chapter
                  :parent nil
                  :source-url source-url
                  :source-section "Introduction"
                  :tags '(:shop3 :manual :planning :htn)
                  :text "Topic root parsed from the SHOP3 manual Introduction chapter."))))
    (loop for paragraph in paragraphs
          for index from 1
          do (push
              (%make-shop3-introduction-topic
               index
               :concept
               (%paragraph-topic-title paragraph)
               paragraph
               :parent root-id
               :section "Introduction paragraphs"
               :source-url source-url)
              topics))
    (loop for feature in features
          for index from (+ 1 (length paragraphs))
          do (push
              (%make-shop3-introduction-topic
               index
               :distinctive-characteristic
               (%feature-topic-title feature)
               feature
               :parent root-id
               :section "Distinctive characteristics list"
               :source-url source-url)
              topics))
    (nreverse topics)))
