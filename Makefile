.PHONY: repomix repomix-help repomix-clean repomix-all \
        repomix-core repomix-dock repomix-validation repomix-fedwiki \
        repomix-dmx repomix-deployment repomix-dm6 repomix-zotero \
        repomix-full \
        kioskbeerli-pi-sim-plan kioskbeerli-pi-sim-eval \
        kioskbeerli-pi-sim-build kioskbeerli-pi-sim-run

REPOMIX_PACK = core
PACK = $(REPOMIX_PACK)
REPOMIX_FOCUSED_PACKS = core dock validation fedwiki dmx deployment dm6 zotero
KIOSKBEERLI_PI_SIM_BACKEND ?=

repomix:
	tools/repomix-pack.sh $(PACK)

repomix-core:
	tools/repomix-pack.sh core

repomix-dock:
	tools/repomix-pack.sh dock

repomix-validation:
	tools/repomix-pack.sh validation

repomix-fedwiki:
	tools/repomix-pack.sh fedwiki

repomix-dmx:
	tools/repomix-pack.sh dmx

repomix-deployment:
	tools/repomix-pack.sh deployment

repomix-dm6:
	tools/repomix-pack.sh dm6

repomix-zotero:
	tools/repomix-pack.sh zotero

repomix-full:
	tools/repomix-pack.sh full

repomix-all:
	for pack in $(REPOMIX_FOCUSED_PACKS); do \
		tools/repomix-pack.sh "$$pack"; \
	done

repomix-clean:
	rm -f repomix-output-hyperdoc*.md repomix-output-hyperdoc*.xml

repomix-help:
	@echo "Repomix targets:"
	@echo "  make repomix                  # generate core pack"
	@echo "  make repomix PACK=dock        # generate one named pack"
	@echo "  make repomix REPOMIX_PACK=dock"
	@echo "  make repomix-core"
	@echo "  make repomix-dock"
	@echo "  make repomix-validation"
	@echo "  make repomix-fedwiki"
	@echo "  make repomix-dmx"
	@echo "  make repomix-deployment"
	@echo "  make repomix-dm6"
	@echo "  make repomix-zotero"
	@echo "  make repomix-all              # all focused packs, not full"
	@echo "  make repomix-full             # intentional expensive full repo pack"
	@echo "  make repomix-clean"

kioskbeerli-pi-sim-plan:
	nix develop -c sbcl --noinform --disable-debugger \
		--eval '(require :asdf)' \
		--eval '(asdf:load-system :kioskbeerli/pi-simulation)' \
		--eval '(let ((plan (kioskbeerli/pi-simulation:make-pi-simulation-plan))) (format t "~&~A~%mode=~S levels=~D tasks=~D next=~{~A~^, ~}~%" (kioskbeerli/pi-simulation:title-of plan) (kioskbeerli/pi-simulation:execution-mode-of plan) (length (kioskbeerli/pi-simulation:levels-of plan)) (length (kioskbeerli/pi-simulation:tasks-of plan)) (mapcar (lambda (task) (kioskbeerli/pi-simulation:id-of task)) (kioskbeerli/pi-simulation:pi-simulation-next-actions :plan plan))))' \
		--quit

kioskbeerli-pi-sim-eval:
	nix develop -c sbcl --noinform --disable-debugger \
		--eval '(require :asdf)' \
		--eval '(asdf:load-system :kioskbeerli/pi-simulation)' \
		--eval '(dolist (spec (remove-if-not (lambda (spec) (= 1 (kioskbeerli/pi-simulation:level-of spec))) (kioskbeerli/pi-simulation:pi-simulation-command-specs))) (format t "~&[plan-only] ~A~%" (kioskbeerli/pi-simulation:command-text-of spec)))' \
		--quit

kioskbeerli-pi-sim-build:
	nix develop -c sbcl --noinform --disable-debugger \
		--eval '(require :asdf)' \
		--eval '(asdf:load-system :kioskbeerli/pi-simulation)' \
		--eval '(dolist (spec (remove-if-not (lambda (spec) (= 2 (kioskbeerli/pi-simulation:level-of spec))) (kioskbeerli/pi-simulation:pi-simulation-command-specs))) (format t "~&[plan-only] ~A~%" (kioskbeerli/pi-simulation:command-text-of spec)))' \
		--quit

kioskbeerli-pi-sim-run:
	nix develop -c sbcl --noinform --disable-debugger \
		--eval '(require :asdf)' \
		--eval '(asdf:load-system :kioskbeerli/pi-simulation)' \
		--eval '(let ((status (kioskbeerli/pi-simulation:pi-simulation-vm-boot-status :backend (unless (string= "$(KIOSKBEERLI_PI_SIM_BACKEND)" "") "$(KIOSKBEERLI_PI_SIM_BACKEND)")))) (format t "~&VM boot status: ~S~%backend: ~S~%reason: ~A~%" (kioskbeerli/pi-simulation:status-of status) (kioskbeerli/pi-simulation:backend-of status) (kioskbeerli/pi-simulation:reason-of status)))' \
		--quit
