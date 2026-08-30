(in-package #:dreyeck/fedwiki-journal)

(defmethod dreyeck/topicmap:topicmap-projection-of
           ((candidate fedwiki-journal-repair-candidate))
  (let* ((page (repair-page-of candidate))
         (origin (hyperbook/fedwiki::origin-of page))
         (site (hyperbook/fedwiki::domain-name-of origin))
         (slug (hyperbook/fedwiki::origin-id-of page))
         (page-id (format nil "fedwiki-remote-page:~A:~A" site slug))
         (candidate-id (format nil "repair-candidate:~A:~A:date-domain" site slug)))
    (make-instance 'dreyeck/topicmap:topicmap-projection :source candidate :topics
                   (list
                    (make-instance 'dreyeck/topicmap:topicmap-topic :id page-id :type
                                   :fedwiki-page :label
                                   (format nil "~A @ ~A" (hyperbook:title-of page)
                                           site)
                                   :object page)
                    (make-instance 'dreyeck/topicmap:topicmap-topic :id candidate-id
                                   :type :fedwiki-journal-repair-candidate :label
                                   (format nil "~D date-domain repairs"
                                           (length (repairs-of candidate)))
                                   :object candidate))
                   :associations
                   (list
                    (make-instance 'dreyeck/topicmap:topicmap-association :id
                                   (format nil "proposed-repair:~A:~A" site slug) :type
                                   :proposed-repair :from page-id :to candidate-id)))))
