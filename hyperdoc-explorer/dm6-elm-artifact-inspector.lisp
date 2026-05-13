;;;; DM6 Elm artifact inspector.
;;;; Generated from SLY/MREPL and intentionally persisted as source.


(IN-PACKAGE #:HYPERDOC)


(DEFPARAMETER *DM6-ELM-DEFAULT-REPO* #P"/Users/rgb/workspace/dm6-elm/")


(DEFUN DM6-HYPERDOC-ROOT () (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY :HYPERDOC))


(DEFUN DM6-HYPERDOC-PATH (RELATIVE)
  (MERGE-PATHNAMES RELATIVE (DM6-HYPERDOC-ROOT)))


(DEFUN DM6-ASSET-PATH (NAME)
  (MERGE-PATHNAMES (PATHNAME NAME) (DM6-HYPERDOC-PATH #P"assets/dm6-elm/")))


(DEFUN DM6-WRITE-FILE-STRING (PATHNAME STRING)
  (ENSURE-DIRECTORIES-EXIST PATHNAME)
  (WITH-OPEN-FILE
      (OUT PATHNAME :DIRECTION :OUTPUT :IF-EXISTS :SUPERSEDE :IF-DOES-NOT-EXIST
       :CREATE :EXTERNAL-FORMAT :UTF-8)
    (WRITE-STRING STRING OUT))
  PATHNAME)


(DEFUN DM6-READ-FILE-STRING (PATHNAME)
  (WHEN (PROBE-FILE PATHNAME)
    (WITH-OPEN-FILE (IN PATHNAME :DIRECTION :INPUT :EXTERNAL-FORMAT :UTF-8)
      (WITH-OUTPUT-TO-STRING (OUT)
        (LOOP FOR LINE = (READ-LINE IN NIL NIL)
              WHILE LINE
              DO (WRITE-STRING LINE OUT) (TERPRI OUT))))))


(DEFUN DM6-LINES (STRING)
  (WITH-INPUT-FROM-STRING (IN (OR STRING ""))
    (LOOP FOR LINE = (READ-LINE IN NIL NIL)
          WHILE LINE
          COLLECT LINE)))


(DEFUN DM6-TRIM (STRING)
  (STRING-TRIM '(#\  #\Tab #\Newline #\Return) (OR STRING "")))


(DEFUN DM6-FIRST-LINE (STRING) (FIRST (DM6-LINES STRING)))


(DEFUN DM6-FIRST-TOKEN (STRING)
  (LET* ((LINE (DM6-TRIM (DM6-FIRST-LINE STRING))) (SPACE (POSITION #\  LINE)))
    (IF SPACE
        (SUBSEQ LINE 0 SPACE)
        LINE)))


(DEFUN DM6-RUN/SOFT (DIRECTORY PROGRAM &REST ARGS)
  (LET ((OUT (MAKE-STRING-OUTPUT-STREAM)))
    (HANDLER-CASE
     (PROGN
      (UIOP/RUN-PROGRAM:RUN-PROGRAM (CONS PROGRAM ARGS) :DIRECTORY DIRECTORY
                                    :OUTPUT OUT :ERROR-OUTPUT OUT
                                    :IGNORE-ERROR-STATUS T)
      (GET-OUTPUT-STREAM-STRING OUT))
     (ERROR (C) (FORMAT NIL "ERROR running ~A ~{~A~^ ~}: ~A" PROGRAM ARGS C)))))


(DEFUN DM6-RUN/PRINT (DIRECTORY PROGRAM &REST ARGS)
  (LET ((OUTPUT (APPLY #'DM6-RUN/SOFT DIRECTORY PROGRAM ARGS)))
    (FORMAT T "~&~A~%" OUTPUT)
    OUTPUT))


(DEFUN DM6-ENSURE-INSPECTOR-RUNTIME! ()
  (HANDLER-CASE
   (PROGN
    (ASDF/OPERATE:LOAD-SYSTEM :HYPERDOC/EXPLORER)
    (ASDF/OPERATE:LOAD-SYSTEM :HYPERDOC/INSPECTOR)
    T)
   (ERROR (C) (FORMAT T "~&Could not load inspector runtime: ~A~%" C) NIL)))


(DEFCLASS DM6-ELM-ARTIFACT NIL
          ((REPO :READER DM6-ELM-REPO-OF :INITARG :REPO :INITFORM
            *DM6-ELM-DEFAULT-REPO*)
           (APPEMBED-BUNDLE :READER DM6-ELM-APPEMBED-BUNDLE-OF :INITARG
            :APPEMBED-BUNDLE :INITFORM
            (DM6-HYPERDOC-PATH #P"assets/dm6-elm/app.js"))
           (MAIN-BUNDLE :READER DM6-ELM-MAIN-BUNDLE-OF :INITARG :MAIN-BUNDLE
            :INITFORM (DM6-HYPERDOC-PATH #P"assets/dm6-elm/main.js"))
           (STANDALONE-SHELL :READER DM6-ELM-STANDALONE-SHELL-OF :INITARG
            :STANDALONE-SHELL :INITFORM
            (DM6-HYPERDOC-PATH #P"assets/dm6-elm/dm6-standalone-shell.html"))
           (SIDE-BY-SIDE-PAGE :READER DM6-ELM-SIDE-BY-SIDE-PAGE-OF :INITARG
            :SIDE-BY-SIDE-PAGE :INITFORM
            (DM6-HYPERDOC-PATH
             #P"hyperdoc/DM6 AppEmbed Side-by-Side Comparison.html"))
           (NIX-INSTALLABLE :READER DM6-ELM-NIX-INSTALLABLE-OF :INITARG
            :NIX-INSTALLABLE :INITFORM NIL)))


(DEFUN MAKE-DM6-ELM-ARTIFACT
       (
        &KEY (REPO *DM6-ELM-DEFAULT-REPO*)
        (APPEMBED-BUNDLE (DM6-HYPERDOC-PATH #P"assets/dm6-elm/app.js"))
        (MAIN-BUNDLE (DM6-HYPERDOC-PATH #P"assets/dm6-elm/main.js"))
        (STANDALONE-SHELL
         (DM6-HYPERDOC-PATH #P"assets/dm6-elm/dm6-standalone-shell.html"))
        (SIDE-BY-SIDE-PAGE
         (DM6-HYPERDOC-PATH
          #P"hyperdoc/DM6 AppEmbed Side-by-Side Comparison.html"))
        NIX-INSTALLABLE)
  (MAKE-INSTANCE 'DM6-ELM-ARTIFACT :REPO REPO :APPEMBED-BUNDLE APPEMBED-BUNDLE
                 :MAIN-BUNDLE MAIN-BUNDLE :STANDALONE-SHELL STANDALONE-SHELL
                 :SIDE-BY-SIDE-PAGE SIDE-BY-SIDE-PAGE :NIX-INSTALLABLE
                 NIX-INSTALLABLE))


(DEFVAR *DM6-ARTIFACT* (MAKE-DM6-ELM-ARTIFACT))


(DEFUN DM6-CURRENT-ARTIFACT ()
  (IF (AND (BOUNDP '*DM6-ARTIFACT*) *DM6-ARTIFACT*)
      *DM6-ARTIFACT*
      (SETF *DM6-ARTIFACT* (MAKE-DM6-ELM-ARTIFACT))))


(DEFCLASS DM6-SIDE-BY-SIDE-SURFACE NIL
          ((ARTIFACT :READER DM6-SIDE-BY-SIDE-ARTIFACT-OF :INITARG :ARTIFACT)
           (TITLE :READER DM6-SIDE-BY-SIDE-TITLE-OF :INITARG :TITLE :INITFORM
            "DM6 AppEmbed Side-by-Side Comparison")))


(DEFUN MAKE-DM6-SIDE-BY-SIDE-SURFACE
       (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (MAKE-INSTANCE 'DM6-SIDE-BY-SIDE-SURFACE :ARTIFACT ARTIFACT))


(DEFUN DM6-CLOG-INSPECT (OBJECT)
  (DM6-ENSURE-INSPECTOR-RUNTIME!)
  (LET* ((PKG (FIND-PACKAGE "CLOG-MOLDABLE-INSPECTOR"))
         (SYM (AND PKG (FIND-SYMBOL "CLOG-INSPECT" PKG))))
    (IF (AND SYM (FBOUNDP SYM))
        (FUNCALL SYM :OBJECT OBJECT)
        (FORMAT T
                "~&CLOG inspector entry point not found; returning object only.~%")))
  OBJECT)


(DEFUN DM6-ADD-DM6-ASSETS-FOR-CURRENT-VIEW ()
  "Register /dm6-elm/ for the currently rendering view only."
  (VIEWS:ADD-ASSET-PATH "/dm6-elm/" (DM6-ASSET-PATH "")))


(DEFUN DM6-GIT (ARTIFACT &REST ARGS)
  (APPLY #'DM6-RUN/SOFT (DM6-ELM-REPO-OF ARTIFACT) "git" ARGS))


(DEFUN DM6-GIT-ONE-LINE (ARTIFACT &REST ARGS)
  (DM6-TRIM (DM6-FIRST-LINE (APPLY #'DM6-GIT ARTIFACT ARGS))))


(DEFUN DM6-FILE-BYTES (PATHNAME)
  (WHEN (PROBE-FILE PATHNAME)
    (WITH-OPEN-FILE
        (IN PATHNAME :DIRECTION :INPUT :ELEMENT-TYPE '(UNSIGNED-BYTE 8))
      (FILE-LENGTH IN))))


(DEFUN DM6-FILE-SHA256 (PATHNAME)
  (WHEN (PROBE-FILE PATHNAME)
    (LET* ((NAMESTRING (NAMESTRING (TRUENAME PATHNAME)))
           (DIR (MAKE-PATHNAME :NAME NIL :TYPE NIL :DEFAULTS PATHNAME))
           (SHA
            (DM6-FIRST-TOKEN
             (DM6-RUN/SOFT DIR "shasum" "-a" "256" NAMESTRING))))
      (IF (AND SHA (= (LENGTH SHA) 64))
          SHA
          (LET ((SHA2
                 (DM6-FIRST-TOKEN (DM6-RUN/SOFT DIR "sha256sum" NAMESTRING))))
            (AND SHA2 (= (LENGTH SHA2) 64) SHA2))))))


(DEFUN DM6-ELM-JSON-PATH (ARTIFACT)
  (MERGE-PATHNAMES #P"elm.json" (DM6-ELM-REPO-OF ARTIFACT)))


(DEFUN DM6-ELM-VERSION-LINE (ARTIFACT)
  (OR
   (FIND-IF (LAMBDA (LINE) (SEARCH "\"elm-version\"" LINE :TEST #'CHAR=))
            (DM6-LINES
             (OR (DM6-READ-FILE-STRING (DM6-ELM-JSON-PATH ARTIFACT)) "")))
   "No elm-version line found."))


(DEFUN DM6-VERSION-ALIST (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  `(("Repository" . ,(NAMESTRING (DM6-ELM-REPO-OF ARTIFACT)))
    ("Git branch"
     . ,(DM6-GIT-ONE-LINE ARTIFACT "rev-parse" "--abbrev-ref" "HEAD"))
    ("Git commit"
     . ,(DM6-GIT-ONE-LINE ARTIFACT "rev-parse" "--short=12" "HEAD"))
    ("Git latest"
     . ,(DM6-GIT-ONE-LINE ARTIFACT "log" "-1" "--format=%h %ad %s"
                          "--date=iso-strict"))
    ("Elm version" . ,(DM6-ELM-VERSION-LINE ARTIFACT))
    ("AppEmbed bundle" . ,(NAMESTRING (DM6-ELM-APPEMBED-BUNDLE-OF ARTIFACT)))
    ("AppEmbed bytes"
     . ,(OR
         (AND (PROBE-FILE (DM6-ELM-APPEMBED-BUNDLE-OF ARTIFACT))
              (PRINC-TO-STRING
               (DM6-FILE-BYTES (DM6-ELM-APPEMBED-BUNDLE-OF ARTIFACT))))
         "missing"))
    ("AppEmbed sha256"
     . ,(OR (DM6-FILE-SHA256 (DM6-ELM-APPEMBED-BUNDLE-OF ARTIFACT)) "missing"))
    ("Main bundle" . ,(NAMESTRING (DM6-ELM-MAIN-BUNDLE-OF ARTIFACT)))
    ("Main bytes"
     . ,(OR
         (AND (PROBE-FILE (DM6-ELM-MAIN-BUNDLE-OF ARTIFACT))
              (PRINC-TO-STRING
               (DM6-FILE-BYTES (DM6-ELM-MAIN-BUNDLE-OF ARTIFACT))))
         "missing"))
    ("Main sha256"
     . ,(OR (DM6-FILE-SHA256 (DM6-ELM-MAIN-BUNDLE-OF ARTIFACT)) "missing"))))


(DEFUN DM6-NIX-METADATA (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (IF (PROBE-FILE (MERGE-PATHNAMES #P"flake.nix" (DM6-ELM-REPO-OF ARTIFACT)))
      (DM6-RUN/SOFT (DM6-ELM-REPO-OF ARTIFACT) "nix" "flake" "metadata"
                    "--quiet" ".")
      "No flake.nix found in dm6-elm repo."))


(DEFUN DM6-DOT-ESCAPE (STRING)
  (WITH-OUTPUT-TO-STRING (OUT)
    (LOOP FOR CH ACROSS (OR STRING "")
          DO (CASE CH
               (#\" (WRITE-STRING "\\\"" OUT))
               (#\\ (WRITE-STRING "\\\\" OUT))
               (#\Newline (WRITE-STRING "\\n" OUT))
               (OTHERWISE (WRITE-CHAR CH OUT))))))


(DEFUN DM6-METADATA-INPUT-NAMES (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (LET ((METADATA (DM6-NIX-METADATA ARTIFACT)))
    (REMOVE-DUPLICATES
     (LOOP FOR LINE IN (DM6-LINES METADATA)
           WHEN (OR (SEARCH "───" LINE :TEST #'CHAR=)
                    (SEARCH "---" LINE :TEST #'CHAR=))
           COLLECT (LET* ((TRIMMED (DM6-TRIM LINE))
                          (COLON (POSITION #\: TRIMMED)))
                     (IF COLON
                         (DM6-TRIM
                          (SUBSEQ TRIMMED
                                  (OR (POSITION-IF #'ALPHANUMERICP TRIMMED) 0)
                                  COLON))
                         TRIMMED)))
     :TEST #'EQUAL)))


(DEFUN DM6-NIX-INPUT-DOT (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (WITH-OUTPUT-TO-STRING (OUT)
    (LET ((INPUTS (DM6-METADATA-INPUT-NAMES ARTIFACT)))
      (FORMAT OUT "digraph dm6_nix_inputs {~%")
      (FORMAT OUT "  rankdir=LR;~%")
      (FORMAT OUT "  node [shape=box, style=rounded];~%")
      (FORMAT OUT "  root [label=\"dm6-elm flake\"];~%")
      (IF INPUTS
          (LOOP FOR INPUT IN INPUTS
                FOR N FROM 0
                DO (FORMAT OUT "  n~D [label=\"~A\"];~%" N
                           (DM6-DOT-ESCAPE INPUT)) (FORMAT OUT
                                                           "  root -> n~D;~%"
                                                           N))
          (PROGN
           (FORMAT OUT
                   "  missing [label=\"No flake input metadata available\"];~%")
           (FORMAT OUT "  root -> missing;~%")))
      (FORMAT OUT "}~%"))))


(DEFUN DM6-WRITE-NIX-GRAPH-SVG! (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (LET* ((DOT-PATH (DM6-ASSET-PATH "dm6-nix-input-graph.dot"))
         (SVG-PATH (DM6-ASSET-PATH "dm6-nix-input-graph.svg"))
         (DIAG-PATH (DM6-ASSET-PATH "dm6-nix-input-graph.diagnostic.txt")))
    (ENSURE-DIRECTORIES-EXIST DOT-PATH)
    (DM6-WRITE-FILE-STRING DOT-PATH (DM6-NIX-INPUT-DOT ARTIFACT))
    (LET ((DIAGNOSTIC
           (DM6-RUN/SOFT (DM6-ASSET-PATH "") "dot" "-Tsvg"
                         (NAMESTRING DOT-PATH) "-o" (NAMESTRING SVG-PATH))))
      (DM6-WRITE-FILE-STRING DIAG-PATH DIAGNOSTIC)
      (FORMAT T "~&Wrote DOT: ~A~%" DOT-PATH)
      (FORMAT T "~&Wrote SVG: ~A ~:[(missing)~;(ok)~]~%" SVG-PATH
              (PROBE-FILE SVG-PATH))
      (LIST :DOT DOT-PATH :SVG SVG-PATH :DIAGNOSTIC DIAG-PATH :SVG-PRESENT-P
            (NOT (NULL (PROBE-FILE SVG-PATH)))))))


(DEFUN DM6-CHECK-SIDE-BY-SIDE-ASSETS!
       (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (LET ((CHECKS
         `(("dm6-elm repo" . ,(DM6-ELM-REPO-OF ARTIFACT))
           ("AppEmbed bundle" . ,(DM6-ELM-APPEMBED-BUNDLE-OF ARTIFACT))
           ("Main bundle" . ,(DM6-ELM-MAIN-BUNDLE-OF ARTIFACT))
           ("Inline adapter" . ,(DM6-ASSET-PATH "hyperdoc-dm6-inline.js"))
           ("Inline CSS" . ,(DM6-ASSET-PATH "hyperdoc-dm6-inline.css"))
           ("Standalone shell" . ,(DM6-ELM-STANDALONE-SHELL-OF ARTIFACT))
           ("Side-by-side page" . ,(DM6-ELM-SIDE-BY-SIDE-PAGE-OF ARTIFACT))
           ("Nix graph DOT" . ,(DM6-ASSET-PATH "dm6-nix-input-graph.dot"))
           ("Nix graph SVG" . ,(DM6-ASSET-PATH "dm6-nix-input-graph.svg")))))
    (LOOP FOR (LABEL . PATH) IN CHECKS
          COLLECT (LET ((PRESENT (NOT (NULL (PROBE-FILE PATH)))))
                    (FORMAT T "~&~A: ~:[missing~;ok~] ~A~%" LABEL PRESENT PATH)
                    (LIST :LABEL LABEL :PATH PATH :PRESENT-P PRESENT)))))


(DEFUN DM6-BUILD-APPEMBED-BUNDLE! (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (LET* ((REPO (DM6-ELM-REPO-OF ARTIFACT))
         (SOURCE (MERGE-PATHNAMES #P"src/AppEmbed.elm" REPO))
         (TARGET (DM6-ELM-APPEMBED-BUNDLE-OF ARTIFACT)))
    (COND
     ((NOT (PROBE-FILE REPO)) (FORMAT T "~&dm6-elm repo missing: ~A~%" REPO)
      (LIST :OK NIL :REASON :REPO-MISSING :REPO REPO))
     ((NOT (PROBE-FILE SOURCE))
      (FORMAT T "~&AppEmbed source missing: ~A~%" SOURCE)
      (LIST :OK NIL :REASON :SOURCE-MISSING :SOURCE SOURCE))
     (T (ENSURE-DIRECTORIES-EXIST TARGET)
      (FORMAT T "~&Building AppEmbed bundle: ~A -> ~A~%" SOURCE TARGET)
      (LET ((OUTPUT
             (DM6-RUN/PRINT REPO "npx" "elm" "make" "src/AppEmbed.elm"
                            "--output" (NAMESTRING TARGET))))
        (LIST :OK (NOT (NULL (PROBE-FILE TARGET))) :SOURCE SOURCE :TARGET
              TARGET :OUTPUT OUTPUT))))))


(DEFUN DM6-BUILD-MAIN-BUNDLE! (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (LET* ((REPO (DM6-ELM-REPO-OF ARTIFACT))
         (SOURCE (MERGE-PATHNAMES #P"src/Main.elm" REPO))
         (TARGET (DM6-ELM-MAIN-BUNDLE-OF ARTIFACT)))
    (COND
     ((NOT (PROBE-FILE REPO)) (FORMAT T "~&dm6-elm repo missing: ~A~%" REPO)
      (LIST :OK NIL :REASON :REPO-MISSING :REPO REPO))
     ((NOT (PROBE-FILE SOURCE)) (FORMAT T "~&Main source missing: ~A~%" SOURCE)
      (LIST :OK NIL :REASON :SOURCE-MISSING :SOURCE SOURCE))
     (T (ENSURE-DIRECTORIES-EXIST TARGET)
      (FORMAT T "~&Building Main bundle: ~A -> ~A~%" SOURCE TARGET)
      (LET ((OUTPUT
             (DM6-RUN/PRINT REPO "npx" "elm" "make" "src/Main.elm" "--output"
                            (NAMESTRING TARGET))))
        (LIST :OK (NOT (NULL (PROBE-FILE TARGET))) :SOURCE SOURCE :TARGET
              TARGET :OUTPUT OUTPUT))))))


(DEFUN DM6-DEMO-STORED-JSON ()
  "{n  \"topics\":[{\"id\":0,\"icon\":\"\",\"text\":\"DM6 Elm\",\"size\":{\"view\":{\"w\":0,\"h\":0},\"editor\":{\"w\":0,\"h\":0}},\"assocIds\":[4,5,6]},{\"id\":1,\"icon\":\"circle\",\"text\":\"Click a topic\",\"size\":{\"view\":{\"w\":128,\"h\":38},\"editor\":{\"w\":128,\"h\":38}},\"assocIds\":[4]},{\"id\":2,\"icon\":\"circle\",\"text\":\"Drag a topic\",\"size\":{\"view\":{\"w\":128,\"h\":38},\"editor\":{\"w\":128,\"h\":38}},\"assocIds\":[5]},{\"id\":3,\"icon\":\"circle\",\"text\":\"Inspect emitted events\",\"size\":{\"view\":{\"w\":160,\"h\":38},\"editor\":{\"w\":160,\"h\":38}},\"assocIds\":[6]}],n  \"assocs\":[{\"id\":4,\"type\":\"Hierarchy\",\"topicId1\":0,\"topicId2\":1},{\"id\":5,\"type\":\"Hierarchy\",\"topicId1\":0,\"topicId2\":2},{\"id\":6,\"type\":\"Hierarchy\",\"topicId1\":0,\"topicId2\":3}],n  \"itemSets\":[{\"id\":1,\"items\":[{\"topicId\":1},{\"topicId\":2},{\"topicId\":3}]}],n  \"boxes\":[{\"id\":0,\"itemSetId\":1,\"topics\":[{\"id\":1,\"expansion\":\"Collapsed\"},{\"id\":2,\"expansion\":\"Collapsed\"},{\"id\":3,\"expansion\":\"Collapsed\"}],\"renderer\":\"TopicMap\"}],n  \"boxId\":0,n  \"nextId\":7,n  \"topicMap\":{\"viewProps\":[{\"id\":0,\"rect\":{\"x1\":0,\"y1\":0,\"x2\":900,\"y2\":520},\"scroll\":{\"x\":0,\"y\":0},\"topics\":[{\"id\":1,\"pos\":{\"x\":120,\"y\":120}},{\"id\":2,\"pos\":{\"x\":360,\"y\":250}},{\"id\":3,\"pos\":{\"x\":560,\"y\":130}}]}]},n  \"topicList\":{\"viewProps\":[{\"id\":0,\"order\":[1,2,3],\"size\":{\"w\":900,\"h\":520}}]},n  \"tool\":{\"lineStyle\":\"Cornered\"}n}")


(DEFUN DM6-STANDALONE-SHELL-HTML
       (
        &KEY (TITLE "dm6-elm standalone comparison shell")
        (STORED (DM6-DEMO-STORED-JSON)))
  (FORMAT NIL "<!doctype html>
<meta charset='utf-8'>
<title>~A</title>
<style>
html,body{margin:0;height:100%;font:14px system-ui,sans-serif}
body{display:grid;grid-template-rows:auto 1fr;background:#f7fafc}
header{padding:.65rem .85rem;border-bottom:1px solid #c8d5df;background:#fff}
#status{color:#35536b}
#mount{min-height:0;overflow:auto;background-image:linear-gradient(#edf2f7 1px,transparent 1px),linear-gradient(90deg,#edf2f7 1px,transparent 1px);background-size:24px 24px}
#stage{position:relative;width:1600px;height:1200px}
</style>
<header><strong>Standalone dm6 Elm app</strong><span id='status'>loading...</span></header>
<div id='mount'><div id='stage'></div></div>
<script>
(function(){
const stored=~S;
const flags={slug:'dm6-side-by-side-standalone',stored};
function setStatus(text){document.getElementById('status').textContent=' - '+text;}
function loadScript(src){return new Promise(function(resolve,reject){const script=document.createElement('script');script.src=src;script.onload=function(){resolve(src);};script.onerror=function(){reject(new Error('failed to load '+src));};document.head.appendChild(script);});}
function pickElmModule(){if(!window.Elm)return null;return window.Elm.Main||window.Elm.AppMain||window.Elm.AppEmbed||null;}
function moduleName(App){if(window.Elm&&App===window.Elm.Main)return 'Main';if(window.Elm&&App===window.Elm.AppMain)return 'AppMain';if(window.Elm&&App===window.Elm.AppEmbed)return 'AppEmbed';return 'unknown';}
function boot(App){const stage=document.getElementById('stage');const attempts=[()=>App.init({node:stage,flags}),()=>App.init({flags}),()=>App.init({node:stage}),()=>App.init()];let lastError=null;for(const attempt of attempts){try{const app=attempt();setStatus('booted Elm.'+moduleName(App)+' with storedLen='+stored.length);return app;}catch(e){lastError=e;}}throw lastError||new Error('Elm init failed');}
async function main(){const bundles=[new URL('main.js',document.baseURI).href,new URL('app.js',document.baseURI).href];for(const src of bundles){try{await loadScript(src);const App=pickElmModule();if(App){setStatus('loaded '+src);boot(App);return;}}catch(e){console.warn(e);}}setStatus('no bootable Elm module found; build main.js or app.js');}
main().catch(function(error){console.error(error);setStatus(String(error&&error.message||error));});
}());
</script>"
          TITLE STORED))


(DEFUN DM6-SIDE-BY-SIDE-PAGE-HTML
       (
        &OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT))
        &KEY (STORED (DM6-DEMO-STORED-JSON)))
  (DECLARE (IGNORE ARTIFACT))
  (FORMAT NIL "<!doctype html>
<meta charset='utf-8'>
<title>DM6 AppEmbed Side-by-Side Comparison</title>
<link rel='stylesheet' href='/dm6-elm/hyperdoc-dm6-inline.css'>
<style>
body{margin:0;font:14px system-ui,sans-serif;background:#eef4f8}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:12px}
.panel{background:white;border:1px solid #c9d6e2;border-radius:10px;overflow:hidden}
.panel h2{margin:0;padding:10px 12px;background:#f8fbfd;border-bottom:1px solid #dbe5ee;font-size:16px}
.body{height:680px;overflow:auto}
iframe{width:100%;height:680px;border:0;display:block}
</style>
<div class='grid'>
<section class='panel'>
<h2>Embedded AppEmbed inside HyperDoc</h2>
<div class='body'>
<section class='dm6-hyperdoc-map dm6-island' data-dm6-slug='dm6-side-by-side-embedded' data-dm6-bundle='/dm6-elm/app.js'>
<script type='application/json' class='dm6-stored'>
~A
</script>
<header class='dm6-island-header'>
<div class='dm6-island-title'><h2>DM6 Topic Map</h2><span class='dm6-island-subtitle'>Embedded AppEmbed island with evidence capture</span></div>
<nav class='dm6-toolbar' aria-label='dm6 controls'>
<button type='button' data-dm6-action='select'>Select</button>
<button type='button' data-dm6-action='move'>Move</button>
<button type='button' data-dm6-action='cross'>Cross</button>
<button type='button' data-dm6-action='fit'>Fit</button>
<button type='button' data-dm6-action='reset'>Reset</button>
<button type='button' data-dm6-action='evidence'>Evidence</button>
</nav>
</header>
<div class='dm6-mode-banner'><span><b>Input owner:</b> <span class='dm6-input-owner'>page</span></span><span><b>Mode:</b> <span class='dm6-mode'>select</span></span><span><b>HyperDoc:</b> <span class='dm6-hyperdoc-state'>overlays active outside embedded app</span></span></div>
<div class='dm6-canvas'><div class='dm6-stage'>dm6 AppEmbed mount pending...</div></div>
<div class='dm6-success-card'><div><strong class='dm6-mount-summary'>dm6 mounting...</strong><br>Try: click a topic, drag a topic, inspect emitted events.</div><div><b>Status:</b> <span class='dm6-status'>not mounted</span></div></div>
<details class='dm6-evidence-drawer'><summary>Evidence: <span class='dm6-evidence-count'>0</span> events - last: <span class='dm6-evidence-last'>none</span></summary><pre class='dm6-evidence-summary'></pre><pre class='dm6-evidence'></pre></details>
</section>
</div>
</section>
<section class='panel'>
<h2>Standalone Elm boot shell</h2>
<iframe src='/dm6-elm/dm6-standalone-shell.html'></iframe>
</section>
</div>
<script src='/dm6-elm/hyperdoc-dm6-inline.js'></script>
<script>window.hyperdocDm6Inline&&window.hyperdocDm6Inline.mountAll(document);</script>"
          STORED))


(DEFUN DM6-WRITE-SIDE-BY-SIDE! (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (DM6-WRITE-FILE-STRING (DM6-ELM-STANDALONE-SHELL-OF ARTIFACT)
                         (DM6-STANDALONE-SHELL-HTML))
  (DM6-WRITE-FILE-STRING (DM6-ELM-SIDE-BY-SIDE-PAGE-OF ARTIFACT)
                         (DM6-SIDE-BY-SIDE-PAGE-HTML ARTIFACT))
  (FORMAT T "~&Wrote standalone shell: ~A~%"
          (DM6-ELM-STANDALONE-SHELL-OF ARTIFACT))
  (FORMAT T "~&Wrote side-by-side page: ~A~%"
          (DM6-ELM-SIDE-BY-SIDE-PAGE-OF ARTIFACT))
  ARTIFACT)


(DEFUN DM6-MAIN-HYPERDOC ()
  (DM6-ENSURE-INSPECTOR-RUNTIME!)
  (OR (IGNORE-ERRORS (FIND-HYPERBOOK "hyperdoc" :SIGNAL-ERROR? T))
      (AND (BOUNDP '*HYPERDOC*) *HYPERDOC*)))


(DEFUN DM6-RELOAD-MAIN-HYPERDOC-PAGES! ()
  (LET ((HD (DM6-MAIN-HYPERDOC)))
    (UNLESS HD (ERROR "Could not find the main HyperDoc object."))
    (RELOAD-TEXT-PAGES HD)
    HD))


(DEFUN DM6-FIND-MAIN-HYPERDOC-PAGE! (TITLE)
  (LET ((HD (DM6-RELOAD-MAIN-HYPERDOC-PAGES!)))
    (OR (FIND-PAGE HD TITLE :SIGNAL-ERROR? NIL)
        (ERROR "HyperDoc page not found after reload: ~S" TITLE))))


(DEFUN DM6-OPEN-RUNBOOK-PAGE! ()
  (DM6-ENSURE-INSPECTOR-RUNTIME!)
  (LET ((PAGE
         (DM6-FIND-MAIN-HYPERDOC-PAGE! "DM6 Elm Artifact Inspector Runbook")))
    (DM6-CLOG-INSPECT PAGE)
    PAGE))


(DEFMETHOD VIEWS:TEXT-REPRESENTATION ((ARTIFACT DM6-ELM-ARTIFACT))
  (FORMAT NIL "dm6-elm artifact @ ~A"
          (DM6-GIT-ONE-LINE ARTIFACT "rev-parse" "--short=12" "HEAD")))


(DEFMETHOD VIEWS:TEXT-REPRESENTATION ((SURFACE DM6-SIDE-BY-SIDE-SURFACE))
  (DM6-SIDE-BY-SIDE-TITLE-OF SURFACE))


(VIEWS:DEFVIEW DM6-ARTIFACT-VERSION-VIEW (ARTIFACT DM6-ELM-ARTIFACT)
               (VIEWS:HTML-VIEW :TITLE "Version metadata" :PRIORITY 1
                                (VIEWS:HTML
                                  (:TABLE :CLASS "inspector-table"
                                   (LOOP FOR (KEY
                                              . VALUE) IN (DM6-VERSION-ALIST
                                                           ARTIFACT)
                                         DO (VIEWS:HTML
                                              (:TR (:TH (CL-WHO:ESC KEY))
                                               (:TD
                                                (:CODE
                                                 (CL-WHO:ESC VALUE))))))))))


(VIEWS:DEFVIEW DM6-ARTIFACT-NIX-METADATA-VIEW (ARTIFACT DM6-ELM-ARTIFACT)
               (VIEWS:HTML-VIEW :TITLE "Nix metadata" :PRIORITY 2
                                (VIEWS:HTML
                                  (:PRE :STYLE "white-space: pre-wrap;"
                                   (CL-WHO:ESC (DM6-NIX-METADATA ARTIFACT))))))


(VIEWS:DEFVIEW DM6-ARTIFACT-NIX-SVG-VIEW (ARTIFACT DM6-ELM-ARTIFACT)
               (DM6-WRITE-NIX-GRAPH-SVG! ARTIFACT)
               (VIEWS:HTML-VIEW :TITLE "Nix graph SVG" :PRIORITY 3
                                (DM6-ADD-DM6-ASSETS-FOR-CURRENT-VIEW)
                                (VIEWS:HTML
                                  (:P
                                   "Server-side Graphviz output generated by "
                                   (:CODE "dot -Tsvg") ".")
                                  (:IFRAME :SRC
                                   "/dm6-elm/dm6-nix-input-graph.svg" :STYLE
                                   "width: 100%; height: 560px; border: 1px solid #ccd6df; border-radius: .5rem; background: white;")
                                  (:DETAILS (:SUMMARY "Raw DOT")
                                   (:PRE :STYLE "white-space: pre-wrap;"
                                    (CL-WHO:ESC
                                     (DM6-NIX-INPUT-DOT ARTIFACT)))))))


(VIEWS:DEFVIEW DM6-ARTIFACT-BUILD-COMMANDS-VIEW (ARTIFACT DM6-ELM-ARTIFACT)
               (VIEWS:HTML-VIEW :TITLE "Build commands" :PRIORITY 4
                                (VIEWS:HTML
                                  (:PRE :STYLE "white-space: pre-wrap;"
                                   (CL-WHO:ESC
                                    (FORMAT NIL
                                            "cd ~A~%~%npx elm make src/AppEmbed.elm --output=~A~%npx elm make src/Main.elm --output=~A~%~%(dm6-build-appembed-bundle! *dm6-artifact*)~%(dm6-build-main-bundle! *dm6-artifact*)~%(dm6-open!)"
                                            (NAMESTRING
                                             (DM6-ELM-REPO-OF ARTIFACT))
                                            (NAMESTRING
                                             (DM6-ELM-APPEMBED-BUNDLE-OF
                                              ARTIFACT))
                                            (NAMESTRING
                                             (DM6-ELM-MAIN-BUNDLE-OF
                                              ARTIFACT))))))))


(VIEWS:DEFVIEW DM6-SIDE-BY-SIDE-BROWSER-VIEW (SURFACE DM6-SIDE-BY-SIDE-SURFACE)
               (LET* ((ARTIFACT (DM6-SIDE-BY-SIDE-ARTIFACT-OF SURFACE))
                      (HTML
                       (PROGN
                        (DM6-WRITE-SIDE-BY-SIDE! ARTIFACT)
                        (DM6-SIDE-BY-SIDE-PAGE-HTML ARTIFACT))))
                 (VIEWS:HTML-VIEW :TITLE "Browser" :PRIORITY 1
                                  (DM6-ADD-DM6-ASSETS-FOR-CURRENT-VIEW)
                                  (VIEWS:HTML
                                    (:P
                                     "Assets are served in the inspector from "
                                     (:CODE "/dm6-elm/"))
                                    (:IFRAME :SRCDOC HTML :STYLE
                                     "width: 100%; height: 860px; border: 1px solid #ccd6df; border-radius: .5rem; background: white;")))))


(VIEWS:DEFVIEW DM6-SIDE-BY-SIDE-SOURCE-VIEW (SURFACE DM6-SIDE-BY-SIDE-SURFACE)
               (LET ((ARTIFACT (DM6-SIDE-BY-SIDE-ARTIFACT-OF SURFACE)))
                 (VIEWS:HTML-VIEW :TITLE "Generated source" :PRIORITY 2
                                  (VIEWS:HTML
                                    (:PRE :STYLE "white-space: pre-wrap;"
                                     (CL-WHO:ESC
                                      (DM6-SIDE-BY-SIDE-PAGE-HTML
                                       ARTIFACT)))))))


(DEFUN DM6-INSPECT-ARTIFACT! (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (DM6-ENSURE-INSPECTOR-RUNTIME!)
  (DM6-CLOG-INSPECT ARTIFACT)
  ARTIFACT)


(DEFUN DM6-INSPECT-SIDE-BY-SIDE-PAGE!
       (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (DM6-ENSURE-INSPECTOR-RUNTIME!)
  (DM6-WRITE-SIDE-BY-SIDE! ARTIFACT)
  (LET ((SURFACE (MAKE-DM6-SIDE-BY-SIDE-SURFACE ARTIFACT)))
    (DM6-CLOG-INSPECT SURFACE)
    SURFACE))


(DEFUN DM6-CALL-SOFT (NAME &REST ARGS)
  (COND
   ((NOT (FBOUNDP NAME))
    (FORMAT T "~&Skipping ~S: not defined in this image.~%" NAME) NIL)
   (T
    (HANDLER-CASE (APPLY (SYMBOL-FUNCTION NAME) ARGS)
                  (ERROR (C)
                         (FORMAT T "~&Skipping ~S after error: ~A~%" NAME C)
                         NIL)))))


(DEFUN DM6-OPEN! (&OPTIONAL (ARTIFACT (DM6-CURRENT-ARTIFACT)))
  (DM6-ENSURE-INSPECTOR-RUNTIME!)
  (DM6-WRITE-SIDE-BY-SIDE! ARTIFACT)
  (DM6-WRITE-NIX-GRAPH-SVG! ARTIFACT)
  (DM6-CHECK-SIDE-BY-SIDE-ASSETS! ARTIFACT)
  (DM6-CALL-SOFT 'DM6-OPEN-RUNBOOK-PAGE!)
  (DM6-INSPECT-ARTIFACT! ARTIFACT)
  (DM6-INSPECT-SIDE-BY-SIDE-PAGE! ARTIFACT)
  ARTIFACT)

