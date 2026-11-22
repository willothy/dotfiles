#!/usr/bin/env bash
set -euo pipefail

LATEST_URL="https://capy.ai/download/linux/x64/appimage"
OVERLAY="$(dirname "$(realpath "$0")")/../overlays/capy.nix"

die() {
  echo "update-capy: $*" >&2
  exit 1
}

for field in version hash; do
  count=$(grep -cE "^ *$field = \"[^\"]*\";" "$OVERLAY" || true)
  [[ $count == 1 ]] || die "expected one $field in $OVERLAY, found $count"
done

url=$(curl -fsSIL -o /dev/null -w '%{url_effective}' "$LATEST_URL")
[[ $url =~ /capy-([0-9]+\.[0-9]+\.[0-9]+)-x86_64\.AppImage$ ]] ||
  die "can't find a version in $url"
version=${BASH_REMATCH[1]}

echo "Fetching capy $version"
# fetchurl names the store path "appimage", so matching it saves a second download on rebuild
hash=$(nix store prefetch-file --json --name appimage "$url" | jq -er .hash)

current_version=$(sed -nE 's/^ *version = "([^"]*)";/\1/p' "$OVERLAY")
current_hash=$(sed -nE 's/^ *hash = "([^"]*)";/\1/p' "$OVERLAY")

if [[ $version == "$current_version" && $hash == "$current_hash" ]]; then
  echo "Already pinned to capy $version"
  exit 0
fi

sed -i -E \
  -e "s|^( *version = )\"[^\"]*\";|\1\"$version\";|" \
  -e "s|^( *hash = )\"[^\"]*\";|\1\"$hash\";|" \
  "$OVERLAY"

echo "Pinned capy $current_version -> $version"
echo "To install: nixos-rebuild switch --flake ~/.dotfiles --sudo"
