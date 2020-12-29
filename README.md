<div align="center">
  <h1>dotfiles 👨‍💻</h1>
  <p>My blessing… and my curse
</div>

<hr />

## Installation

<!-- TODO: Figure out how to set up git credentials. Might have to do that before this step, or figure out some `curl` way to install this without git. See how others do it -->

> NEXT_MACHINE: Try step 2 on its own. If it works, take a note of that, and maybe make a to-do that simplifies this (i.e. remove step 1, run those commands in `bootstrap.sh`, only run those commands once by putting some kind of flag into `.zshrc\_\_private, etc.)

1. On a brand new installation of macOS:

<!-- softwareupdate: Updates and installs Apple software (like Safari, macOS, etc.) -->
<!-- xcode-select: Installs dev tools (like git, make, etc.) -->

- `sudo softwareupdate -i -a`
- `xcode-select --install`

2. Install: `` bash -c "`curl -fsSL https://raw.githubusercontent.com/babramczyk/dotfiles/master/remote-install.sh`" ``
1. In this repo, uncomment/handle lines labeled with `NEXT_MACHINE`
1. `cd ~/dotfiles && source bootstrap.sh`
1. Add sensitive data to [.zshrc\_\_private](.zshrc__private) (find them in your password manager)

```shell
export __TRELLO_API_KEY=
export __TRELLO_TOKEN=
```

6. Fix or note any findings that were specific to the "next machine" (including these installation instructions 🙂)

#### You might need to...

1. Make sure third-party apps are running properly with their license keys (you either put them in Bitwarden or have them somewhere in your email)

- [ ] Alfred
- [ ] Bartender

2. Put this at the top of `/private/etc/pam.d/sudo`: `auth sufficient pam_tid.so`. This allows TouchID instead of a password for sudo
1. Follow any other instructions below

#### Double check...

- [ ] That Alfred is indexing markdown files properly. In Alfred's modal, try `in <text>`, where text is some text that exists in a markdown file on the machine. If this doesn't work, try running [scripts/make-spotlight-index-markdown.sh](scripts/make-spotlight-index-markdown.sh) again. If it does work right away, remove this blurb.

### macOS Preferences 👨‍💻

The macOS setup script tries to set all necessary preferences as best it can, but there's a few essential things it doesn't work work with yet. Maybe we'll fix those one day, but for now just go and manually check these.

- Turn off Spotlight keyboard shortcut (Alfred instead). `System Preferences` > `Keyboard` > `Shortcuts` > `Spotlight` > Uncheck spotlight search
- Enable Alfred workflows to run all scripts. `System Preferences` > `Security & Privacy` > `Privacy` > `Developer Tools` > `Enable Alfred`

### Rectangle ▬

1. Open Rectangle's preferences
1. Copy the keybindings [shown here](/assets/rectangle-keybindings.png)

<details>
   This is done here because this keybinding changes a plist option where it's some data array, and I don't know exactly how to modify that correctly.
</details>

### Bartender ⧓

As of writing this, there's a Bartender 4 update that is only for Big Sur+. Because of the unknown of that, when setting up just set up Bartender manually. Maybe at that time, run the pref diffs and add them to the macos setup script as necessary.

### Terminal 💻

1. Open Terminal
1. Open `Preferences > Profile`
1. Drag [macos/terminal-theme.terminal](macos/terminal-theme.terminal) into the pane with all of the profiles
1. Select the font to be `Dank Mono Regular`, `18 pt.`
1. Elsewhere in preferences, set that to be the default theme and window

<details>
   Terminal's preferences are weird and nested, and I don't want to deal with that right now, and who knows, maybe I switch to iTerm one day 😅. So this is fine for now.
</details>

### Alfred 🎩

Alfred recommends syncing with Dropbox. For now, all Alfred data is stored in this repository at [/Alfred](/Alfred) for simplicity of migrating on a new computer. If this becomes infeasible, I can always move this back to Dropbox folder syncing.

- [ ] When starting Alfred for the first time, you'll need to point it to the files in this repo. To do so, open Alfred's preferences > `Appearance` > `Set preferences folder…` and select `<DOTFILES_REPO_PATH>/Alfred`
- [ ] Make sure Alfred and its workflows have proper OS access. In Alfred's preferences, go to `General` > `Permissions` > `Request Permissions`, and let Alfred guide you 🧙‍♂️

### Keyboard ⌨️

Keyboard remapping is done with the Karabiner-Elements app.

> NOTE: Remapping for external "non-Mac" keyboards is currently done on a one-off basis for my particular mechanical keyboard (Karabiner stores product and vendor IDs). If you ever switch keyboards, you'll need to manually \*\*swap the `opt` and `command` keys just for that keyboard

- [ ] Make sure the default Profile is called `Goku`

### Font 🔠

For use in VS Code, download the [Dank Mono](https://gumroad.com/l/dank-mono) font (the confirmation/link to the actual asset should be in your email somewhere)

### After cloning repositories

After cloning any repositories, exclude their `node_modules` from Alfred's/Spotlight's search by going to `System Preferences` > `Spotlight` > `Privacy` and adding each `node_modules` folder to the list.

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

- Nikita's dotfiles: https://github.com/nikitavoloboev/dotfiles
- WebPro's dotfiles: https://github.com/webpro/dotfiles
- https://github.com/mjackson/dotfiles
- Nikita's shell aliases: https://github.com/nikitavoloboev/dotfiles/blob/43568152bdade89cd331b45ee4db39a7036b2663/zsh/alias.zsh
- [dotcommon - common vim plugins, shell aliases, etc.](https://github.com/Kharacternyk/dotcommon)

### Just when you think you're done...

✨ https://github.com/search?q=dotfiles ✨
