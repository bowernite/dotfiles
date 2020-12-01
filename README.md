## Installation

<!-- TODO: Figure out how to set up git credentials. Might have to do that before this step, or figure out some `curl` way to install this without git. See how others do it -->

1. `cd ~ && git clone https://github.com/mathiasbynens/dotfiles.git`
1. Uncomment/handle lines labeled with `NEXT_MACHINE`
1. `cd ~/dotfiles && source bootstrap.sh`
1. Fix or note any findings that were specific to the "next machine" (including these installation instructions 🙂)

#### You might need to...

1. Make sure third-party apps are running properly with their license keys (you either put them in Bitwarden or have them somewhere in your email)

- [ ] Alfred
- [ ] Bartender

2. Put this at the top of `/private/etc/pam.d/sudo`: `auth sufficient pam_tid.so`. This allows TouchID instead of a password for sudo
3. Follow any other instructions below

### macOS Preferences

The macOS setup script tries to set all necessary preferences as best it can, but there's a few essential things it doesn't work work with yet. Maybe we'll fix those one day, but for now just go and manually check these.

- Turn off Spotlight keyboard shortcut (Alfred instead). `System Preferences` > `Keyboard` > `Shortcuts` > `Spotlight` > Uncheck spotlight search
- Enable Alfred workflows to run all scripts. `System Preferences` > `Security & Privacy` > `Privacy` > `Developer Tools` > `Enable Alfred`

### Rectangle

1. Open Rectangle's preferences
1. Add a keybinding for "Almost Maximize" (e.g. `ctrl+opt+cmd+↩`), if desired

<details>
   This is done here because this keybinding changes a plist option where it's some data array, and I don't know exactly how to modify that correctly.
</details>

### Bartender

As of writing this, there's a Bartender 4 update that is only for Big Sur+. Because of the unknown of that, when setting up just set up Bartender manually. Maybe at that time, run the pref diffs and add them to the macos setup script as necessary.

### Terminal

1. Open Terminal
1. Open `Preferences > Profile`
1. Drag [macos/terminal-theme.terminal](macos/terminal-theme.terminal) into the pane with all of the profiles
1. Select the font to be `Dank Mono Regular`, `18 pt.`
1. Elsewhere in preferences, set that to be the default theme and window

<details>
   Terminal's preferences are weird and nested, and I don't want to deal with that right now, and who knows, maybe I switch to iTerm one day 😅. So this is fine for now.
</details>

### Alfred

Alfred recommends syncing with Dropbox. For now, all Alfred data is stored in this repository at [/Alfred](/Alfred) for simplicity of migrating on a new computer. If this becomes infeasible, I can always move this back to Dropbox folder syncing.

When starting Alfred for the first time, you'll need to point it to the files in this repo. To do so, open Alfred's preferences > `Appearance` > `Set preferences folder…` and select `<DOTFILES_REPO_PATH>/Alfred`

### Keyboard

Keyboard remapping is done with the Karabiner-Elements app.

> NOTE: Remapping for external "non-Mac" keyboards is currently done on a one-off basis for my particular mechanical keyboard (Karabiner stores product and vendor IDs). If you ever switch keyboards, you'll need to manually \*\*swap the `opt` and `command` keys just for that keyboard

### Font

For use in VS Code, download the [Dank Mono](https://gumroad.com/l/dank-mono) font (the confirmation/link to the actual asset should be in your email somewhere)

## Resources

- https://medium.com/@pechyonkin/how-to-map-capslock-to-control-and-escape-on-mac-60523a64022b
- https://www.legeektrotteur.com/mac-os-x-lock-caps-with-the-shift-key
- [Reference for Karabiner Emacs bindings](https://github.com/drliangjin/karabiner.d)
- [Remapping Cocoa Keybindings](http://irreal.org/blog/?p=259)
  - Decided against this, since plenty of apps don't use Coca's text system. Using Karabiner to define keybindings at the OS level seems far more robust
- https://github.com/drliangjin/karabiner.d

## To-Do

There's a million things I could do... I don't know, maybe some of them are over the top. I'm just gonna put them down here in case I decide they're a good idea one day...

- Get crazy with Karabiner remappings: https://wiki.nikitavoloboev.xyz/macos/macos-apps/karabiner
- Look into Hyper. Maybe trigger with left control. [Dr. Jin's Karabiner repo](https://github.com/drliangjin/karabiner.d) might be able to help
