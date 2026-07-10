(:zettel-9182-shop3-provider-boundary-repair
 (:checkpoint "Zettel 9182")
 (:selected-task
  (!build-next-declarative-successor-with-kioskbeerli-wifi-module))
 (:failure
  (:type simple-package-error)
  (:message "ALEXANDRIA.1.0.0 is a nickname for the package ALEXANDRIA")
  (:cause :broad-shop3-checkout-source-registry-exposes-vendored-alexandria))
 (:repair
  (:narrow-source-registry t)
  (:provider-system :hyperdoc/shop3-provider-boundary)
  (:provider-system-pre-hyperdoc-loadable t)
  (:optional-planner-system :hyperdoc/shop3)
  (:forbid-shop3-root-tree t)
  (:forbid-vendored-alexandria-provider t)
  (:ignore-inherited-source-registry t)
  (:fasl-output-translations :writable-cache)
  (:package-mutation :forbidden)
  (:delete-package :forbidden)
  (:rename-alexandria-packages :forbidden))
 (:boundary
  (:selected-directories
   (#p"/Users/rgb/workspace/hyperdoc/"
    #p"/Users/rgb/workspace/shop3/shop3/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/pddl-tools/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/fiveam-asdf/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/random-state/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/documentation-utils/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/trivial-indent/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/trivial-garbage/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/iterate/"))
  (:rejected-directories
   (#p"/Users/rgb/workspace/shop3/"
    #p"/Users/rgb/workspace/shop3/jenkins/ext/alexandria/"))
  (:broad-shop3-root-tree-registration :forbidden)
  (:vendored-alexandria-provider :forbidden))
 (:validation
  (:load-hyperdoc t)
  (:load-hyperdoc-shop3-provider-boundary t)
  (:load-hyperdoc-shop3-after-narrow-registration t)
  (:root-hyperdoc-does-not-load-shop3 t)
  (:hyperdoc-does-not-load-kioskbeerli t)
  (:broad-shop3-tree-registration :forbidden-and-absent)
  (:alexandria-package-mutation :not-used))
 (:plan-only-layer
  (:hyperdoc/shop3 :plan-only)
  (:does-not-edit-files t)
  (:does-not-run-shell-commands t)
  (:does-not-mutate-dmx t)
  (:does-not-run-tests t)
  (:does-not-commit-changes t)))
