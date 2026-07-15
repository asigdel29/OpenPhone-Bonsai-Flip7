#!/usr/bin/env bash
set -euo pipefail

base="${1:?usage: $0 <base-revision>}"
cap="${SOURCE_LOC_CAP:-200}"
[[ "$cap" =~ ^[0-9]+$ ]] || { echo "SOURCE_LOC_CAP must be an integer" >&2; exit 2; }

added="$(git diff --numstat --no-renames "$base"...HEAD | awk '
  $3 !~ /^(vendor|third_party|node_modules)\// && $3 !~ /(^|\/)(prebuilts|generated)(\/|$)/ { total += $1 }
  END { print total + 0 }
')"
if (( added > cap )); then
  echo "source LOC cap exceeded: ${added} added hand-authored lines (cap: ${cap})" >&2
  exit 1
fi
echo "source LOC cap: ${added}/${cap} added lines"
