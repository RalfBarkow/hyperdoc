;;;; Relations are object references, not reconstructed from display strings.
(in-package #:dreyeck/lisp-critic)

(defun critic-relations-view (pairs)
  (html-inspector-views:html-view :title "Critic relations" :priority 1
    (html-inspector-views:html
      (:table
       (dolist (pair pairs)
         (html-inspector-views:html
           (:tr (:th (html-inspector-views:esc (car pair)))
                (:td (html-inspector-views:object-ref (cdr pair))))))))))

(html-inspector-views:defview critic-target-view (target critic-target)
  (critic-relations-view
   (cons (cons "Program form" (target-form-of target))
         (mapcar (lambda (run) (cons "Evaluation Record" run)) (target-runs-of target)))))

(html-inspector-views:defview critic-run-view (record critic-rule-run-record)
  (critic-relations-view
   (append (list (cons "Target" (target-of record)) (cons "Critic Rule" (rule-of record)))
           (mapcar (lambda (finding) (cons "Critique" finding)) (critiques-of record)))))

(html-inspector-views:defview critic-rule-view (rule critic-rule)
  (critic-relations-view
   (append (list (cons "Rule name" (rule-name-of rule))
                 (cons "Pattern" (rule-pattern-of rule))
                 (cons "Source" (rule-source-of rule))
                 (cons "Response template" (rule-response-of rule)))
           (mapcar (lambda (finding) (cons "Critique" finding)) (critiques-of rule)))))

(html-inspector-views:defview critique-view (finding critique)
  (critic-relations-view
   (list (cons "Critic Rule" (rule-of finding)) (cons "Target" (target-of finding))
         (cons "Evaluation Record" (critique-record-of finding))
         (cons "Match evidence" (critique-evidence-of finding))
         (cons "Explanation / recommendation" (critique-explanation-of finding)))))
