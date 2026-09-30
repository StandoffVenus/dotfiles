# Audits and repairs the Fallout: New Vegas + MO2 + SteamTinkerLaunch setup.
#
# Each invariant here corresponds to something that has silently regressed at
# least once. Most drift is caused by Steam updates/verifies, the vanilla
# launcher, or Proton reinitialising the wineprefix.
#
#   fnv-doctor          audit only, exits 1 if anything is wrong
#   fnv-doctor fix      audit, then repair everything safely repairable

FNV_DIR="${FNV_DIR:-/home/kaiser/Games/SteamLibrary/steamapps/common/Fallout New Vegas}"
FNV_LIBRARY="${FNV_LIBRARY:-/home/kaiser/Games/SteamLibrary}"
FNV_PFX="${FNV_PFX:-$FNV_LIBRARY/steamapps/compatdata/22380/pfx}"
FNV_MO2="${FNV_MO2:-$FNV_PFX/drive_c/Modding/MO2}"
FNV_DOCS="${FNV_DOCS:-$FNV_PFX/drive_c/users/steamuser/Documents/My Games/FalloutNV}"
FNV_PROTON="${FNV_PROTON:-GE-Proton9-27}"

MODE="${1:-check}"
fail=0
fixed=0

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }

ok()   { grn "  ok    $*"; }
bad()  { red "  FAIL  $*"; fail=$((fail+1)); }
did()  { ylw "  fixed $*"; fixed=$((fixed+1)); }
note() { printf '  note  %s\n' "$*"; }

doing_fix() { [ "$MODE" = "fix" ]; }

mo2_running() { pgrep -f 'ModOrganizer\.exe' >/dev/null 2>&1; }

# --- 1. 4GB large-address-aware patch -----------------------------------
# Steam restores the stock exe on every update or file verify, silently
# reverting the patch and reintroducing out-of-memory crashes.
check_laa() {
  echo "4GB LAA patch"
  local exe="$FNV_DIR/FalloutNV.exe" peoff ch
  [ -f "$exe" ] || { bad "FalloutNV.exe missing"; return; }
  peoff=$(od -An -tu4 -j 60 -N 4 "$exe" | tr -d ' ')
  ch=$(od -An -tu2 -j $((peoff + 22)) -N 2 "$exe" | tr -d ' ')
  if [ $((ch & 0x20)) -ne 0 ]; then
    ok "LAA bit set"
  else
    # Deliberately not auto-run: FalloutNVPatcher is interactive and needs
    # an FHS env, so it is left to the existing `fnv4gb` shell helper.
    bad "LAA bit NOT set - run: fnv4gb"
  fi
}

# --- 2. NVHR loader ------------------------------------------------------
# NVHR installs a ~40KB proxy d3dx9_38.dll into the game root, outside MO2.
# It does not work under Proton, and when its binaries are absent it fails
# init and takes the process down. The real d3dx9_38.dll is ~2MB; Proton
# supplies a builtin when the file is absent entirely.
check_nvhr() {
  echo "NVHR proxy"
  local dll="$FNV_DIR/d3dx9_38.dll"
  if [ ! -f "$dll" ]; then
    ok "absent (Proton builtin d3dx9_38 in use)"
    return
  fi
  if grep -qa "nvhr_" "$dll" 2>/dev/null; then
    if doing_fix; then
      mv "$dll" "$dll.nvhr-proxy"
      did "moved NVHR proxy aside"
    else
      bad "NVHR proxy present at d3dx9_38.dll"
    fi
  else
    ok "stock d3dx9_38.dll (not NVHR)"
  fi
}

# --- 3. MO2 drive letters ------------------------------------------------
# Switching Proton reinitialises dosdevices/, which only recreates c: and z:.
# Any custom letter (this setup used S:) disappears and MO2 can no longer
# find the game. z: -> / is always recreated, so paths are pinned to it.
check_mo2_paths() {
  echo "MO2 paths"
  local ini="$FNV_MO2/ModOrganizer.ini"
  [ -f "$ini" ] || { bad "ModOrganizer.ini missing"; return; }
  if ! grep -qaE '=@?[A-Za-z()]*\(?[S-Sa-z]:[\\/]' "$ini" && ! grep -qaE '[= (]S:[\\/]' "$ini"; then
    ok "no stale drive-letter paths"
    return
  fi
  if doing_fix; then
    if mo2_running; then
      bad "MO2 is running - close it first (it rewrites this file on exit)"
      return
    fi
    cp "$ini" "$ini.bak-$(date +%F-%H%M%S)"
    sed -i \
      -e "s|S:\\\\\\\\|Z:\\\\\\\\home\\\\\\\\kaiser\\\\\\\\Games\\\\\\\\SteamLibrary\\\\\\\\|g" \
      -e "s|=S:/|=Z:/home/kaiser/Games/SteamLibrary/|g" \
      "$ini"
    did "repointed MO2 paths to z:"
  else
    bad "ModOrganizer.ini still references S: (dies when Proton changes)"
  fi
}

# --- 4. INI sanity -------------------------------------------------------
# These are NOT made read-only. That was tried and it breaks MO2: with
# LocalSettings=true MO2 replaces My Games/FalloutPrefs.ini at launch, and
# a read-only file makes the game crash immediately on start. The read-only
# trick only guards against FalloutNVLauncher.exe's GPU detection, which is
# no longer in the launch path now that Steam's launch options start MO2
# directly. What is still worth catching is the launcher having run anyway
# and left a ~22-line stub behind, discarding all tuning.
check_inis() {
  echo "My Games INIs"
  local f n
  for f in "$FNV_DOCS/Fallout.ini" "$FNV_DOCS/FalloutPrefs.ini"; do
    [ -f "$f" ] || { bad "$(basename "$f") missing"; continue; }
    n=$(wc -l < "$f")
    if [ "$n" -lt 100 ]; then
      bad "$(basename "$f") looks launcher-reset ($n lines) - restore from '$FNV_DOCS/Bethini Pie backups'"
    elif [ ! -w "$f" ]; then
      if doing_fix; then
        chmod u+w "$f"
        did "$(basename "$f") made writable (read-only breaks MO2's INI swap)"
      else
        bad "$(basename "$f") is read-only - MO2 cannot swap it, game will crash on launch"
      fi
    else
      ok "$(basename "$f") sane ($n lines)"
    fi
  done
}

# --- 5. Steam launch path -----------------------------------------------
# FNV must be launched by Steam with a Proton compat tool and a launch
# option that swaps FalloutNVLauncher.exe for ModOrganizer.exe, so MO2 runs
# inside Steam's Proton session. SteamTinkerLaunch used to sit here and ran
# MO2 under bare wine with no Steam environment; the Steam build of FNV then
# exits during startup no matter which mods are enabled. These live in
# Steam's localconfig.vdf, which Steam rewrites from memory, so they cannot
# be checked from outside reliably -- recorded here as a reminder.
check_launch() {
  echo "Steam launch path"
  note "compat tool should be GE-Proton9-27 (not SteamTinkerLaunch)"
  note "launch options should sed FalloutNVLauncher.exe -> ModOrganizer.exe"
}

# --- 7. NVSE plugin INIs -------------------------------------------------
# These ship as SEPARATE optional downloads on Nexus, not in the main mod
# archives, so a normal install leaves them absent. NVTF calls
# ExitProcess(0) without its INI, which is a hard crash rather than a
# warning; the others degrade or warn. The Stewie and ShowOff files are
# self-populating stubs -- the plugins write their real settings on first
# launch -- so only their existence matters. Reference copies are kept in
# the home-manager config because they cannot be re-fetched without a
# Nexus login.
check_plugin_inis() {
  echo "NVSE plugin INIs"
  local rel ref dst dir
  while read -r ref rel; do
    dst="$FNV_MO2/mods/$rel"
    dir=$(dirname "$dst")
    if [ ! -d "$dir" ]; then
      note "${ref} - mod not installed, skipping"
      continue
    fi
    if [ -f "$dst" ]; then
      ok "$ref"
    elif doing_fix && [ -n "${FNV_INI_DIR:-}" ] && [ -f "$FNV_INI_DIR/$ref" ]; then
      cp "$FNV_INI_DIR/$ref" "$dst"
      did "restored $ref"
    else
      bad "$ref MISSING at $rel"
    fi
  done <<'TABLE'
NVTF.ini NVTF - New Vegas Tick Fix/NVSE/Plugins/NVTF.ini
ShowOffNVSE.ini ShowOff xNVSE Plugin/nvse/plugins/ShowOffNVSE.ini
nvse_stewie_tweaks.ini lStewieAl's Tweaks and Engine Fixes/NVSE/plugins/nvse_stewie_tweaks.ini
TABLE
}

# --- 6. Informational ----------------------------------------------------
check_info() {
  echo "Context"
  local d="$FNV_PFX/dosdevices"
  if [ -e "$d/z:" ]; then ok "z: mapping present"; else bad "z: mapping missing (prefix broken)"; fi
  if [ -f "$FNV_DIR/steam_appid.txt" ]; then
    note "steam_appid.txt present - suppresses FNV's Steam relaunch; suspected of truncating NVSE's hook"
  else
    note "steam_appid.txt absent (currently backed out for testing)"
  fi
  if mo2_running; then note "MO2 is currently running"; fi
  return 0
}

echo "fnv-doctor (${MODE})"
echo
check_laa;       echo
check_nvhr;      echo
check_mo2_paths; echo
check_inis;      echo
check_launch;    echo
check_plugin_inis; echo
check_info;      echo

if [ "$fixed" -gt 0 ]; then echo "repaired: $fixed"; fi
if [ "$fail" -gt 0 ]; then
  red "$fail issue(s) outstanding"
  doing_fix || echo "run 'fnv-doctor fix' to repair what is safely repairable"
  exit 1
fi
grn "all checks passed"
