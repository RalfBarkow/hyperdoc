;;;; Explorer views for inspectable operational targets
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun render-shell-block (shell-text)
  (views:html
    (:pre :style "white-space: pre-wrap;"
          (views:esc shell-text))))

(defmethod views:text-representation ((host-target nixos-host-target))
  (format nil "~A@~A"
          (ssh-user-of host-target)
          (hostname-of host-target)))

(defmethod views:text-representation ((operation git-remote-operation))
  (title-of operation))

(views:defview 👀summary (host-target nixos-host-target)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of host-target)))
      (:p (views:esc (summary-of host-target)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Hostname"))
                   (:td (:tt (views:esc (hostname-of host-target)))))
              (:tr (:td (views:esc "SSH user"))
                   (:td (:tt (views:esc (ssh-user-of host-target)))))
              (:tr (:td (views:esc "Checkout root"))
                   (:td (:tt (views:esc
                              (namestring (checkout-root-of host-target))))))
              (:tr (:td (views:esc "Service name"))
                   (:td (:tt (views:esc (service-name-of host-target)))))
              (:tr (:td (views:esc "Deployment mode"))
                   (:td (:tt (views:esc
                              (deployment-mode-label
                               (deployment-mode-of host-target))))))))))

(views:defview 👀materialization (host-target nixos-host-target)
  (views:html-view :title "Materialization" :priority 2
    (views:html
      (:p "This host target renders a concrete shell block for inspecting the live service context without executing deployment changes.")
      (render-shell-block (materialization-shell-block host-target)))))

(views:defview 👀summary (operation git-remote-operation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of operation)))
      (:p (views:esc (summary-of operation)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Host target"))
                   (:td (views:object-ref (host-target-of operation))))
              (:tr (:td (views:esc "Operation kind"))
                   (:td (:tt (views:esc
                              (git-remote-operation-kind-label
                               (operation-kind-of operation))))))
              (:tr (:td (views:esc "Remote name"))
                   (:td (:tt (views:esc (remote-name-of operation)))))
              (:tr (:td (views:esc "Remote URL"))
                   (:td (:tt (views:esc (remote-url-of operation)))))
              (:tr (:td (views:esc "Branch"))
                   (:td (:tt (views:esc (branch-of operation)))))))))

(views:defview 👀materialization (operation git-remote-operation)
  (views:html-view :title "Materialization" :priority 2
    (views:html
      (:p "This operation renders the exact host-aware shell block to run. It does not execute the remote command from inside HyperDoc.")
      (render-shell-block (materialization-shell-block operation)))))
