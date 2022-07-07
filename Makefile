ALLOW_BROKEN=0

install:
	env NIXPKGS_ALLOW_BROKEN=${ALLOW_BROKEN} \
		home-manager -f home.nix switch
	@echo ""
	@echo "Prefer using \"hm\" to \"home-manager\" so you're pointed to the right configuration file."

configure:
	sh ./get-nix.sh
	sh ./get-home-manager.sh
