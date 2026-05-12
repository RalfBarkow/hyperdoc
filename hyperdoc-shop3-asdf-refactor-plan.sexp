((:index 1 :kind :source-edit :operator !add-recursive-component-collector
  :arguments nil :manual? t)
 (:index 2 :kind :commit :stage recursive-component-collector-added :message
  add-recursive-hyperdoc-source-component-discovery :manual? t)
 (:index 3 :kind :source-edit :operator !create-asdf-system :arguments
  (hyperdoc/kernel) :manual? t)
 (:index 4 :kind :source-edit :operator !create-asdf-system :arguments
  (hyperdoc/topics) :manual? t)
 (:index 5 :kind :commit :stage hyperdoc/topics :message
  introduce-hyperdoc-kernel-and-topics-systems :manual? t)
 (:index 6 :kind :source-edit :operator !split-topic-family :arguments (asdf)
  :manual? t)
 (:index 7 :kind :verification :action :load-system :system hyperdoc :manual?
  t)
 (:index 8 :kind :verification :action :run-smoke-test :test
  compile-order-smoke :manual? t)
 (:index 9 :kind :commit :stage compile-order-smoke :message
  split-asdf-topic-family-and-verify-load-order :manual? t))