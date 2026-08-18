.PHONY: help link-cmux link-ghostty check test

help:
	@echo "Targets:"
	@echo "  make link-cmux      Link cmux + Ghostty config into ~/.config (idempotent)"
	@echo "  make link-ghostty   Alias for 'make link-cmux' (they're linked together)"
	@echo "  make check          Verify the links are in place and cmux's config is valid"
	@echo "  make test           Run the shell test suites"

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

# Every suite runs against a sandbox $$HOME, so this never touches real machine
# state.
test:
	@fail=0; \
	for t in $$(find . -name '*.test.sh' -o -name '*.test.zsh' | sort); do \
		echo "==> $$t"; \
		case "$$t" in *.zsh) zsh "$$t" || fail=1;; *) bash "$$t" || fail=1;; esac; \
	done; \
	exit $$fail
