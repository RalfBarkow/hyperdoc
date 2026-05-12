;;; Parsed from https://shop-planner.github.io/#Introduction

(in-package #:cl-user)

(defparameter *shop3-introduction-topics*
  '((:ID #1="shop3-introduction/root" :TITLE "1 Introduction" :KIND
     :SOURCE-CHAPTER :PARENT NIL :SOURCE-URL
     #2="https://shop-planner.github.io/#Introduction" :SOURCE-SECTION
     "Introduction" :TAGS (:SHOP3 :MANUAL :PLANNING :HTN) :TEXT
     "Topic root parsed from the SHOP3 manual Introduction chapter.")
    (:ID
     "shop3-introduction/01-next-execution-environment-previous-shop3-manual-up-shop3-manual-contents-index"
     :TITLE
     #3="Next: Execution Environment , Previous: SHOP3 Manual , Up: SHOP3 Manual [ Contents ][ Index ]"
     :KIND :CONCEPT :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION
     #4="Introduction paragraphs" :TAGS (:SHOP3 :PLANNING :CONCEPT) :TEXT #3#)
    (:ID "shop3-introduction/02-ai-planning-as-means-ends-reasoning" :TITLE
     "AI planning as means-ends reasoning" :KIND :CONCEPT :PARENT #1#
     :SOURCE-URL #2# :SOURCE-SECTION #4# :TAGS (:SHOP3 :PLANNING :CONCEPT)
     :TEXT
     "AI planning is the subfield of artificial intelligence (AI) that aims at automating processes of means-ends reasoning . In general, AI planning is the problem of finding a sequence of actions that, executed in a specified initial state, will reach a goal state. This is a problem with applications to diverse areas including manufacturing, autonomous space and deep sea exploration, medical treatment, and military operations, to name just a few. This is the manual for SHOP3 , the third major version of the Simple Hierarchical Ordered Planner. ")
    (:ID "shop3-introduction/03-domain-problem-objective-and-plan" :TITLE
     "Domain, problem, objective, and plan" :KIND :CONCEPT :PARENT #1#
     :SOURCE-URL #2# :SOURCE-SECTION #4# :TAGS (:SHOP3 :PLANNING :CONCEPT)
     :TEXT
     "An AI planning system takes as input a domain – a description of available actions, relations, etc.; a problem – a description of the initial state of the system, and an objective , a task to be performed or goal to be achieved. From these, it generates a plan : a sequence of actions that, if performed with the expected results, will attain the objective. This is the key function performed by SHOP3 , although, as will be seen in this manual, many additional functions are offered. ")
    (:ID "shop3-introduction/04-shop3-as-ordered-task-decomposition" :TITLE
     "SHOP3 as ordered task decomposition" :KIND :CONCEPT :PARENT #1#
     :SOURCE-URL #2# :SOURCE-SECTION #4# :TAGS (:SHOP3 :PLANNING :CONCEPT :HTN)
     :TEXT
     "SHOP3 is a domain-independent planning system based on ordered task decomposition , a modified version of Hierarchical Task Network (HTN) planning that involves planning for tasks in the same order that they will later be executed. An HTN, or decomposition, planner “proceeds by decomposing nonprimitive tasks recursively into smaller and smaller subtasks, until primitive tasks are reached that can be performed directly using the planning operators” (see Ghallab et al. , 2004 ). This manual does not give an introduction to HTN planning or AI planning in general, for that we recommend the textbook by Ghallab et al. and the research papers describing SHOP . ")
    (:ID "shop3-introduction/05-shop-lineage-and-stewardship" :TITLE
     "SHOP lineage and stewardship" :KIND :CONCEPT :PARENT #1# :SOURCE-URL #2#
     :SOURCE-SECTION #4# :TAGS (:SHOP3 :PLANNING :CONCEPT) :TEXT
     "SHOP and SHOP 2 were originally developed at the Computer Science Department of the University of Maryland, College Park, by Prof. Dana Nau’s research group. This manual draws heavily on material from the manual for SHOP2 , which was, in turn based, in part, on the JSHOP documentation written by Füsun Yaman, with additional material from Yue Cao’s December 2000 draft of the SHOP2 documentation and pseudocode from Nau et al. (see Nau et al. , 2001 ). Some updates to the SHOP2 manual were made by Robert P. Goldman and John Maraist, of SIFT. ")
    (:ID "shop3-introduction/06-unifier-and-theorem-prover-subsystems" :TITLE
     "Unifier and theorem-prover subsystems" :KIND :CONCEPT :PARENT #1#
     :SOURCE-URL #2# :SOURCE-SECTION #4# :TAGS
     (:SHOP3 :PLANNING :CONCEPT :THEOREM-PROVER :UNIFIER) :TEXT
     "SHOP3 contains two important subsystems that perform useful functions as part of it, but can also be used on their own. The first is the unifier , which computes the most general unifier of two logical formulas, encoded as Lisp s-expressions. The second subsystem is the theorem-prover , which performs Prolog-style rule-based Horn clause deduction over state sequences. ")
    (:ID "shop3-introduction/07-goldman-and-kuter-2019-citation" :TITLE
     "Goldman and Kuter 2019 citation" :KIND :CONCEPT :PARENT #1# :SOURCE-URL
     #2# :SOURCE-SECTION #4# :TAGS (:SHOP3 :PLANNING :CONCEPT) :TEXT
     "Robert P. Goldman and Ugur Kuter have a paper in the European Lisp Symposium describing SHOP3 (see Goldman & Kuter, 2019 ). ")
    (:ID
     "shop3-introduction/08-the-planners-in-the-shop-family-have-the-following-distinctive-characteristics"
     :TITLE
     #5="The planners in the SHOP family have the following distinctive characteristics: "
     :KIND :CONCEPT :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION #4# :TAGS
     (:SHOP3 :PLANNING :CONCEPT) :TEXT #5#)
    (:ID "shop3-introduction/09-state-aware-planning-process" :TITLE
     "State-aware planning process" :KIND :DISTINCTIVE-CHARACTERISTIC :PARENT
     #1# :SOURCE-URL #2# :SOURCE-SECTION #6="Distinctive characteristics list"
     :TAGS (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC) :TEXT
     "SHOP knows the current state-of-the-world at each step of the planning process. ")
    (:ID
     "shop3-introduction/10-expressive-mixed-symbolic-and-numeric-preconditions"
     :TITLE "Expressive mixed symbolic and numeric preconditions" :KIND
     :DISTINCTIVE-CHARACTERISTIC :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION
     #6# :TAGS (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC :PDDL) :TEXT
     "It has great expressive power, far beyond that of conventional PDDL planners. For example, in the preconditions of operators and methods it can do mixed symbolic/numeric computations and execute calls to external programs. ")
    (:ID "shop3-introduction/11-domain-specific-planning-algorithms" :TITLE
     "Domain-specific planning algorithms" :KIND :DISTINCTIVE-CHARACTERISTIC
     :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION #6# :TAGS
     (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC) :TEXT
     "It can be used to create very efficient domain-specific planning algorithms. The software distribution includes several examples of such domain-specific algorithms. ")
    (:ID "shop3-introduction/12-pddl-feature-incorporation" :TITLE
     "PDDL feature incorporation" :KIND :DISTINCTIVE-CHARACTERISTIC :PARENT #1#
     :SOURCE-URL #2# :SOURCE-SECTION #6# :TAGS
     (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC :PDDL) :TEXT
     "SHOP3 incorporates many features from PDDL , e.g., support for quantifiers and conditional effects in methods and operators. ")
    (:ID "shop3-introduction/13-ordered-and-unordered-task-networks" :TITLE
     "Ordered and unordered task networks" :KIND :DISTINCTIVE-CHARACTERISTIC
     :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION #6# :TAGS
     (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC) :TEXT
     "SHOP2 and SHOP3 (unlike SHOP ) allow a combination of partially ordered and fully ordered task networks through the use of the :unordered and :ordered keywords. ")
    (:ID
     "shop3-introduction/14-expressiveness-boundary-versus-full-htn-planners"
     :TITLE "Expressiveness boundary versus full HTN planners" :KIND
     :DISTINCTIVE-CHARACTERISTIC :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION
     #6# :TAGS (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC :HTN) :TEXT
     "SHOP3 task networks are less expressive than full HTN planners such as UMCP, which have labeled tasks in their task networks and allow arbitrary ordering constraints. ")
    (:ID "shop3-introduction/15-plan-cost-optimization" :TITLE
     "Plan-cost optimization" :KIND :DISTINCTIVE-CHARACTERISTIC :PARENT #1#
     :SOURCE-URL #2# :SOURCE-SECTION #6# :TAGS
     (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC) :TEXT
     "SHOP3 allows branch-and-bound optimization of plan costs. For small problems, this capability can be used to find the absolute minimum cost plans. For larger problems, this capability can be used with time limits to get the lowest cost plan that is found within the given time limit. ")
    (:ID "shop3-introduction/16-pddl-support-and-domain-engineering" :TITLE
     "PDDL support and domain engineering" :KIND :DISTINCTIVE-CHARACTERISTIC
     :PARENT #1# :SOURCE-URL #2# :SOURCE-SECTION #6# :TAGS
     (:SHOP3 :PLANNING :DISTINCTIVE-CHARACTERISTIC :PDDL) :TEXT
     "SHOP3 adds support for the Planner Domain Description Language (PDDL), and updates the SHOP language for easier domain engineering. ")))
