.PHONY: help link-cmux link-ghostty check

help:
	@echo "Targets:"
	@echo "  make link-cmux      Link cmux + Ghostty config into ~/.config (idempotent)"
	@echo "  make link-ghostty   Alias for 'make link-cmux' (they're linked together)"
	@echo "  make check          Verify the links are in place and cmux's config is valid"

# Both configs are linked by one script: cmux reads the Ghostty config, so
# they're only useful together.
link-cmux:
	@dotfiles_dir="$(CURDIR)" bash setup/link-cmux-ghostty.sh

link-ghostty: link-cmux

check:
	@echo "cmux.json:"; ls -ld $(HOME)/.config/cmux/cmux.json
	@echo "ghostty:";   ls -ld $(HOME)/.config/ghostty
	@if [ -x /Applications/cmux.app/Contents/Resources/bin/cmux ]; then \
		/Applications/cmux.app/Contents/Resources/bin/cmux config check; \
	else \
		echo "cmux not installed; skipping config check"; \
	fi
