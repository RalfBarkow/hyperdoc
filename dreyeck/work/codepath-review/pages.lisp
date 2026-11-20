;;;; The reading: a book with an overview (Play runs the analysis), two text pages and one code page, all DITA,
;;;; and the call graph as a Topicmap object.
(in-package #:codepath-review)

(defun topic-file (name) (asdf:system-relative-pathname "codepath-review" name))
(defun read-topic (name) (uiop:read-file-string (topic-file name) :external-format :utf-8))

(defun xml-escape (text)
  (with-output-to-string (s)
    (loop for c across (princ-to-string text)
          do (case c (#\& (write-string "&amp;" s)) (#\< (write-string "&lt;" s)) (#\> (write-string "&gt;" s))
                     (#\" (write-string "&quot;" s)) (t (write-char c s))))))

(defun split-at-step (xml step-id)
  "Render the DITA topic XML; return the HTML before and after the end of the <cmd> of step STEP-ID."
  (let* ((root (dita:parse-dita-topic xml))
         (node (plump:get-element-by-id root step-id))
         (marker (symbol-name (gensym "PLAY-"))))
    (plump:make-text-node (plump:make-element (elt (plump:get-elements-by-tag-name node "cmd") 0) "ph") marker)
    (let* ((html (dita:render-dita-topic (plump:serialize root nil)))
           (offset (search marker html)))
      (values (subseq html 0 offset) (subseq html (+ offset (length marker)))))))

;;; Status words, as the pages say them

(defparameter +status-words+
  '((:guarded "prüft die Sperre selbst" "#1a7f37")
    (:protected "geschützt: jeder Aufrufer-Weg prüft die Sperre" "#1a7f37")
    (:covered "abgedeckt: jeder Weg zur Senke prüft die Sperre" "#1a7f37")
    (:no-caller "ungeprüft, aber kein Aufrufer in diesem Image gefunden" "#9a6700")
    (:open "OFFEN: ein Aufrufer-Weg ohne Sperre" "#cf222e")
    (:uncovered "OFFEN: ein Weg zu einer ungeprüften Senke" "#cf222e")
    (:to-read "zu lesen: ein Weg endet in einem Textfund" "#9a6700")
    (:not-determined "nicht bestimmt (Zyklus oder keine Querverweise)" "#57606a")))

(defun status-word (status &optional role)
  (if (and (eq role :text-sink) (member status '(:open :no-caller)))
      (format nil "zu lesen: nur ein Textfund (~A)" (if (eq status :open) "auf einem Weg ohne Sperre" "ohne Aufrufer"))
      (or (second (assoc status +status-words+)) (string-downcase status))))
(defun status-color (status &optional role)
  (if (and (eq role :text-sink) (member status '(:open :no-caller))) "#9a6700" (or (third (assoc status +status-words+)) "#57606a")))
(defun role-word (role)
  (ecase role (:sink "Senke (Querverweis)") (:text-sink "Senke (nur im Text)") (:caller "Aufrufer")))
(defun guard-word (guard) (case guard (:xref "ja, direkter Aufruf") (:text "ja, nur im Text (z. B. symbol-call)") (t "nein")))

;;; Play

(defvar *message* nil)

(defun play-analyze ()
  (setf *message*
        (handler-case
            (let ((a (setf *analysis* (analyze))))
              (format nil "~A · Revision ~A · ~D Senken, ~D Knoten, ~D Kanten · offene Senken (Querverweis): ~D"
                      (time-string (analysis-time a)) (analysis-revision a)
                      (count-if (lambda (n) (member (node-role n) '(:sink :text-sink))) (analysis-nodes a))
                      (length (analysis-nodes a)) (length (analysis-edges a))
                      (count-if (lambda (n) (and (eq (node-role n) :sink) (eq (node-status n) :open))) (analysis-nodes a))))
          (error (c) (princ-to-string c)))))

(policy:register-reviewed-control "codepath-review/analyze"
  :effect "Reads SBCL cross-reference data and the loaded source files of this image, and records which code paths reach page-attached code."
  :audit "PLAY-ANALYZE calls ANALYZE: SB-INTROSPECT who-calls/who-binds/who-sets and reading files; it loads, compiles and evaluates nothing.")

(defun time-string (universal)
  (multiple-value-bind (s mi h d mo y) (decode-universal-time universal 0)
    (format nil "~D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC" y mo d h mi s)))

(defun render-analyze-task ()
  (multiple-value-bind (before after) (split-at-step (read-topic "analyze-codepaths.dita") "analyze")
    (v:html (v:str before) " "
            (v:eval-button "Play" (policy:reviewed-thunk "codepath-review/analyze" (play-analyze))
                           "Codepfade in diesem Image ermitteln")
            (v:str after))))

;;; The code page, generated as a DITA reference from the analysis

(defun sink-reference-xml (analysis)
  (with-output-to-string (s)
    (format s "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~%<reference id=\"codepath-review-sinks\" xml:lang=\"de-CH\">~%")
    (format s "<title>Code: die Senken</title>~%<shortdesc>Jede Definition, die ASDF eine Seite sehen lassen oder eine .asd laden kann, mit ihrem Quelltext aus der Datei, aus der dieses Image sie geladen hat. Revision ~A, ermittelt ~A.</shortdesc>~%<refbody>~%"
            (xml-escape (analysis-revision analysis)) (xml-escape (time-string (analysis-time analysis))))
    (dolist (n (sort (remove-if-not (lambda (n) (member (node-role n) '(:sink :text-sink))) (copy-list (analysis-nodes analysis)))
                     #'string< :key (lambda (n) (format nil "~A~S" (node-status n) (node-name n)))))
      (multiple-value-bind (text path) (definition-text (node-name n))
        (format s "<section><title>~A</title>~%<p>~A · ~A · Sperre: ~A~@[ · <filepath>~A</filepath>~]</p>~%"
                (xml-escape (string-downcase (prin1-to-string (node-name n))))
                (xml-escape (role-word (node-role n))) (xml-escape (status-word (node-status n) (node-role n)))
                (xml-escape (guard-word (node-guard n)))
                (and path (xml-escape (enough-namestring path (asdf:system-source-directory "dreyeck")))))
        (let ((callers (callers-of analysis (node-name n))))
          (format s "<p>Aufrufer: ~:[keine gefunden~;~:*~{<codeph>~A</codeph>~^, ~}~]</p>~%"
                  (mapcar (lambda (c) (xml-escape (string-downcase (prin1-to-string c)))) callers)))
        (format s "<codeblock outputclass=\"lisp\">~A</codeblock></section>~%" (xml-escape (or text "Quelltext nicht gefunden")))))
    (when (analysis-text-only analysis)
      (format s "<section><title>Textfunde ohne Definition</title><p>Formen, die ein Muster nennen, aber keine Funktion definieren:</p><ul>~%")
      (dolist (h (analysis-text-only analysis))
        (format s "<li><filepath>~A</filepath>: <codeph>~A</codeph></li>~%"
                (xml-escape (enough-namestring (text-hit-path h) (asdf:system-source-directory "dreyeck")))
                (xml-escape (text-hit-pattern h))))
      (format s "</ul></section>~%"))
    (format s "</refbody></reference>~%")))

;;; Book and pages

(defclass codepath-book (hb:hyperbook) ())
(defclass codepath-page (hb:page) ((kind :initarg :kind :reader page-kind)))

(defparameter +book-id+ "codepath-review")
(defparameter +pages+
  '(("overview" :overview "Übersicht")
    ("trust-boundary" :text "Die Vertrauensgrenze")
    ("method" :text "Methode und Grenzen")
    ("sinks" :code "Code: die Senken")
    ("production-run" :evidence "Beleg: der Produktions-Catalog")))

(defmethod hb:title-of ((book codepath-book)) "Codepfade in Seiten-Code")
(defmethod hb:title-of ((page codepath-page)) (third (assoc (hb:id-of page) +pages+ :test #'equal)))
(defmethod hb:main-page-id-of ((book codepath-book)) "overview")

(defmethod hb:find-page ((book codepath-book) id &key signal-error?)
  (let ((entry (assoc id +pages+ :test #'equal)))
    (cond (entry (make-instance 'codepath-page :id id :hyperbook book :kind (second entry)))
          (signal-error? (error 'hb:page-lookup-failure :hyperbook book :page-id id)))))

(defun page-ref (page id)
  (let ((target (hb:find-page (hb:hyperbook-of page) id :signal-error? t)))
    (v:object-ref target :display (hb:title-of target))))

(defun page-links (page)
  (v:html (:p "Seiten: "
              (dolist (entry +pages+)
                (unless (equal (first entry) (hb:id-of page))
                  (v:html (page-ref page (first entry)) " · "))))))

(defun status-table (analysis)
  (v:html
   (:table :class "inspector-table"
    (:tr (:th "Definition") (:th "Rolle") (:th "Status") (:th "Sperre"))
    (dolist (n (sort (copy-list (analysis-nodes analysis)) #'string<
                     :key (lambda (n) (format nil "~A~A~S" (if (eq (node-role n) :caller) 1 0) (node-status n) (node-name n)))))
      (let ((name (node-name n)))
        (v:html (:tr (:td (if (and (symbolp name) (fboundp name))
                              (v:object-ref (fdefinition name) :display (string-downcase (prin1-to-string name)))
                              (v:esc (prin1-to-string name))))
                     (:td (v:esc (role-word (node-role n))))
                     (:td :style (format nil "color:~A" (status-color (node-status n) (node-role n))) (v:esc (status-word (node-status n) (node-role n))))
                     (:td (v:esc (guard-word (node-guard n)))))))))))

(v:defview codepath-page-view (page codepath-page)
  (v:html-view :title (case (page-kind page) (:code "Code") (:text "Text") (t "Übersicht")) :priority -100
    (let ((analysis *analysis*))
      (ecase (page-kind page)
        (:overview
         (v:html
          (:p "Kann Code, der mit einer Wiki-Seite kommt, in diesem Image ausgewertet werden, und wo hält eine Sperre "
              "das auf? Die Antwort stammt aus diesem Image, nicht aus einer Notiz.")
          (when *message* (v:html (:p :role "status" (v:esc *message*))))
          (render-analyze-task)
          (if analysis
              (v:html (:p (v:object-ref (make-instance 'call-graph :analysis analysis) :display "Die Codepfade als Topicmap")
                          (v:esc (format nil " · Revision ~A · ermittelt ~A · ~D Quelldateien gelesen"
                                         (analysis-revision analysis) (time-string (analysis-time analysis))
                                         (analysis-files analysis))))
                      (:p "Sperren (Funktionen mit " (:code "execution-permitted-p") " im Namen): "
                          (v:esc (format nil "~{~(~S~)~^, ~}" (analysis-guards analysis))))
                      (status-table analysis))
              (v:html (:p "Noch nicht ermittelt: Play drücken.")))
          (page-links page)))
        (:text
         (v:html (v:str (dita:render-dita-topic (read-topic (if (equal (hb:id-of page) "method") "method.dita" "trust-boundary.dita"))))
                 (page-links page)))
        (:code
         (v:html (if analysis
                     (v:str (dita:render-dita-topic (sink-reference-xml analysis)))
                     (v:html (:p "Noch nicht ermittelt: Play auf der Übersicht drücken.")))
                 (page-links page)))
        (:evidence
         (v:html (:p "Aufgezeichnet von Claude (Anthropic) am 2026-11-20 in einem Container, nicht in deinem Image und nicht "
                     "auf dem Server: der Produktions-Catalog " (:code "dreyeck/catalog-application") " in Revision "
                     (:code "6057938a") " lokal geladen und befragt. Ein eigener Lauf in deinem Image ersetzt diesen Beleg.")
                 (:pre :style "white-space:pre-wrap"
                       (v:esc (uiop:read-file-string (topic-file "evidence/production-catalog-6057938a.sexp") :external-format :utf-8)))
                 (page-links page)))))))

;;; Routes, as site-observation does them: one exact CLOG route per page

(defun page-paths (book)
  (let ((slug (hyperbook/server::slug book)))
    (loop for (id) in +pages+ collect (cons id (format nil "/~A/~A" slug id)))))

(defun add-routes (book)
  (loop for (id . path) in (page-paths book)
        do (let ((page-id id))
             (clog:set-on-new-window
              (lambda (body)
                (clog-moldable-inspector:on-new-inspector
                 body :object (hb:find-page book page-id :signal-error? t)
                      :pane-width "850px" :title (hb:title-of book)
                      :playground? (second hyperbook/server::*server-parameters*)))
              :path path))))

(defun open-task (&key (port 18760))
  "Open the overview in this image's running CLOG server, or start a loopback Catalog on PORT when CLOG is not
running. Return the overview URL."
  (let ((book (or (hb:find-hyperbook +book-id+) (make-instance 'codepath-book :id +book-id+))))
    (unless (clog:is-running-p)
      (hyperbook/server:serve-catalog :host "127.0.0.1" :port port :development nil :pane-width "850px"))
    (hb:register book)
    (add-routes book)
    (format nil "http://127.0.0.1:~D~A" clog:*clog-port* (cdr (first (page-paths book))))))
