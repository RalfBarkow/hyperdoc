;;;; Redirection of Web links to HyperBook links
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defun replace-by-hyperbook-link (url)
  (loop for fn in (link-redirections-of *catalog*)
        for hb-link = (funcall fn url)
        when hb-link
        return hb-link))
