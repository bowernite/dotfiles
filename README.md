<div align="center">
  <h1>dotfiles 👨‍💻</h1>
  <p>My blessing… and my curse
</div>

<hr />

## Installation

> NEXT_MACHINE: Try step 2 on its own. If it works, take a note of that, and maybe make a to-do that simplifies this (i.e. remove step 1, run those commands in `bootstrap.sh`, only run those commands once by putting some kind of flag into `.zshrc\_\_private, etc.)

1. On a brand new installation of macOS:

<!-- softwareupdate: Updates and installs Apple software (like Safari, macOS, etc.) -->
<!-- xcode-select: Installs dev tools (like git, make, etc.) -->

- `sudo softwareupdate -i -a`
- `xcode-select --install`

2. Install: `` bash -c "`curl -fsSL https://raw.githubusercontent.com/babramczyk/dotfiles/master/remote-install.sh`" ``
1. `cd ~/src/personal/dotfiles && source bootstrap.sh`
1. Add any sensitive data to [.zshrc\_\_private](.zshrc__private) (find them in your password manager)

```shell
export __a_secret=
```

6. `macos/dock.sh` (sets up the dock for the first time on a new machine)

<!-- TODO: Automate this -->

2. Put this at the top of `/private/etc/pam.d/sudo`: `auth sufficient pam_tid.so`. This allows TouchID instead of a password for sudo
1. Follow any other instructions below

## Post-Installation 🔨

I try to automate everything I can, but here's everything I haven't yet, or maybe don't ever want to, or maybe it's just too early to tell if these are evergreen yet.

### One-offs 1️⃣

- Turn off Spotlight keyboard shortcut (Alfred instead). `System Preferences` > `Keyboard` > `Shortcuts` > `Spotlight` > Uncheck spotlight search
- Save Trello (and Slack) as "apps" from Chrome (overflow menu > `More Tools` > `Create shortcut…` > check `Open as new window`)
- Rectangle ◻️: Open up Rectangle, and set its keybindings and preferences to what you're used to
- Bartender ️🍸: Open up Bartneder, and configure it how you'd like it

### Keyboard ⌨️

Keyboard remapping is done with the Karabiner-Elements app.

- [ ] Open up the Karabiner-Elements app > `Profile` > Rename the default to `Goku`.

<!-- NOTE: Remapping for external "non-Mac" keyboards is currently done on a one-off basis for my particular mechanical keyboard (Karabiner stores product and vendor IDs). If you ever switch keyboards, you'll need to manually **swap the `opt` and `command` keys just for that keyboard** -->

### Alfred 🎩

- [ ] Make sure Alfred and its workflows have proper OS access. In Alfred's preferences, go to `General` > `Permissions` > `Request Permissions`, and let Alfred guide you 🧙‍♂️
- [ ] Exclude all `node_modules` from Spotlight: `System Preferences` > `Spotlight` > `Privacy`: Drag folders from Finder into the drop area. You can easily find these by triggering Alfred and querying for `node_modules`

### Font 🔠

For use in VS Code and your terminal:

1. Download the [Dank Mono](https://gumroad.com/l/dank-mono) font (link to download it is in your password manager)
1. Extract and open the downloaded zip
1. Open the `OpenType-PS` directory
1. Double click on all the fonts, and click `Install Font` for each

### Terminal 💻

1. Open Terminal
1. Open `Preferences > Profile`
1. Drag [macos/terminal-theme.terminal](macos/terminal-theme.terminal) into the pane with all of the profiles
1. Select the font to be `Dank Mono Regular`, `18 pt.`
1. Elsewhere in preferences, set that to be the default theme and window

<details>
   Terminal's preferences are weird and nested, and I don't want to deal with that right now, and who knows, maybe I switch to iTerm one day 😅. So this is fine for now.
</details>

### GitHub 🐙

To authenticate with GitHub from the command line...

- [ ] Follow the [instructions here](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) to create a personal access token (you'll need to do this, since having 2FA enabled on your GitHub account prevents you from using username+password from the CLI).
  - [ ] Copy the generated token
- [ ] Go to any repo that's been cloned for you in `~/src/personal/`
  - [ ] Make a small change and commit it
  - [ ] `git push`
  - [ ] Use your GitHub username (not email), and the token for the password

You should now be properly authenticated for future requests to GitHub.

## Resources 📚

- https://medium.com/@pechyonkin/how-to-map-capslock-to-control-and-escape-on-mac-60523a64022b
- https://www.legeektrotteur.com/mac-os-x-lock-caps-with-the-shift-key
- [Remapping Cocoa Keybindings](http://irreal.org/blog/?p=259)
- https://github.com/drliangjin/karabiner.d
- https://wiki.nikitavoloboev.xyz/macos/macos-apps/karabiner
- https://medium.com/@nikitavoloboev/karabiner-god-mode-7407a5ddc8f6

## Inspirations 📝

The Issues page on GitHub contains concrete to-dos.

Here are some places to poke around at for inspiration for things you might want to do

- https://github.com/nikitavoloboev/dotfiles
- https://github.com/webpro/dotfiles
- https://github.com/mjackson/dotfiles
- Nikita's shell aliases: https://github.com/nikitavoloboev/dotfiles/blob/43568152bdade89cd331b45ee4db39a7036b2663/zsh/alias.zsh
- https://github.com/Kharacternyk/dotcommon

### Just when you think you're done...

✨ https://github.com/search?q=dotfiles ✨
