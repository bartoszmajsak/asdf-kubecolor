#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/hidetatz/kubecolor"
TOOL_NAME="kubecolor"
TOOL_TEST="kubecolor --kubecolor-version"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  list_github_tags
}

get_arch() {
  local platform=""
  
  local unamePlatform
  unamePlatform=$(uname -m)
  
  case $unamePlatform in
    
    arm64)
      platform="$unamePlatform"
      ;;

    amd64|i686|x86_64)
      platform="x86_64"
      ;;

    ppc64le)
      platform="$unamePlatform"
      ;;
    
    *)
      fail "Your platform (${unamePlatform}) does not have corresponding release."
      ;;

  esac
  
  local unameOS
  unameOS=$(uname -s)
  case "${unameOS}" in

    Darwin|Linux)
      echo "${unameOS}_${platform}"
      ;;

    *)
      fail "Your OS (${unameOS}) does not have corresponding release."
      ;;
  esac

}

download_release() {
  local version filename url arch
  version="$1"
  filename="$2"
  arch=$(get_arch)

  url="$GH_REPO/releases/download/v${version}/${TOOL_NAME}_${version}_${arch}.tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  )
}
