(in-package #:five-ways)

(defvar *checks* 0)
(defmacro check (form) `(progn (assert ,form () "Failed: ~S" ',form) (incf *checks*)))

(defun test-each-file-alone ()
  "Every CTM file reads on its own, so each can be imported by itself."
  (dolist (name +files+)
    (check (tmdm:topic-map-topics (read-ctm name)))))

(defun test-map ()
  (let ((map (the-map)))
    (check (equal '("1" "2" "3" "4" "5") (mapcar (lambda (m) (occurrence m :stufe)) (methods map))))
    (check (equal '("Vanilla configuration.nix" "Flakes" "flake-parts" "The dendritic pattern" "den") (mapcar #'name-of (methods map))))
    ;; The ladder: each step names the next.
    (check (= 4 (count "naechster-schritt" (statements map) :key #'car :test #'equal)))
    (dolist (m (methods map))
      (check (occurrence m :steam-beispiel))
      ;; Flakes and flake-parts leave Steam in configuration.nix; their examples show where it is switched on.
      (check (or (search "programs.steam.enable = true;" (occurrence m :steam-beispiel))
                 (search "configuration.nix" (occurrence m :steam-beispiel))))
      ;; As many strengths as the source lists: three each, four for den.
      (check (= (if (equal (local-id m) "den") 4 3) (length (occurrences m :kann))))
      (check (= 3 (length (occurrences m :kostet))))
      (check (occurrence m :erster-sud))
      (check (occurrence m :lernkurve))
      (check (first (tmdm:topic-subject-locators (first (related-of-type m "beschrieben-auf"))))))
    ;; The tasting board as the source writes it.
    (check (equal "Built for it, Macs too" (occurrence (topic :den map) :mehrere-maschinen)))
    (check (equal "Usually (not required)" (occurrence (topic :dendritic map) :braucht-flakes)))
    (check (not (search "programs.steam" (occurrence (topic :flakes map) :steam-beispiel))))
    ;; The interpretation is marked as such and kept apart from the source.
    (check (occurrences (topic :fleet map) :einordnung))
    (check (notany (lambda (m) (occurrences m :einordnung)) (methods map)))))

(defun test-workspace ()
  (let* ((graph (make-instance 'five-ways-map :map (the-map)))
         (projection (tm:topicmap-projection-of graph))
         (ids (mapcar #'tm:topicmap-topic-id-of (tm:topicmap-projection-topics-of projection))))
    (check (every (lambda (id) (member id ids :test #'equal)) '("vanilla" "flakes" "flake-parts" "dendritic" "den" "fleet")))
    (check (notany (lambda (id) (uiop:string-prefix-p "seite-" id)) ids))
    (check (plusp (length (tm:topicmap-projection-associations-of projection))))
    (check (typep (workspace) 'tm:topicmap-workspace))
    (check (typep (workspace :den) 'tm:topicmap-workspace))
    (let* ((near (tm:topicmap-projection-of (make-instance 'five-ways-map :map (the-map) :focus (topic :den))))
           (near-ids (mapcar #'tm:topicmap-topic-id-of (tm:topicmap-projection-topics-of near))))
      (check (member "aspekt" near-ids :test #'equal))
      (check (not (member "channel" near-ids :test #'equal))))))

(defun test-views ()
  (dolist (id '(:vanilla :flakes :flake-parts :dendritic :den))
    (let ((html (v:view-html (first (v:all-views (method-sheet id))))))
      (check (search "Steam einschalten" html))
      (check (search "Was es kostet" html))))
  (let ((html (v:view-html (first (v:all-views (tasting-board))))))
    (check (search "Built for it, Macs too" html))))

(defun test-pages ()
  "Every page link names a page of this HyperDoc; every expr link evaluates."
  (let* ((dir (asdf:system-relative-pathname "five-ways-to-organise-your-config" "pages/"))
         (files (directory (merge-pathnames "*.html" dir)))
         (titles (mapcar (lambda (f) (let ((s (uiop:read-file-string f :external-format :utf-8)))
                                       (subseq s (+ 7 (search "<title>" s)) (search "</title>" s))))
                         files))
         (*package* (find-package '#:five-ways)))
    (check (= 9 (length files)))
    (check (member "Fünf Wege, eine NixOS-Konfiguration zu ordnen" titles :test #'string=))
    (dolist (f files)
      (let ((s (uiop:read-file-string f :external-format :utf-8)))
        (loop for at = (search "page=\"" s) then (search "page=\"" s :start2 (1+ at))
              while at
              do (let ((name (subseq s (+ at 6) (position #\" s :start (+ at 6)))))
                   (check (member name titles :test #'string=))))
        (loop for at = (search "expr=\"" s) then (search "expr=\"" s :start2 (1+ at))
              while at
              do (let ((form (plump:decode-entities (subseq s (+ at 6) (position #\" s :start (+ at 6))))))
                   (check (eval (read-from-string form)))))))))

(defun run-tests ()
  (let ((*checks* 0))
    (test-each-file-alone) (test-map) (test-workspace) (test-views) (test-pages)
    (format t "~&five-ways-to-organise-your-config: ~D checks passed.~%" *checks*)
    *checks*))
