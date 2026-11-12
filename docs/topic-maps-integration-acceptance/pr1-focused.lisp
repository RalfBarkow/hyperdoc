;;;; Acceptance harness only; the fixed Topic Maps sources and tests are unchanged.
(require :asdf)
(asdf:initialize-source-registry '(:source-registry :ignore-inherited-configuration))
(asdf:initialize-output-translations
 '(:output-translations (t "/workspace/work/acceptance-fasls-topic/") :ignore-inherited-configuration))
(asdf:load-asd #P"/workspace/work/acceptance-runtime/topic-maps-c446a822/topic-maps.asd")
(asdf:test-system "topic-maps/tmdm/default-name-type-tests")
(asdf:test-system "topic-maps/tmdm/core-relationship-tests")
(assert (= 21 (length (topic-maps.default-name-type.tests:default-name-type-checks))))
(assert (= 50 (length (topic-maps.core-relationship.tests:core-relationship-checks))))
(topic-maps.core-relationship.tests:write-report
 #P"/workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/pr1-counts.json")
(format t "~&ACCEPTANCE-PR1-PASS: 21 default-name and 50 relationship checks from the fixed source; no HyperDoc code loaded.~%")
