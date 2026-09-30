#!/usr/bin/env bash

# Script to duplicate all files named with a v1 suffix to vN (e.g., v5),
# updating internal references from v1 to vN as well.
# Usage: ./bump_v1_to_vN.sh [dir] <N>

set -euo pipefail

dir="${1:-.}"                    # folder to scan (default: current)
N="${2:?Usage: $0 [dir] <N>}"    # target N (e.g., 5)

# Finds files whose names end with v1, or _v1.<ext>, or v1.<ext>
# (no GNU-only flags; works on macOS/BSD too)
find "$dir" -type f \( -name '*_v1' -o -name '*_v1.*' -o -name '*v1' -o -name '*v1.*' \) -print0 |
while IFS= read -r -d '' f; do
  d=$(dirname "$f")
  bn=$(basename "$f")
  # Build new filename: replace trailing _v1 or v1 (optionally before extension) with vN
  new_bn=$(printf '%s' "$bn" | sed -E "s/_v1(\.[^./]+)?$/_v${N}\1/; t; s/v1(\.[^./]+)?$/v${N}\1/")
  new_path="$d/$new_bn"

  cp "$f" "$new_path"

  # Replace standalone 'v1' tokens inside content (not v10, etc.)
  perl -0777 -i -pe "s/(?<![A-Za-z0-9])v1(?![0-9])/v${N}/g" "$new_path"

  echo "Created: $new_path"
done
