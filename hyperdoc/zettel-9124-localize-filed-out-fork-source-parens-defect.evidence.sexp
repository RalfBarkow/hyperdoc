(:TASK
 (!LOCALIZE-FILED-OUT-FORK-SOURCE-PARENS-DEFECT :REPO :HYPERDOC :FILE
  "hyperdoc/fedwiki-materialization.lisp")
 :ZETTEL 9124 :SOURCE-FILE "hyperdoc/fedwiki-materialization.lisp"
 :PREVIOUS-RESULT
 ((CHECK-LISP-PARENS-EXIT-CODE 255) (CONDITION "Unmatched bracket or quote")
  (GIT-STATUS "MM hyperdoc/fedwiki-materialization.lisp"))
 :SOURCE-SHAPE
 (:LINE-COUNT 756 :REMOTE-FORK-MARKER-COUNT 2
  :PAGE-WITH-APPENDED-FORK-ACTION-DEFUN-COUNT 1
  :DECLARE-IGNORE-STRING-KEY-COUNT 1)
 :EMACS-CHECK-PARENS-LOCALIZATION
 (:COMMAND
  ("nix" "develop" "-c" "emacs" "--batch" "-l"
   "/tmp/nix-shell.OE15UR/z9124-localize-check-parens.el"
   "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
Z9124-CHECK-PARENS-ERROR file=hyperdoc/fedwiki-materialization.lisp line=511 column=23 point=23380 error=(user-error \"Unmatched bracket or quote\")
---CONTEXT-START---

(DEFUN (SETF FEDWIKI-MATERIALIZATION-JSON-SLOT)
       (VALUE JSON STRING-KEY KEYWORD-KEY)
  \"Set JSON slot STRING-KEY / KEYWORD-KEY on a hash-table or plist-like object.\"
  (COND ((HASH-TABLE-P JSON) (SETF (GETHASH STRING-KEY JSON) VALUE))
         (SETF (GETF JSON KEYWORD-KEY) VALUE))
        (T
         (ERROR \"Cannot set JSON slot ~S / ~S on ~S\" STRING-KEY KEYWORD-KEY
                JSON))))


(DEFUN FEDWIKI-MATERIALIZATION-JSON-SEQUENCE-LIST (SEQUENCE)
  \"Return SEQUENCE as a list, accepting vectors and lists but not strings.\"
  (COND ((NULL SEQUENCE) NIL)
        ((AND (VECTORP SEQUENCE) (NOT (STRINGP SEQUENCE)))
         (LOOP FOR ITEM ACROSS SEQUENCE
               COLLECT ITEM))

---CONTEXT-END---
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
Loading /nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/share/emacs/site-lisp/site-start...
Mark set
"
  :EXIT-CODE 42)
 :GIT-STATUS
 (:COMMAND
  (#1="nix" #2="develop" #3="-c" #4="git" "status" "--short" "--"
   "hyperdoc/fedwiki-materialization.lisp"
   "hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp"
   "hyperdoc/zettel-9124-repair-filed-out-fork-source-parens.evidence.sexp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
MM hyperdoc/fedwiki-materialization.lisp
A  hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp
?? hyperdoc/zettel-9124-repair-filed-out-fork-source-parens.evidence.sexp
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
"
  :EXIT-CODE 0)
 :UNSTAGED-DIFF
 (:COMMAND
  (#1# #2# #3# #4# "diff" "--" "hyperdoc/fedwiki-materialization.lisp") :STDOUT
  "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
diff --git a/hyperdoc/fedwiki-materialization.lisp b/hyperdoc/fedwiki-materialization.lisp
index 571f58d4..59b5d4f0 100644
--- a/hyperdoc/fedwiki-materialization.lisp
+++ b/hyperdoc/fedwiki-materialization.lisp
@@ -614,7 +614,9 @@ provenance to the canonical page JSON.\"
     COPY))
 
 
+
 ;;;; Remote FedWiki fork materialization
+;;;; Filed out from the live image during Zettel 9124.
 
 (defun fedwiki-materialization-json-slot (json string-key keyword-key)
   \"Return JSON slot STRING-KEY / KEYWORD-KEY from a hash-table or plist-like object.\"
@@ -630,6 +632,7 @@ provenance to the canonical page JSON.\"
 (defun (setf fedwiki-materialization-json-slot)
     (value json string-key keyword-key)
   \"Set JSON slot STRING-KEY / KEYWORD-KEY on a hash-table or plist-like object.\"
+  (declare (ignore string-key))
   (cond
     ((hash-table-p json)
      (setf (gethash string-key json) value))
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
"
  :EXIT-CODE 0)
 :STAGED-DIFF
 (:COMMAND
  (#1# #2# #3# #4# "diff" "--cached" "--"
   "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
diff --git a/hyperdoc/fedwiki-materialization.lisp b/hyperdoc/fedwiki-materialization.lisp
index 370f6241..571f58d4 100644
--- a/hyperdoc/fedwiki-materialization.lisp
+++ b/hyperdoc/fedwiki-materialization.lisp
@@ -484,3 +484,270 @@
     (assert-equal \"minab-school-strike\"
                   (fedwiki-materialization-selector-of plan))
     plan))
+
+
+;;;; Remote FedWiki fork materialization
+;;;; Filed out from the live image during Zettel 9124.
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-JSON-SLOT (JSON STRING-KEY KEYWORD-KEY)
+  \"Return JSON slot STRING-KEY / KEYWORD-KEY from a hash-table or plist-like object.\"
+  (COND
+   ((HASH-TABLE-P JSON)
+    (OR (GETHASH STRING-KEY JSON) (GETHASH KEYWORD-KEY JSON)))
+   ((LISTP JSON)
+    (OR (GETF JSON KEYWORD-KEY)
+        (GETF JSON (INTERN (STRING-UPCASE STRING-KEY) :KEYWORD))))
+   (T NIL)))
+
+
+(DEFUN (SETF FEDWIKI-MATERIALIZATION-JSON-SLOT)
+       (VALUE JSON STRING-KEY KEYWORD-KEY)
+  \"Set JSON slot STRING-KEY / KEYWORD-KEY on a hash-table or plist-like object.\"
+  (COND ((HASH-TABLE-P JSON) (SETF (GETHASH STRING-KEY JSON) VALUE))
+         (SETF (GETF JSON KEYWORD-KEY) VALUE))
+        (T
+         (ERROR \"Cannot set JSON slot ~S / ~S on ~S\" STRING-KEY KEYWORD-KEY
+                JSON))))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-JSON-SEQUENCE-LIST (SEQUENCE)
+  \"Return SEQUENCE as a list, accepting vectors and lists but not strings.\"
+  (COND ((NULL SEQUENCE) NIL)
+        ((AND (VECTORP SEQUENCE) (NOT (STRINGP SEQUENCE)))
+         (LOOP FOR ITEM ACROSS SEQUENCE
+               COLLECT ITEM))
+        ((AND (LISTP SEQUENCE) (NOT (STRINGP SEQUENCE))) SEQUENCE)
+        (T (ERROR \"Expected JSON sequence, got ~S\" SEQUENCE))))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-COPY-JSON (VALUE)
+  \"Deep-copy the JSON-like structures used by HyperDoc FedWiki pages.\"
+  (COND
+   ((HASH-TABLE-P VALUE)
+    (LET ((COPY (MAKE-HASH-TABLE :TEST (HASH-TABLE-TEST VALUE))))
+      (LOOP FOR KEY BEING THE HASH-KEYS OF VALUE USING (HASH-VALUE SUBVALUE)
+            DO (SETF (GETHASH KEY COPY)
+                       (FEDWIKI-MATERIALIZATION-COPY-JSON SUBVALUE)))
+      COPY))
+   ((AND (VECTORP VALUE) (NOT (STRINGP VALUE)))
+    (COERCE
+     (LOOP FOR ITEM ACROSS VALUE
+           COLLECT (FEDWIKI-MATERIALIZATION-COPY-JSON ITEM))
+     'VECTOR))
+   ((CONSP VALUE) (COPY-TREE VALUE)) (T VALUE)))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-APPEND-JSON-SEQUENCE (SEQUENCE ITEM)
+  \"Append ITEM to SEQUENCE, preserving vector-vs-list representation.\"
+  (LET ((ITEMS
+         (APPEND (FEDWIKI-MATERIALIZATION-JSON-SEQUENCE-LIST SEQUENCE)
+                 (LIST ITEM))))
+    (IF (VECTORP SEQUENCE)
+        (COERCE ITEMS 'VECTOR)
+        ITEMS)))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-JSON-OBJECT-KEYS (JSON)
+  \"Return JSON object keys for hash-table or plist-like JSON objects.\"
+  (COND
+   ((HASH-TABLE-P JSON)
+    (LOOP FOR KEY BEING THE HASH-KEYS OF JSON
+          COLLECT KEY))
+   ((LISTP JSON)
+    (LOOP FOR (KEY VALUE) ON JSON BY #'CDDR
+          COLLECT KEY))
+   (T NIL)))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-CANONICAL-FORK-ACTION-KEY-P (KEY)
+  \"Return true when KEY is one of the canonical fork journal action keys.\"
+  (MEMBER KEY '(\"type\" \"site\" \"date\" :TYPE :SITE :DATE) :TEST #'EQUAL))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-MAKE-EXPLICIT-FORK-ACTION (&KEY SITE DATE)
+  \"Return the canonical FedWiki fork journal action.
+
+The canonical action intentionally has only TYPE, SITE, and DATE. Source slug,
+target site, target slug, reader purpose, and HyperDoc routing provenance belong
+outside the canonical page JSON.\"
+  (UNLESS (AND (STRINGP SITE) (> (LENGTH SITE) 0))
+    (ERROR \"Missing source site for fork action: ~S\" SITE))
+  (UNLESS (NUMBERP DATE) (ERROR \"Missing numeric fork action date: ~S\" DATE))
+  (LIST :TYPE \"fork\" :SITE SITE :DATE DATE))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-CANONICAL-FORK-ACTION-P (ACTION)
+  \"Return true when ACTION is a canonical FedWiki fork action.\"
+  (AND (EQUAL (FEDWIKI-MATERIALIZATION-JSON-SLOT ACTION \"type\" :TYPE) \"fork\")
+       (STRINGP (FEDWIKI-MATERIALIZATION-JSON-SLOT ACTION \"site\" :SITE))
+       (NUMBERP (FEDWIKI-MATERIALIZATION-JSON-SLOT ACTION \"date\" :DATE))
+       (EVERY #'FEDWIKI-MATERIALIZATION-CANONICAL-FORK-ACTION-KEY-P
+              (FEDWIKI-MATERIALIZATION-JSON-OBJECT-KEYS ACTION))))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-PAGE-STORY-ITEM-IDS (PAGE)
+  \"Return the story item ids of PAGE, preserving story order.\"
+  (LOOP FOR ITEM IN (FEDWIKI-MATERIALIZATION-JSON-SEQUENCE-LIST
+                     (FEDWIKI-MATERIALIZATION-JSON-SLOT PAGE \"story\" :STORY))
+        COLLECT (FEDWIKI-MATERIALIZATION-JSON-SLOT ITEM \"id\" :ID)))
+
+
+(DEFUN FEDWIKI-MATERIALIZATION-PAGE-WITH-APPENDED-FORK-ACTION
+       (REMOTE-PAGE FORK-ACTION)
+  \"Return a local fork candidate copied from REMOTE-PAGE.
+
+The operation preserves the page title, story item ids, story order, and source
+journal entries. It appends FORK-ACTION as the final journal action. It does not
+write the page, does not normalize plugin items, and does not add HyperDoc-only
+provenance to the canonical page JSON.\"
+  (UNLESS REMOTE-PAGE (ERROR \"Missing remote page JSON.\"))
+  (UNLESS (FEDWIKI-MATERIALIZATION-CANONICAL-FORK-ACTION-P FORK-ACTION)
+    (ERROR \"Not a canonical FedWiki fork action: ~S\" FORK-ACTION))
+  (LET* ((COPY (FEDWIKI-MATERIALIZATION-COPY-JSON REMOTE-PAGE))
+         (JOURNAL (FEDWIKI-MATERIALIZATION-JSON-SLOT COPY \"journal\" :JOURNAL))
+         (NEW-JOURNAL
+          (FEDWIKI-MATERIALIZATION-APPEND-JSON-SEQUENCE JOURNAL
+           (FEDWIKI-MATERIALIZATION-COPY-JSON FORK-ACTION))))
+    (SETF (FEDWIKI-MATERIALIZATION-JSON-SLOT COPY \"journal\" :JOURNAL)
+            NEW-JOURNAL)
+    COPY))
+
+
+;;;; Remote FedWiki fork materialization
+
+(defun fedwiki-materialization-json-slot (json string-key keyword-key)
+  \"Return JSON slot STRING-KEY / KEYWORD-KEY from a hash-table or plist-like object.\"
+  (cond
+    ((hash-table-p json)
+     (or (gethash string-key json)
+         (gethash keyword-key json)))
+    ((listp json)
+     (or (getf json keyword-key)
+         (getf json (intern (string-upcase string-key) :keyword))))
+    (t nil)))
+
+(defun (setf fedwiki-materialization-json-slot)
+    (value json string-key keyword-key)
+  \"Set JSON slot STRING-KEY / KEYWORD-KEY on a hash-table or plist-like object.\"
+  (cond
+    ((hash-table-p json)
+     (setf (gethash string-key json) value))
+    ((listp json)
+     (setf (getf json keyword-key) value))
+    (t
+     (error \"Cannot set JSON slot ~S / ~S on ~S\"
+            string-key keyword-key json))))
+
+(defun fedwiki-materialization-json-sequence-list (sequence)
+  \"Return SEQUENCE as a list, accepting vectors and lists but not strings.\"
+  (cond
+    ((null sequence) nil)
+    ((and (vectorp sequence)
+          (not (stringp sequence)))
+     (loop for item across sequence collect item))
+    ((and (listp sequence)
+          (not (stringp sequence)))
+     sequence)
+    (t
+     (error \"Expected JSON sequence, got ~S\" sequence))))
+
+(defun fedwiki-materialization-copy-json (value)
+  \"Deep-copy the JSON-like structures used by HyperDoc FedWiki pages.\"
+  (cond
+    ((hash-table-p value)
+     (let ((copy (make-hash-table :test (hash-table-test value))))
+       (loop for key being the hash-keys of value
+             using (hash-value subvalue)
+             do (setf (gethash key copy)
+                      (fedwiki-materialization-copy-json subvalue)))
+       copy))
+    ((and (vectorp value)
+          (not (stringp value)))
+     (coerce
+      (loop for item across value
+            collect (fedwiki-materialization-copy-json item))
+      'vector))
+    ((consp value)
+     (copy-tree value))
+    (t value)))
+
+(defun fedwiki-materialization-append-json-sequence (sequence item)
+  \"Append ITEM to SEQUENCE, preserving vector-vs-list representation.\"
+  (let ((items
+          (append (fedwiki-materialization-json-sequence-list sequence)
+                  (list item))))
+    (if (vectorp sequence)
+        (coerce items 'vector)
+        items)))
+
+(defun fedwiki-materialization-json-object-keys (json)
+  \"Return JSON object keys for hash-table or plist-like JSON objects.\"
+  (cond
+    ((hash-table-p json)
+     (loop for key being the hash-keys of json collect key))
+    ((listp json)
+     (loop for (key value) on json by #'cddr
+           collect key))
+    (t nil)))
+
+(defun fedwiki-materialization-canonical-fork-action-key-p (key)
+  \"Return true when KEY is one of the canonical fork journal action keys.\"
+  (member key
+          '(\"type\" \"site\" \"date\" :type :site :date)
+          :test #'equal))
+
+(defun fedwiki-materialization-make-explicit-fork-action
+    (&key site date)
+  \"Return the canonical FedWiki fork journal action.\"
+  (unless (and (stringp site)
+               (> (length site) 0))
+    (error \"Missing source site for fork action: ~S\" site))
+  (unless (numberp date)
+    (error \"Missing numeric fork action date: ~S\" date))
+  (list :type \"fork\"
+        :site site
+        :date date))
+
+(defun fedwiki-materialization-canonical-fork-action-p (action)
+  \"Return true when ACTION is a canonical FedWiki fork action.\"
+  (and (equal (fedwiki-materialization-json-slot action \"type\" :type)
+              \"fork\")
+       (stringp
+        (fedwiki-materialization-json-slot action \"site\" :site))
+       (numberp
+        (fedwiki-materialization-json-slot action \"date\" :date))
+       (every #'fedwiki-materialization-canonical-fork-action-key-p
+              (fedwiki-materialization-json-object-keys action))))
+
+(defun fedwiki-materialization-page-story-item-ids (page)
+  \"Return the story item ids of PAGE, preserving story order.\"
+  (loop for item in
+        (fedwiki-materialization-json-sequence-list
+         (fedwiki-materialization-json-slot page \"story\" :story))
+        collect
+        (fedwiki-materialization-json-slot item \"id\" :id)))
+
+(defun fedwiki-materialization-page-with-appended-fork-action
+    (remote-page fork-action)
+  \"Return a local fork candidate copied from REMOTE-PAGE.
+
+The operation preserves the page title, story item ids, story order, and source
+journal entries. It appends FORK-ACTION as the final journal action. It does not
+write the page, does not normalize plugin items, and does not add HyperDoc-only
+provenance to the canonical page JSON.\"
+  (unless remote-page
+    (error \"Missing remote page JSON.\"))
+  (unless (fedwiki-materialization-canonical-fork-action-p fork-action)
+    (error \"Not a canonical FedWiki fork action: ~S\" fork-action))
+  (let* ((copy
+           (fedwiki-materialization-copy-json remote-page))
+         (journal
+           (fedwiki-materialization-json-slot copy \"journal\" :journal))
+         (new-journal
+           (fedwiki-materialization-append-json-sequence
+            journal
+            (fedwiki-materialization-copy-json fork-action))))
+    (setf (fedwiki-materialization-json-slot copy \"journal\" :journal)
+          new-journal)
+    copy))
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
"
  :EXIT-CODE 0)
 :DIFF-STAT
 (:COMMAND
  (#1# #2# #3# #4# "diff" "--stat" "--"
   "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
 hyperdoc/fedwiki-materialization.lisp | 3 +++
 1 file changed, 3 insertions(+)
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
"
  :EXIT-CODE 0)
 :ACCEPTANCE
 ((SOURCE-NOT-MODIFIED T) (GIT-INDEX-NOT-MODIFIED T) (COMMIT-NOT-PERFORMED T)
  (PAGE-ATTACHED-ASDF-NOT-WRITTEN T) (SQLITE-NOT-CREATED T))
 :NEXT-TASK
 (!REPAIR-LOCALIZED-FILED-OUT-FORK-SOURCE-PARENS-DEFECT :REPO :HYPERDOC :FILE
  "hyperdoc/fedwiki-materialization.lisp"))
