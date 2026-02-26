;;;; Override playground Eval behavior to avoid replacing the current pane
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :clog-moldable-inspector)

(defun playground-selection-positions (ace)
  (multiple-value-bind (r1 c1 r2 c2)
      (ace-get-range ace)
    (let* ((text (clog-ace:text-value ace))
           (lines (str:lines text))
           (pos1 (+ c1 1 (length (str:unlines (subseq lines 0 r1)))))
           (pos2 (+ c2 1 (length (str:unlines (subseq lines 0 r2))))))
      (values pos1 pos2))))

(defun create-playground-view (pane parent-element)
  (let* ((enabled? (inspector-playground? (inspector pane)))
         (warning (unless enabled?
                    (clog:create-div parent-element :class "inspector-error"
                                     :content "Playground evaluation disabled for security reasons. You must install the software on your own computer to run code in the playground.")))
         (ace (clog-ace:create-clog-ace-element parent-element))
         (tool-bar (clog:create-div parent-element :style "display:flex; justify-content:space-between; align-items:center; gap:8px; margin:2px")))
    (flet ((selected-result ()
             (multiple-value-bind (pos1 pos2)
                 (playground-selection-positions ace)
               (hvs:playground-eval (pane-object pane) pos1 pos2))))
      (let* ((eval-action-thunk (hv:thunk
                                  (selected-result)
                                  nil))
             (eval-inspect-thunk (hv:thunk
                                   (selected-result)))
             (button-refs nil)
             (eval-button-id nil)
             (eval-inspect-button-id nil)
             (eval-button nil)
             (eval-inspect-button nil))
        (multiple-value-bind (buttons-html references assets)
            (hv:html-and-references
              (hv:action-button "Eval" eval-action-thunk)
              (hv:eval-button "Eval + Inspect" eval-inspect-thunk))
          (declare (ignore assets))
          (setf (clog:inner-html tool-bar) buttons-html
                button-refs references))
        (setf eval-button-id
              (car (rassoc eval-action-thunk button-refs :test #'eq))
              eval-inspect-button-id
              (car (rassoc eval-inspect-thunk button-refs :test #'eq)))
        (setf eval-button (clog:attach-as-child tool-bar eval-button-id)
              eval-inspect-button (clog:attach-as-child tool-bar eval-inspect-button-id))
        (clog:set-geometry ace
                           :width (- (clog:client-width parent-element) 2)
                           :height (- (clog:client-height parent-element)
                                      (clog:client-height tool-bar)
                                      (if warning
                                          (clog:client-height warning)
                                          0)))
        (clog-ace:resize ace)
        (setf (clog-ace:font-size ace) 14)
        (setf (clog-ace:text-value ace)
              (hvs:get-playground-content (pane-object pane)))
        (setf (clog-ace:mode ace) "ace/mode/lisp")
        (unless enabled?
          (setf (clog:attribute eval-button "disabled") t)
          (setf (clog:attribute eval-inspect-button "disabled") t))
        (when enabled?
          (set-event-handlers pane tool-bar button-refs)
          (clog:js-execute ace
                           (format nil
                                   "~A.commands.addCommand(
                                    {name: \"evalLisp\",
                                     bindKey: \"Shift-Enter\",
                                     exec: function(editor) {
                                       clog['~A'].click();}});"
                                   (clog-ace::js-ace ace)
                                   eval-button-id))
          (clog:set-on-change
           ace
           #'(lambda (obj)
               (declare (ignore obj))
               (hvs:store-playground-content (pane-object pane) (clog-ace:text-value ace)))))))))
