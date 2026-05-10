;;;; Magma2 closure-tree teaching examples

(in-package :hyperdoc)

(defstruct (magma2-closure-tree-node
             (:constructor make-magma2-closure-tree-node
                 (id closure &optional parent)))
  "A minimal teaching model of a Magma2 tree node.
The node is a heap object whose CLOSURE slot is a pointer to a closure object."
  id
  closure
  parent
  (children nil))

(defun magma2-closure-tree-make-frame-closure
    (agent locals suspended-form)
  "Return a closure that exposes the suspended computation it remembers."
  (let ((agent agent)
        (locals locals)
        (suspended-form suspended-form))
    (lambda ()
      (list :agent agent
            :locals locals
            :suspended-form suspended-form))))

(defun magma2-closure-tree-add-child (parent id closure)
  "Add a child node under PARENT and return the new node."
  (let ((node (make-magma2-closure-tree-node id closure parent)))
    (when parent
      (push node (magma2-closure-tree-node-children parent)))
    node))

(defun magma2-closure-tree-node-ids (nodes)
  (mapcar #'magma2-closure-tree-node-id nodes))

(defun magma2-closure-tree-path-to-root (node)
  "Return node ids from NODE up through its fathers."
  (loop for current = node then (magma2-closure-tree-node-parent current)
        while current
        collect (magma2-closure-tree-node-id current)))

(defun magma2-closure-tree-fail (bstack)
  "Tiny model of Magma2 FAIL: choose the top backtracking node.
Return the restored current node, the closure to resume, and the remaining
backtracking stack."
  (let ((backnode (first bstack)))
    (values (magma2-closure-tree-node-parent backnode)
            (magma2-closure-tree-node-closure backnode)
            (rest bstack))))

(defexample magma2-closure-tree-pointer-example
  (let* ((shared-closure
           (magma2-closure-tree-make-frame-closure
            'genrow
            '((board nil) (j 1) (i 1))
            '(choice genrow board j n)))
         (left-node (make-magma2-closure-tree-node 'left shared-closure))
         (right-node (make-magma2-closure-tree-node 'right shared-closure)))
    (list :different-nodes-p (not (eq left-node right-node))
          :same-closure-pointer-p
          (eq (magma2-closure-tree-node-closure left-node)
              (magma2-closure-tree-node-closure right-node))
          :closure-value (funcall shared-closure))))

(defexample magma2-closure-tree-recursive-path-example
  (let* ((nqueen-1
           (make-magma2-closure-tree-node
            'nqueen-1
            (magma2-closure-tree-make-frame-closure
             'nqueen
             '((board nil) (j 1) (n 4))
             '(result-of nqueen))))
         (genrow-1
           (magma2-closure-tree-add-child
            nqueen-1
            'genrow-1
            (magma2-closure-tree-make-frame-closure
             'genrow
             '((board nil) (j 1) (n 4) (i 1))
             '(choice genrow))))
         (nqueen-2
           (magma2-closure-tree-add-child
            genrow-1
            'nqueen-2
            (magma2-closure-tree-make-frame-closure
             'nqueen
             '((board ((1 . 1))) (j 2) (n 4))
             '(result-of nqueen)))))
    (list :current-node (magma2-closure-tree-node-id nqueen-2)
          :path-to-root (magma2-closure-tree-path-to-root nqueen-2)
          :current-closure-state
          (funcall (magma2-closure-tree-node-closure nqueen-2)))))

(defexample magma2-closure-tree-backtracking-example
  (let* ((root
           (make-magma2-closure-tree-node
            'root
            (magma2-closure-tree-make-frame-closure
             'nqueen '((board nil) (j 1) (n 4)) '(start))))
         (first-choice
           (magma2-closure-tree-add-child
            root
            'first-choice
            (magma2-closure-tree-make-frame-closure
             'genrow '((i 1) (j 1)) '(retchoice (cons i j)))))
         (failing-attempt
           (magma2-closure-tree-add-child
            first-choice
            'failing-attempt
            (magma2-closure-tree-make-frame-closure
             'nqueen '((board ((1 . 1))) (j 2)) '(fail nil))))
         (saved-alternative
           (magma2-closure-tree-add-child
            first-choice
            'saved-alternative
            (magma2-closure-tree-make-frame-closure
             'genrow '((i 3) (j 2)) '(retchoice (cons i j)))))
         (bstack (list saved-alternative)))
    (declare (ignore failing-attempt))
    (multiple-value-bind (restored-current resumed-closure remaining-bstack)
        (magma2-closure-tree-fail bstack)
      (list :restored-current-node
            (magma2-closure-tree-node-id restored-current)
            :resumed-closure-state (funcall resumed-closure)
            :remaining-bstack (magma2-closure-tree-node-ids remaining-bstack)))))

(defexample magma2-closure-tree-sharing-example
  (let* ((root
           (make-magma2-closure-tree-node
            'root
            (magma2-closure-tree-make-frame-closure
             'nqueen '((board nil)) '(start))))
         (shared-prefix
           (magma2-closure-tree-add-child
            root
            'choice-for-column-1
            (magma2-closure-tree-make-frame-closure
             'genrow '((i 1) (j 1)) '(choice genrow))))
         (context-a
           (magma2-closure-tree-add-child
            shared-prefix
            'context-a
            (magma2-closure-tree-make-frame-closure
             'nqueen '((board ((1 . 1))) (j 2)) '(result-of nqueen))))
         (context-b
           (magma2-closure-tree-add-child
            shared-prefix
            'context-b
            (magma2-closure-tree-make-frame-closure
             'nqueen '((board ((1 . 1) (3 . 2))) (j 3)) '(result-of nqueen)))))
    (list :context-a-path (magma2-closure-tree-path-to-root context-a)
          :context-b-path (magma2-closure-tree-path-to-root context-b)
          :same-prefix-node-p
          (eq (magma2-closure-tree-node-parent context-a)
              (magma2-closure-tree-node-parent context-b))
          :shared-prefix-children
          (magma2-closure-tree-node-ids
           (magma2-closure-tree-node-children shared-prefix)))))
