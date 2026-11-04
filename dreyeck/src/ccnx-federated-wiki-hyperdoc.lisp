;;;; HyperDoc registration for the CCNx Federated Wiki reading.

(in-package #:dreyeck/ccnx-federated-wiki)

(dreyeck/hyperdoc:defhyperdoc *ccnx-federated-wiki-hyperdoc*
  :title "The CCNx Federated Wiki"
  :id "dreyeck/ccnx-federated-wiki"
  :asdf-system-name "dreyeck/ccnx-federated-wiki"
  :subdirectory "dreyeck/pages/ccnx-federated-wiki"
  :main-page-id "Reading the CCNx Federated Wiki")
