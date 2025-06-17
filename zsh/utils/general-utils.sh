#####################################################################
# General utilities
#####################################################################

# change_directory_or_run_command changes to the specified directory and optionally runs a command.
# It takes at least one parameter:
# - target_directory: The directory to change to.
# - Any additional parameters are treated as a command to run in that directory.
function change_directory_or_run_command() {
  local target_directory="$1"
  shift
  if [ $# -eq 0 ]; then
    cd "$target_directory"
  else
    (cd "$target_directory" && $*)
  fi
} 