.PHONY: repomix repomix-help repomix-clean repomix-all \
        repomix-core repomix-dock repomix-validation repomix-fedwiki \
        repomix-dmx repomix-deployment repomix-dm6 repomix-zotero \
        repomix-full

REPOMIX_PACK = core
PACK = $(REPOMIX_PACK)
REPOMIX_FOCUSED_PACKS = core dock validation fedwiki dmx deployment dm6 zotero

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
