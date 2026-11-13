(in-package #:dreyeck/work/remote-control-planning)

(defun reading-page-titles ()
  '("Planning Remote Control for the Zettelkasten App with SHOP3"
    "Model Authority and the Control Surface"
    "How SHOP3 Reads the Architecture Task"
    "Case C - Two Alternative Plan Trees"
    "Cases D and E - When Planning Refuses"
    "Evidence and Open Acceptance"))

(defun reading-page-expressions (text)
  "Read this reading's quoted EXPR attributes, not a general HTML parser."
  (loop with start = 0
        for pos = (search "expr=" text :start2 start)
        while pos
        for quote = (char text (+ pos 5))
        for end = (position quote text :start (+ pos 6))
        do (assert (find quote "\"'")) (assert end)
        collect (subseq text (+ pos 6) end)
        do (setf start (1+ end))))

(defun rendered-plan-result (result)
  (let* ((views (remove-if-not
                (lambda (view)
                  (string= "Read the Plan" (html-inspector-views:view-title view)))
                (html-inspector-views:all-views result)))
         (view (first views)))
    (assert (= 1 (length views)))
    ;; Views are lazy. Obtaining the view alone misses CL-WHO errors such as
    ;; (:OL ...) evaluated as a function call inside a Lisp conditional.
    (values (plump:parse (html-inspector-views:view-html view))
            (html-inspector-views:view-references view))))

(defun plan-elements (node tag)
  (coerce (plump:get-elements-by-tag-name node tag) 'list))

(defun plan-element-values (node references)
  "Recover the real objects behind rendered references, in document order."
  (loop for span in (plan-elements node "span")
        for entry = (assoc (plump:get-attribute span "id") references :test #'equal)
        when entry collect (cdr entry)))

(defun plan-section-after (section heading)
  (plump:next-element
   (or (find heading (plan-elements section "h4") :key #'plump:text :test #'equal)
       (error "Missing section ~A" heading))))

(defun check-rendered-case-c ()
  (let ((result (reading-result :c)))
    (assert (equal (case-initial-state :c) (dreyeck/shop3:initial-facts-of result)))
    ;; The snapshot must not share the actual problem's nested fact lists.
    (assert (not (eq (first (shop3:state-atoms (shop3:find-problem 'remote-control-c)))
                     (first (dreyeck/shop3:initial-facts-of result)))))
    (multiple-value-bind (document references) (rendered-plan-result result)
      (let ((sections (plan-elements document "section")))
        (assert (= 2 (length sections)))
        (loop for section in sections
              for plan in (dreyeck/shop3:plans-of result)
              for tree in (dreyeck/shop3:plan-trees-of result)
              for state in (dreyeck/shop3:final-states-of result)
              for route = (fifth (third plan))
              for method = (ecase route
                             (agent 'agent-session-method)
                             (direct 'direct-api-method))
              for expected-added = `((modeled-route zettelkasten macbook-a android ,route)
                                     (control-surface android zettelkasten ,route)
                                     (mobile-control-verified zettelkasten macbook-a android ,route))
              do
                 ;; Ordered list and decomposition expose exactly the original
                 ;; operators/arguments, and the method belongs to this route.
                 (assert (equal plan
                                (mapcar (lambda (code) (plan-element-values code references))
                                        (plan-elements (first (plan-elements section "ol")) "code"))))
                 (let* ((summary (first (plan-elements section "summary")))
                        (values (plan-element-values summary references)))
                   (assert (equal values
                                  (append (shop3:complex-node-task (first tree)) (list method)))))
                 (let ((leaves (remove-if-not
                                (lambda (li) (equal "plan-leaf" (plump:get-attribute li "class")))
                                (plan-elements section "li"))))
                   (assert (= 3 (length leaves)))
                   (loop for leaf in leaves for step in plan for number from 1
                         do (assert (search (format nil "Step ~D: " number) (plump:text leaf)))
                            (assert (equal step (plan-element-values leaf references)))))
                 (let* ((added (plan-section-after section "Added Facts"))
                        (facts (mapcar (lambda (code) (plan-element-values code references))
                                       (plan-elements added "code"))))
                   (assert (= 3 (length facts)))
                   (assert (subsetp expected-added facts :test #'equal))
                   (assert (string= "None." (plump:text (plan-section-after section "Removed Facts")))))
                 (let* ((final (find "Modeled Final State" (plan-elements section "details")
                                     :test #'equal :key
                                     (lambda (details) (plump:text (first (plan-elements details "summary"))))))
                        (facts (mapcar (lambda (code) (plan-element-values code references))
                                       (plan-elements final "code"))))
                   (assert final)
                   (assert (not (plump:has-attribute final "open")))
                   (assert (member state (plan-element-values final references) :test #'eq))
                   (assert (and (subsetp facts (shop3:state-atoms state) :test #'equal)
                                (subsetp (shop3:state-atoms state) facts :test #'equal)))))))))

(defun check-rendered-plan-edge-cases ()
  (dolist (case '(:d :e))
    (let ((document (rendered-plan-result (reading-result case))))
      (assert (search "No plan found." (plump:text document)))
      (assert (null (plan-elements document "section")))))
  ;; The pinned recursive planner has an unrelated empty-plan tree defect.
  ;; Exercise a real empty search without requesting a tree, then render it.
  (shop3:defdomain read-plan-empty-domain ((:method (ready) already-ready () ())))
  (shop3:defproblem read-plan-empty read-plan-empty-domain () ((ready)))
  (multiple-value-bind (raw seconds trees states)
      (shop3:find-plans 'read-plan-empty :which :all :verbose 0 :collect-state t)
    (assert raw)
    (let* ((result (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                    :problem-name 'read-plan-empty :plans (mapcar #'shop3:shorter-plan raw)
                    :raw-plans raw :time seconds :plan-trees trees :final-states states
                    :initial-facts nil))
           (document (rendered-plan-result result)))
      (assert (search "Plan found with no primitive steps." (plump:text document)))
      (assert (not (search "No plan found." (plump:text document))))))
  (let* ((current (reading-result :c))
         (legacy (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                   :problem-name (dreyeck/shop3:problem-name-of current)
                   :plans (dreyeck/shop3:plans-of current)
                   :raw-plans (dreyeck/shop3:raw-plans-of current)
                   :plan-trees (dreyeck/shop3:plan-trees-of current)
                   :final-states (dreyeck/shop3:final-states-of current) :time 0)))
    (multiple-value-bind (document references) (rendered-plan-result legacy)
      (assert (search "Difference unavailable" (plump:text document)))
      (loop for section in (plan-elements document "section")
            for state in (dreyeck/shop3:final-states-of current)
            for facts = (mapcar (lambda (code) (plan-element-values code references))
                                (plan-elements (car (last (plan-elements section "details"))) "code"))
            do (assert (member state (mapcar #'cdr references) :test #'eq))
               (assert (equal "Unavailable." (plump:text (plan-section-after section "Added Facts"))))
               (assert (equal "Unavailable." (plump:text (plan-section-after section "Removed Facts"))))
               (assert (= (length facts) (length (shop3:state-atoms state))))
               (assert (subsetp (shop3:state-atoms state) facts :test #'equal)))))
  ;; A removed fact, a known empty final state and repeated tasks around
  ;; an internal operator. Tree traversal order differs from step order.
  (let* ((task '(!repeat android))
         (internal '(!!internal android))
         (state (shop3.common:make-initial-state nil :list nil))
         (result (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                   :problem-name 'repeated :plans (list (list task task))
                   :raw-plans (list (list task 1 internal 0 task 1)) :time 0
                   :plan-trees (list (list (shop3:make-complex-node '(repeat)
                                           (list (list 1 task 2) (list 0 internal 1) (list 1 task 0))
                                           :reduction-label 'repeat-method)))
                   :initial-facts '((ready android)) :final-states (list state))))
    (multiple-value-bind (document references) (rendered-plan-result result)
      (let* ((section (first (plan-elements document "section")))
             (leaves (remove-if-not
                      (lambda (li) (equal "plan-leaf" (plump:get-attribute li "class")))
                      (plan-elements section "li"))))
        (assert (= 2 (length leaves)))
        (assert (search "Step 2: " (plump:text (first leaves))))
        (assert (search "Step 1: " (plump:text (second leaves))))
        (assert (equal '(ready android)
                       (plan-element-values (plan-section-after section "Removed Facts") references)))
        (assert (not (search "Difference unavailable" (plump:text document)))))))
  (format t "~&READ-THE-PLAN-PASS: rendered Case C methods, steps, leaf numbers, route facts; D/E, empty success, legacy state, removals and repeated tasks.~%"))

(defun run-reading-tests ()
  (let* ((book *remote-control-reading*)
         (assets (hyperbook:html-page-assets-of book))
         (css "/remote-control-reading/css/reading.css")
         (generic-assets (hyperbook:html-page-assets-of (make-instance 'hyperdoc:hyperdoc)))
         (count 0))
    (assert (eq book (hyperbook:find-hyperbook "dreyeck/work/remote-control-planning")))
    (assert (member css (hyperbook::css-of assets) :test #'equal))
    (assert (eq generic-assets (hyperbook::inherit-of assets)))
    (assert (not (member css (hyperbook::css-of generic-assets) :test #'equal)))
    (assert (probe-file (merge-pathnames "css/reading.css" (cdar (hyperbook::paths-of assets)))))
    (dolist (title (reading-page-titles))
      (let ((text (uiop:read-file-string
                   (asdf:system-relative-pathname
                    "dreyeck/work/remote-control-planning/reading"
                    (format nil "dreyeck/pages/remote-control-planning/~A.html" title)))))
        (dolist (expression (reading-page-expressions text))
          (let ((*package* (find-package :dreyeck/work/remote-control-planning))
                (*read-eval* nil))
            (assert (eval (read-from-string expression))))
          (incf count))))
    (dolist (route '(:agent :direct))
      (let* ((result (reading-result :c))
             (plan (reading-alternative route :plan))
             (index (position plan (dreyeck/shop3:plans-of result) :test #'eq)))
        (assert index)
        (assert (eq (reading-alternative route :tree)
                    (nth index (dreyeck/shop3:plan-trees-of result))))
        (assert (eq (reading-alternative route :state)
                    (nth index (dreyeck/shop3:final-states-of result))))))
    (dolist (case '(:a :b :c :d :e))
      (assert (eq (reading-case case) (reading-case case)))
      (assert (eq :plan-only (dreyeck/shop3:execution-mode-of (reading-result case)))))
    (dolist (case '(:d :e))
      (assert (eq :no-plan (getf (reading-case case) :outcome)))
      (assert (null (dreyeck/shop3:raw-plans-of (reading-result case)))))
    (check-rendered-case-c)
    (check-rendered-plan-edge-cases)
    (format t "~&REMOTE-CONTROL-READING-PASS: six pages, ~D evaluated object links; shared results and book-local assets.~%" count)
    t))
