;;;; Zero-knowledge-proofs starter topics
;;
;;;; Draft topic factories for the first HyperDoc slice around
;;;; "History of Zero Knowledge Proofs" page 1.

(in-package :hyperdoc)

(defun zero-knowledge-proofs-topic ()
  (make-topic
   :id "zero-knowledge-proofs"
   :title "Zero Knowledge Proofs"
   :summary "Cryptographic proof systems that let one party prove possession of some knowledge without disclosing the knowledge itself, introduced here as a bridge to HyperDoc's existing digital identity and trust cluster."
   :references '("Zero Knowledge Proofs"
                 "Trust Without Disclosure"
                 "Digital Identity as Abstraction"
                 "Over-Identification and Identity Creep"
                 "Design Constraints for Public Digital Identity")))

(defun trust-without-disclosure-topic ()
  (make-topic
   :id "trust-without-disclosure"
   :title "Trust Without Disclosure"
   :summary "A bridge concept for the problem of proving what matters without disclosing everything one knows, everything one is, or everything a system could collect."
   :references '("Trust Without Disclosure"
                 "Zero Knowledge Proofs"
                 "Over-Identification and Identity Creep"
                 "Design Constraints for Public Digital Identity")))

(defun social-authentication-before-cryptography-topic ()
  (make-topic
   :id "social-authentication-before-cryptography"
   :title "Social Authentication Before Cryptography"
   :summary "Historical proof and membership practices such as guild ritual, passwords, gestures, and question-and-answer forms that demonstrated belonging or competence without fully disclosing protected knowledge."
   :references '("Social Authentication Before Cryptography"
                 "Trust Without Disclosure"
                 "Digital Identity and Social Engineering"
                 "Confession, Privacy, and Trusted Speech")))

(defun confession-privacy-and-trusted-speech-topic ()
  (make-topic
   :id "confession-privacy-and-trusted-speech"
   :title "Confession, Privacy, and Trusted Speech"
   :summary "A historical privacy-architecture topic for settings in which truthful or significant speech depends on sharply constrained disclosure."
   :references '("Confession, Privacy, and Trusted Speech"
                 "Trust Without Disclosure"
                 "Zero Knowledge Proofs"
                 "Design Constraints for Public Digital Identity")))

(defun martin-guerre-and-the-problem-of-identity-topic ()
  (make-topic
   :id "martin-guerre-and-the-problem-of-identity"
   :title "Martin Guerre and the Problem of Identity"
   :summary "Historical identity case used here to frame the limits of purely social vouching and the appeal of stronger but less exposing proof relations."
   :references '("Martin Guerre and the Problem of Identity"
                 "Digital Identity as Abstraction"
                 "Trust Erosion from Identity Fraud"
                 "Zero Knowledge Proofs")))

(eval-when (:load-toplevel :execute)
  (install-topic-proxy-wrappers))
