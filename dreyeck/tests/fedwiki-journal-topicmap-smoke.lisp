(in-package #:dreyeck/fedwiki-journal/topicmap/tests)

(defun run-fedwiki-journal-topicmap-tests ()
  (let* ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "repair-test"))
         (page (hyperbook/fedwiki::make-fedwiki-page wiki "repair-test" "Repair Test"))
         (candidate
          (make-instance 'dreyeck/fedwiki-journal::fedwiki-journal-repair-candidate
                         :page page :source-json nil :repaired-json nil :repairs
                         (list
                          (list :entry-index 1 :entry-type "add" :from 3990137795000
                                :to 1781148995000))))
         (projection (dreyeck/topicmap:topicmap-projection-of candidate))
         (topics (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (associations
          (dreyeck/topicmap:topicmap-projection-associations-of projection))
         (page-topic
          (find :fedwiki-page topics :key #'dreyeck/topicmap:topicmap-topic-type-of
                :test #'eq))
         (candidate-topic
          (find :fedwiki-journal-repair-candidate topics :key
                #'dreyeck/topicmap:topicmap-topic-type-of :test #'eq))
         (association
          (find :proposed-repair associations :key
                #'dreyeck/topicmap:topicmap-association-type-of :test #'eq)))
    (and (eq candidate (dreyeck/topicmap:topicmap-projection-source-of projection))
         (= 2 (length topics)) page-topic candidate-topic (= 1 (length associations))
         association
         (string= (dreyeck/topicmap:topicmap-topic-id-of page-topic)
                  (dreyeck/topicmap:topicmap-association-from-of association))
         (string= (dreyeck/topicmap:topicmap-topic-id-of candidate-topic)
                  (dreyeck/topicmap:topicmap-association-to-of association))
         (progn (format t "~&FedWiki journal Topicmap tests passed.~%") t))))
