#!/usr/bin/env bash
# Reclaims disk space taken by old Nix generations and unreferenced store
# paths. Safe to run any time: only generations you are not booted into or
# currently using are removed, and the store keeps everything still reachable
# from a surviving generation.
set -euo pipefail

# A `nix-env --delete-generations` spec. "14d" keeps a fortnight, "+5" keeps
# the five newest whatever their age, "old" keeps only the current one.
spec=14d
spec_set=""
optimise=0
dry_run=0

usage() {
  cat >&2 <<'USAGE'
usage: nix-clean [--days N | --keep N | --all] [--optimise] [--dry-run]

  --days N    keep generations from the last N days (default: 14)
  --keep N    keep the N newest generations, however old they are
  --all       keep only the current generation
  --optimise  hard-link duplicate files in the store afterwards (slow)
  --dry-run   show what would be deleted without deleting it

--days, --keep and --all are mutually exclusive.
USAGE
  exit 2
}

set_spec() {
  if [ -n "$spec_set" ]; then
    echo "nix-clean: $1 conflicts with $spec_set" >&2
    usage
  fi
  spec_set="$1"
  spec="$2"
}

want_count() {
  case "$1" in
    "" | *[!0-9]*) echo "nix-clean: $2 needs a whole number, got '$1'" >&2; usage ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --days) [ $# -ge 2 ] || usage; want_count "$2" --days; set_spec --days "${2}d"; shift 2 ;;
    --keep) [ $# -ge 2 ] || usage; want_count "$2" --keep; set_spec --keep "+${2}"; shift 2 ;;
    --all) set_spec --all old; shift ;;
    --optimise|--optimize) optimise=1; shift ;;
    --dry-run|-n) dry_run=1; shift ;;
    -h|--help) usage ;;
    *) echo "nix-clean: unknown argument: $1" >&2; usage ;;
  esac
done

# Every profile is a symlink next to its own -link generations; `per-user` is
# a plain directory, so restricting to symlinks skips it. Enumerating these
# by hand rather than leaning on `nix-collect-garbage --delete-older-than`
# is what lets --keep work: only nix-env understands a "+N" spec.
list_profiles() {
  [ -d "$1" ] || return 0
  find "$1" -maxdepth 1 -type l ! -name '*-link' -print
}

mapfile -t user_profiles < <(list_profiles "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles")
mapfile -t system_profiles < <(list_profiles /nix/var/nix/profiles)

# Resolved absolute, because sudo resets PATH to secure_path and would not
# otherwise find the nix-env this script was built against.
nix_env=("$(command -v nix-env)" --delete-generations "$spec")
if [ "$dry_run" -eq 1 ]; then
  nix_env+=(--dry-run)
fi

for profile in "${user_profiles[@]}"; do
  echo "==> ${profile}"
  "${nix_env[@]}" -p "$profile"
done

for profile in "${system_profiles[@]}"; do
  echo "==> ${profile} (root)"
  sudo "${nix_env[@]}" -p "$profile"
done

if [ "$dry_run" -eq 1 ]; then
  echo
  echo "==> would then sweep unreferenced store paths"
  nix-collect-garbage --dry-run
  exit 0
fi

before=$(df --output=avail -B1 /nix | tail -1)

# Expiring a generation only drops a GC root; this is what actually reclaims
# the disk. Run as both users, since each sweeps the roots it can see.
echo "==> sweeping unreferenced store paths"
nix-collect-garbage
sudo nix-collect-garbage

if [ "$optimise" -eq 1 ]; then
  echo "==> optimising store"
  nix store optimise
fi

after=$(df --output=avail -B1 /nix | tail -1)
echo "==> freed $(numfmt --to=iec --suffix=B "$(( after - before ))") ($(numfmt --to=iec --suffix=B "$after") now free on /nix)"

cat <<'NOTE'

If system generations went away, the boot menu still lists them. Run
`nixos boot` (or `sudo nixos-rebuild boot --flake ...`) to regenerate it.
NOTE
