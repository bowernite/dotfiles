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