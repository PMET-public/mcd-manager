#!/bin/bash

set -e # stop on errors
[[ "$debug" ]] && set -x

red='\033[0;31m'
yellow='\033[1;33m'
green='\033[0;32m'
no_color='\033[0m'

error() {
  printf "\n[%s] %b%s%b\n\n" "$($date_cmd --utc +"%Y-%m-%d %H:%M:%S")" "$red" "Error: $*" "$no_color" 1>&2 && exit 1
}

warning() {
  printf "%b%s%b" "$yellow" "$*" "$no_color"
}

warning_w_newlines() {
  warning "
$*
"
}

msg() {
  printf "%b%s%b\n" "$green" "$*" "$no_color"
}

msg_w_newlines() {
  msg "
$*
"
}

is_CI() {
  [[ $GITHUB_WORKSPACE || $TRAVIS ]]
}

# increase the size & clear the terminal
printf '\e[8;50;140t'


# needed for testing
if [[ $GITHUB_WORKSPACE ]]; then
  REPO_BRANCH="${GITHUB_REF#refs/heads/}"
elif [[ $TRAVIS ]]; then
  REPO_BRANCH="$TRAVIS_BRANCH"
fi

# grab latest mdm release/branch head and link it
# this code should closely mirror download_and_link_latest func in lib.sh
# but must also exist here to bootstrap mdm
repo_url="https://github.com/PMET-public/mdm"
mdm_path="$HOME/.mdm"
mkdir -p "$mdm_path"
cd "$mdm_path"
# testing should grab the latest head of the branch
# unless master which would be equivalent to the latest release so use/test that instead
if [[ "$REPO_BRANCH" && "$REPO_BRANCH" != "master" ]]; then
  latest_ver="$REPO_BRANCH"
else
  latest_ver=$(curl -s "$repo_url/releases" | \
    perl -ne 'BEGIN{undef $/;} /archive\/(.*)\.tar\.gz/ and print $1')
fi
curl -sLO "$repo_url/archive/$latest_ver.tar.gz"
mkdir -p "$latest_ver"
tar -zxf "$latest_ver.tar.gz" --strip-components 1 -C "$latest_ver"
rm "$latest_ver.tar.gz" current 2> /dev/null || : # cleanup and remove old link
ln -sf "$latest_ver" current
rsync -az current/certs/ certs/ # cp/replace over any new certs

set +x # if we make it this far, turn off the debugging output for the rest
clear

msg_w_newlines "
Once all requirements are installed and validated, this script will not need to run again."

[[ "$(uname)" = "Darwin" ]] && {
  # install homebrew
  [[ -f /usr/local/bin/brew ]] || {
    warning_w_newlines "This script installs Homebrew, which may require your password. If you're
  skeptical about entering your password here, you can install Homebrew (https://brew.sh/)
  independently first. Then you will NOT be prompted for your password by this script."
    msg_w_newlines "Alternatively, you can allow this script to install Homebrew by pressing ANY key to continue."

    ! is_CI && read -n 1 -s -r -p ""

    clear

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  }

  # do not install docker (which is docker toolbox) via homebrew; use docker for mac instead
  # upgrade mac's bash, use coreutils for consistency across *NIX
  # install mkcert but do not install CA generated by mkcert without explicit user interaction
  # nss is required by mkcert to install Firefox trust store
  brew install bash coreutils mkcert nss || :
  brew upgrade bash coreutils mkcert nss

  [[ -d /Applications/Docker.app ]] || {
    msg_w_newlines "
  Press ANY key to continue to the Docker Desktop For Mac download page. Then download and install that app.

  https://hub.docker.com/editions/community/docker-ce-desktop-mac/
"
    ! is_CI && read -n 1 -s -r -p ""
    # open docker for mac installation page
    open "https://hub.docker.com/editions/community/docker-ce-desktop-mac/"
  }

  msg_w_newlines "CLI dependencies successfully installed. If you downloaded and installed Docker Desktop for Mac, this script should not need to run again.

You may close this terminal.
"
}

: # return true
