;;;; Fresh local test server, using the real DMX HTTP client. Never the environment/default client.
(require :asdf)
(let ((root (truename (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))))
  (asdf:initialize-source-registry
   `(:source-registry (:directory ,root)
     ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
             unless (zerop (length path)) collect
             `(,(if (and (>= (length path) 2) (string= path "//" :start1 (- (length path) 2))) :tree :directory)
               ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
     :ignore-inherited-configuration))
  (asdf:load-asd (merge-pathnames "hyperbook.asd" root))
  (asdf:load-asd (merge-pathnames "hyperdoc.asd" root)))
(asdf:load-system "hyperdoc/mcp")
(format t "~&DMX-DISCOVERY-FRESH global-array-helper-bound ~S~%" (fboundp 'hyperdoc::json-array-elements))
;; Reproduce the original server from an explicit test-owned source file when requested.
(let ((original (uiop:getenv "HYPERDOC_DISCOVERY_ORIGINAL_SOURCE"))) (when original (load original)))
(let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                              :base-url (uiop:getenv "HYPERDOC_DISCOVERY_BACKEND") :verbose nil))
       (server (hyperdoc::make-dmx-mcp-server
                :read-client client :write-client client
                :workspace-topicmap-id 1 :known-topic-ids '(7 999)
                :bearer-token (uiop:getenv "HYPERDOC_DISCOVERY_TOKEN")
                :allowed-origins '("https://review.invalid") :live-writes-enabled-p nil
                :sessions (make-hash-table :test #'equal) :log-stream *error-output*)))
  (unwind-protect
       (progn
         (hyperdoc::serve-dmx-mcp-server :server server :address "127.0.0.1"
                                       :port (parse-integer (uiop:getenv "HYPERDOC_DISCOVERY_PORT")))
         (format t "~&DMX-DISCOVERY-READY~%") (finish-output)
         (loop repeat 1200 until (probe-file (uiop:getenv "HYPERDOC_DISCOVERY_STOP")) do (sleep 0.1)))
    (hyperdoc::stop-dmx-mcp-server)))
