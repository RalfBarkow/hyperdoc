(in-package #:fork-lineup)

(defparameter *stylesheet*
  ".publication{max-width:68ch;margin:1rem auto;padding:0 1rem 1rem;font:1rem/1.55 system-ui,sans-serif;color:#242729}
.publication h2,.publication h3{line-height:1.25}.publication dl{margin-block:1rem}.publication dt{font-weight:650;margin-top:.55rem}.publication dd{margin:0}
.publication code,.publication pre{font-size:.86em;overflow-wrap:anywhere}.publication pre{padding:.8rem;background:#f3f5f5;white-space:pre-wrap}
.publication button{font:inherit;padding:.22rem .85rem}.publication li{margin-block:.6rem}.publication a{text-decoration:underline}")

(dreyeck/authority-policy:register-reviewed-control "fork-lineup/play-test-fork"
  :effect "Executes the frozen publication offer on its private FedWiki fixture and records one run."
  :audit "publication/lineup.lisp PLAY calls FEDWIKI-FORK:PUBLISH-PAGE with the offer's release and revision.")

(defun show-play-step (offer)
  ;; Only this exact trusted DITA step is executable. The renderer still owns the document.
  (let* ((file (merge-pathnames "publish-page.dita" *directory*))
         (root (dita:parse-dita-topic (uiop:read-file-string file :external-format :utf-8)))
         (step (plump:get-element-by-id root "publish-page"))
         (marker (symbol-name (gensym "PLAY-"))))
    (assert (and (eq :publish-page (step-of (plan offer))) (equal "task" (plump:tag-name root))
                 (equal "publish-release" (plump:attribute root "id"))
                 step (equal "step" (plump:tag-name step))))
    (plump:make-text-node (plump:make-element (elt (plump:get-elements-by-tag-name step "cmd") 0) "ph") marker)
    (let* ((html (dita:render-dita-topic (plump:serialize root nil)))
           (pos (or (search marker html) (error "DITA Play step cannot be rendered."))))
      (v:html (v:str (subseq html 0 pos)))
      (v:html " ")
      (v:eval-button "Play" (dreyeck/authority-policy:reviewed-thunk "fork-lineup/play-test-fork" (play offer))
                     "Freigegebenen Test-Fork ausführen")
      (v:html (v:str (subseq html (+ pos (length marker))))))))

(defun recent-link (object)
  (let ((book (hb:hyperbook-of object)))
    (v:object-ref (gethash "recent-changes" (pages book)) :select "Recent Changes" :display "Recent Changes")))

(v:defview offer-view (offer offer)
  (v:html-view :title "DITA Task" :priority -100
    (v:html (:style (v:str *stylesheet*))
      (:section :class "publication" :aria-label "Publikationsangebot"
       (:dl (:dt "Freigegebene Release") (:dd (:code (v:esc (fork:release-reference (release-of offer)))))
            (:dt "Ziel-Slug") (:dd (v:esc (fork:release-slug (release-of offer))))
            (:dt "Beobachtete Zielrevision") (:dd (:code (v:esc (revision offer))))
            (:dt "SHOP3-Angebot") (:dd (:code (v:esc (format nil "~S" (step-of (plan offer)))))))
       (show-play-step offer)
       (:p (recent-link offer))))))

(defun put-count (run)
  (count "PUT" (http-log run) :key (lambda (entry) (gethash "method" entry)) :test #'equal))

(v:defview run-view (run publication-run)
  (v:html-view :title "Ergebnis" :priority -100
    (let ((status (getf (receipt run) :status))
          (fact (getf (receipt run) :evidence)))
      (v:html (:style (v:str *stylesheet*))
        (:section :class "publication" :aria-label "Ergebnis"
         (:h2 (v:esc (case status (:published "Fork bestätigt") (:already-published "Fork bereits vorhanden")
                            (:reconcile-target "Zielkonflikt") (otherwise "Ausführungsbefund"))))
         (:dl (:dt "Laufreferenz") (:dd (:a :href (page-url run) (v:esc (hb:id-of run))))
              (:dt "Ergebnis") (:dd (:code (v:esc (format nil "~S" status))))
              (:dt "PUTs dieses Laufs") (:dd (v:esc (princ-to-string (put-count run))))
              (:dt "Nächster SHOP3-Schritt")
              (:dd (:code (v:esc (if (next-plan run) (format nil "~S" (step-of (next-plan run))) "offen"))))
              (:dt "Geplante Zielrevision") (:dd (:code (v:esc (revision (offer-of run)))))
              (:dt "Zurückgelesene Zielrevision") (:dd (:code (v:esc (revision run)))))
         (when (diagnostic run) (v:html (:p (v:esc (diagnostic run)))))
         (when fact (v:html (:h3 "Beleg an PLAN-NEXT")
                            (:p (:code (v:esc (format nil "~S" (first fact))) " " (v:esc (second fact))))))
         (:h3 "HTTP-Befund")
         (:ul (dolist (entry (http-log run))
                (v:html (:li (:code (v:esc (format nil "~A ~A → HTTP ~D"
                                                   (gethash "method" entry) (gethash "path" entry)
                                                   (gethash "status" entry))))))))
         (:h3 "JSON-Readback")
         (:pre (v:esc (if (readback run) (let ((*print-pretty* t)) (shasht:write-json (readback run) nil))
                           "Kein Seiten-JSON zurückgelesen.")))
         (:p (recent-link run)))))))

(v:defview history-view (page recent-changes)
  (v:html-view :title "Recent Changes" :priority -100
    (let ((entries (sb-thread:with-mutex (*lock*) (copy-list (runs (hb:hyperbook-of page))))))
      (v:html (:style (v:str *stylesheet*))
        (:section :class "publication" :aria-label "Recent Changes"
         (:h2 "Recent Changes")
         (if entries
             (v:html (:ol (dolist (run entries)
                            (v:html (:li (v:object-ref run :select "Ergebnis" :display (hb:id-of run))
                                         " · " (v:esc (format nil "~S" (getf (receipt run) :status)))
                                         " · " (v:esc (princ-to-string (put-count run))) " PUT(s)")))))
             (v:html (:p "Bisher kein Play-Lauf."))))))))

(v:defview book-view (book publication-book)
  (v:html-view :title "Publikation" :priority -100
    (v:html (:p (v:object-ref (latest book) :select "DITA Task" :display "Publikationsangebot öffnen"))
            (:p (v:object-ref (gethash "recent-changes" (pages book)) :display "Recent Changes")))))
