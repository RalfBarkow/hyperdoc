;;;; nixos-parallels-topicmap-persistence-v2.lisp
;;;; HyperDoc / SLY mREPL projection:
;;;;   workflow evidence -> topics -> topicmap -> SQLite -> browser/inspector object
;;;;
;;;; Load in SLY:
;;;;   (load #p"~/Downloads/nixos-parallels-topicmap-persistence-v2.lisp")
;;;;   (defparameter *tm* (nixos-parallels-topicmap-persistence:run :inspect t :open-browser t))
;;;;
;;;; This file does not modify the NixOS VM. It only writes local HyperDoc
;;;; artifacts and a SQLite database under the page assets directory.

(require :asdf)

(defpackage #:nixos-parallels-topicmap-persistence
  (:use #:cl)
  (:export
   #:topic
   #:topic-id
   #:topic-title
   #:topic-kind
   #:topic-status
   #:topic-payload
   #:relation
   #:relation-source
   #:relation-target
   #:relation-kind
   #:relation-label
   #:topicmap-result
   #:topicmap-result-title
   #:topicmap-result-generated-at
   #:topicmap-result-assets-dir
   #:topicmap-result-db-path
   #:topicmap-result-sql-path
   #:topicmap-result-dot-path
   #:topicmap-result-svg-path
   #:topicmap-result-html-path
   #:topicmap-result-topics
   #:topicmap-result-relations
   #:topicmap-result-current-task
   #:topicmap-result-acceptance-gate
   #:topicmap-result-shell-probes
   #:topicmap-result-notes
   #:make-current-topicmap
   #:persist-topicmap
   #:write-topicmap-dot
   #:write-topicmap-html
   #:inspect-topicmap
   #:open-topicmap-html
   #:run))

(in-package #:nixos-parallels-topicmap-persistence)

(defstruct topic
  id
  title
  kind
  status
  payload)

(defstruct relation
  source
  target
  kind
  label)

(defstruct topicmap-result
  title
  generated-at
  assets-dir
  db-path
  sql-path
  dot-path
  svg-path
  html-path
  topics
  relations
  current-task
  acceptance-gate
  shell-probes
  notes)

(defun now-iso8601 ()
  (multiple-value-bind (second minute hour date month year)
      (decode-universal-time (get-universal-time))
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0D"
            year month date hour minute second)))

(defun default-assets-dir ()
  (merge-pathnames
   #p".wiki/wiki.ralfbarkow.ch/assets/pages/nixos-vm-on-intel-macbook-pro/"
   (user-homedir-pathname)))

(defun normalize-assets-dir (assets-dir)
  (let ((dir (or assets-dir (default-assets-dir))))
    (ensure-directories-exist (merge-pathnames #p".keep" dir))
    dir))

(defun safe-namestring (path)
  (namestring path))

(defun printable-string (thing)
  (typecase thing
    (null "")
    (string thing)
    (symbol (string-downcase (symbol-name thing)))
    (pathname (namestring thing))
    (t (prin1-to-string thing))))

(defun sql-quote (thing)
  (let ((s (printable-string thing)))
    (with-output-to-string (out)
      (write-char #\' out)
      (loop for ch across s do
        (if (char= ch #\')
            (write-string "''" out)
            (write-char ch out)))
      (write-char #\' out))))

(defun html-escape (thing)
  (let ((s (printable-string thing)))
    (with-output-to-string (out)
      (loop for ch across s do
        (case ch
          (#\< (write-string "&lt;" out))
          (#\> (write-string "&gt;" out))
          (#\& (write-string "&amp;" out))
          (#\" (write-string "&quot;" out))
          (otherwise (write-char ch out)))))))

(defun dot-quote (thing)
  (let ((s (printable-string thing)))
    (with-output-to-string (out)
      (write-char #\" out)
      (loop for ch across s do
        (case ch
          (#\" (write-string "\\\"" out))
          (#\\ (write-string "\\\\" out))
          (#\Newline (write-string "\\n" out))
          (otherwise (write-char ch out))))
      (write-char #\" out))))

(defun topic-status-rank (status)
  (case status
    (:done 0)
    (:current 1)
    (:next 2)
    (:pending 3)
    (:blocked 4)
    (:guarded 5)
    (:final 6)
    (otherwise 99)))

(defun make-current-topics ()
  (list
   (make-topic :id "workflow"
               :title "NixOS VM on Intel MacBook Pro: Parallels Tools workflow"
               :kind "workflow"
               :status :current
               :payload '((guest nixos-parallels-guest)
                          (host macos-host)
                          (guest-user rgb)
                          (guest-ip "10.211.55.7")))
   (make-topic :id "stable-boot"
               :title "Stable boot baseline verified"
               :kind "state"
               :status :done
               :payload '((ssh-key-login-enabled rgb)
                          (passwordless-sudo-enabled rgb)
                          (display-manager-active gdm)
                          (prltoolsd active)
                          (cups masked)
                          (prlshprint masked)))
   (make-topic :id "wayland-session"
               :title "Active GNOME session is Wayland"
               :kind "evidence"
               :status :done
               :payload '((graphical-session rgb wayland active)
                          (service gdm-autologin)))
   (make-topic :id "prltoolsd-active"
               :title "Base Parallels Tools daemon active"
               :kind "evidence"
               :status :done
               :payload '((process prltoolsd active)))
   (make-topic :id "prlcc-absent"
               :title "Parallels Control Center absent after stable recovery"
               :kind "evidence"
               :status :current
               :payload '((process prlcc absent)
                          (meaning "clipboard agent not available yet")))
   (make-topic :id "prldnd-absent"
               :title "Parallels drag-and-drop agent absent after stable recovery"
               :kind "evidence"
               :status :current
               :payload '((process prldnd absent)
                          (meaning "drag/drop companion agent not available yet")))
   (make-topic :id "start-prlcc-runtime-only"
               :title "Start prlcc/prldnd as runtime-only action"
               :kind "task"
               :status :next
               :payload '((pddl (start-prlcc-runtime-only nixos-parallels-guest rgb))
                          (mutation-scope user-systemd-only)
                          (forbidden (nixos-rebuild switch))
                          (shell "cd ~/Downloads && ./diagnose-repair-parallels-clipboard-agent.sh rgb 10.211.55.7 repair")))
   (make-topic :id "gate-runtime-prlcc"
               :title "Acceptance gate: runtime prlcc/prldnd"
               :kind "gate"
               :status :pending
               :payload '((must-have (process-running nixos-parallels-guest prlcc))
                          (must-have (process-running nixos-parallels-guest prldnd))))
   (make-topic :id "manual-clipboard-test"
               :title "Manual bidirectional clipboard test"
               :kind "task"
               :status :blocked
               :payload '((precondition (process-running prlcc))
                          (precondition (process-running prldnd))
                          (test "macOS Cmd+C -> NixOS Ctrl+V or Ctrl+Shift+V")
                          (test "NixOS copy/select -> macOS Cmd+V")))
   (make-topic :id "test-x11-generation"
               :title "Guarded X11 test generation"
               :kind "task"
               :status :guarded
               :payload '((precondition (manual-clipboard-test-failed))
                          (mutation nixos-rebuild-test-only)
                          (rollback reboot)
                          (forbidden (nixos-rebuild switch-before-acceptance))))
   (make-topic :id "persist-x11"
               :title "Persist X11 only if clipboard works"
               :kind "task"
               :status :blocked
               :payload '((precondition (clipboard-direction-works macos-host nixos-parallels-guest))
                          (precondition (clipboard-direction-works nixos-parallels-guest macos-host))
                          (allowed-action (nixos-rebuild switch))))
   (make-topic :id "final-wayland-success"
               :title "Final state: clipboard works under Wayland"
               :kind "final-world-state"
               :status :final
               :payload '((graphical-session rgb wayland active)
                          (process-running prlcc)
                          (process-running prldnd)
                          (bidirectional-clipboard-available)))
   (make-topic :id "final-x11-success"
               :title "Final state: clipboard works under X11"
               :kind "final-world-state"
               :status :final
               :payload '((graphical-session rgb x11 active)
                          (process-running prlcc)
                          (process-running prldnd)
                          (bidirectional-clipboard-available)))
   (make-topic :id "blocked-upstream"
               :title "Blocked: upstream/Parallels clipboard limitation"
               :kind "final-world-state"
               :status :final
               :payload '((stable-boot-baseline-verified)
                          (clipboard-not-available-under-tested-session)
                          (do-not-destabilize-boot-for-clipboard)))))

(defun make-current-relations ()
  (list
   (make-relation :source "workflow" :target "stable-boot" :kind "has-state" :label "verified baseline")
   (make-relation :source "workflow" :target "wayland-session" :kind "observes" :label "current session")
   (make-relation :source "workflow" :target "prltoolsd-active" :kind "observes" :label "base tools")
   (make-relation :source "workflow" :target "prlcc-absent" :kind "observes" :label "missing user agent")
   (make-relation :source "workflow" :target "prldnd-absent" :kind "observes" :label "missing dnd agent")
   (make-relation :source "stable-boot" :target "start-prlcc-runtime-only" :kind "enables" :label "safe next step")
   (make-relation :source "wayland-session" :target "start-prlcc-runtime-only" :kind "precondition" :label "active user session")
   (make-relation :source "prltoolsd-active" :target "start-prlcc-runtime-only" :kind "precondition" :label "base daemon")
   (make-relation :source "prlcc-absent" :target "start-prlcc-runtime-only" :kind "motivates" :label "start missing agent")
   (make-relation :source "prldnd-absent" :target "start-prlcc-runtime-only" :kind "motivates" :label "start missing agent")
   (make-relation :source "start-prlcc-runtime-only" :target "gate-runtime-prlcc" :kind "must-pass" :label "acceptance gate")
   (make-relation :source "gate-runtime-prlcc" :target "manual-clipboard-test" :kind "unblocks" :label "when prlcc/prldnd running")
   (make-relation :source "manual-clipboard-test" :target "final-wayland-success" :kind "success" :label "clipboard works")
   (make-relation :source "manual-clipboard-test" :target "test-x11-generation" :kind "failure" :label "clipboard still fails")
   (make-relation :source "test-x11-generation" :target "final-x11-success" :kind "success" :label "x11 test works")
   (make-relation :source "test-x11-generation" :target "blocked-upstream" :kind "failure" :label "record blocker")
   (make-relation :source "final-x11-success" :target "persist-x11" :kind "permits" :label "switch allowed")))

(defun make-current-topicmap (&key (assets-dir nil))
  "Create the inspectable topicmap object from the current known evidence."
  (let* ((dir (normalize-assets-dir assets-dir))
         (topics (make-current-topics))
         (relations (make-current-relations)))
    (make-topicmap-result
     :title "NixOS Parallels stepwise topicmap"
     :generated-at (now-iso8601)
     :assets-dir dir
     :db-path (merge-pathnames #p"nixos-parallels-stepwise-workflow.sqlite" dir)
     :sql-path (merge-pathnames #p"nixos-parallels-stepwise-workflow.sql" dir)
     :dot-path (merge-pathnames #p"nixos-parallels-stepwise-workflow.dot" dir)
     :svg-path (merge-pathnames #p"nixos-parallels-stepwise-workflow.svg" dir)
     :html-path (merge-pathnames #p"nixos-parallels-stepwise-workflow-topicmap.html" dir)
     :topics topics
     :relations relations
     :current-task '(start-prlcc-runtime-only nixos-parallels-guest rgb)
     :acceptance-gate '((process-running nixos-parallels-guest prlcc)
                        (process-running nixos-parallels-guest prldnd))
     :shell-probes
     '((observe "ssh rgb@10.211.55.7 '<observe graphical session and Parallels agents>'")
       (start-prlcc "cd ~/Downloads && ./diagnose-repair-parallels-clipboard-agent.sh rgb 10.211.55.7 repair")
       (manual-clipboard-test "Copy hello-from-macos on macOS; paste in NixOS. Copy hello-from-nixos in NixOS; paste on macOS."))
     :notes
     '("This topicmap is a local HyperDoc projection of the current workflow, not a VM mutation."
       "Persistent NixOS changes are blocked until acceptance gates pass."
       "The next action is runtime-only prlcc/prldnd startup."))))

(defun write-sql (result)
  (with-open-file (s (topicmap-result-sql-path result)
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format s "PRAGMA foreign_keys = ON;~%")
    (format s "CREATE TABLE IF NOT EXISTS topics (id TEXT PRIMARY KEY, title TEXT NOT NULL, kind TEXT NOT NULL, status TEXT NOT NULL, payload TEXT);~%")
    (format s "CREATE TABLE IF NOT EXISTS relations (source TEXT NOT NULL, target TEXT NOT NULL, kind TEXT NOT NULL, label TEXT, PRIMARY KEY(source,target,kind,label));~%")
    (format s "CREATE TABLE IF NOT EXISTS progress_events (id INTEGER PRIMARY KEY AUTOINCREMENT, event_time TEXT NOT NULL, topic_id TEXT NOT NULL, status TEXT NOT NULL, evidence TEXT);~%")
    (format s "CREATE TABLE IF NOT EXISTS current_view (key TEXT PRIMARY KEY, value TEXT NOT NULL);~%")
    (format s "DELETE FROM topics;~%DELETE FROM relations;~%DELETE FROM current_view;~%")
    (dolist (topic (topicmap-result-topics result))
      (format s "INSERT OR REPLACE INTO topics (id,title,kind,status,payload) VALUES (~A,~A,~A,~A,~A);~%"
              (sql-quote (topic-id topic))
              (sql-quote (topic-title topic))
              (sql-quote (topic-kind topic))
              (sql-quote (topic-status topic))
              (sql-quote (topic-payload topic))))
    (dolist (edge (topicmap-result-relations result))
      (format s "INSERT OR REPLACE INTO relations (source,target,kind,label) VALUES (~A,~A,~A,~A);~%"
              (sql-quote (relation-source edge))
              (sql-quote (relation-target edge))
              (sql-quote (relation-kind edge))
              (sql-quote (relation-label edge))))
    (format s "INSERT OR REPLACE INTO current_view (key,value) VALUES ('current-task',~A);~%"
            (sql-quote (topicmap-result-current-task result)))
    (format s "INSERT OR REPLACE INTO current_view (key,value) VALUES ('acceptance-gate',~A);~%"
            (sql-quote (topicmap-result-acceptance-gate result)))
    (format s "INSERT INTO progress_events (event_time,topic_id,status,evidence) VALUES (~A,'workflow','projected',~A);~%"
            (sql-quote (topicmap-result-generated-at result))
            (sql-quote "topicmap projection persisted from SLY")))
  (topicmap-result-sql-path result))

(defun persist-topicmap (result)
  (write-sql result)
  (let ((db (safe-namestring (topicmap-result-db-path result)))
        (sql (safe-namestring (topicmap-result-sql-path result))))
    (handler-case
        (progn
          (uiop:run-program (list "sqlite3" db (format nil ".read ~A" sql))
                            :output *standard-output*
                            :error-output *error-output*)
          t)
      (error (condition)
        (format *error-output*
                "~&Could not run sqlite3. SQL was written to ~A.~%Error: ~A~%"
                sql condition)
        nil))))

(defun write-topicmap-dot (result)
  (with-open-file (s (topicmap-result-dot-path result)
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format s "digraph nixos_parallels_workflow {~%")
    (format s "  rankdir=LR;~%")
    (format s "  node [shape=box];~%")
    (dolist (topic (sort (copy-list (topicmap-result-topics result))
                         #'<
                         :key (lambda (item)
                                (topic-status-rank (topic-status item)))))
      (format s "  ~A [label=~A];~%"
              (dot-quote (topic-id topic))
              (dot-quote (format nil "~A~%[~A / ~A]"
                                 (topic-title topic)
                                 (topic-kind topic)
                                 (topic-status topic)))))
    (dolist (edge (topicmap-result-relations result))
      (format s "  ~A -> ~A [label=~A];~%"
              (dot-quote (relation-source edge))
              (dot-quote (relation-target edge))
              (dot-quote (or (relation-label edge) (relation-kind edge)))))
    (format s "}~%"))
  (topicmap-result-dot-path result))

(defun try-render-svg (result)
  (handler-case
      (progn
        (uiop:run-program
         (list "dot" "-Tsvg"
               "-o" (safe-namestring (topicmap-result-svg-path result))
               (safe-namestring (topicmap-result-dot-path result)))
         :output *standard-output*
         :error-output *error-output*)
        (probe-file (topicmap-result-svg-path result)))
    (error (condition)
      (format *error-output* "~&Graphviz dot not available or failed: ~A~%" condition)
      nil)))

(defun write-topicmap-html (result)
  (with-open-file (s (topicmap-result-html-path result)
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format s "<!doctype html>~%<html>~%<head><meta charset=\"utf-8\"><title>~A</title></head>~%<body>~%"
            (html-escape (topicmap-result-title result)))
    (format s "<h1>~A</h1>~%" (html-escape (topicmap-result-title result)))
    (format s "<p>Generated: ~A</p>~%" (html-escape (topicmap-result-generated-at result)))
    (format s "<p>Current task:</p><pre>~A</pre>~%"
            (html-escape (topicmap-result-current-task result)))
    (format s "<p>Acceptance gate:</p><pre>~A</pre>~%"
            (html-escape (topicmap-result-acceptance-gate result)))
    (when (probe-file (topicmap-result-svg-path result))
      (format s "<h2>Topicmap SVG</h2>~%")
      (format s "<object type=\"image/svg+xml\" data=\"~A\"></object>~%"
              (html-escape (file-namestring (topicmap-result-svg-path result)))))
    (format s "<h2>Topics</h2>~%")
    (dolist (topic (topicmap-result-topics result))
      (format s "<section id=\"~A\">~%" (html-escape (topic-id topic)))
      (format s "<h3>~A</h3>~%" (html-escape (topic-title topic)))
      (format s "<p>kind: <code>~A</code> status: <code>~A</code></p>~%"
              (html-escape (topic-kind topic))
              (html-escape (topic-status topic)))
      (format s "<pre>~A</pre>~%" (html-escape (topic-payload topic)))
      (format s "</section>~%"))
    (format s "<h2>Relations</h2>~%<pre>~%")
    (dolist (edge (topicmap-result-relations result))
      (format s "~A --~A/~A--> ~A~%"
              (html-escape (relation-source edge))
              (html-escape (relation-kind edge))
              (html-escape (relation-label edge))
              (html-escape (relation-target edge))))
    (format s "</pre>~%")
    (format s "<h2>Shell probes</h2><pre>~A</pre>~%"
            (html-escape (topicmap-result-shell-probes result)))
    (format s "<h2>Persistence</h2><pre>SQLite DB: ~A~%SQL: ~A~%DOT: ~A~%SVG: ~A</pre>~%"
            (html-escape (safe-namestring (topicmap-result-db-path result)))
            (html-escape (safe-namestring (topicmap-result-sql-path result)))
            (html-escape (safe-namestring (topicmap-result-dot-path result)))
            (html-escape (safe-namestring (topicmap-result-svg-path result))))
    (format s "</body>~%</html>~%"))
  (topicmap-result-html-path result))

(defun open-topicmap-html (result)
  (handler-case
      (progn
        (uiop:run-program
         (list "open" (safe-namestring (topicmap-result-html-path result)))
         :ignore-error-status t)
        t)
    (error (condition)
      (format *error-output* "~&Could not open browser automatically: ~A~%" condition)
      nil)))

(defun maybe-call (package-name symbol-name &rest args)
  (let* ((pkg (find-package package-name))
         (sym (and pkg (find-symbol symbol-name pkg))))
    (when (and sym (fboundp sym))
      (apply (symbol-function sym) args)
      t)))

(defun inspect-topicmap (result)
  "Open an inspector if a HyperDoc/CLOG inspector hook is present.
Falls back to CL:INSPECT and leaves the HTML topicmap openable in a browser."
  (or
   (maybe-call "HYPERDOC" "INSPECT" result)
   (maybe-call "HYPERDOC" "OPEN-INSPECTOR" result)
   (maybe-call "HYPERDOC/INSPECTOR" "INSPECT" result)
   (maybe-call "HYPERDOC/INSPECTOR" "OPEN-INSPECTOR" result)
   (maybe-call "CLOG-TOOLS" "CLOG-INSPECTOR" result)
   (maybe-call "CLOG-INSPECTOR" "INSPECT" result)
   (progn
     (format t "~&No HyperDoc/CLOG inspector hook found. Falling back to CL:INSPECT.~%")
     (inspect result)
     nil))
  result)

(defun run (&key (assets-dir nil) (inspect t) (open-browser t))
  (let ((result (make-current-topicmap :assets-dir assets-dir)))
    (persist-topicmap result)
    (write-topicmap-dot result)
    (try-render-svg result)
    (write-topicmap-html result)
    (format t "~&Persisted topicmap DB: ~A~%" (safe-namestring (topicmap-result-db-path result)))
    (format t "~&Wrote topicmap HTML: ~A~%" (safe-namestring (topicmap-result-html-path result)))
    (when open-browser
      (open-topicmap-html result))
    (when inspect
      (inspect-topicmap result))
    result))
