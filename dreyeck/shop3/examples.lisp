;;;; Examples and fixtures for optional HyperDoc SHOP3 planning layer
;;
;;;; Copyright (c) 2026

(in-package #:dreyeck/shop3)

(defparameter *hyperdoc-asdf-refactor-checklist-fixture-pathname*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc-shop3-asdf-refactor-plan.sexp"))

(defun read-hyperdoc-asdf-refactor-checklist-fixture
    (&optional (pathname *hyperdoc-asdf-refactor-checklist-fixture-pathname*))
  (with-open-file (stream pathname :direction :input)
    (let ((*package* (find-package '#:dreyeck/shop3)))
      (read stream nil nil))))

(defun hyperdoc-asdf-refactor-checklist-example ()
  (let* ((plan-result (run-hyperdoc-asdf-refactor-plan-object))
         (computed-checklist (hyperdoc-plan-checklist plan-result))
         (fixture-checklist (read-hyperdoc-asdf-refactor-checklist-fixture)))
    (list :matches-fixture (equal computed-checklist fixture-checklist)
          :computed-checklist computed-checklist
          :fixture-checklist fixture-checklist
          :summary (hyperdoc-plan-summary plan-result))))
;;;; BEGIN SHOP3 manual introduction topic parser examples

(defun shop3-introduction-example-source-url ()
  "The source URL used by the runnable SHOP3 manual topic parser examples."
  "https://shop-planner.github.io/#Introduction")

(defun shop3-introduction-example-html ()
  "A compact local SHOP3 Introduction fragment.

The runnable examples deliberately use a local string instead of fetching the
manual over the network. The important behavior demonstrated here is that
PARSE-SHOP3-INTRODUCTION-TOPICS receives :SOURCE-URL explicitly and stores it
on every generated topic."
  "<div class=\"chapter\" id=\"Introduction\">
<h2 class=\"chapter\">1 Introduction</h2>
<p>AI planning is the subfield of artificial intelligence (AI) that aims at automating processes of means-ends reasoning.</p>
<p>An AI planning system takes as input a domain, a problem, and an objective. From these, it generates a plan.</p>
<ul>
<li>SHOP knows the current state-of-the-world at each step of the planning process.</li>
<li>It has great expressive power, including mixed symbolic/numeric computations.</li>
<li>SHOP3 adds support for the Planner Domain Description Language (PDDL), and updates the SHOP language for easier domain engineering.</li>
</ul>
</div>")

(hyperdoc:defexample shop3-introduction-source-url-example
  "Show the explicit :SOURCE-URL value used by the parser examples."
  (let ((source-url (shop3-introduction-example-source-url)))
    (list :source-url source-url
          :matches-default?
          (string= source-url *shop3-introduction-source-url*))))

(hyperdoc:defexample shop3-introduction-parse-source-url-example
  "Parse a local SHOP3 Introduction HTML fragment with an explicit :SOURCE-URL parameter."
  (let* ((source-url (shop3-introduction-example-source-url))
         (topics (parse-shop3-introduction-topics
                  (shop3-introduction-example-html)
                  :source-url source-url)))
    (list :source-url source-url
          :topic-count (length topics)
          :root-topic (first topics)
          :titles (mapcar (lambda (topic)
                            (getf topic :title))
                          topics))))

(hyperdoc:defexample shop3-introduction-topic-source-url-example
  "Verify that every parsed topic carries the caller-supplied :SOURCE-URL."
  (let* ((source-url (shop3-introduction-example-source-url))
         (topics (parse-shop3-introduction-topics
                  (shop3-introduction-example-html)
                  :source-url source-url)))
    (list :topic-count (length topics)
          :all-have-source-url?
          (every (lambda (topic)
                   (string= (getf topic :source-url)
                            source-url))
                 topics)
          :topic-source-urls
          (mapcar (lambda (topic)
                    (list :id (getf topic :id)
                          :source-url (getf topic :source-url)))
                  topics))))

(hyperdoc:defexample shop3-introduction-topic-kinds-example
  "Summarize the topic kinds produced from the local SHOP3 Introduction fragment."
  (let* ((source-url (shop3-introduction-example-source-url))
         (topics (parse-shop3-introduction-topics
                  (shop3-introduction-example-html)
                  :source-url source-url)))
    (list :topic-count (length topics)
          :source-chapters
          (count :source-chapter topics
                 :key (lambda (topic) (getf topic :kind)))
          :concepts
          (count :concept topics
                 :key (lambda (topic) (getf topic :kind)))
          :distinctive-characteristics
          (count :distinctive-characteristic topics
                 :key (lambda (topic) (getf topic :kind)))
          :kinds
          (mapcar (lambda (topic)
                    (list :title (getf topic :title)
                          :kind (getf topic :kind)))
                  topics))))

;;;; END SHOP3 manual introduction topic parser examples
