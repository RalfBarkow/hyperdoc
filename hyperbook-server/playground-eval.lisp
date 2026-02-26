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
         (debug-marker (clog:create-div parent-element
                                        :style "font-size: 12px; color: #944; margin: 2px 2px 6px 2px;")))
    (labels ((selection-bounds ()
             (playground-selection-positions ace))
           (selected-result ()
             (multiple-value-bind (pos1 pos2)
                 (selection-bounds)
               (with-slots (object) pane
                 (hvs:playground-eval object pos1 pos2))))
           (selected-source ()
             (multiple-value-bind (pos1 pos2)
                 (selection-bounds)
               (let* ((text (clog-ace:text-value ace))
                      (start (max 0 (1- (min pos1 pos2))))
                      (end (min (length text) (max pos1 pos2))))
                 (if (< start end)
                     (subseq text start end)
                     ""))))
           (set-status (message)
             (setf (clog:inner-html debug-marker)
                   (format nil "Playground wiring: override active | ~A" message)))
           (debug-log (format-string &rest args)
             (apply #'format *error-output* format-string args)
             (finish-output *error-output*))
           (run-selection-eval ()
             (multiple-value-bind (pos1 pos2)
                 (selection-bounds)
               (let* ((source (selected-source))
                      (selection? (/= pos1 pos2))
                      (trimmed (string-trim '(#\Space #\Tab #\Newline #\Return #\Page) source)))
                 (when (and selection? (zerop (length trimmed)))
                   (set-status "Empty selection")
                   (return-from run-selection-eval (values nil nil nil)))
                 (handler-case
                     (let ((result (selected-result)))
                       (set-status "Eval executed")
                       (values t result nil))
                   (error (e)
                     (set-status (format nil "~A" e))
                     (debug-log "~&[PLAYGROUND] ERROR: ~A~%" e)
                     (values nil nil e)))))))
      (let* ((eval-action-thunk (hv:thunk
                                  (debug-log "~&[PLAYGROUND] Eval clicked~%")
                                  (let ((code (selected-source)))
                                    (debug-log "~&[PLAYGROUND] Evaluating:~%~A~%" code)
                                    (multiple-value-bind (ok? result)
                                        (run-selection-eval)
                                      (when ok?
                                        (debug-log "~&[PLAYGROUND] Result: ~S~%" result)
                                        (format t "~&Eval executed.~%"))))
                                  nil))
             (ping-action-thunk (hv:thunk
                                  (debug-log "~&[PLAYGROUND] Ping clicked~%")
                                  nil))
             (eval-inspect-thunk (hv:thunk
                                   (multiple-value-bind (ok? result)
                                       (run-selection-eval)
                                     (when ok?
                                       result))))
             (debug-thunk (hv:thunk
                            (let ((code (selected-source)))
                              (multiple-value-bind (ok? result err)
                                  (run-selection-eval)
                                (if ok?
                                    result
                                    (and err
                                         (make-playground-debug-report err code)))))))
             (button-refs nil)
             (sanitized-refs nil)
             (ping-button-id nil)
             (eval-button-id nil)
             (eval-inspect-button-id nil)
             (debug-button-id nil)
             (ping-button nil)
             (eval-button nil)
             (eval-inspect-button nil)
             (debug-button nil))
        (multiple-value-bind (buttons-html references assets)
            (hv:html-and-references
              (hv:action-button "Ping" ping-action-thunk)
              (hv:action-button "Evaluate" eval-action-thunk)
              (hv:eval-button "Evaluate and Inspect" eval-inspect-thunk)
              (hv:eval-button "Debug" debug-thunk))
          (declare (ignore assets))
          (setf (clog:inner-html tool-bar) buttons-html
                button-refs references))
        (setf ping-button-id
              (car (rassoc ping-action-thunk button-refs :test #'eq))
              eval-button-id
              (car (rassoc eval-action-thunk button-refs :test #'eq))
              eval-inspect-button-id
              (car (rassoc eval-inspect-thunk button-refs :test #'eq))
              debug-button-id
              (car (rassoc debug-thunk button-refs :test #'eq)))
        (setf ping-button (clog:attach-as-child tool-bar ping-button-id)
              eval-button (clog:attach-as-child tool-bar eval-button-id)
              eval-inspect-button (clog:attach-as-child tool-bar eval-inspect-button-id)
              debug-button (clog:attach-as-child tool-bar debug-button-id))
        (setf (clog:inner-html debug-marker)
              (format nil "Playground wiring: override active | Ping=~A | Evaluate=~A | Evaluate+Inspect=~A | Debug=~A"
                      ping-button-id
                      eval-button-id
                      eval-inspect-button-id
                      debug-button-id))
        (clog:js-execute
         tool-bar
         (format nil
                 "(function(){
                    function hook(id){
                      var el = document.getElementById(id);
                      if(!el){ console.log('[PLAYGROUND] missing element', id); return; }
                      console.log('[PLAYGROUND] hooked', id);
                      el.addEventListener('mousedown', function(){ console.log('[PLAYGROUND] mousedown', id); });
                      el.addEventListener('click', function(){
                        console.log('[PLAYGROUND] click', id);
                        el.style.outline = '3px solid red';
                        setTimeout(function(){ el.style.outline = ''; }, 300);
                      });
                    }
                    hook(~S);
                    hook(~S);
                    hook(~S);
                    hook(~S);
                  })();"
                 ping-button-id
                 eval-button-id
                 eval-inspect-button-id
                 debug-button-id))
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
          (setf (clog:attribute ping-button "disabled") t)
          (setf (clog:attribute eval-button "disabled") t)
          (setf (clog:attribute eval-inspect-button "disabled") t)
          (setf (clog:attribute debug-button "disabled") t))
        (when enabled?
          (let ((dropped 0))
            (setf sanitized-refs
                  (remove-if
                   #'(lambda (ref)
                       (let ((id (car ref)))
                         (when (or (null id)
                                   (and (stringp id)
                                        (zerop (length id))))
                           (incf dropped)
                           t)))
                   button-refs))
            (debug-log "~&[PLAYGROUND] refs=~D (dropped ~D bad ids)~%"
                       (length button-refs)
                       dropped)
            (dolist (ref button-refs)
              (debug-log "~&[PLAYGROUND] ref id=~S id-type=~S target-type=~S~%"
                         (car ref)
                         (type-of (car ref))
                         (type-of (cdr ref)))))
          (set-event-handlers pane tool-bar sanitized-refs)
          (debug-log "~&[PLAYGROUND] Event handlers installed refs=~D ping=~A eval=~A eval+inspect=~A debug=~A~%"
                     (length sanitized-refs)
                     ping-button-id
                     eval-button-id
                     eval-inspect-button-id
                     debug-button-id)
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
