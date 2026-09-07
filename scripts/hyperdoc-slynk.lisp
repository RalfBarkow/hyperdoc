;;; One fresh, editor-independent white image. No application systems are loaded.
(require :asdf)
(require :sb-posix)
(sb-posix:unsetenv "DYLD_LIBRARY_PATH")
(load (sb-ext:posix-getenv "HYPERDOC_SLYNK_LOADER"))
;; Do not import personal ~/.slynk.lisp or ~/.slynkrc state into this image.
(slynk-loader:init :setup nil)
(pushnew :slynk *features*)
(slynk::run-hook slynk::*after-init-hook*)

;; CREATE-SERVER returns the socket's allocated port after starting the server.
(let ((port (slynk:create-server :interface "127.0.0.1" :port 0
                                 :dont-close t :style :spawn)))
  (with-open-stream
      (endpoint (sb-sys:make-fd-stream
                 (parse-integer (sb-ext:posix-getenv "HYPERDOC_ENDPOINT_FD"))
                 :output t :element-type 'character :external-format :utf-8))
    (format endpoint "127.0.0.1~C~D~C~A~C~A~%"
            #\Tab port #\Tab (lisp-implementation-type)
            #\Tab (lisp-implementation-version))
    (finish-output endpoint)))

;; The launcher owns lifetime; stdin and editor connections do not own it.
(sb-thread:wait-on-semaphore (sb-thread:make-semaphore))
