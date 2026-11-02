;;;; One scenario, in a fresh SBCL with the debugger disabled, against ONE checkout of hyperbook/fedwiki (ours or Konrad Hinsen's upstream).
;;;; MAKE-FEDWIKI starts a thread per site; a condition that escapes that thread ends the process (the packaged hyperdoc-catalog runs with
;;;; --script). Prints SURVIVED with the site's status, or the process dies with the unhandled condition and a non-zero exit status.
;;;;   CHECKOUT (the tree with hyperbook.asd), SCENARIO (below). Run under `unshare -rn`: no network can be reached.
;;;; The scenarios control the two places a name-service condition can arise: the first connection attempt (the HTTPS probe,
;;;; USOCKET:SOCKET-CONNECT) and the fetch of the site map (FETCH-SITEMAP). Injection is by SB-INT:ENCAPSULATE on those two functions, so
;;;; each checkout's own handlers see the condition exactly as they would see the library's.
;;;;   probe-real              nothing injected: the platform's resolver fails in the empty namespace (ns-try-again-error from the probe)
;;;;   probe-try-again | probe-no-recovery | probe-host-not-found     the probe's SOCKET-CONNECT signals that condition (the site map then fails the same way)
;;;;   sitemap-try-again | sitemap-no-recovery | sitemap-host-not-found   the probe passes; FETCH-SITEMAP signals that condition
;;;; and two conditions that are NOT name-service errors of USOCKET, kept in the matrix so that it also shows what no checkout handles:
;;;;   probe-nodata | sitemap-nodata                  SB-BSD-SOCKETS:NAME-SERVICE-ERROR, what the resolver gives for NOERROR with no address (#18)
;;;;   probe-network-unreachable | sitemap-network-unreachable    USOCKET:NETWORK-UNREACHABLE-ERROR, a connect failure (#16)
;;;; and the one name-service condition that only the parent class USOCKET:NS-ERROR keeps: USOCKET:NS-UNKNOWN-ERROR, which usocket's SBCL backend never
;;;; raises (so this is a difference of the handlers, not of any observed behaviour), and which cannot be printed:
;;;;   probe-unknown | sitemap-unknown
(require :asdf)
;; The checkout under test comes first; everything else (CLOG, drakma, usocket, ... as the dev shell's SBCL provides them) is inherited.
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(uiop:ensure-directory-pathname (or (uiop:getenv "CHECKOUT") (error "CHECKOUT")))) :inherit-configuration))
;; Upstream's pages.lisp reads CLOG symbols without its system declaring CLOG: load CLOG first (our checkout declares it through its dependencies).
(let ((*standard-output* (make-broadcast-stream)))
  (asdf:load-system "clog")
  (handler-bind ((warning #'muffle-warning))
    (let ((*error-output* *error-output*)) (asdf:load-system "hyperbook/fedwiki"))))
(defparameter *scenario* (or (uiop:getenv "SCENARIO") (error "SCENARIO")))
(defparameter *host* "wiki.test-host.invalid")
(defun condition-class (name)
  (ecase (intern (string-upcase name) :keyword)
    (:try-again 'usocket:ns-try-again-error) (:no-recovery 'usocket:ns-no-recovery-error) (:host-not-found 'usocket:ns-host-not-found-error)
    (:nodata 'sb-bsd-sockets:name-service-error) (:network-unreachable 'usocket:network-unreachable-error)
    (:unknown 'usocket:ns-unknown-error)))
(defun signal-it (class)
  (case class
    (sb-bsd-sockets:name-service-error (error class :error-code -5 :syscall "getaddrinfo"))
    (usocket:network-unreachable-error (error class :socket nil))
    (t (error class :socket nil :host-or-ip *host*))))
(defun encapsulate (name function) (sb-int:encapsulate name 'scenario (lambda (original &rest arguments) (declare (ignore original)) (apply function arguments))))
(let* ((kind (subseq *scenario* 0 (position #\- *scenario*)))
       (class (unless (string= *scenario* "probe-real") (condition-class (subseq *scenario* (1+ (position #\- *scenario*)))))))
  ;; the second attempt, the site map and the plugin data: nothing real happens there in an injected scenario
  (unless (string= *scenario* "probe-real")
    (encapsulate 'hyperbook/fedwiki::fetch-plugin-data (lambda (&rest arguments) (declare (ignore arguments)) nil))
    (cond ((string= kind "probe")
           (encapsulate 'usocket:socket-connect (lambda (&rest arguments) (declare (ignore arguments)) (signal-it class)))
           (encapsulate 'hyperbook/fedwiki::fetch-sitemap (lambda (&rest arguments) (declare (ignore arguments)) (signal-it class))))
          ((string= kind "sitemap")
           (encapsulate 'usocket:socket-connect (lambda (&rest arguments) (declare (ignore arguments)) nil))
           (encapsulate 'usocket:socket-close (lambda (&rest arguments) (declare (ignore arguments)) nil))
           (encapsulate 'hyperbook/fedwiki::fetch-sitemap (lambda (&rest arguments) (declare (ignore arguments)) (signal-it class))))
          (t (error "unknown scenario ~A" *scenario*)))))
(let ((wiki (hyperbook/fedwiki::make-fedwiki *host*)))
  (hyperbook/fedwiki::wait-for-sitemap wiki)
  (format t "SURVIVED ~A status=~S printable=~A~%" *scenario* (type-of (hyperbook/fedwiki::status-of wiki))
          ;; the value is used: a call whose value is dropped is flushed by the compiler and would "print" anything
          (if (plusp (length (or (ignore-errors (princ-to-string (hyperbook/fedwiki::status-of wiki))) ""))) "yes" "NO"))
  (finish-output))
