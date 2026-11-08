;;;; Independent counter-probes for PR #35 (68ca0c5). Run in a fresh SBCL under `unshare --net` and `strace -f -e trace=%network,mkdir`.
;;;; PR_TREE = the tree under test (default: this checkout). PROBE_DIR = empty scratch directory for a COPY of the fixtures; the tree is never written.
;;;; Prints lines prefixed N (network), P (provenance/input), C (continuation), I (inspector), G (guards), STRACE-MARKER.
(require :asdf)
(defparameter cl-user::*review-tree*
  (uiop:ensure-directory-pathname
   (or (uiop:getenv "PR_TREE")
       (truename (merge-pathnames "../../../../" (uiop:pathname-directory-pathname *load-truename*))))))
(defparameter cl-user::*review-work*
  (uiop:ensure-directory-pathname
   (or (uiop:getenv "PROBE_DIR") (error "Set PROBE_DIR to an empty scratch directory (run-review.sh does this)."))))
(asdf:load-asd (merge-pathnames "dreyeck.asd" cl-user::*review-tree*))
(asdf:load-system "dreyeck/work/fedwiki-local-only")
(defpackage #:probe35
  (:use #:cl)
  (:local-nicknames (#:i #:dreyeck/work/fedwiki-local-only) (#:h #:dreyeck/shop3)
                    (#:d #:dreyeck/work/defederation-planning) (#:r #:dreyeck/work/local-only-resolution)
                    (#:fw #:hyperbook/fedwiki) (#:hb #:hyperbook) (#:v #:html-inspector-views)))
(in-package #:probe35)
(setf *print-pretty* nil *print-length* 12 *print-level* 5)

;;; ---------- fixture copy in PROBE_DIR (the reviewed tree stays untouched) ----------
(defparameter *src* (asdf:system-relative-pathname "dreyeck/work/fedwiki-local-only" "dreyeck/tests/fixtures/fedwiki-local-only/"))
(defparameter *fx* (uiop:ensure-directory-pathname (merge-pathnames "fx/" cl-user::*review-work*)))
(uiop:delete-directory-tree *fx* :validate t :if-does-not-exist :ignore)
(dolist (sub '("" "pages/" "snapshots/"))
  (ensure-directories-exist (merge-pathnames sub *fx*))
  (dolist (f (uiop:directory-files (merge-pathnames sub *src*)))
    (uiop:copy-file f (merge-pathnames (enough-namestring f (merge-pathnames sub *src*)) (merge-pathnames sub *fx*)))))
(defun put (relative text) (with-open-file (o (merge-pathnames relative *fx*) :direction :output :if-exists :supersede :external-format :utf-8) (write-string text o)))
(defun sha (path) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (dreyeck/local-fedwiki-page::%read-octets path))))
(put "pages/source2" "{\"title\":\"Source2\",\"story\":[{\"type\":\"paragraph\",\"id\":\"p1\",\"text\":\"[[Target]] [https://en.wikipedia.org/wiki/Lisp Lisp] [http://remote.example/view/target remote] [[Missing]]\"},{\"type\":\"reference\",\"id\":\"ref\",\"site\":\"remote.example\",\"slug\":\"target\",\"title\":\"Target\",\"text\":\"see [[Remote Only]]\"},{\"type\":\"image\",\"id\":\"img\",\"url\":\"http://remote.example/favicon.png\",\"text\":\"[[Broken]]\"}],\"journal\":[{\"type\":\"fork\",\"site\":\"remote.example\"},{\"type\":\"edit\",\"attribution\":{\"site\":\"attributed.example\"}}]}")
(put "pages/empty-story" "{\"title\":\"Empty\",\"journal\":[{\"type\":\"fork\",\"site\":\"remote.example\"}]}")
(put "outside-copy.json" "{\"title\":\"Not a page of remote-item\"}")
(defparameter *base-facts* "[\"fork-permitted\",\"fedwiki:local\",\"missing\"],[\"fork-source-policy\",\"fedwiki:local\",\"missing\",\"cached-copy-sufficient\"]")
(defun evidence (name facts copies) (put name (format nil "{\"facts\":[~A],\"copies\":[~A]}" facts copies)) (merge-pathnames name *fx*))
(defun copy-entry (site slug path) (format nil "{\"site\":\"~A\",\"slug\":\"~A\",\"path\":\"~A\",\"sha256\":\"~A\"}" site slug path (sha (merge-pathnames path *fx*))))
(defun snap (remote path) (format nil "[\"remote-snapshot\",\"fedwiki:local\",\"missing\",\"~A\",\"~A\"]" remote (sha (merge-pathnames path *fx*))))

(defun outcome (thunk)
  (handler-case (list :ok (funcall thunk))
    (error (c) (list :condition (type-of c) (subseq (substitute #\Space #\Newline (princ-to-string c)) 0 (min 110 (length (princ-to-string c))))))))
(defmacro say (prefix id label form) `(format t "~&~A ~A ~A: ~S~%" ,prefix ,id ,label ,form))
(defun steps (result) (and result (mapcar (lambda (p) (mapcar #'first p)) (h:plans-of result))))
(defun requested-sites (result) (loop for p in (h:plans-of result) collect (loop for s in p when (eq (car s) 'r::!request) collect (third s))))

;;; ---------- guards: broader than the PR's own, and only counting (strace is the ground truth) ----------
(defvar *calls* (make-hash-table :test #'equal))
(defparameter +refused+ '(usocket:socket-connect usocket:get-host-by-name usocket:get-hosts-by-name sb-bsd-sockets:get-host-by-name
                          sb-bsd-sockets:get-host-by-address drakma:http-request fw::fetch-json fw::get-fedwiki fw::make-fedwiki
                          fw::get-plugin-page fw::fetch-page-json fw::reload-page fw::probe-fedwiki-protocol sb-ext:run-program uiop:run-program))
(defparameter +counted+ '(bt:make-thread fw::load-page fw::extract-context))
(defvar *originals* nil)
(defun install-guards ()
  (dolist (s (append +refused+ +counted+))
    (when (fboundp s)
      (let ((orig (symbol-function s)) (refuse (member s +refused+)) (name (format nil "~(~S~)" s)))
        (push (cons s orig) *originals*)
        (sb-ext:without-package-locks
          (setf (symbol-function s)
                (lambda (&rest args) (incf (gethash name *calls* 0))
                  (if refuse (error "PROBE-GUARD refused ~A" name) (apply orig args))))))))
  (sb-ext:without-package-locks
    (eval '(defmethod sb-bsd-sockets:socket-connect :before ((s sb-bsd-sockets:socket) &rest address)
             (declare (ignore address)) (incf (gethash "sb-bsd-sockets:socket-connect (method)" *calls* 0))
             (error "PROBE-GUARD refused socket-connect method")))))
(defun remove-guards ()
  (sb-ext:without-package-locks (loop for (s . f) in *originals* do (setf (symbol-function s) f)))
  (let ((m (find-method #'sb-bsd-sockets:socket-connect '(:before) (list (find-class 'sb-bsd-sockets:socket)) nil)))
    (when m (remove-method #'sb-bsd-sockets:socket-connect m))))
(defun calls () (sort (loop for k being the hash-keys of *calls* using (hash-value v) collect (list k v)) #'string< :key #'first))

(install-guards)
(say "G" "0" "link redirections registered in this image" (length (hb::link-redirections-of hb:*catalog*)))
(defparameter *site* (i:make-own-site *fx* "fedwiki:local"))
(defparameter *ev* (merge-pathnames "evidence.json" *fx*))

;;; ---------- 1. network: local target, missing, remote-only, broken JSON, journal/item sites, repetition, real thunks ----------
(defparameter *obs* (list :local (i:observe-link *site* "source" 0 :evidence-file *ev* :reader-origin "fedwiki:local" :panel-site "fedwiki:local")
                          :missing (i:observe-link *site* "source" 1 :evidence-file *ev* :reader-origin "fedwiki:local" :panel-site "fedwiki:local")
                          :remote (i:observe-link *site* "source" 2 :evidence-file *ev* :reader-origin "fedwiki:local" :panel-site "fedwiki:local")
                          :broken (i:observe-link *site* "source" 3 :reader-origin "fedwiki:local" :panel-site "fedwiki:local")))
(loop for (k o) on *obs* by #'cddr do
  (say "N" "1" k (list :finding (i:finding o) :failure (and (i::failure-of o) (type-of (i::failure-of o)))
                       :context (fw::context-of (i:observed-page o))
                       :thunk (loop repeat 3 collect (let ((x (v:eval-thunk (hb:thunk-of (i:target-link o))))) (if (typep x 'condition) (type-of x) (type-of x))))
                       :lookup (outcome (lambda () (type-of (fw::lookup-slug-in-page-context (fw::target-slug-of (i:target-link o)) (i:observed-page o)))))
                       :local-only (steps (i:resolve-link o)) :requests (requested-sites (i:resolution-result o))
                       :collaborative (requested-sites (i:resolve-link o :policy :collaborative)))))
(say "N" "2" "repeated observe+resolve x3 of the missing link, findings" (loop repeat 3 collect (i:finding (let ((o (i:observe-link *site* "source" 1 :evidence-file *ev*))) (i:resolve-link o) o))))
;; A page with web, Wikipedia, external-FedWiki, reference and image items plus a journal fork and an attribution site.
(defparameter *s2* (hb:find-page *site* "source2"))
(say "N" "3" "source2 context / item types" (list (fw::context-of *s2*) (map 'list #'fw::item-type-of (fw::story-of *s2*))))
(let ((links (hb:links-of *s2*)))
  (say "N" "3" "source2 links (wiki page hyperbook web)" (mapcar #'length (list (fw::wiki-links-of links) (hb::page-links-of links) (hb::hyperbook-links-of links) (hb::web-links-of links))))
  (dolist (l (append (fw::wiki-links-of links) (hb::page-links-of links) (hb::hyperbook-links-of links)))
    (say "N" "3" (format nil "thunk ~A" (hb:key-of l)) (outcome (lambda () (let ((x (v:eval-thunk (hb:thunk-of l)))) (if (typep x 'condition) (list :condition-value (type-of x)) (type-of x)))))))
  (dolist (l (hb::web-links-of links)) (say "N" "3" "web link (no thunk; opened by the browser)" (hb::url-of l))))
(defparameter *empty* (hb:find-page *site* "empty-story"))
(say "N" "4" "page without story: story-of / load-page" (list (fw::story-of *empty*) (outcome (lambda () (fw::load-page *empty*) :loaded))))

;;; ---------- 3. input guard and provenance ----------
(defun obs-try (id label file &rest keys)
  (say "P" id label (outcome (lambda () (let ((o (apply #'i:observe-link *site* "source" (or (getf keys :item) 1) :evidence-file file (progn (remf keys :item) keys))))
                                          (list :finding (i:finding o) :local-only (steps (i:resolve-link o))
                                                :fork (count 'd::!simulate-fork (first (h:plans-of (i:prepare-link o))) :key #'car)))))))
(obs-try "1a" "evidence asserts page-available for the OWN site, store finding unknown (broken)"
         (evidence "own-available-broken.json" "[\"page-available\",\"fedwiki:local\",\"broken\"]" "") :item 3)
(obs-try "1b" "evidence asserts page-available for the OWN site, store says absent"
         (evidence "own-available-missing.json" (format nil "[\"page-available\",\"fedwiki:local\",\"missing\"],~A" *base-facts*) "") :item 1)
(obs-try "1c" "evidence asserts page-unavailable 404 for the OWN site, store unknown" (evidence "own-404-broken.json" "[\"page-unavailable\",\"fedwiki:local\",\"broken\",404]" "") :item 3)
(obs-try "1d" "evidence asserts request-error for the OWN site, store says present" (evidence "own-error-target.json" "[\"request-error\",\"fedwiki:local\",\"target\"]" "") :item 0)
(obs-try "1e" "shipped evidence-500.json (own site HTTP 500), store unknown" (merge-pathnames "evidence-500.json" *fx*) :item 3)
(obs-try "2a" "snapshot copy = the OWN site's local page file pages/source (not a remote copy)"
         (evidence "copy-own-page.json" (format nil "~A,~A" (snap "remote-item" "pages/source") *base-facts*) (copy-entry "remote-item" "missing" "pages/source")))
(obs-try "2b" "snapshot copy path outside the snapshots directory (fixture root)"
         (evidence "copy-outside.json" (format nil "~A,~A" (snap "remote-item" "outside-copy.json") *base-facts*) (copy-entry "remote-item" "missing" "outside-copy.json")))
(obs-try "2c" "snapshot copy given by ABSOLUTE path"
         (evidence "copy-absolute.json" (format nil "~A,~A" (snap "remote-item" "outside-copy.json") *base-facts*)
                   (format nil "{\"site\":\"remote-item\",\"slug\":\"missing\",\"path\":\"~A\",\"sha256\":\"~A\"}" (namestring (merge-pathnames "outside-copy.json" *fx*)) (sha (merge-pathnames "outside-copy.json" *fx*)))))
(obs-try "2d" "snapshot whose copy entry names another slug" (evidence "copy-other-slug.json" (format nil "~A,~A" (snap "remote-item" "snapshots/missing.json") *base-facts*) (copy-entry "remote-item" "other" "snapshots/missing.json")))
(obs-try "2e" "snapshot whose copy entry names another remote site" (evidence "copy-other-site.json" (format nil "~A,~A" (snap "remote-item" "snapshots/missing.json") *base-facts*) (copy-entry "remote-zz" "missing" "snapshots/missing.json")))
(dolist (case '(("3a" "facts missing" "{\"copies\":[]}") ("3b" "facts not an array" "{\"facts\":\"x\"}") ("3c" "row not an array" "{\"facts\":[\"fork-permitted\"]}")
                ("3d" "empty row" "{\"facts\":[[]]}") ("3e" "policy row too short" "{\"facts\":[[\"fork-source-policy\"]]}")
                ("3f" "null arguments" "{\"facts\":[[\"fork-permitted\",null,null]]}") ("3g" "boolean argument" "{\"facts\":[[\"fork-permitted\",true,\"missing\"]]}")
                ("3h" "float status" "{\"facts\":[[\"page-unavailable\",\"remote-item\",\"missing\",404.5]]}") ("3i" "nested array argument" "{\"facts\":[[\"fork-permitted\",[\"a\"],\"missing\"]]}")
                ("3j" "upper-case predicate LOCAL-PAGE" "{\"facts\":[[\"LOCAL-PAGE\",\"fedwiki:local\",\"missing\"]]}") ("3k" "upper-case MODELED-FORK" "{\"facts\":[[\"MODELED-FORK\",\"fedwiki:local\",\"missing\",\"r\",\"s\"]]}")
                ("3l" "unknown policy" "{\"facts\":[[\"fork-source-policy\",\"fedwiki:local\",\"missing\",\"whatever\"]]}") ("3m" "not JSON" "not json")
                ("3n" "wrong arity" "{\"facts\":[[\"fork-permitted\",\"fedwiki:local\"]]}") ("3o" "string status" "{\"facts\":[[\"page-unavailable\",\"remote-item\",\"missing\",\"500\"]]}")))
  (put (format nil "m~A.json" (first case)) (third case))
  (say "P" (first case) (second case) (outcome (lambda () (i::facts-of (i:observe-link *site* "source" 1 :evidence-file (merge-pathnames (format nil "m~A.json" (first case)) *fx*)))))))
(say "P" "4a" "item index out of range" (outcome (lambda () (i:observe-link *site* "source" 9))))
(say "P" "4b" "item without a wiki link (source2 image item has one; empty-story has none)" (outcome (lambda () (i:observe-link *site* "empty-story" 0))))
(say "P" "4c" "facts argument equal to the evidence file" (outcome (lambda () (i:finding (i:observe-link *site* "source" 1 :evidence-file *ev* :facts (getf (i::evidence-of (getf *obs* :missing)) :facts))))))
;; Mutation after registration
(defun fresh () (i:observe-link *site* "source" 1 :evidence-file *ev*))
(defun mut (id label mutate)
  ;; each mutation gets its own site object, so no mutation leaks into the next probe
  (let ((o (i:observe-link (i:make-own-site *fx* "fedwiki:local") "source" 1 :evidence-file *ev*)))
    (funcall mutate o) (say "P" id label (outcome (lambda () (steps (i:prepare-link o)))))))
(mut "5a" "fact string mutated in place" (lambda (o) (setf (char (second (first (i::facts-of o))) 0) #\X)))
(mut "5b" "finding slot changed" (lambda (o) (setf (slot-value o 'i::finding) :observed-local)))
(mut "5c" "target-link slug slot changed" (lambda (o) (setf (slot-value (i:target-link o) 'fw::target-slug) "target")))
(mut "5d" "own-site id changed" (lambda (o) (setf (slot-value (i::own-site-of o) 'hb::id) "fedwiki:other")))
(mut "5e" "evidence copy sha string mutated" (lambda (o) (setf (char (getf (first (getf (i::evidence-of o) :copies)) :sha256) 0) #\f)))
(mut "5f" "own-site root changed (not sealed)" (lambda (o) (setf (slot-value (i::own-site-of o) 'dreyeck/local-fedwiki-page::site-root) cl-user::*review-work*)))
(mut "5g" "story item text of the source page changed (not sealed)" (lambda (o) (setf (slot-value (i:observed-item o) 'fw::text) "[[Target]]")))
(say "P" "5h" "forged observation via make-instance" (outcome (lambda () (i:prepare-link (make-instance 'i:observation :own-site *site*)))))
;; restore the shared site object mutated by 5d/5f for the rest of the run
(setf *site* (i:make-own-site *fx* "fedwiki:local"))

;;; ---------- 4. continuation ----------
(defparameter *m* (i:observe-link *site* "source" 1 :evidence-file *ev*))
(defparameter *p* (i:prepare-link *m* :repeat 2))
(say "C" "0" "prepare x2: plans / forks" (list (length (h:plans-of *p*)) (count 'd::!simulate-fork (first (h:plans-of *p*)) :key #'car)))
(say "C" "1a" "foreign result (plan-defederation on scenario B)" (outcome (lambda () (i:continue-preparation *m* (d:plan-defederation (d:scenario-state :b))))))
(say "C" "1b" "resolution result instead of a preparation result" (outcome (lambda () (i:continue-preparation *m* (i:resolve-link *m*)))))
(say "C" "2" "result of another observation of the same link" (outcome (lambda () (i:continue-preparation (fresh) *p*))))
(let* ((states (h:final-states-of *p*)))
  (say "C" "3a" "number of final states of the x2 preparation" (length states))
  (let ((state (first states)))
    (shop3::add-atom-to-state '(d::local-page "fedwiki:local" "missing") state 0 nil)
    (say "C" "3b" "atom added into the native final state object" (outcome (lambda () (steps (i:continue-preparation *m* *p*)))))
    (shop3::delete-atom-from-state '(d::local-page "fedwiki:local" "missing") state 0 nil)
    (say "C" "3c" "same atom removed again (state restored)" (outcome (lambda () (steps (i:continue-preparation *m* *p*)))))))
(dolist (index (list -1 1 1.0 "0" nil 0))
  (say "C" "4" (format nil "index ~S" index) (outcome (lambda () (steps (i:continue-preparation *m* *p* :index index))))))
;; Two admissible fork alternatives (two verified copies of two remotes)
(put "snapshots/new.json" "{\"title\":\"Missing\",\"story\":[{\"type\":\"paragraph\",\"id\":\"n\",\"text\":\"Copy from remote-new.\"}],\"journal\":[]}")
(defparameter *two* (evidence "two-copies.json" (format nil "~A,~A,~A" (snap "remote-item" "snapshots/missing.json") (snap "remote-new" "snapshots/new.json") *base-facts*)
                              (format nil "~A,~A" (copy-entry "remote-item" "missing" "snapshots/missing.json") (copy-entry "remote-new" "missing" "snapshots/new.json"))))
(let* ((o (i:observe-link *site* "source" 1 :evidence-file *two*)) (p (i:prepare-link o)))
  (say "C" "5a" "two alternatives: forks per plan" (mapcar (lambda (pl) (remove-if-not (lambda (s) (eq (car s) 'd::!simulate-fork)) pl)) (h:plans-of p)))
  (dolist (k '(0 1))
    (let ((c (i:continue-preparation o p :index k)) (rr (i:resolve-link o :prepared p :index k)))
      (say "C" "5b" (format nil "index ~D: continuation steps / resolution steps" k) (list (steps c) (steps rr)))))
  (say "C" "5c" "index 2 on two alternatives" (outcome (lambda () (i:continue-preparation o p :index 2)))))
(let* ((o (fresh)) (p1 (i:prepare-link o)) (p2 (i:prepare-link o)))
  (say "C" "6" "repeated preparation: forks in p1 / p2; continue from the older p1" (list (count 'd::!simulate-fork (first (h:plans-of p1)) :key #'car) (count 'd::!simulate-fork (first (h:plans-of p2)) :key #'car)
                                                                                        (outcome (lambda () (steps (i:continue-preparation o p1))))))
  (let ((c (i:continue-preparation o p2)))
    (say "C" "6b" "continuation of a continuation" (outcome (lambda () (steps (i:continue-preparation o c)))))))
(let* ((u (i:observe-link *site* "source" 3 :evidence-file (merge-pathnames "evidence-500.json" *fx*))) (p (i:prepare-link u)))
  (say "C" "7" "no-solution preparation, then continue / resolve with it" (list (length (h:plans-of p)) (outcome (lambda () (i:continue-preparation u p))) (outcome (lambda () (i:resolve-link u :prepared p))))))
(let ((l (getf *obs* :local))) (say "C" "8" "observed-local: preparation steps, resolution with it" (let ((p (i:prepare-link l))) (list (steps p) (steps (i:resolve-link l :prepared p))))))
(let ((rr (i:resolve-link *m* :prepared *p*)))
  (say "C" "9" "after hypothetical resolution: finding, target page, store lookup, resolution facts about own presence"
       (list (i:finding *m*) (i:target-page *m*) (hb:find-page *site* "missing")
             (remove-if-not (lambda (a) (and (member (car a) '(r::page-available r::modeled-local-page d::local-page)) (equal "missing" (third a)))) (shop3:state-atoms (first (h:final-states-of rr))))
             (steps rr))))
(say "C" "10" "problems registered by prepare/resolve stay in *all-problems* (count grows by)"
     (let ((n (length shop3::*all-problems*))) (dotimes (k 3) (i:resolve-link *m*) (i:prepare-link *m*)) (- (length shop3::*all-problems*) n)))

;;; ---------- 5. inspector: views and identities ----------
(defun views-of (object)
  (loop for view in (v:all-views object)
        collect (let ((html (outcome (lambda () (v:view-html view)))))
                  (list (v:view-title view)
                        (if (eq (first html) :ok) (let ((s (princ-to-string (second html)))) (list :ok :favicon (and (search "favicon" s) t) :http (and (search "http" s) t)))
                            html)))))
(let* ((rr (i:resolve-link *m* :prepared *p*)) (problem (shop3:find-problem (h:problem-name-of *p*))))
  (dolist (pair (list (cons "observation" *m*) (cons "own-site" *site*) (cons "source page" (i:observed-page *m*)) (cons "story item" (i:observed-item *m*))
                      (cons "wiki-link" (i:target-link *m*)) (cons "links" (hb:links-of (i:observed-page *m*))) (cons "observed target page" (i:target-page (getf *obs* :local)))
                      (cons "preparation result" *p*) (cons "resolution result" rr) (cons "problem" problem) (cons "source2 page" *s2*) (cons "empty-story page" *empty*)))
    (say "I" "1" (car pair) (views-of (cdr pair))))
  (let ((refs (mapcar #'cdr (v:view-references (let ((vw (find "Local-only evidence" (v:all-views *m*) :key #'v:view-title :test #'equal))) (v:view-html vw) vw)))))
    (say "I" "2" "observation view references (EQ): page item link evidence problem prep res final-states plans"
         (mapcar (lambda (x) (and (member x refs :test #'eq) t))
                 (list (i:observed-page *m*) (i:observed-item *m*) (i:target-link *m*) (i::local-evidence-of *m*) problem *p* rr (h:final-states-of *p*) (h:plans-of *p*))))
    (say "I" "3" "plan trees referenced from the observation view directly?" (and (member (h:plan-trees-of *p*) refs :test #'eq) t)))
  (say "I" "4" "back-references: does any view of page / item / link reference the observation?"
       (loop for x in (list (i:observed-page *m*) (i:observed-item *m*) (i:target-link *m*))
             collect (some (lambda (vw) (ignore-errors (v:view-html vw)) (member *m* (mapcar #'cdr (v:view-references vw)) :test #'eq)) (v:all-views x))))
  (say "I" "5" "link thunk result is EQ to the observation's target page (local target)?"
       (let ((l (getf *obs* :local))) (eq (v:eval-thunk (hb:thunk-of (i:target-link l))) (i:target-page l))))
  (say "I" "6" "own-page title-bar buttons / own-site title-bar buttons"
       (list (princ-to-string (v:view-html (v:title-bar-action-buttons (i:observed-page *m*)))) (and (search "button" (princ-to-string (v:view-html (v:title-bar-action-buttons *site*)))) :button))))

;;; ---------- guard summary, then strace positive control ----------
(say "G" "1" "guarded calls during the probes (name count)" (calls))
(remove-guards)
(ensure-directories-exist (merge-pathnames "STRACE-MARKER-BEFORE-CONTROL/" cl-user::*review-work*))
(format t "~&STRACE-MARKER control connect: ~S~%" (outcome (lambda () (usocket:socket-connect "127.0.0.1" 9))))
(format t "~&PROBES35-DONE~%")
