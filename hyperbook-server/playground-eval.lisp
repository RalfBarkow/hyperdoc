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
         (tool-bar (clog:create-div parent-element :style "display:flex; justify-content:space-between; align-items:center; gap:8px; margin:2px"))
         ;; Primary action: evaluate code without switching away from the current object.
         (eval-button (clog:create-button tool-bar
                                          :style "border-style:solid; border-width:2px; padding:2px 8px"
                                          :content "Eval"))
         ;; Secondary action: keep previous behavior and inspect the returned value.
         (eval-inspect-button (clog:create-button tool-bar
                                                  :style "border-style:solid; border-width:1px; padding:2px 8px"
                                                  :content "Eval + Inspect")))
    (flet ((selected-result ()
             (multiple-value-bind (pos1 pos2)
                 (playground-selection-positions ace)
               (hvs:playground-eval (pane-object pane) pos1 pos2))))
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
        (clog:set-on-mouse-click
         eval-button
         #'(lambda (obj event)
             (declare (ignore obj event))
             (selected-result)
             nil))
        (clog:set-on-mouse-click
         eval-inspect-button
         #'(lambda (obj event)
             (declare (ignore obj))
             (with-slots (inspector) pane
               (unless (getf event :shift-key)
                 (close-panes-after inspector pane))
               (create-pane inspector (selected-result)))))
        (clog:js-execute ace
                         (format nil
                                 "~A.commands.addCommand(
                                    {name: \"evalLisp\",
                                     bindKey: \"Shift-Enter\",
                                     exec: function(editor) {
                                       clog['~A'].click();}});"
                                 (clog-ace::js-ace ace)
                                 (clog:html-id eval-button)))
        (clog:set-on-change
         ace
         #'(lambda (obj)
             (declare (ignore obj))
             (hvs:store-playground-content (pane-object pane) (clog-ace:text-value ace))))))))
