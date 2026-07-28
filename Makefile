.PHONY: help cmux ghostty check

help:
	@echo "Targets:"
	@echo "  make cmux      Link cmux + Ghostty config into ~/.config (idempotent)"
	@echo "  make ghostty   Alias for 'make cmux' (they're linked together)"
	@echo "  make check     Verify the links are in place and cmux's config is valid"

# Both configs are linked by one script: cmux reads the Ghostty config, so
# they're only useful together.
cmux:
	@dotfiles_dir="$(CURDIR)" bash setup/link-cmux-ghostty.sh

ghostty: cmux

check:
	@echo "cmux.json:"; ls -ld $(HOME)/.config/cmux/cmux.json
	@echo "ghostty:";   ls -ld $(HOME)/.config/ghostty
	@if [ -x /Applications/cmux.app/Contents/Resources/bin/cmux ]; then \
		/Applications/cmux.app/Contents/Resources/bin/cmux config check; \
	else \
		echo "cmux not installed; skipping config check"; \
	fi
