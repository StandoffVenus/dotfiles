#!/usr/bin/env bash
# Shows the disks, their partitions and how full they are. Read-only: it
# never mounts, unmounts or writes anything, and needs no root.
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: nixos disk [list | usage [PATH] [--depth N]]

  list          every disk with its partitions, filesystems, labels, mount
                points and space (the default)
  usage         size, used and free space of each mounted filesystem
  usage PATH    the largest directories under PATH, staying on its
                filesystem; --depth N looks N levels down (default: 1)

lsblk only knows the space on mounted partitions, so unmounted ones show
their size alone.
USAGE
  exit 2
}

# zram's major number is assigned at boot, so it is looked up rather than
# hard-coded next to loop (7) and ram (1).
excluded_majors() {
  local majors=1,7 zram
  zram=$(awk '$2 == "zram" { print $1 }' /proc/devices)
  [ -n "$zram" ] && majors+=",$zram"
  echo "$majors"
}

list() {
  [ $# -eq 0 ] || usage
  # MOUNTPOINTS comes last because a bind-mounted partition lists one per
  # line, which would otherwise push every column after it out of line.
  lsblk -e "$(excluded_majors)" \
    -o NAME,MODEL,TRAN,SIZE,FSTYPE,LABEL,FSUSED,FSAVAIL,FSUSE%,MOUNTPOINTS
}

filesystems() {
  # df shows each device once even when it is bind-mounted elsewhere, as
  # /home/kaiser and /mnt/games are here.
  df -h --output=source,fstype,size,used,avail,pcent,target \
    -x tmpfs -x devtmpfs -x efivarfs -x overlay -x ramfs -x squashfs
}

largest() {
  local path="" depth=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --depth)
        [ $# -ge 2 ] || usage
        case "$2" in
          "" | *[!0-9]*) echo "nixos disk: --depth needs a whole number, got '$2'" >&2; usage ;;
        esac
        depth="$2"; shift 2 ;;
      -*) echo "nixos disk: unknown argument: $1" >&2; usage ;;
      *)
        [ -z "$path" ] || usage
        path="$1"; shift ;;
    esac
  done

  if [ ! -d "$path" ]; then
    echo "nixos disk: not a directory: $path" >&2
    exit 1
  fi

  # -x keeps du on PATH's own filesystem, so / does not wander into /home
  # or the games drive. Unreadable directories are skipped rather than
  # reported one by one; their sizes are then undercounted.
  du -xh --max-depth="$depth" -- "$path" 2>/dev/null | sort -rh | head -n 20 || true
}

case "${1-list}" in
  list) shift || true; list "$@" ;;
  usage)
    shift
    if [ $# -eq 0 ]; then
      filesystems
    else
      largest "$@"
    fi
    ;;
  -h | --help) usage ;;
  *) echo "nixos disk: unknown subcommand: $1" >&2; usage ;;
esac
