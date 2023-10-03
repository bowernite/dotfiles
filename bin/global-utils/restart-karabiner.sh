#!/usr/bin/env sh

# (untested)
function restart_karabiner() {
  launchctl stop org.pqrs.karabiner.karabiner_console_user_server
  launchctl start org.pqrs.karabiner.karabiner_console_user_server
}
