<div align="center">
  <h1>dotfiles 👨‍💻</h1>
  <p>My blessing… and my curse
</div>

<hr />

## Installation

> You may need to restart your mac between some of these steps, but if you can defer until as late in this process as possible, do so to keep the number of reboots to a minimum.

On a brand new installation of macOS:

<!-- softwareupdate: Updates and installs Apple software (like Safari, macOS, etc.) -->
<!-- xcode-select: Installs dev tools (like git, make, etc.) -->

- `sudo softwareupdate -i -a`
- `xcode-select --install`

1. `sudo softwareupdate -i -a` (updates Apple software like Safari)
1. `xcode-select --install` (install dev tools, like `git` and `make`)
1. `` bash -c "`curl -fsSL https://raw.githubusercontent.com/babramczyk/dotfiles/master/remote-install.sh`" `` (clones this repo to the machine)
1. `cd ~/src/personal/dotfiles && source bootstrap.sh`
1. Add any sensitive data to [.zshrc\_\_private](.zshrc__private)

```shell
export __a_secret=
```

6. `macos/dock.sh` (sets up the dock for the first time on a new machine)

## Post-Installation 🔨

I try to automate everything I can, but here's everything I haven't yet (or won't at all).

### One-offs 1️⃣

- [ ] Turn off Spotlight keyboard shortcut (Alfred instead). `System Preferences` > `Keyboard` > `Shortcuts` > `Spotlight` > Uncheck spotlight search
- [ ] Save Trello (and Slack) as "apps" from Chrome (overflow menu > `More Tools` > `Create shortcut…` > check `Open as new window`)
- [ ] Rectangle ◻️: Open up Rectangle, and configure it how you'd like
- [ ] Bartender ️🍸: Open up Bartender, and configure it how you'd like

### Keyboard ⌨️

Keyboard remapping is done with the Karabiner-Elements app.

- [ ] Open up the Karabiner-Elements app > `Profile` > Rename the default to `Goku`.

<!-- NOTE: Remapping for external "non-Mac" keyboards is currently done on a one-off basis for my particular mechanical keyboard (Karabiner stores product and vendor IDs). If you ever switch keyboards, you'll need to manually **swap the `opt` and `command` keys just for that keyboard** -->

### Dropbox 📦

- [ ] If you use Dropbox, open the app and log in. Make sure any preferences are set up properly.

### Alfred 🎩

- [ ] Sync settings with Dropbox using the "second mac" instructions [here](https://www.alfredapp.com/help/advanced/sync/)
- [ ] Set non-synced settings
  - [ ] Global Alfred hotkey
  - [ ] Theme (set one for dark theme and one for light theme, based on macOS dark/light)
- [ ] Make sure Alfred and its workflows have proper OS access. In Alfred's preferences, go to `General` > `Permissions` > `Request Permissions`, and let Alfred guide you 🧙‍♂️
- [ ] Exclude all `node_modules` from Spotlight: `System Preferences` > `Spotlight` > `Privacy`: Drag folders from Finder into the drop area. You can easily find these by triggering Alfred and querying for `node_modules`

### Font 🔠

- [ ] For use in VS Code and your terminal:

1. Download the [Dank Mono](https://gumroad.com/l/dank-mono) font (link to download it is in your password manager)
1. Extract and open the downloaded zip
1. Open the `OpenType-PS` directory
1. Double click on all the fonts, and click `Install Font` for each

### Terminal 💻

- [ ] Configure vanilla macOS Terminal app:

1. Open Terminal
1. Open `Preferences > Profile`
1. Drag [macos/terminal-theme.terminal](macos/terminal-theme.terminal) into the pane with all of the profiles
1. Select the font to be `Dank Mono Regular`, `18 pt.`
1. Elsewhere in preferences, set that to be the default theme and window

<details>
   Terminal's preferences are weird and nested, and I don't want to deal with that right now, and who knows, maybe I switch to iTerm one day 😅. So this is fine for now.
</details>

### GitHub 🐙

- [ ] Authenticate with GitHub so that you can push from the CLI

1. Follow the [instructions here](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) to create a personal access token (you'll need to do this, since having 2FA enabled on your GitHub account prevents you from using username+password from the CLI).
1. Copy the generated token
1. Go to any repo that's been cloned for you in `~/src/personal/`
1. Make a small change and commit it
1. `git push`
1. Use your GitHub username (not email), and the token for the password

### Apps and Websites 📱

- [ ] If you want to be thorough and get as much of the setup done now vs. things popping up later, go through all of your apps and common websites and do anything applicable from the following. This will save a lot of interruptions and annoyance in your first week or so of starting to use the apps and websites you typically use.

> NOTE: These might not be necessary if you're using a Time Machine/cloud backup.

1. Login
1. For apps, make sure any settings are properly synced or manually set

#### Examples

- Browsers
- Music Players
- VS Code/editor
- Apple Apps like iMessage and Contacts
- Super common websites, like GitHub, Google, email

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

## Resources 📚

- https://medium.com/@pechyonkin/how-to-map-capslock-to-control-and-escape-on-mac-60523a64022b
- https://www.legeektrotteur.com/mac-os-x-lock-caps-with-the-shift-key
- [Remapping Cocoa Keybindings](http://irreal.org/blog/?p=259)
- https://github.com/drliangjin/karabiner.d
- https://wiki.nikitavoloboev.xyz/macos/macos-apps/karabiner
- https://medium.com/@nikitavoloboev/karabiner-god-mode-7407a5ddc8f6
