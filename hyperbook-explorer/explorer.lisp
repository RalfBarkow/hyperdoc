;;;; Views on HyperBooks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; Better display of lookup failures
;;

(defmethod views:html-representation ((condition page-lookup-failure) &optional id)
  (views:html
    (:span :id id :class "inspector-error"
           (views:esc "No page \"")
           (views:esc (slot-value condition 'page-id))
           (views:esc "\" in HyperBook \"")
           (views:esc (title-of (slot-value condition 'hyperbook)))
           (views:esc "\""))))

(defmethod views:html-representation ((condition hyperbook-lookup-failure) &optional id)
  (views:html
    (:span :id id :class "inspector-error"
           (views:esc "No HyperBook \"")
           (views:esc (slot-value condition 'id))
           (views:esc "\""))))


;;
;; View showing the main page
;;

(views:defview 👀main-page (hb hyperbook)
  (when-let (main-page-id (main-page-id-of hb))
    (when-let (main-page (find-page hb main-page-id))
      (views:👀content main-page))))

