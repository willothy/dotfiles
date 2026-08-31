#!/usr/bin/env bash
set -euo pipefail

BOOT_DIR="/boot/EFI/nixos"
KEEP=5   # number of newest generations to keep

cd "$BOOT_DIR"

echo "Boot directory: $BOOT_DIR"
echo "Keeping newest $KEEP kernel/initrd pairs"
echo

# Extract generation IDs from initrd filenames
gens=$(
  ls -1 initrd-* 2>/dev/null \
  | sed -E 's/^initrd-([^-]+)-.*/\1/' \
  | sort -u
)

count=$(echo "$gens" | wc -l)

if (( count <= KEEP )); then
  echo "Nothing to delete ($count generations total)"
  exit 0
fi

# Generations to delete = oldest ones
to_delete=$(echo "$gens" | head -n $((count - KEEP)))

echo "Removing generations:"
echo "$to_delete"
echo

for gen in $to_delete; do
  echo "Deleting generation $gen"
  rm -f linux-"$gen"-*
  rm -f initrd-"$gen"-*
done

echo
echo "Done."
