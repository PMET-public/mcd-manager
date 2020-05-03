#!/usr/bin/env bash
set -e

# shellcheck source=lib.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

# cd to app dir containing relevant docker-compose files
cd "$lib_dir/.." || exit
[[ -f docker-compose.yml ]] && export_compose_project_name

# shellcheck source=menu-items-handlers.sh
source "$lib_dir/menu-items-handlers.sh"

# shellcheck source=menu-items.sh
source "$lib_dir/menu-items.sh"

if run_without_args; then
  render_platypus_status_menu
else
  handle_menu_selection
fi

[[ $resource_dir ]] && {
  # if quit_detection_file does not exist, start monitoring for quit
  if [[ ! -f "$quit_detection_file" ]]; then
    detect_quit_and_stop_app >> "$handler_log_file" 2>&1 & # must background & disconnect STDIN & STDOUT for Platypus to exit
  fi
}
