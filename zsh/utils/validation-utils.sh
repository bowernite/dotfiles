#####################################################################
# Validation utils
#####################################################################

# log_validation_result logs the result of a validation check.
# It takes three parameters:
# - type: Indicates the type of result, either "failure" or "success".
# - message: A descriptive message about the validation check.
# - error_message: An error message to display in case of failure.
function log_validation_result() {
  local type="$1"
  local message="$2"
  local error_message="$3"

  if [[ $type == "failure" ]]; then
    echo -e "❌ \033[1;31m$message: $error_message\033[0m"
    validation_status="failed"
    failed_components+=("$message")
  elif [[ $type == "success" ]]; then
    echo -e "✅ \033[1;32m$message\033[0m"
  fi
}

# run_validation executes a command intended for component validation.
# It takes two parameters:
# - component_action: A descriptive name of the action being validated.
# - command: The command to execute for validation.
# This function will log the validation result and return an exit status.
function run_validation() {
  local component_action=$1
  local command=$2

  echo -e "\n🚀 \033[1;34m$component_action:\033[0m in progress..."
  (eval $command)
  local command_status=$?
  if [ $command_status -ne 0 ]; then
    local error_message="Command failed with status $command_status"
    log_validation_result "failure" "$component_action failed" "$error_message"
    return 1
  else
    log_validation_result "success" "$component_action succeeded"
  fi
}

# show_validation_result displays the final result of the validation process.
# It takes two parameters:
# - validation_status: The overall status of the validation ("success" or "failed").
# - failed_components: An array of components that failed validation.
function show_validation_result() {
  local validation_status="$1"
  local failed_components=("${@:2}") # Capture all arguments after the first one as an array
  echo -e "\n\n\n========================================\n"
  if [[ $validation_status == "success" ]]; then
    echo -e "✅ \033[1;32mValidation completed successfully.\033[0m"
  else
    echo -e "❌ \033[1;31mValidation failed.\033[0m"
    # echo "Failed components:"
    # for component in "${failed_components[@]}"; do
    #   echo -e "• $component"
    # done
  fi
}

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

# validate_repo executes linting and formatting on changed files.
# It takes commands with optional names in the format "NAME::command".
# Commands without names will use a default label.
function validate_repo() {
  local -a names=()
  local -a actual_commands=()
  
  # Parse each command string
  for cmd in "$@"; do
    if [[ "$cmd" == *"::"* ]]; then
      names+=("${cmd%%::*}")
      actual_commands+=("${cmd#*::}")
    else
      # If no name provided, use a generic one
      names+=("CMD")
      actual_commands+=("$cmd")
    fi
  done
  
  # Run all commands concurrently with names
  concurrently -n "$(IFS=,; echo "${names[*]}")" -c "bgYellow,bgMagenta,bgBlue,bgGreen,bgCyan" "${actual_commands[@]}" &&
    echo -e "\n\033[0;32mGood to go.\033[0m" ||
    (echo -e "\n\033[0;31mThere be errors.\033[0m" && exit 1)
}

# run_node_bin is a utility function to find the best command to run a node binary
# It takes one parameter:
# - bin_name: The name of the binary to find (e.g., "eslint", "prettier")
# It returns a string with the command to run the binary
function run_node_bin() {
  local bin_name="$1"
  
  # Check for available package managers and binary runners
  if command -v npx &>/dev/null; then
    echo "npx $bin_name"
  elif command -v bun &>/dev/null; then
    echo "bun $bin_name"
  elif command -v yarn &>/dev/null && [[ -f package.json ]] && grep -q '"packageManager": "yarn' package.json 2>/dev/null; then
    echo "yarn $bin_name"
  elif [[ -f ./node_modules/.bin/$bin_name ]]; then
    # Use the local node_modules binary if it exists
    echo "./node_modules/.bin/$bin_name"
  else
    # Fallback to npx as the most universal solution
    echo "npx $bin_name"
  fi
}
