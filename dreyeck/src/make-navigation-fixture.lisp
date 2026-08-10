(in-package #:dreyeck/fedwiki-navigation/prototype)

(defun make-navigation-fixture ()
  (let* ((site "ward.dojo.fed.wiki")

         (welcome
           (make-navigation-page
            :site site
            :slug "welcome-visitors"
            :title "Welcome Visitors"
            :story
            (list
             (make-navigation-item
              :id "welcome-intro"
              :text "Welcome to this Federated Wiki site.")
             (make-navigation-item
              :id "welcome-share"
              :text "Pages where we do and share.")
             (make-navigation-item
              :id "welcome-yearbooks"
              :text "[[Dojo Practice Yearbooks]]"
              :link-slug "dojo-practice-yearbooks"))))

         (yearbooks
           (make-navigation-page
            :site site
            :slug "dojo-practice-yearbooks"
            :title "Dojo Practice Yearbooks"
            :story
            (list
             (make-navigation-item
              :id "yearbooks-intro"
              :text "We make pages here mostly for the making experience.")
             (make-navigation-item
              :id "yearbooks-2020"
              :text "[[Dojo Practices 2020]] with diagrams"
              :link-slug "dojo-practices-2020")
             (make-navigation-item
              :id "yearbooks-2021"
              :text "[[Dojo Practices 2021]] with scripts"
              :link-slug "dojo-practices-2021"))))

         (practices-2020
           (make-navigation-page
            :site site
            :slug "dojo-practices-2020"
            :title "Dojo Practices 2020"
            :story
            (list
             (make-navigation-item
              :id "practices-2020-intro"
              :text "We make pages here mostly for the making experience."))))

         (practices-2021
           (make-navigation-page
            :site site
            :slug "dojo-practices-2021"
            :title "Dojo Practices 2021"
            :story
            (list
             (make-navigation-item
              :id "practices-2021-intro"
              :text "We make pages here mostly for the making experience.")))))

    (make-navigation-session
     :origin site
     :pages (list welcome yearbooks
                  practices-2020 practices-2021)
     :lineup (list (make-navigation-panel :page welcome)))))


(defun navigation-snapshot (session command)
  (let* ((panel (session-current-panel session))
         (page (navigation-panel-page panel))
         (item (session-current-item session)))
    (list command
          (navigation-page-slug page)
          (navigation-item-id item)
          (navigation-panel-item-number panel)
          (mapcar
           (lambda (lineup-panel)
             (navigation-page-slug
              (navigation-panel-page lineup-panel)))
           (navigation-session-lineup session))
          (session-location session))))


(defun execute-navigation-command (session command)
  (if (atom command)
      (ecase command
        (:move-next
         (move-next session))
        (:follow-link
         (follow-link session)))
      (ecase (first command)
        (:case
         (record-navigation-case (second command)))
        (:find-next
         (find-next session (second command)))
        (:move-back
         (move-back session (second command)))
        (:test
         (assert-current-item session (second command))))))


(defun run-navigation-transcript (session commands)
  (let ((transcript
          (list (navigation-snapshot session :start))))
    (dolist (command commands (nreverse transcript))
      (execute-navigation-command session command)
      (push (navigation-snapshot session command)
            transcript))))


(defparameter *navigation-commands*
  '((:find-next "share")
    :move-next
    :follow-link
    (:find-next "2020")
    :follow-link
    (:move-back "Yearbooks")
    :move-next))


(defparameter *expected-navigation-transcript*
  '((:start
     "welcome-visitors" "welcome-intro" 0
     ("welcome-visitors")
     "http://ward.dojo.fed.wiki/view/welcome-visitors")

    ((:find-next "share")
     "welcome-visitors" "welcome-share" 1
     ("welcome-visitors")
     "http://ward.dojo.fed.wiki/view/welcome-visitors")

    (:move-next
     "welcome-visitors" "welcome-yearbooks" 2
     ("welcome-visitors")
     "http://ward.dojo.fed.wiki/view/welcome-visitors")

    (:follow-link
     "dojo-practice-yearbooks" "yearbooks-intro" 0
     ("welcome-visitors" "dojo-practice-yearbooks")
     "http://ward.dojo.fed.wiki/view/welcome-visitors/view/dojo-practice-yearbooks")

    ((:find-next "2020")
     "dojo-practice-yearbooks" "yearbooks-2020" 1
     ("welcome-visitors" "dojo-practice-yearbooks")
     "http://ward.dojo.fed.wiki/view/welcome-visitors/view/dojo-practice-yearbooks")

    (:follow-link
     "dojo-practices-2020" "practices-2020-intro" 0
     ("welcome-visitors"
      "dojo-practice-yearbooks"
      "dojo-practices-2020")
     "http://ward.dojo.fed.wiki/view/welcome-visitors/view/dojo-practice-yearbooks/view/dojo-practices-2020")

    ((:move-back "Yearbooks")
     "dojo-practice-yearbooks" "yearbooks-2020" 1
     ("welcome-visitors" "dojo-practice-yearbooks")
     "http://ward.dojo.fed.wiki/view/welcome-visitors/view/dojo-practice-yearbooks")

    (:move-next
     "dojo-practice-yearbooks" "yearbooks-2021" 2
     ("welcome-visitors" "dojo-practice-yearbooks")
     "http://ward.dojo.fed.wiki/view/welcome-visitors/view/dojo-practice-yearbooks")))


(defun navigation-transcript-smoke-test ()
  (let* ((session (make-navigation-fixture))
         (actual
           (run-navigation-transcript
            session
            *navigation-commands*)))
    (unless (equal actual *expected-navigation-transcript*)
      (error "Navigation transcript differs.~%Expected:~%~S~%Actual:~%~S"
             *expected-navigation-transcript*
             actual))
    (values t actual session)))


(defvar *navigation-fixture* nil)
(defvar *navigation-transcript* nil)
(defvar *navigation-observation* nil)
