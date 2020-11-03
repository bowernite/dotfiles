### Alfred

Alfred recommends syncing with Dropbox. For now, all Alfred data is stored in this repository at [/Alfred](/Alfred) for simplicity of migrating on a new computer. If this becomes infeasible, I can always move this back to Dropbox folder syncing.

When starting Alfred for the first time, you'll need to point it to the files in this repo. To do so, open Alfred's preferences > `Appearance` > `Set preferences folder…` and select `<DOTFILES_REPO_PATH>/Alfred`

### Keyboard

Keyboard remapping is done with the Karabiner-Elements app.

This app is installed through homebrew-cask within the `bootstrap.sh` file, but needs some additional configuration:

<hr />

- There are files tracked in `.config/karabiner/assets/complex_modifications`. Not sure yet if these will get overwritten upon installing the app. If they do, then just copy-paste them from this repo back to where they're supposed to be.

<hr />

1. Open the Karabiner-Elements app.
2. Open the `Complex modifications` tab.
3. Click `Add rule` button (bottom left)
4. Enable the following rules:
   - `Change caps_lock to control if pressed with other keys, to escape if pressed alone.`
   - `Toggle caps_lock by pressing left_shift + right_shift at the same time`
      - NOTE: Neither of these solutions seem to turn on the keyboard light for external keyboards. If you want to try and tackle this, check out [this tutorial](https://robin.lauren.fi/posts/map-caps-lock-to-ctrl-or-escape/#:~:text=Open%20the%20%E2%80%9CComplex%20Modifications%E2%80%9D%20tab,alone%20and%20you're%20done!)

<hr />

As of writing this, there's weird behavior between mac keybinding remappings (done through the `Preferences` app) and Karabiner with this configuration, where the option and command keys can't be swapped on external keyboards. If that's the case...

1. Open the Karabiner-Elements app
2. Open the `Simple modifications` tab
3. Add 4 mappings for swapping command and option (e.g. `left_command` to `left_option`)

<hr />

##### Additional Links

- https://medium.com/@pechyonkin/how-to-map-capslock-to-control-and-escape-on-mac-60523a64022b
- https://www.legeektrotteur.com/mac-os-x-lock-caps-with-the-shift-key

#### Function keys w/ Touch Bar

If using a mac with a touch bar, and opting for the control strip by default and function keys when holding `fn`, you'll need to make this modification [shown here](/assets/fn-key-remap.png).

<details>
   The reason this is necessary is that Karabiner thinks you're holding down `fn` and hitting a `f*` key, which the checkbox at the bottom says that it should use the "special feature" for that `f*` key.
</details>
