#!/bin/bash

set -e # stop on errors
set -x 

red='\033[0;31m'
green='\033[0;32m'
no_color='\033[0m'

error() {
  printf "\n%b%s%b\n\n" "$red" "$*" "$no_color" 1>&2 && exit 1
}
msg() {
  printf "%b%s%b\n" "$green" "$*" "$no_color"
}

# increase the size & clear the terminal
printf '\e[8;50;140t'


# grab latest mdm release and link it
# this code should closely mirror download_and_link_latest_release func in lib.sh
# but must also exist here to bootstrap mdm
repo_url="https://github.com/PMET-public/mdm"
mdm_path="$HOME/.mdm"
mkdir -p "$mdm_path"
cd "$mdm_path"
latest_release_ver=$(curl -s "$repo_url/releases" | \
  perl -ne 'BEGIN{undef $/;} /archive\/(.*)\.tar\.gz/ and print $1')
curl -svLO "$repo_url/archive/$latest_release_ver.tar.gz"
mkdir -p "$latest_release_ver"
tar -zxf "$latest_release_ver.tar.gz" --strip-components 1 -C "$latest_release_ver"
rm "$latest_release_ver.tar.gz" current || : # cleanup and remove old link
ln -sf "$latest_release_ver" current

set +x # if we make it this far, turn off the debugging output for the rest
clear

msg "

Once all requirements are installed and validated, this script will not need to run again.
(This script will require an admin account.)

"

# install homebrew
[[ -f /usr/local/bin/brew ]] || \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# do not install docker (which is docker toolbox) via homebrew; use docker for mac instead
brew install bash coreutils
brew upgrade bash coreutils

[[ -d /Applications/Docker.app ]] || {
  msg "

Press ANY key to continue to the Docker Desktop For Mac download page. Then download and install that app.

https://hub.docker.com/editions/community/docker-ce-desktop-mac/

"
  read -n 1 -s -r -p ""
  # open docker for mac installation page
  open "https://hub.docker.com/editions/community/docker-ce-desktop-mac/"
}

msg "
CLI dependencies successfully installed. If you downloaded and installed Docker Desktop for Mac,
this script should not need to run again.

You may close this terminal.

"

