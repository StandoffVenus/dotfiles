ALLOW_BROKEN=0

all: configure install

configure:
	sh ./get-nix.sh
	sh ./get-home-manager.sh

install:
	env NIXPKGS_ALLOW_BROKEN=${ALLOW_BROKEN} \
		home-manager -f home.nix switch
	@echo ""
	@echo "Created first home-manager generation."
	@echo "Prefer using \"hm\" to \"home-manager\" so you're pointed to the right configuration file."
