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
    (format t "~&REMOTE-CONTROL-READING-PASS: six pages, ~D evaluated object links; shared results and book-local assets.~%" count)
    t))
