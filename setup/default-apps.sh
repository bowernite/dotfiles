#!/usr/bin/env bash
##############################################################
# Set default apps for file types using duti
# https://github.com/moretension/duti/
#
# Can be run standalone: ./setup/default-apps.sh
# Also sourced by setup/macos.sh
##############################################################

if ! command -v duti &>/dev/null; then
  echo "Error: duti is not installed. Install with: brew install duti"
  return 1 2>/dev/null || exit 1
fi

CURSOR="com.todesktop.230313mzl4w4u92"

echo "Setting default apps..."

# Broad UTI categories (covers many text/code files at once)
duti -s $CURSOR public.plain-text all
duti -s $CURSOR public.source-code all
duti -s $CURSOR public.script all
duti -s $CURSOR public.shell-script all
duti -s $CURSOR public.xml all
duti -s $CURSOR public.json all
duti -s $CURSOR public.yaml all
duti -s $CURSOR public.data all

# Web / JS / TS
for ext in js mjs cjs jsx ts tsx css scss sass less vue svelte astro; do
  duti -s $CURSOR $ext all
done

# Data / Config
for ext in json jsonc yml yaml toml xml csv plist env ini cfg conf properties; do
  duti -s $CURSOR $ext all
done

# Documentation / Text
for ext in md mdx txt rst tex log; do
  duti -s $CURSOR $ext all
done

# Shell / Scripts
for ext in sh bash zsh fish; do
  duti -s $CURSOR $ext all
done

# Programming languages
for ext in py pyc rb go rs c cpp h hpp java kt swift m php pl lua r scala hs ex exs erl clj edn; do
  duti -s $CURSOR $ext all
done

# DevOps / Infra
for ext in dockerfile tf hcl; do
  duti -s $CURSOR $ext all
done

# Misc
for ext in sql graphql gql lock diff patch makefile cmake gradle svg; do
  duti -s $CURSOR $ext all
done

echo "Done setting default apps."
