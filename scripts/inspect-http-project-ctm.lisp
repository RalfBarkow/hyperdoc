;;;; Read trusted local files populated by the HTTP fixture; no Lisp READ/EVAL of responses.
(require :asdf)
(asdf:load-system "dreyeck/work/project")
(let* ((received-path (uiop:getenv "HYPERDOC_BOOTSTRAP_RECEIVED"))
       (expected-path (uiop:getenv "HYPERDOC_BOOTSTRAP_EXPECTED"))
       (received (dreyeck/work/project:ctm-revision-from-octets (dreyeck/work/project::%octets received-path)))
       (expected (dreyeck/work/project:ctm-revision-from-octets (dreyeck/work/project::%octets expected-path)))
       (map (dreyeck/work/project:revision-map received))
       (index (and map (dreyeck/work/project::%index map)))
       (id "codex-2026-10-29-template-identity-substitution")
       (owner (and index (gethash (dreyeck/work/project::%iri "assignment" id) index)))
       (checks 0))
  (flet ((verify (label condition)
           (incf checks)
           (unless condition (error "HTTP native check failed: ~A" label))
           (format t "~&HTTP-NATIVE-CHECK ~A PASS~%" label)))
    (verify "reader-pin" (getf (dreyeck/work/project::topic-maps-source-identity) :pinned))
    (verify "native-map-without-refusal" (and map (null (dreyeck/work/project:revision-refusal received))))
    (verify "known-assignment" owner)
    (verify "assignment-type"
            (member (gethash (dreyeck/work/project:schema-iri "implementation-assignment") index)
                    (dreyeck/work/project::%types map owner) :test #'eq))
    (dolist (entry '("original-source" "corpus-expectation" "reader-behavior" "expanded-control"
                     "grammar-reading" "substitution-reading" "unresolved-question"
                     "unresolved-contracts" "execution-boundary" "decision-note"))
      (let* ((topic (gethash (dreyeck/work/project::%iri "evidence" id entry) index))
             (occurrence (and topic (topic-maps.tmdm:topic-reified topic))))
        (verify (format nil "evidence/~A/reification-and-owner" entry)
                (and occurrence (eq owner (topic-maps.tmdm:occurrence-parent occurrence))
                     (eq topic (topic-maps.tmdm:item-reifier occurrence))
                     (eq (gethash (dreyeck/work/project:schema-iri "evidence-note") index)
                         (topic-maps.tmdm:occurrence-type occurrence))))
        (verify (format nil "evidence/~A/attributed-value" entry)
                (eql 0 (search "Operator report" (topic-maps.tmdm:occurrence-value occurrence))))))
    (let* ((page (gethash (dreyeck/work/project:page-iri "dreyeck/work/project" "Implementation Assignments") index))
           (declared (dreyeck/work/project::%of-role map owner "declared-on" "declaration"))
           (reads (dreyeck/work/project::%of-role map owner "reads-source" "assignment")))
      (verify "declared-on-roles-and-source-page"
              (and declared (= 2 (length (topic-maps.tmdm:association-roles declared)))
                   (eq page (dreyeck/work/project::%player declared (dreyeck/work/project:schema-iri "source-page")))))
      (verify "reads-source-roles-and-source-page"
              (and reads (= 2 (length (topic-maps.tmdm:association-roles reads)))
                   (eq page (dreyeck/work/project::%player reads (dreyeck/work/project:schema-iri "source")))))
      (verify "source-page-path"
              (equal '("dreyeck/pages/project/Implementation Assignments.html")
                     (dreyeck/work/project::%occurrences page (dreyeck/work/project:schema-iri "repository-path"))))
      (verify "source-page-sha256"
              (equal '("0d755af7b32bd02c30d41573afc9956767c8027e0e7fb79f20affa294cc1e463")
                     (dreyeck/work/project::%occurrences page (dreyeck/work/project:schema-iri "source-sha256")))))
    (let ((comparison (dreyeck/work/project:compare-revisions expected received)))
      (verify "transport-octet-equivalence" (getf comparison :octets-equal))
      (verify "same-document-and-base-cxtm-equivalence" (getf comparison :cxtm-equal)))
    (verify "unchanged-octet-export-not-serializer"
            (equalp (dreyeck/work/project:revision-octets received)
                    (dreyeck/work/project:revision-export-octets received)))
    (format t "~&HTTP-NATIVE-PASS: ~D checks; doc/base ~A; CXTM SHA256 ~A~%" checks
            dreyeck/work/project:+document-iri+
            (dreyeck/work/project::%sha256 (dreyeck/work/project:revision-cxtm received)))))
