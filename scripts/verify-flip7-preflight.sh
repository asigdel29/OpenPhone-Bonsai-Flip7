#!/usr/bin/env bash

# Refuse a Flip7 port until the plan's device/recovery gates have concrete,
# local evidence. This script performs no unlock, flash, or network action.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
evidence_dir="${1:-$root/.local-bonsai/flip7-preflight}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
need() { [[ -s "$evidence_dir/$1" ]] || die "missing required evidence: $1"; }

[[ -d "$evidence_dir" ]] || die "evidence directory does not exist: $evidence_dir"

# Text evidence is intentionally required instead of a guessed codename. It
# should contain the raw, sanitized output or link/checksum for the exact unit.
need identity.txt
need unlock-proof.txt
need lineage-source.txt
need kernel-source.txt
need vendor-extraction.txt
need partition-layout.txt
need stock-restore.md
need stock-firmware.sha256

if rg -qi 'unavailable|blocked|unsupported|exploit|paid unlock|bypass' \
  "$evidence_dir/unlock-proof.txt"; then
  die "unlock evidence does not establish a supported user unlock path"
fi

if ! rg -qi 'tested|success|restore' "$evidence_dir/stock-restore.md"; then
  die "stock restore evidence must record a tested successful restoration"
fi

if ! rg -q '^[[:xdigit:]]{64}[[:space:]]+' "$evidence_dir/stock-firmware.sha256"; then
  die "stock-firmware.sha256 must contain a SHA-256 checksum and filename"
fi

printf 'Flip7 preflight evidence passed: %s\n' "$evidence_dir"
