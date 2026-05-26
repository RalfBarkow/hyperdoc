(in-package :cl-user)

(require :asdf)

(load #p"kioskbeerli/dmx-associative-mirror.lisp")

(kioskbeerli.dmx-associative-mirror:run-dmx-associative-mirror-smoke
 :db-path #p"/tmp/dmx-associative-mirror-smoke.sqlite")
