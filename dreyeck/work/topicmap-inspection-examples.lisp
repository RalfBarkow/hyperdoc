;;;; The worked example of the DITA topics on Topicmap inspection: one real proposal, its Topicmap and the objects the two inspection Operations reach
(in-package #:dreyeck/item-edit-ctm)

;; The topics "Topicmap Signs and Represented Objects" and "TMDM Roles and Projected Edges" explain the Association node `proposes` of the Topicmap of an Item
;; edit. Their hyperdoc:example: references open the objects below, each reached from the one before: the proposal for the Item E3 of the retained plan page,
;; the CTM projection made of it, the projected Topic of `proposes`, the TMDM Association it represents, and one Role of it. Preparing the proposal reads the
;; page file and writes nothing. The proposal is made once for each page revision and Item, so that the references of one document lead to one chain of objects.

(defparameter +example-page+ '("fedwiki:dreyeck.ch" "ctm-and-tmdm-in-hyperdoc" "ed37e9bac2fcd548")
  "The Item the example proposal is made for: the Item E3 of the plan page, as the Catalog that serves the wiki's site root has it.")
(defparameter +proposes-id+ "proposes(action=the-proposed-action,proposal=the-proposal)")

(defvar *example-proposals* (make-hash-table :test #'equal) "page revision and Item id -> the proposal made for it")

(defvar *example-item* nil
  "A LOCAL-STORY-ITEM to make the example proposal for, instead of looking the Item up in the Catalog. For tests, which have no Catalog.")

(defun %example-item ()
  (or *example-item* (%catalog-example-item)))

(defun %catalog-example-item ()
  (let ((helper (find-symbol "REGISTERED-STORY-ITEM" "DREYECK/WORK/CTM-PAGE-AUTHORING")))
    (if helper (apply helper +example-page+)
        "The page that holds the example Item is not registered in this Catalog.")))

(defun %example-chain ()
  "The chain of example objects as a plist, or a string that says why there is none."
  (let ((item (%example-item)))
    (if (stringp item)
        item
        (let* ((key (list (lp:page-source-sha256 (lp:story-item-source item)) (lp:story-item-id item)))
               (proposal (or (gethash key *example-proposals*) (setf (gethash key *example-proposals*) (p:propose-item-edit item))))
               (c (current-projection proposal))
               (projection (native-projection c))
               (topic (tm:topicmap-projection-topic-by-id projection +proposes-id+))
               (edge (find (format nil "~A:action:the-proposed-action" +proposes-id+) (tm:topicmap-projection-associations-of projection)
                           :key #'tm:topicmap-association-id-of :test #'equal))
               (role (getf (tm:topicmap-association-properties-of edge) :tmdm-role)))
          (list :proposal proposal :ctm c :topic topic :association (tm:topicmap-topic-object-of topic)
                :edge edge :role role :role-type (tmdm:association-role-type role) :player (tmdm:association-role-player role)
                :player-topic (tm:topicmap-projection-topic-by-id projection "the-proposed-action")
                :action (ctm-binding c "the-proposed-action"))))))

(dolist (entry '(("proposal" :proposal) ("ctm" :ctm) ("proposes-topic" :topic) ("proposes-association" :association) ("proposes-edge-action" :edge)
                 ("proposes-role-action" :role) ("role-type-action" :role-type) ("player-the-proposed-action" :player)
                 ("player-topic-the-proposed-action" :player-topic) ("the-proposed-action-object" :action)))
  (let ((name (first entry)) (key (second entry)))
    (setf (gethash name dreyeck/dita-story-item:*dita-examples*)
          (lambda () (let ((chain (%example-chain))) (if (stringp chain) chain (getf chain key)))))))
