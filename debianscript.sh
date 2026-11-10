#!/usr/bin/env bash
#==============================================================================
#
#  HOW TO RUN
#     sed -i 's/\r$//' cyberpatriot_debian12.sh   # only if copied from Windows/Google Docs
#     sudo bash cyberpatriot_debian12.sh
#   No working sudo yet? Use a LOGIN root shell:   su -    then   bash /path/to/cyberpatriot_debian12.sh
#   (On Debian, plain `su` without the dash leaves /usr/sbin out of PATH.)
#
#  BEFORE YOU RUN IT
#   1. Answer the FORENSICS QUESTIONS first. This script removes users,
#      software and media files those questions often ask about.
#   2. Read the README. Have ready: authorized admins, authorized standard
#      users, and every service the README calls "critical"/"required".
#   3. Open a SECOND terminal with a root shell (`sudo -i` or `su -`) and
#      leave it open until you've confirmed you can still log in and use sudo.
#
#  SAFETY DESIGN
#   * Nothing destructive happens without showing you what and asking first.
#   * Every config edit is backed up to /root/cp-backups and VALIDATED
#     (sshd -t, visudo -c, apache2ctl configtest, testparm, named-checkconf,
#     PAM module check, service restart check). Failed validation = rollback.
#   * Services the README needs are hardened, never removed.
#   * Packages are only purged if apt confirms it won't also remove the
#     desktop or a critical package. No `apt autoremove`; anything a purge
#     orphans is marked "manual" so a later autoremove can't strip the desktop.
#   * APT stays on Debian 12 repos only ("stable" is pinned to "bookworm",
#     because Debian 13 is now "stable").
#   * Your own account is never deleted, demoted or locked.
#   * Root is only locked if sudo is installed (Debian may not have it).
#   * Anything that looks like the CyberPatriot scoring engine is skipped.
#==============================================================================

if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
if [[ $EUID -ne 0 ]]; then echo "This script must be run as root:  sudo bash $0   (or from a 'su -' shell)"; exit 1; fi

# Debian's plain `su` keeps the calling user's PATH (no /usr/sbin), which breaks
# useradd, visudo, sysctl, ufw, ... so always use a full root PATH.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive
export UCF_FORCE_CONFFOLD=1
export NEEDRESTART_SUSPEND=1
export APT_LISTCHANGES_FRONTEND=none
export APT_LISTBUGS_FRONTEND=none
# Lock::Timeout: wait (up to 10 min) instead of failing when automatic updates hold the apt lock
APT_OPTS=(-y -q -o DPkg::Lock::Timeout=600 -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
umask 022
SELF=$(readlink -f "$0" 2>/dev/null)
declare -A SAFE_PID=()
_p=$$; while [[ $_p =~ ^[0-9]+$ ]] && ((_p > 1)); do SAFE_PID[$_p]=1; _p=$(awk '/^PPid:/{print $2}' "/proc/$_p/status" 2>/dev/null); done

if [[ -t 1 ]]; then R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; W=$'\e[1m'; N=$'\e[0m'
else R=; G=; Y=; C=; W=; N=; fi
TTY=/dev/tty
if ! { : <"$TTY"; } 2>/dev/null; then echo "Run this script from a terminal window — it needs to ask you questions."; exit 1; fi

#----------------------------- main user / paths ------------------------------
MAIN_USER=${SUDO_USER:-}
if [[ -z $MAIN_USER || $MAIN_USER == root ]]; then
  guess=$(logname 2>/dev/null); [[ $guess == root ]] && guess=
  read -rp "Enter YOUR username (the account you log in with)${guess:+ [$guess]}: " MAIN_USER <"$TTY"
  MAIN_USER=${MAIN_USER:-$guess}
fi
if [[ -z $MAIN_USER ]] || ! id "$MAIN_USER" &>/dev/null; then echo "User '$MAIN_USER' does not exist."; exit 1; fi
if [[ $MAIN_USER == root ]]; then echo "Enter your normal (non-root) login account, not root."; exit 1; fi
MAIN_HOME=$(getent passwd "$MAIN_USER" | cut -d: -f6)
DESKTOP=$(runuser -u "$MAIN_USER" -- xdg-user-dir DESKTOP 2>/dev/null)
[[ -n $DESKTOP && $DESKTOP != "$MAIN_HOME" && -d $DESKTOP ]] || DESKTOP="$MAIN_HOME/Desktop"
[[ -d $DESKTOP ]] || { mkdir -p "$DESKTOP"; chown "$MAIN_USER": "$DESKTOP"; }   # don't leave a root-owned Desktop

STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$DESKTOP/CP-Script"
LOGDIR="$OUT/logs"
LOG="$OUT/script.log"
REPORT="$OUT/REVIEW-ME.txt"
BACKUP="/root/cp-backups/$STAMP"
QUAR="/root/cp-quarantine"
mkdir -p "$LOGDIR" "$BACKUP/files" "$QUAR"
chmod 700 /root/cp-backups "$BACKUP" "$QUAR"
START=$(date +%s)
touch "$BACKUP/.start-marker"
{
  echo "CyberPatriot script review list (Debian 12) — $(date)"
  echo "Items marked [!] need YOUR attention. Everything else is info for forensics/manual checks."
  echo "Backups: $BACKUP     Quarantined files: $QUAR"
  echo
} >"$REPORT"
trap 'chown -R "$MAIN_USER": "$OUT" 2>/dev/null; chmod -R go-rwx "$OUT" 2>/dev/null' EXIT

#--------------------------------- logging ------------------------------------
ts()      { local t=$(( $(date +%s) - START )); printf '%02d:%02d' $((t/60)) $((t%60)); }
log()     { echo "[$(ts)] $*" >>"$LOG"; echo "${G}[+]${N} $*"; }
info()    { echo "[$(ts)]     $*" >>"$LOG"; echo "    $*"; }
warn()    { echo "[$(ts)] WARNING: $*" >>"$LOG"; echo "${Y}[!] $*${N}"; echo "[!] $*" >>"$REPORT"; }
review()  { echo "$*" >>"$REPORT"; }
section() { echo; echo "${C}==== $* ====${N}"; printf '\n==== %s ====\n' "$*" >>"$LOG"; }
run()     { "$@" >>"$LOG" 2>&1; }

#------------------------------- prompting ------------------------------------
ask_yn() {
  local ans
  while true; do
    read -rp "${Y}[?]${N} $1 [y/n]: " ans <"$TTY" || { echo; return 1; }   # terminal gone = "no"
    case "${ans,,}" in y|yes) return 0 ;; n|no) return 1 ;; esac
    echo "    Please type y or n."
  done
}
ask() { local __v; read -rp "${Y}[?]${N} $1 " __v <"$TTY" || true; printf '%s' "$__v"; }

#-------------------------------- utilities -----------------------------------
in_list()        { local x=$1 e; shift; for e in "$@"; do [[ $e == "$x" ]] && return 0; done; return 1; }
group_members()  { getent group "$1" | cut -d: -f4 | tr ',' ' '; }
user_in_group()  { group_members "$2" | tr ' ' '\n' | grep -qxF -- "$1"; }
# First call wins, so $BACKUP/files always holds the PRE-script original of each file.
backup_file()    { local f; for f in "$@"; do [[ -e $f && ! -e $BACKUP/files$f ]] && cp -a --parents "$f" "$BACKUP/files/" 2>/dev/null; done; return 0; }
uid_of()         { id -u "$1" 2>/dev/null; }

UID_MIN=$(awk '/^[[:space:]]*UID_MIN[[:space:]]/{print $2; exit}' /etc/login.defs); [[ $UID_MIN =~ ^[0-9]+$ ]] || UID_MIN=1000
UID_MAX=$(awk '/^[[:space:]]*UID_MAX[[:space:]]/{print $2; exit}' /etc/login.defs); [[ $UID_MAX =~ ^[0-9]+$ ]] || UID_MAX=60000
human_users()    { awk -F: -v min="$UID_MIN" -v max="$UID_MAX" '$3>=min && $3<=max {print $1}' /etc/passwd; }
is_human()       { local u; u=$(uid_of "$1") || return 1; (( u >= UID_MIN && u <= UID_MAX )); }

# Anything that looks like the CyberPatriot scoring engine / VM tools / README is never touched.
CP_PROTECT_RE='cyberpatriot|ccs|css|scor(e|ing)|aeacus|phocus|forensic|readme|vbox|virtualbox|vmware|vmtools|open-vm|spice-vdagent|qemu-ga'
is_protected()   { grep -qEi -- "$CP_PROTECT_RE" <<<"$1"; }

# Reverse-shell / downloader patterns (cron, systemd, autostart, shell rc files, processes)
SUSP='/dev/tcp/|/dev/udp/|bash -i|sh -i|nc [^|]*-e|ncat [^|]*-e|mkfifo|base64[[:space:]]+-d|python[0-9.]*[[:space:]]+-c|perl[[:space:]]+-e|socat|/tmp/|/dev/shm/|curl[^|]*\||wget[^|]*\|'
# Stricter subset for files a PACKAGE installed (those may legitimately mention /tmp etc.)
REVSH='/dev/tcp/|/dev/udp/|bash -i|nc [^|]*-e|ncat [^|]*-e|mkfifo|base64[[:space:]]+-d[[:space:]]*\||curl[^|]*\|[[:space:]]*(ba)?sh|wget[^|]*\|[[:space:]]*(ba)?sh'
# What `sudo -l -U USER` prints when USER has full admin rights
SUDO_ALL_RE='\(ALL([[:space:]]*:[[:space:]]*ALL)?\)[[:space:]]+(NOPASSWD:[[:space:]]*)?ALL[[:space:]]*$'

#----------------------- package-ownership helpers ----------------------------
# In system folders, anything no package installed is suspect (planted tools, backdoor
# scripts, cron jobs). Debian 12 has merged /usr, so /bin/x and /usr/bin/x are one file.
PKGFILES="$BACKUP/pkg-owned-files.txt"
build_pkgfiles() {
  cat /var/lib/dpkg/info/*.list 2>/dev/null | awk '{ print }
    /^\/(bin|sbin|lib|lib32|lib64|libx32)\//     { print "/usr" $0 }
    /^\/usr\/(bin|sbin|lib|lib32|lib64|libx32)\// { print substr($0, 5) }' | sort -u >"$PKGFILES"
}
pkg_owned()     { [[ -s $PKGFILES ]] || build_pkgfiles; grep -qxF -- "$1" "$PKGFILES"; }
not_pkg_owned() { [[ -s $PKGFILES ]] || build_pkgfiles; grep -vxFf "$PKGFILES"; }

#------------------------------ quarantine helpers ----------------------------
# "Quarantine" = move (not delete) into /root/cp-quarantine/files/<original path>.
# The file is gone from where the scoring engine looks, but you can still restore it.
quarantine() {
  local f=$1 dest="$QUAR/files$1"
  [[ -e $f || -L $f ]] || return 1
  if is_protected "$f"; then info "Not touching $f (looks like the scoring engine / VM tools)"; return 1; fi
  [[ $(readlink -f -- "$f") == "$SELF" ]] && return 1
  mkdir -p "$(dirname "$dest")" && mv -f -- "$f" "$dest" 2>/dev/null
}
peek() { # show what's inside an archive / what a file is, to help you decide
  case "${1,,}" in
    *.zip|*.jar|*.whl) command -v unzip >/dev/null && unzip -l "$1" 2>/dev/null | sed -n '4,8p' ;;
    *.tar|*.tar.*|*.tgz|*.tbz|*.tbz2|*.txz) tar -tf "$1" 2>/dev/null | head -5 ;;
    *.deb) dpkg-deb -f "$1" Package Description 2>/dev/null | head -3 ;;
    *) command -v file >/dev/null && file -b "$1" 2>/dev/null | cut -c1-100 ;;
  esac | sed 's/^/        /'
}
# Kill processes whose PROGRAM or an ARGUMENT is exactly this file (a precise
# 'pkill -f FILE' that can't hit an unrelated process that merely mentions the name).
kill_running() {
  local target=$1 d pid a exe argv n=0
  for d in /proc/[0-9]*; do
    pid=${d#/proc/}; [[ $pid == "$$" || -n ${SAFE_PID[$pid]:-} ]] && continue
    exe=$(readlink "$d/exe" 2>/dev/null) || continue
    if [[ ${exe% (deleted)} == "$target" ]]; then kill -9 "$pid" 2>/dev/null && ((n++)); continue; fi
    argv=(); mapfile -d '' -t argv 2>/dev/null <"$d/cmdline" || continue
    for a in "${argv[@]:1}"; do
      [[ ${a##*/} == "${target##*/}" ]] || continue
      [[ $a == /* ]] || a=$(readlink -f -- "$d/cwd/$a" 2>/dev/null)
      [[ $a == "$target" ]] && { kill -9 "$pid" 2>/dev/null && ((n++)); break; }
    done
  done
  ((n)) && info "Stopped $n running process(es) using $target"
  return 0
}
# quarantine_files "description" FILE... — lists them, then asks: all / each / none
quarantine_files() {
  local desc=$1 ans f n=0 keep=(); shift
  for f in "$@"; do is_protected "$f" || keep+=("$f"); done   # never offer the scoring engine's files
  set -- "${keep[@]}"
  if (($# == 0)); then info "No $desc found."; return 0; fi
  echo "${W}Found $# $desc:${N}"
  printf '   %s\n' "${@:1:40}"; (($# > 40)) && echo "   ... and $(($# - 40)) more (full list in REVIEW-ME.txt)"
  review "--- $desc ---"; printf '   %s\n' "$@" >>"$REPORT"; review ""
  while true; do
    read -rp "${Y}[?]${N} Quarantine them? [a]ll / [e]ach (ask per file) / [n]one: " ans <"$TTY" || { ans=n; break; }
    ans=${ans,,}; [[ $ans == a || $ans == e || $ans == n ]] && break
  done
  if [[ $ans == n ]]; then info "Left in place — listed in REVIEW-ME.txt"; return 0; fi
  for f in "$@"; do
    [[ -e $f ]] || continue
    if [[ $ans == e ]]; then
      echo "   $f  ($(du -h -- "$f" 2>/dev/null | cut -f1))"; peek "$f"
      ask_yn "   Quarantine it?" || continue
    fi
    quarantine "$f" && ((n++))
  done
  log "Quarantined $n $desc (originals kept under $QUAR/files)"
}

# Levenshtein distance (for typo warnings on usernames)
lev() {
  awk -v a="$1" -v b="$2" 'BEGIN{la=length(a); lb=length(b)
    for(i=0;i<=la;i++) d[i,0]=i; for(j=0;j<=lb;j++) d[0,j]=j
    for(i=1;i<=la;i++) for(j=1;j<=lb;j++){ c=(substr(a,i,1)==substr(b,j,1))?0:1
      x=d[i-1,j]+1; y=d[i,j-1]+1; z=d[i-1,j-1]+c; m=(x<y)?x:y; d[i,j]=(m<z)?m:z }
    print d[la,lb]}'
}

# set_conf FILE KEY VALUE [SEP]  — replace first active "KEY..." line (drop duplicates) or append.
set_conf() {
  local f=$1 k=$2 v=$3 sep=${4- = }
  [[ -f $f ]] || { mkdir -p "$(dirname "$f")"; touch "$f"; }
  awk -v k="$k" -v v="$v" -v sep="$sep" '
    { t=$0; sub(/^[[:space:]]+/,"",t) }
    index(t,k)==1 { r=substr(t,length(k)+1)
      if (r=="" || r ~ /^[[:space:]=:]/) { if(!done){print k sep v; done=1}; next } }
    { print }
    END { if(!done) print k sep v }' "$f" >"$f.cptmp" && cat "$f.cptmp" >"$f"
  rm -f "$f.cptmp"
}

# ini_set FILE SECTION KEY VALUE [SEP]  — section-aware (gdm, lightdm, sddm, smb.conf, my.cnf)
ini_set() {
  local f=$1 s=$2 k=$3 v=$4 sep=${5-=}
  [[ -f $f ]] || { mkdir -p "$(dirname "$f")"; touch "$f"; }
  awk -v s="$s" -v k="$k" -v v="$v" -v sep="$sep" '
    function trim(x){ sub(/^[[:space:]]+/,"",x); sub(/[[:space:]]+$/,"",x); return x }
    function iskey(line,  t,r){ t=trim(line); if (index(tolower(t),tolower(k))!=1) return 0
      r=substr(t,length(k)+1); return (r=="" || r ~ /^[[:space:]]*=/) }
    { t=trim($0)
      if (t ~ /^\[.*\]$/) { if (insec && !done) { print k sep v; done=1 }
        insec=(tolower(t)==tolower("[" s "]")); print; next }
      if (insec && iskey($0)) { if (!done) { print k sep v; done=1 }; next }
      print }
    END { if (!done) { if (!insec) print "\n[" s "]"; print k sep v } }' "$f" >"$f.cptmp" && cat "$f.cptmp" >"$f"
  rm -f "$f.cptmp"
}

# sshd_set FILE KEY VALUE [replace_only] — case-insensitive; inserts before first Match block.
sshd_set() {
  local f=$1 k=$2 v=$3 ro=${4:-0}
  awk -v k="$k" -v v="$v" -v ro="$ro" '
    BEGIN{ lk=tolower(k) }
    { L[NR]=$0; t=$0; sub(/^[[:space:]]+/,"",t); split(t,a,/[[:space:]=]+/); w=tolower(a[1])
      if (w=="match" && !fm) fm=NR
      # only touch global-scope keys (before the first Match block); leave Match blocks alone
      if (w==lk && !fm) { L[NR]=k " " v; found=1 } }
    END{ for(i=1;i<=NR;i++){ if(!found && ro=="0" && fm==i) print k " " v; print L[i] }
         if(!found && ro=="0" && !fm) print k " " v }' "$f" >"$f.cptmp" && cat "$f.cptmp" >"$f"
  rm -f "$f.cptmp"
}

insert_before_first() { # FILE REGEX LINE
  awk -v re="$2" -v line="$3" '!done && $0 ~ re { print line; done=1 } { print }' "$1" >"$1.cptmp" && cat "$1.cptmp" >"$1"
  rm -f "$1.cptmp"
}

# comment_line FILE EXACT_LINE TAG — exact full-line match (lines may contain [ ] . * — not regex-safe)
comment_line() {
  awk -v t="$2" -v tag="$3" '$0==t{print "# " $0 "   # " tag; next} {print}' "$1" >"$1.cptmp" && cat "$1.cptmp" >"$1"
  rm -f "$1.cptmp"
}

# snapshot paths -> temp dir; restore_snapshot DIR puts them back (rollback)
snapshot()         { local d p; d=$(mktemp -d /root/cp-snap.XXXXXX); for p in "$@"; do [[ -e $p ]] && cp -a --parents "$p" "$d/"; done; echo "$d"; }
restore_snapshot() { [[ -d $1 ]] && cp -a "$1/." / ; }

#------------------------------ package helpers -------------------------------
is_installed()       { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }
installed_matching() { dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' "$@" 2>/dev/null | awk '$1 ~ /^ii/ {print $2}'; }
apt_busy() {
  if command -v fuser >/dev/null 2>&1; then
    fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1
  else
    pgrep -x 'apt|apt-get|dpkg|aptitude|unattended-upgr|packagekitd' >/dev/null 2>&1
  fi
}
wait_for_apt() {
  local n=0
  while apt_busy; do
    ((n == 0)) && info "Another package manager (automatic updates / GNOME Software) is running — waiting..."
    sleep 5; ((n++))
    ((n >= 180)) && { warn "Package manager still busy after 15 minutes; continuing anyway."; break; }
  done
}
apt_install() {
  wait_for_apt
  apt-get install "${APT_OPTS[@]}" "$@" >>"$LOG" 2>&1
  local rc=$?; ((rc)) && warn "apt-get install $* failed (rc=$rc) — no internet / broken sources? See log."
  return $rc
}

# Packages that must never be removed as a side effect of purging something else (Debian names).
PROTECT_BASE='task-desktop|task-.*-desktop|gnome-core|gnome-shell|gnome-session|gnome-session-bin|gnome-session-common|gnome-settings-daemon|mutter|nautilus|gnome-control-center|gnome-terminal|gdm3|lightdm|lightdm-gtk-greeter|slick-greeter|sddm|cinnamon|cinnamon-core|cinnamon-desktop-environment|mate-core|mate-desktop-environment.*|xfce4|xfce4-session|xfce4-panel|xfdesktop4|kde-plasma-desktop|plasma-desktop|plasma-workspace|lxde|lxde-core|lxqt|lxqt-core|desktop-base|xorg|xserver-xorg|xserver-xorg-core|xwayland|network-manager|network-manager-gnome|dbus|systemd|systemd-sysv|sudo|apt|dpkg|adduser|libpam-runtime|libpam-modules|login|passwd|ufw|firefox-esr|policykit-1|polkitd|pkexec|unattended-upgrades|linux-image-amd64|linux-image-[0-9].*|grub-pc|grub-efi-amd64|grub-efi-amd64-signed|shim-signed|openssh-client|open-vm-tools.*|virtualbox-guest-.*|spice-vdagent|qemu-guest-agent'
PROTECT_PKG_RE="^(${PROTECT_BASE})$"   # extended after the service questions
REMOVED_PKGS=()

safe_purge() {
  local p=$1 sim q bad=() others
  is_installed "$p" || return 0
  if [[ $p =~ $PROTECT_PKG_RE ]]; then info "Keeping $p (needed by a required service / protected)"; return 0; fi
  wait_for_apt
  sim=$(apt-get -s purge "$p" 2>/dev/null | awk '/^(Purg|Remv) /{print $2}' | sed 's/:.*//')
  for q in $sim; do
    [[ $q == "$p" ]] && continue
    [[ $q =~ $PROTECT_PKG_RE ]] && bad+=("$q")
  done
  if ((${#bad[@]})); then
    warn "Did NOT remove '$p': apt would also remove ${bad[*]}. If the README says '$p' is prohibited, run 'sudo apt purge $p' yourself — but NEVER run 'apt autoremove' afterwards."
    return 1
  fi
  if apt-get purge "${APT_OPTS[@]}" "$p" >>"$LOG" 2>&1; then
    log "Removed package: $p"; REMOVED_PKGS+=("$p")
    others=$(printf '%s\n' $sim | grep -vxF -- "$p" | tr '\n' ' ')
    [[ -n $others ]] && { info "(apt also removed: $others)"; review "Note: removing $p also removed: $others"; }
  else
    warn "Failed to remove $p (see log)"
  fi
}

# A purge can turn a desktop metapackage's dependencies into "auto-removable".
# Mark anything apt would autoremove as manual, so a later `apt autoremove` is harmless.
pin_orphans() {
  local o; mapfile -t o < <(apt-get -s autoremove 2>/dev/null | awk '/^Remv /{print $2}')
  ((${#o[@]})) || return 0
  apt-mark manual "${o[@]}" >>"$LOG" 2>&1 \
    && info "Marked ${#o[@]} orphaned package(s) as manual so 'apt autoremove' can't remove them (list in log)"
  printf '   orphan kept: %s\n' "${o[@]}" >>"$LOG"
}

#------------------------------ service helpers -------------------------------
unit_name()   { [[ $1 == *.* ]] && echo "$1" || echo "$1.service"; }
unit_exists() { systemctl list-unit-files --no-legend "$(unit_name "$1")" 2>/dev/null | grep -q .; }
svc_disable() {
  local s u
  for s in "$@"; do
    u=$(unit_name "$s"); unit_exists "$u" || continue
    systemctl disable --now "$u" >>"$LOG" 2>&1 && log "Stopped & disabled $u"
  done
}
svc_restart_ok() { systemctl restart "$1" >>"$LOG" 2>&1; sleep 2; systemctl is-active --quiet "$1"; }

#-------------------------------- PAM helpers ---------------------------------
pam_module_exists() { local d; for d in /usr/lib/*/security /lib/*/security /usr/lib/security /lib/security /usr/lib64/security; do [[ -e $d/$1 ]] && return 0; done; return 1; }
pam_sanity_ok() {
  local f m; local rc=0
  for f in /etc/pam.d/common-auth /etc/pam.d/common-account /etc/pam.d/common-password /etc/pam.d/common-session; do
    [[ -f $f ]] || continue
    for m in $(grep -vE '^[[:space:]]*#' "$f" | grep -oE 'pam_[A-Za-z0-9_]+\.so' | sort -u); do
      pam_module_exists "$m" || { warn "PAM module $m used in $f does not exist!"; rc=1; }
    done
  done
  grep -qE '^[[:space:]]*auth[[:space:]].*pam_unix\.so' /etc/pam.d/common-auth || rc=1
  grep -qE '^[[:space:]]*password[[:space:]].*pam_unix\.so' /etc/pam.d/common-password || rc=1
  return $rc
}

###############################################################################
#  PHASE 1 — QUESTIONS (asked up front so the rest runs mostly unattended)
###############################################################################
# Read /etc/os-release as data — never source it (it's a file an attacker could plant code in)
osr() { sed -n "s/^$1=//p" /etc/os-release 2>/dev/null | head -1 | tr -d "\"'"; }
ID=$(osr ID); ID_LIKE=$(osr ID_LIKE); VERSION_ID=$(osr VERSION_ID); VERSION_CODENAME=$(osr VERSION_CODENAME); PRETTY_NAME=$(osr PRETTY_NAME)
OS_NAME=${PRETTY_NAME:-unknown}
CODENAME=${VERSION_CODENAME:-}
DEB_MAJOR=$(cut -d. -f1 /etc/debian_version 2>/dev/null)
[[ ${ID:-} == debian && ( ${VERSION_ID:-} == 12 || $DEB_MAJOR == 12 ) ]] && CODENAME=bookworm

clear
cat <<EOF
${C}=========================================================================
   CyberPatriot Debian 12 hardening script
=========================================================================${N}
 Detected OS : $OS_NAME  (codename: ${CODENAME:-?})
 Your account: $MAIN_USER
 sudo        : $(command -v sudo >/dev/null && echo installed || echo "NOT installed yet (the script installs it)")
 Logs/report : $OUT
 Backups     : $BACKUP
EOF
if [[ ${ID:-} != debian || $CODENAME != bookworm ]]; then
  echo "${R}This script is written for Debian 12 (bookworm).${N}"
  [[ ${ID:-} == ubuntu || ${ID:-} == linuxmint || ${ID_LIKE:-} == *ubuntu* ]] \
    && echo "${R}This is Ubuntu/Mint — use the Ubuntu/Mint version of the script instead.${N}"
  ask_yn "Continue anyway?" || exit 0
fi
echo
echo "${R}${W}STOP: answer the FORENSICS QUESTIONS before running this.${N}"
echo "${R}This script removes users, software and media files they may ask about.${N}"
ask_yn "Forensics questions answered (or answers saved) and README read?" || { echo "Run it again when you're ready."; exit 0; }

#--------------------------------- users --------------------------------------
section "Authorized users (copy them from the README)"
mapfile -t HUMAN_USERS < <(human_users)
echo "Human accounts currently on this machine (UID $UID_MIN-$UID_MAX):"
printf '   %s\n' "${HUMAN_USERS[@]}"
mapfile -t UID0_USERS < <(awk -F: '$3==0 && $1!="root"{print $1}' /etc/passwd)

while true; do
  line=$(ask "AUTHORIZED ADMINISTRATORS (space/comma separated, include yourself):")
  read -ra AUTH_ADMINS <<<"${line//,/ }"
  line=$(ask "AUTHORIZED STANDARD USERS (space/comma separated, Enter if none):")
  read -ra TMP_STD <<<"${line//,/ }"
  in_list "$MAIN_USER" "${AUTH_ADMINS[@]}" || AUTH_ADMINS+=("$MAIN_USER")

  # drop system accounts typed by mistake; anyone listed as admin is an admin
  CLEAN=(); for u in "${AUTH_ADMINS[@]}"; do
    if id "$u" &>/dev/null && ! is_human "$u" && ! in_list "$u" "${UID0_USERS[@]}"; then
      echo "${Y}   '$u' is a system account — ignoring it.${N}"; continue; fi
    in_list "$u" "${CLEAN[@]}" || CLEAN+=("$u"); done; AUTH_ADMINS=("${CLEAN[@]}")
  AUTH_STD=(); for u in "${TMP_STD[@]}"; do
    if id "$u" &>/dev/null && ! is_human "$u" && ! in_list "$u" "${UID0_USERS[@]}"; then
      echo "${Y}   '$u' is a system account — ignoring it.${N}"; continue; fi
    in_list "$u" "${AUTH_ADMINS[@]}" "${AUTH_STD[@]}" || AUTH_STD+=("$u"); done
  AUTH_ALL=("${AUTH_ADMINS[@]}" "${AUTH_STD[@]}")

  TO_DELETE=(); TO_CREATE=(); TO_DEMOTE=(); TO_PROMOTE=()
  for u in "${HUMAN_USERS[@]}"; do
    [[ $u == "$MAIN_USER" ]] && continue
    in_list "$u" "${AUTH_ALL[@]}" || TO_DELETE+=("$u")
  done
  for u in "${AUTH_ALL[@]}"; do id "$u" &>/dev/null || TO_CREATE+=("$u"); done
  for g in sudo admin wheel; do
    getent group "$g" >/dev/null || continue
    for m in $(group_members "$g"); do
      [[ $m == root ]] && continue
      in_list "$m" "${AUTH_ADMINS[@]}" "${TO_DELETE[@]}" "${TO_DEMOTE[@]}" || TO_DEMOTE+=("$m")
    done
  done
  for u in "${AUTH_ADMINS[@]}"; do
    id "$u" &>/dev/null && ! id -nG "$u" | tr ' ' '\n' | grep -qx sudo && TO_PROMOTE+=("$u")
  done
  for u in "${TO_CREATE[@]}"; do in_list "$u" "${AUTH_ADMINS[@]}" && TO_PROMOTE+=("$u"); done

  echo
  echo "${W}----------------------------- USER PLAN -----------------------------${N}"
  echo " Administrators       : ${AUTH_ADMINS[*]}"
  echo " Standard users       : ${AUTH_STD[*]:-(none)}"
  echo "${R} DELETE (not in README): ${TO_DELETE[*]:-(none)}${N}"
  echo " Remove admin rights  : ${TO_DEMOTE[*]:-(none)}"
  echo " Give admin rights    : ${TO_PROMOTE[*]:-(none)}"
  echo " CREATE (missing)     : ${TO_CREATE[*]:-(none)}"
  ((${#UID0_USERS[@]})) && echo "${R} UID 0 (hidden root!) : ${UID0_USERS[*]}  -> authorized ones get a normal UID, others are deleted${N}"
  for c in "${TO_CREATE[@]}"; do for d in "${TO_DELETE[@]}"; do
    (( $(lev "${c,,}" "${d,,}") <= 2 )) && echo "${R} !! You typed '$c' (doesn't exist) but '$d' exists and would be DELETED. Typo?${N}"
  done; done
  echo "${W}----------------------------------------------------------------------${N}"
  ask_yn "Is this plan EXACTLY right?" && break
  echo "OK, enter the lists again."
done

# Hidden system accounts that have a real shell AND a password (classic hidden backdoor user)
HIDDEN_DELETE=()
mapfile -t HIDDEN_USERS < <(awk -F: -v min="$UID_MIN" 'NR==FNR { if ($2 ~ /^\$/) h[$1]=1; next }
  $3>0 && $3<min && h[$1] && $7 !~ /(nologin|false|sync|shutdown|halt)$/ {print $1}' /etc/shadow /etc/passwd)
for u in "${HIDDEN_USERS[@]}"; do
  in_list "$u" "${AUTH_ALL[@]}" && continue
  ask_yn "System account '$u' (UID $(uid_of "$u")) has a login shell AND a password — likely a hidden user. Delete it?" && HIDDEN_DELETE+=("$u")
done

line=$(ask "Groups the README wants created? Format group:user1,user2 (space between groups), Enter for none:")
read -ra GROUP_SPECS <<<"$line"

#-------------------------------- password ------------------------------------
DEFAULT_PW='Cyb3rP@triot!2026'
while true; do
  read -rsp "${Y}[?]${N} New password for all OTHER authorized users (Enter = ${DEFAULT_PW}): " PW <"$TTY" || PW=""; echo
  if [[ -z $PW ]]; then PW=$DEFAULT_PW; break; fi
  if (( ${#PW} < 12 )) || ! [[ $PW =~ [A-Z] && $PW =~ [a-z] && $PW =~ [0-9] && $PW =~ [^A-Za-z0-9] ]]; then
    echo "    Needs 12+ characters with upper, lower, digit and symbol."; continue; fi
  read -rsp "    Confirm: " PW2 <"$TTY" || PW2=""; echo
  [[ $PW == "$PW2" ]] && break
  echo "    Passwords didn't match."
done
CHANGE_MAIN_PW=false
ask_yn "Also change YOUR password ($MAIN_USER)? Only if the README calls it weak — you MUST remember it." && CHANGE_MAIN_PW=true

#-------------------------------- services ------------------------------------
section "Critical services (answer from the README)"
svc_q() { # VAR "question" pkg...
  local var=$1 q=$2 tag="(not installed)" p; shift 2
  for p in "$@"; do is_installed "$p" && { tag="${G}(installed)${N}"; break; }; done
  if ask_yn "$q $tag"; then printf -v "$var" true; else printf -v "$var" false; fi
}
SAMBA_GUEST=false; DB_REMOTE=false
svc_q NEED_SSH    "SSH server (OpenSSH) required?" openssh-server
svc_q NEED_FTP    "FTP server (vsftpd / pure-ftpd / proftpd) required?" vsftpd pure-ftpd proftpd-basic proftpd-core
svc_q NEED_SAMBA  "Samba (Windows file sharing) required?" samba
$NEED_SAMBA && svc_q SAMBA_GUEST "   ...must a share allow GUEST/anonymous access? (usually NO)"
svc_q NEED_WEB    "Web server (Apache / Nginx) required?" apache2 nginx nginx-core lighttpd
svc_q NEED_MYSQL  "MariaDB / MySQL required?" mariadb-server default-mysql-server mysql-server
svc_q NEED_PGSQL  "PostgreSQL required?" postgresql
if $NEED_MYSQL || $NEED_PGSQL; then svc_q DB_REMOTE "   ...must OTHER computers connect to the database? (usually NO)"; fi
svc_q NEED_DNS    "DNS server (BIND9) required?" bind9
svc_q NEED_MAIL   "Mail server (Exim / Postfix / Dovecot) required? Debian installs Exim by default." exim4-daemon-light exim4-daemon-heavy postfix dovecot-core
svc_q NEED_PRINT  "Printing (CUPS) required?" cups
svc_q NEED_NFS    "NFS file sharing required?" nfs-kernel-server
svc_q NEED_TELNET "Telnet server required? (almost never)" telnetd inetutils-telnetd
svc_q NEED_VNC    "Remote desktop (VNC / xrdp) required?" x11vnc xrdp tigervnc-standalone-server tightvncserver
DISABLE_IPV6=false
ask_yn "Does the README say to DISABLE IPv6? (normally NO)" && DISABLE_IPV6=true

# Other servers Debian images sometimes ship — only asked about if installed.
echo
echo "${W}Other servers / apps found on this machine:${N}"
EXTRA_SERVERS=(
  "squid|squid|Squid web proxy" "squid-openssl|squid|Squid web proxy" "tinyproxy|tinyproxy|Tinyproxy web proxy"
  "privoxy|privoxy|Privoxy web proxy" "dnsmasq|dnsmasq|dnsmasq DNS/DHCP server" "isc-dhcp-server|isc-dhcp-server|ISC DHCP server"
  "minidlna|minidlna|MiniDLNA media server" "icecast2|icecast2|Icecast streaming server" "mosquitto|mosquitto|Mosquitto MQTT broker"
  "redis-server|redis-server|Redis database server" "memcached|memcached|Memcached server" "mongodb-server|mongodb|MongoDB server"
  "inspircd|inspircd|InspIRCd IRC server" "ngircd|ngircd|ngIRCd IRC server" "ircd-hybrid|ircd-hybrid|Hybrid IRC server"
  "tomcat9|tomcat9|Tomcat 9 Java web server" "tomcat10|tomcat10|Tomcat 10 Java web server"
  "docker.io|docker|Docker container engine" "webmin|webmin|Webmin web admin panel" "usermin|usermin|Usermin web panel"
  "snmpd|snmpd|SNMP agent" "openvpn|openvpn|OpenVPN (service only)" "rsync|rsync|rsync daemon (service only)"
)
SERVER_KEEP=(); SERVER_REMOVE=(); FOUND_EXTRA=0
for e in "${EXTRA_SERVERS[@]}"; do
  IFS='|' read -r pkg unit desc <<<"$e"
  is_installed "$pkg" || continue
  # openvpn / rsync are normal desktop packages — only a running/enabled *service* matters
  if [[ $desc == *"(service only)"* ]] && ! systemctl is-enabled --quiet "$unit" 2>/dev/null \
     && ! systemctl is-active --quiet "$unit" 2>/dev/null; then continue; fi
  FOUND_EXTRA=1
  if ask_yn "$desc ($pkg) is installed. Is it REQUIRED by the README?"; then SERVER_KEEP+=("$e"); else SERVER_REMOVE+=("$e"); fi
done
# Apps installed outside apt ("check the Software Manager app")
FLATPAK_REMOVE=(); SNAP_REMOVE=()
if command -v flatpak >/dev/null 2>&1; then
  while IFS=$'\t' read -r app name; do
    [[ -z $app ]] && continue; FOUND_EXTRA=1
    ask_yn "Flatpak app '${name:-$app}' ($app) is installed. Remove it? (yes unless the README requires it)" && FLATPAK_REMOVE+=("$app")
  done < <(flatpak list --system --app --columns=application,name 2>/dev/null)
fi
if command -v snap >/dev/null 2>&1; then
  while read -r sname _; do
    case $sname in ''|Name|core|core[0-9]*|snapd|bare|gtk-common-themes|gnome-[0-9]*|firefox|chromium) continue ;; esac
    FOUND_EXTRA=1
    ask_yn "Snap '$sname' is installed. Remove it? (yes unless the README requires it)" && SNAP_REMOVE+=("$sname")
  done < <(snap list 2>/dev/null)
fi
((FOUND_EXTRA)) || echo "   (none)"

echo
echo "Install updates at the END of the script?"
echo "   f = FULL upgrade (best for points; 10-40 minutes)"
echo "   c = critical packages only (bash, sudo, openssl, ssh, kernel, firefox-esr, ...)"
echo "   s = skip"
while true; do
  read -rp "${Y}[?]${N} Choice [f/c/s]: " UPDATE_MODE <"$TTY" || UPDATE_MODE=s; UPDATE_MODE=${UPDATE_MODE,,}
  [[ $UPDATE_MODE =~ ^[fcs]$ ]] && break
done

# Protect packages belonging to required services from being purged as collateral
EXTRA=""
$NEED_SSH    && EXTRA+="|openssh-server|openssh-sftp-server|ssh"
$NEED_FTP    && EXTRA+="|vsftpd|pure-ftpd.*|proftpd.*"
$NEED_SAMBA  && EXTRA+="|samba|samba-common|samba-common-bin|samba-.*"
$NEED_WEB    && EXTRA+="|apache2.*|libapache2-.*|php.*|nginx.*|lighttpd"
$NEED_MYSQL  && EXTRA+="|mysql-.*|mariadb-.*|default-mysql-.*"
$NEED_PGSQL  && EXTRA+="|postgresql.*"
$NEED_DNS    && EXTRA+="|bind9.*"
$NEED_MAIL   && EXTRA+="|postfix.*|dovecot.*|exim4.*|sendmail.*|bsd-mailx"
$NEED_PRINT  && EXTRA+="|cups.*"
$NEED_NFS    && EXTRA+="|nfs-kernel-server|nfs-common|rpcbind"
$NEED_TELNET && EXTRA+="|telnetd|inetutils-telnetd|telnetd-ssl|telnet|inetutils-telnet|openbsd-inetd|xinetd"
$NEED_VNC    && EXTRA+="|x11vnc|tigervnc.*|tightvncserver|vnc4server|xrdp"
for e in "${SERVER_KEEP[@]}"; do EXTRA+="|${e%%|*}"; done
PROTECT_PKG_RE="^(${PROTECT_BASE}${EXTRA})$"

# README-critical services that must end up enabled AND running ("name|units to try")
CRIT_GROUPS=()
$NEED_SSH   && CRIT_GROUPS+=("SSH|ssh ssh.socket")
$NEED_FTP   && CRIT_GROUPS+=("FTP|vsftpd pure-ftpd proftpd")
$NEED_SAMBA && CRIT_GROUPS+=("Samba|smbd")
$NEED_WEB   && CRIT_GROUPS+=("Web server|apache2 nginx lighttpd")
$NEED_MYSQL && CRIT_GROUPS+=("MariaDB/MySQL|mariadb mysql")
$NEED_PGSQL && CRIT_GROUPS+=("PostgreSQL|postgresql")
$NEED_DNS   && CRIT_GROUPS+=("DNS (BIND)|named bind9")
$NEED_MAIL  && CRIT_GROUPS+=("Mail|postfix exim4")
$NEED_PRINT && CRIT_GROUPS+=("Printing (CUPS)|cups")
$NEED_NFS   && CRIT_GROUPS+=("NFS|nfs-server nfs-kernel-server")
for e in "${SERVER_KEEP[@]}"; do IFS='|' read -r pkg unit desc <<<"$e"; CRIT_GROUPS+=("$desc|$unit"); done

echo
echo "${W}Summary:${N} SSH=$NEED_SSH FTP=$NEED_FTP Samba=$NEED_SAMBA Web=$NEED_WEB MySQL=$NEED_MYSQL PostgreSQL=$NEED_PGSQL"
echo "         DNS=$NEED_DNS Mail=$NEED_MAIL Print=$NEED_PRINT NFS=$NEED_NFS Telnet=$NEED_TELNET VNC=$NEED_VNC IPv6-off=$DISABLE_IPV6 Updates=$UPDATE_MODE"
RMLIST="$(for e in "${SERVER_REMOVE[@]}"; do printf '%s ' "${e%%|*}"; done)${FLATPAK_REMOVE[*]} ${SNAP_REMOVE[*]}"
[[ -n ${RMLIST// /} ]] && echo "         Also removing: $RMLIST"
ask_yn "Start hardening now?" || exit 0
review "Answers: SSH=$NEED_SSH FTP=$NEED_FTP Samba=$NEED_SAMBA Web=$NEED_WEB MySQL=$NEED_MYSQL PgSQL=$NEED_PGSQL DNS=$NEED_DNS Mail=$NEED_MAIL Print=$NEED_PRINT NFS=$NEED_NFS"
review ""

###############################################################################
#  PHASE 2 — HARDENING
###############################################################################
section "Backups"
tar -czpf "$BACKUP/etc.tar.gz" /etc 2>>"$LOG" && log "Full backup of /etc -> $BACKUP/etc.tar.gz"
cp -a /etc/pam.d "$BACKUP/pam.d.orig"
[[ -f /etc/sudoers ]] && cp -a /etc/sudoers "$BACKUP/sudoers.orig"
[[ -d /etc/sudoers.d ]] && cp -a /etc/sudoers.d "$BACKUP/sudoers.d.orig"
[[ -d /var/spool/cron ]] && cp -a /var/spool/cron "$BACKUP/spool-cron"
info "Restore a file later with:  sudo tar -xzpf $BACKUP/etc.tar.gz -C / etc/path/to/file"

section "Clearing immutable flags (a trick used to block fixes)"
if command -v lsattr >/dev/null; then
  for f in /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers /etc/sudoers.d/* /etc/hosts \
           /etc/login.defs /etc/ssh/sshd_config /etc/sysctl.conf /etc/crontab /etc/rc.local /etc/pam.d/* \
           /etc/apt/sources.list /etc/apt/sources.list.d/* /etc/apt/apt.conf.d/* \
           /etc/lightdm/lightdm.conf /etc/gdm3/daemon.conf /etc/gdm3/custom.conf /etc/security/*.conf; do
    [[ -f $f && ! -L $f ]] || continue
    a=$(lsattr -d "$f" 2>/dev/null | awk '{print $1}')
    [[ $a == *i* || $a == *a* ]] && chattr -i -a "$f" 2>>"$LOG" && warn "Removed immutable/append-only flag from $f"
  done
fi

#--------------------------------- APT ----------------------------------------
section "APT sources & package manager"
wait_for_apt; run dpkg --configure -a

# Official Debian package hosts (deb.debian.org, security.debian.org, ftp.XX.debian.org, ...)
OFFHOST='(([a-z0-9-]+\.)*debian\.org)'
OFFICIAL="https?://${OFFHOST}(/.*)?"
DEB_MIRROR=http://deb.debian.org/debian
DEB_SECMIRROR=http://security.debian.org/debian-security
DEB_COMPS="main contrib non-free non-free-firmware"
# host of the first URI on a one-line "deb ..." entry (skips [opt=..] blocks)
line_host()  { awk '{for(i=1;i<=NF;i++) if($i ~ /:\/\//){u=$i; sub(/^[a-z]+:\/\//,"",u); sub(/\/.*/,"",u); sub(/:.*/,"",u); print tolower(u); exit}}' <<<"$1"; }
# suite (release) of a one-line entry
line_suite() { awk '{i=2; if ($i ~ /^\[/) { while (i<NF && $i !~ /\]$/) i++; i++ } print $(i+1)}' <<<"$1"; }
is_off_host() { [[ $1 =~ ^${OFFHOST}$ ]]; }
ok_suite()    { [[ -n $CODENAME && $1 =~ ^${CODENAME}(-updates|-security|-backports)?$ ]]; }
# Prints why an entry is a problem (empty = fine)
entry_problem() {
  local h s; h=$(line_host "$1"); [[ -z $h ]] && return 0
  if ! is_off_host "$h"; then echo "third-party host $h"; return 0; fi
  [[ -z $CODENAME ]] && return 0
  s=$(line_suite "$1")
  ok_suite "$s" || echo "Debian release '$s' is not $CODENAME (mixing releases breaks the system)"
}
# Rewrite stable/oldstable suites on official lines to the codename (prints the new file)
pin_release_aliases() {
  awk -v cn="$CODENAME" '
    function host(u){ sub(/^[a-z]+:\/\//,"",u); sub(/\/.*/,"",u); sub(/:.*/,"",u); return tolower(u) }
    { t=$0; sub(/^[[:space:]]+/,"",t)
      if (t ~ /^deb(-src)?[[:space:]]/) {
        n=split(t,a,/[[:space:]]+/); i=2
        if (a[i] ~ /^\[/) { while (i<n && a[i] !~ /\]$/) i++; i++ }
        u=a[i]; s=a[i+1]
        if (host(u) ~ /(^|\.)debian\.org$/ && s ~ /^(old)?stable(-[a-z-]+)?$/) {
          ns=s; sub(/^(old)?stable/, cn, ns)
          p=index($0, u) + length(u); rest=substr($0, p); q=index(rest, s)
          $0=substr($0, 1, p-1) substr(rest, 1, q-1) ns substr(rest, q+length(s))
        }
      }
      print }' "$1"
}

fix_apt_sources() {
  local A=${APTDIR:-/etc/apt}
  local SL="$A/sources.list" SLD="$A/sources.list.d" DS f ln why
  DS="$SLD/debian.sources"
  mkdir -p "$SLD"

  # 1) Insecure apt.conf options (accept unsigned/weak packages) -> disable
  for f in "$A/apt.conf" "$A"/apt.conf.d/*; do
    [[ -f $f ]] || continue
    if grep -qiE '^[^/#]*(AllowUnauthenticated|AllowInsecureRepositories|AllowDowngradeToInsecureRepositories|AllowWeakRepositories)[^;]*(true|yes|"1")' "$f"; then
      backup_file "$f"
      sed -i -E 's@^([^/#]*(AllowUnauthenticated|AllowInsecureRepositories|AllowDowngradeToInsecureRepositories|AllowWeakRepositories).*)$@// \1  // disabled by CP script@I' "$f"
      warn "Disabled insecure APT option (unsigned packages allowed) in $f"
    fi
  done

  # 2) 'trusted=yes' / allow-insecure in source entries -> skips signature checks
  for f in "$SL" "$SLD"/*.list "$SLD"/*.sources; do
    [[ -f $f ]] || continue
    if grep -qiE 'trusted=yes|^[[:space:]]*Trusted:[[:space:]]*yes|allow-insecure=yes|allow-weak=yes' "$f"; then
      backup_file "$f"
      sed -i -E 's/trusted=yes/trusted=no/Ig; s/^([[:space:]]*Trusted:[[:space:]]*)yes/\1no/I; s/allow-insecure=yes/allow-insecure=no/Ig; s/allow-weak=yes/allow-weak=no/Ig' "$f"
      warn "Removed signature-check bypass (trusted=yes) from $f"
    fi
  done

  # 3) 'cdrom:' sources (left by DVD installs) make 'apt update' fail -> comment out
  for f in "$SL" "$SLD"/*.list; do
    [[ -f $f ]] || continue
    if grep -qE '^[[:space:]]*deb([[:space:]]|-src[[:space:]]).*cdrom:' "$f"; then
      backup_file "$f"
      sed -i -E 's@^([[:space:]]*deb([[:space:]]|-src[[:space:]]).*cdrom:.*)@# \1   # cdrom disabled by CP script@' "$f"
      warn "Commented out a 'cdrom:' APT source in $f (it blocks apt update)"
    fi
  done

  if [[ -z $CODENAME ]]; then
    warn "Could not detect the Debian codename — NOT touching sources.list. Verify it by hand."
    return
  fi

  # 4) 'stable'/'oldstable' -> 'bookworm'. Debian 13 is now 'stable', so leaving the alias
  #    makes apt try a whole-release upgrade.
  for f in "$SL" "$SLD"/*.list; do
    [[ -f $f ]] || continue
    pin_release_aliases "$f" >"$f.cptmp"
    if ! cmp -s "$f" "$f.cptmp"; then
      backup_file "$f"; cat "$f.cptmp" >"$f"
      warn "Changed 'stable'/'oldstable' to '$CODENAME' in $f (otherwise apt would jump to Debian 13)"
    fi
    rm -f "$f.cptmp"
  done

  # 5) Make sure the OFFICIAL repos (main + -updates + -security) are present & enabled
  if [[ -f $DS ]]; then
    # deb822 format (/etc/apt/sources.list.d/debian.sources)
    local dsbad=0 s u h
    for s in $(grep -iE '^[[:space:]]*Suites:' "$DS" | sed -E 's/^[^:]*:[[:space:]]*//'); do ok_suite "$s" || dsbad=1; done
    for u in $(grep -iE '^[[:space:]]*URIs:' "$DS" | sed -E 's/^[^:]*:[[:space:]]*//'); do
      h=$(line_host "deb $u x y"); [[ -n $h ]] && ! is_off_host "$h" && dsbad=1; done
    if ((dsbad)) || ! grep -qiE "^[[:space:]]*Suites:.*[[:space:]]${CODENAME}-security([[:space:]]|$)" "$DS" \
       || ! grep -qiE "^[[:space:]]*Suites:.*[[:space:]]${CODENAME}-updates([[:space:]]|$)" "$DS" \
       || grep -qiE '^[[:space:]]*Enabled:[[:space:]]*no' "$DS"; then
      backup_file "$DS"
      cat >"$DS" <<EOF
Types: deb
URIs: ${DEB_MIRROR}
Suites: ${CODENAME} ${CODENAME}-updates
Components: ${DEB_COMPS}
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: ${DEB_SECMIRROR}
Suites: ${CODENAME}-security
Components: ${DEB_COMPS}
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
      log "Restored official Debian sources (incl. -updates and -security) in $DS"
    else info "Official deb822 sources already present in $DS"; fi
  else
    # classic one-line format (/etc/apt/sources.list) — Debian 12's default
    has_pocket() { # $1 = "" | -updates | -security
      grep -hsE "^[[:space:]]*deb[[:space:]]+(\[[^]]*\][[:space:]]+)?${OFFICIAL}[[:space:]]+${CODENAME}$1[[:space:]]" \
        "$SL" "$SLD"/*.list 2>/dev/null | grep -q .
    }
    touch "$SL"; backup_file "$SL"
    # Re-enable commented-out official lines (main / -updates / -security only)
    sed -i -E "s@^#[[:space:]]*(deb[[:space:]]+(\[[^]]*\][[:space:]]+)?${OFFICIAL}[[:space:]]+${CODENAME}(-updates|-security)?[[:space:]])@\1@" "$SL"
    has_pocket ""          || echo "deb ${DEB_MIRROR} ${CODENAME} ${DEB_COMPS}" >>"$SL"
    has_pocket "-updates"  || echo "deb ${DEB_MIRROR} ${CODENAME}-updates ${DEB_COMPS}" >>"$SL"
    has_pocket "-security" || echo "deb ${DEB_SECMIRROR} ${CODENAME}-security ${DEB_COMPS}" >>"$SL"
    log "Official ${CODENAME}, ${CODENAME}-updates and ${CODENAME}-security repositories enabled ($SL)"
  fi

  # 6) Flag (and optionally disable) THIRD-PARTY repos and other-release Debian repos
  local reported=0
  #    one-line .list files (PPAs / vendor repos are usually one file each)
  for f in "$SLD"/*.list; do
    [[ -f $f ]] || continue
    local probs=()
    while IFS= read -r ln; do
      why=$(entry_problem "$ln"); [[ -n $why ]] && probs+=("$why")
    done < <(grep -E '^[[:space:]]*deb([[:space:]]|-src[[:space:]])' "$f" | grep -vE 'cdrom:')
    if ((${#probs[@]})); then
      reported=1
      warn "Unofficial APT entry in $f -> ${probs[*]}"
      review "[!] APT repo file: $f  (${probs[*]})"
      if ask_yn "   Disable $f ? (do this unless the README requires this repo)"; then
        backup_file "$f"; mv "$f" "$f.disabled-by-cp"
        log "Disabled repo file $f (renamed .disabled-by-cp)"
      else review "    (kept $f — confirm it is required)"; fi
    fi
  done
  #    deb822 .sources files (debian.sources was validated above)
  for f in "$SLD"/*.sources; do
    [[ -f $f && $f != "$DS" ]] || continue
    grep -qiE '^[[:space:]]*Enabled:[[:space:]]*no' "$f" && continue
    local uris suites badw="" u h s
    uris=$(grep -iE '^[[:space:]]*URIs:' "$f" | sed -E 's/^[^:]*:[[:space:]]*//')
    suites=$(grep -iE '^[[:space:]]*Suites:' "$f" | sed -E 's/^[^:]*:[[:space:]]*//')
    for u in $uris; do h=$(line_host "deb $u x y"); [[ -z $h ]] && continue; is_off_host "$h" || badw+="third-party host $h; "; done
    if [[ -z $badw ]]; then for s in $suites; do ok_suite "$s" || badw+="Debian release '$s'; "; done; fi
    if [[ -n $badw ]]; then
      reported=1
      warn "Unofficial deb822 repo in $f -> $badw"
      review "[!] deb822 repo: $f  ($badw URIs: $uris)"
      if ask_yn "   Disable $f ?"; then backup_file "$f"; mv "$f" "$f.disabled-by-cp"; log "Disabled $f"; fi
    fi
  done
  #    lines inside the MAIN sources.list (comment just the offending line)
  if [[ -f $SL ]]; then
    while IFS= read -r ln; do
      why=$(entry_problem "$ln"); [[ -z $why ]] && continue
      reported=1
      warn "Problem APT line in $SL -> $why"
      review "[!] APT line in $SL ($why): $ln"
      if ask_yn "   Comment out this line in $SL ? ($why)"; then
        backup_file "$SL"; comment_line "$SL" "$ln" "disabled by CP script"
        log "Commented out APT line in $SL"
      fi
    done < <(grep -E '^[[:space:]]*deb([[:space:]]|-src[[:space:]])' "$SL" | grep -vE 'cdrom:')
  fi
  ((reported==0)) && info "No third-party / other-release APT repositories found."
}
fix_apt_sources

{ echo "--- ACTIVE APT repositories after cleanup (should be Debian $CODENAME only, unless README requires more) ---"
  grep -hsvE '^[[:space:]]*(#|$)' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null | sed 's/^/   /'
  grep -hsE '^[[:space:]]*(URIs|Suites|Enabled):' /etc/apt/sources.list.d/*.sources 2>/dev/null | sed 's/^/   /'
  echo "--- APT signing keys (an unknown key = an attacker-trusted repo) ---"
  ls -1 /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/ /etc/apt/keyrings/ 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"
wait_for_apt
if apt-get update -q >>"$LOG" 2>&1; then
  log "apt-get update OK"; APT_OK=true
else
  APT_OK=false
  warn "apt-get update reported errors — a repo may be unreachable/misconfigured. Offending lines:"
  apt-get update 2>&1 | grep -iE '^(E:|W:|Err:)' | sed 's/^/     /' | tee -a "$LOG" >>"$REPORT"
fi

# Debian installs without sudo when a root password is set at install time.
if ! command -v sudo >/dev/null 2>&1; then
  apt_install sudo && log "Installed sudo (it was missing)"
fi

#--------------------------------- USERS --------------------------------------
section "Users & groups"
REAL_PW_CHANGED=()
for u in "${TO_CREATE[@]}"; do
  if useradd -m -s /bin/bash "$u" >>"$LOG" 2>&1; then log "Created user $u (listed in README)"; else warn "Could not create user $u"; fi
done
# Every authorized user needs a home folder (later, DEFAULT_HOME=no refuses logins without one)
for u in "${AUTH_ALL[@]}"; do
  id "$u" &>/dev/null && is_human "$u" || continue
  h=$(getent passwd "$u" | cut -d: -f6)
  [[ -n $h && $h != / && ! -d $h ]] || continue
  if command -v mkhomedir_helper >/dev/null; then mkhomedir_helper "$u" 0027 >>"$LOG" 2>&1
  else mkdir -p "$h" && cp -rT /etc/skel "$h" && chown -R "$u": "$h" && chmod 750 "$h"; fi
  [[ -d $h ]] && log "Created missing home folder $h for $u"
done

for u in "${TO_DELETE[@]}" "${HIDDEN_DELETE[@]}"; do
  [[ $u == "$MAIN_USER" || $u == root || -z $u ]] && continue
  uid=$(uid_of "$u") || continue
  (( uid >= UID_MIN )) && pkill -KILL -u "$u" 2>/dev/null
  crontab -r -u "$u" 2>/dev/null
  if userdel -f "$u" >>"$LOG" 2>&1; then log "Deleted unauthorized user: $u (home folder kept for forensics)"
  else warn "Failed to delete user $u"; fi
done

# Users with UID 0 besides root are root backdoors
for u in "${UID0_USERS[@]}"; do
  if in_list "$u" "${AUTH_ALL[@]}"; then
    newuid=$(awk -F: -v min="$UID_MIN" -v max="$UID_MAX" 'BEGIN{m=min-1} $3>m && $3<=max {m=$3} END{print m+1}' /etc/passwd)
    cp -a /etc/passwd "$BACKUP/passwd.before-uid0-fix"
    awk -F: -v OFS=: -v u="$u" -v n="$newuid" '$1==u{$3=n} {print}' /etc/passwd >/etc/passwd.cptmp \
      && cat /etc/passwd.cptmp >/etc/passwd; rm -f /etc/passwd.cptmp
    h=$(getent passwd "$u" | cut -d: -f6)
    [[ $h == /home/* && -d $h ]] && chown -R "$newuid" "$h"
    log "User $u had UID 0 (root-equivalent) — changed to UID $newuid"
  else
    # NOTE: never pkill a UID-0 name (it would kill every root process)
    if userdel -f "$u" >>"$LOG" 2>&1; then log "Deleted UID-0 backdoor user $u"; else warn "Could not delete UID-0 user $u — remove its line from /etc/passwd manually"; fi
  fi
done

# Primary group tricks (primary GID = sudo/admin/root gives silent admin rights)
mapfile -t HUMAN_USERS < <(human_users)
PRIV_GIDS=" 0 $(getent group sudo | cut -d: -f3) $(getent group admin | cut -d: -f3) $(getent group wheel | cut -d: -f3) "
for u in "${HUMAN_USERS[@]}"; do
  g=$(id -g "$u")
  if [[ $PRIV_GIDS == *" $g "* ]]; then
    getent group "$u" >/dev/null || groupadd "$u"
    usermod -g "$u" "$u" && log "Changed primary group of $u from privileged GID $g to its own group"
  fi
done

# Admin groups: only authorized admins
for g in sudo admin wheel; do
  getent group "$g" >/dev/null || continue
  for m in $(group_members "$g"); do
    [[ $m == root ]] && continue
    in_list "$m" "${AUTH_ADMINS[@]}" || { gpasswd -d "$m" "$g" >>"$LOG" 2>&1 && log "Removed $m from admin group '$g'"; }
  done
done
# Other privileged groups
STD_REMOVE=(adm lpadmin root shadow disk kmem lxd docker)
ALL_REMOVE=(root shadow disk kmem)
for u in "${HUMAN_USERS[@]}"; do
  if in_list "$u" "${AUTH_ADMINS[@]}"; then grs=("${ALL_REMOVE[@]}"); else grs=("${STD_REMOVE[@]}"); fi
  for g in "${grs[@]}"; do
    user_in_group "$u" "$g" && gpasswd -d "$u" "$g" >>"$LOG" 2>&1 && log "Removed $u from privileged group '$g'"
  done
done
for u in "${AUTH_ADMINS[@]}"; do
  id "$u" &>/dev/null || continue
  id -nG "$u" | tr ' ' '\n' | grep -qx sudo || { usermod -aG sudo "$u" && log "Made $u an administrator (sudo group)"; }
done

for spec in "${GROUP_SPECS[@]}"; do
  g=${spec%%:*}; members=""; [[ $spec == *:* ]] && members=${spec#*:}
  [[ -z $g ]] && continue
  getent group "$g" >/dev/null || { groupadd "$g" && log "Created group $g"; }
  IFS=',' read -ra mm <<<"$members"; valid=()
  for m in "${mm[@]}"; do
    [[ -z $m ]] && continue
    if id "$m" &>/dev/null; then valid+=("$m"); else warn "Group $g: user '$m' doesn't exist — skipped"; fi
  done
  ((${#valid[@]})) || continue
  gid=$(getent group "$g" | cut -d: -f3); [[ $gid =~ ^[0-9]+$ ]] || continue
  if (( gid >= UID_MIN )); then
    # like 'gpasswd -M': the group ends up with EXACTLY the members the README lists
    gpasswd -M "$(IFS=,; echo "${valid[*]}")" "$g" >>"$LOG" 2>&1 && log "Group $g members set to exactly: ${valid[*]}"
  else
    for m in "${valid[@]}"; do usermod -aG "$g" "$m" && log "Added $m to group $g"; done
  fi
done

# Passwords + aging (chpasswd runs BEFORE the new PAM policy so it can't be rejected)
for u in "${AUTH_ALL[@]}"; do
  id "$u" &>/dev/null && is_human "$u" || continue
  [[ $u == "$MAIN_USER" && $CHANGE_MAIN_PW != true ]] && continue
  if echo "$u:$PW" | chpasswd >>"$LOG" 2>&1; then
    chage -M 90 -m 7 -W 7 "$u" >>"$LOG" 2>&1
    REAL_PW_CHANGED+=("$u")
  else warn "Could not set password for $u"; fi
done
((${#REAL_PW_CHANGED[@]})) && log "Secure password + aging (max 90/min 7/warn 7) set for: ${REAL_PW_CHANGED[*]}"

# Empty password fields
while IFS=: read -r name hash _; do
  [[ -n $hash || -z $name ]] && continue
  if is_human "$name" && [[ $name != "$MAIN_USER" ]]; then
    echo "$name:$PW" | chpasswd && log "User $name had NO password — set one"
  elif [[ $name != "$MAIN_USER" ]]; then
    passwd -l "$name" >>"$LOG" 2>&1 && log "System account $name had no password — locked"
  fi
done < <(cat /etc/shadow)
[[ -z $(getent shadow "$MAIN_USER" | cut -d: -f2) ]] && warn "YOUR account has an empty password. Set one with: passwd"

# Password aging for EVERY human account (min 7 / max 90 / warn 7). A password older than
# ~80 days gets its "last changed" date reset to today, so the new 90-day limit can't
# expire it mid-round (and, with the 30-day inactivity lock, lock the account).
today=$(( $(date +%s) / 86400 ))
for u in $(human_users); do
  last=$(getent shadow "$u" | cut -d: -f3)
  if [[ -z $last ]] || { [[ $last != 0 ]] && (( today - last > 80 )); }; then chage -d "$(date +%F)" "$u" >>"$LOG" 2>&1; fi
  chage -m 7 -M 90 -W 7 "$u" >>"$LOG" 2>&1
done
log "Password aging (min 7 / max 90 / warn 7 days) applied to every human account"

{ echo "--- Accounts after changes ---"
  awk -F: -v min="$UID_MIN" '$3>=min || $3==0 {print "  " $1 "  uid=" $3 "  shell=" $7}' /etc/passwd
  echo "  sudo group: $(group_members sudo)"
  echo "  Duplicate UIDs: $(awk -F: '{c[$3]++; n[$3]=n[$3] " " $1} END{for(u in c) if(c[u]>1) printf "%s(%s) ", u, n[u]}' /etc/passwd)"
  echo "  Non-default groups (GID>=1000 with no matching user):"
  awk -F: -v min="$UID_MIN" 'NR==FNR{u[$1]=1; next} $3>=min && $3<65534 && !u[$1] {print "     " $0}' /etc/passwd /etc/group
  echo; } >>"$REPORT"

#---------------------------- PASSWORD POLICY ---------------------------------
section "Password & lockout policy (login.defs + PAM)"
backup_file /etc/login.defs
for kv in "PASS_MAX_DAYS 90" "PASS_MIN_DAYS 7" "PASS_WARN_AGE 7" "LOGIN_RETRIES 3" "LOGIN_TIMEOUT 60"; do
  set_conf /etc/login.defs "${kv%% *}" "${kv#* }" $'\t'
done
grep -qE '^[[:space:]]*#?[[:space:]]*PASS_MIN_LEN[[:space:]]+[0-9]' /etc/login.defs \
  && sed -i -E 's/^[[:space:]]*#?[[:space:]]*PASS_MIN_LEN[[:space:]]+[0-9]+.*/PASS_MIN_LEN\t12/' /etc/login.defs
em=$(awk '/^[[:space:]]*ENCRYPT_METHOD/{print $2}' /etc/login.defs)
[[ -z $em || $em =~ ^(DES|MD5)$ ]] && set_conf /etc/login.defs ENCRYPT_METHOD SHA512 $'\t'
log "login.defs: max age 90, min age 7, warn 7 days, 3 login retries"

# Record suspicious PAM lines BEFORE regenerating (forensics + backdoor evidence)
{ echo "--- Suspicious PAM lines found (pam_permit 'sufficient' / pam_exec are classic backdoors) ---"
  grep -nHE '^[^#]*(sufficient[[:space:]]+pam_permit\.so|pam_exec\.so)' /etc/pam.d/* 2>/dev/null; echo; } >>"$REPORT"

is_installed libpam-pwquality || apt_install libpam-pwquality cracklib-runtime
HAVE_PWQ=false;      pam_module_exists pam_pwquality.so && HAVE_PWQ=true
HAVE_FAILLOCK=false; pam_module_exists pam_faillock.so  && HAVE_FAILLOCK=true
HAVE_PWHIST=false;   pam_module_exists pam_pwhistory.so && HAVE_PWHIST=true

# A planted profile in /usr/share/pam-configs would be put right back by pam-auth-update below
for f in /usr/share/pam-configs/*; do
  [[ -f $f ]] || continue
  case $(basename "$f") in faillock|faillock_notify) continue ;; esac
  pkg_owned "$f" && continue
  warn "PAM profile not installed by any package: $f"
  sed 's/^/        /' "$f" | head -12
  if ask_yn "   Quarantine it so pam-auth-update won't add it to the login stack? (yes unless you know what it is)"; then
    quarantine "$f" && log "Quarantined PAM profile $f"
  fi
done

if $HAVE_FAILLOCK; then
  cat >/usr/share/pam-configs/faillock <<'EOF'
Name: Lock accounts after repeated failed logins (pam_faillock)
Default: yes
Priority: 0
Auth-Type: Primary
Auth:
        [default=die]   pam_faillock.so authfail deny=3 unlock_time=600 fail_interval=900
EOF
  cat >/usr/share/pam-configs/faillock_notify <<'EOF'
Name: pam_faillock pre-check and reset counter on success
Default: yes
Priority: 1024
Auth-Type: Primary
Auth:
        requisite       pam_faillock.so preauth deny=3 unlock_time=600 fail_interval=900
Account-Type: Primary
Account:
        required        pam_faillock.so
EOF
  backup_file /etc/security/faillock.conf
  set_conf /etc/security/faillock.conf deny 3
  set_conf /etc/security/faillock.conf unlock_time 600
  set_conf /etc/security/faillock.conf fail_interval 900
  pam-auth-update --force --enable faillock faillock_notify >>"$LOG" 2>&1
else
  warn "pam_faillock.so not found (libpam-modules damaged?) — no account lockout configured."
  pam-auth-update --package --force >>"$LOG" 2>&1
fi
info "PAM common-* files regenerated cleanly with pam-auth-update (removes planted lines)"

CA=/etc/pam.d/common-auth; CPW=/etc/pam.d/common-password

# Null passwords must not authenticate
if [[ -n $(getent shadow "$MAIN_USER" | cut -d: -f2) ]]; then
  sed -i -E 's/[[:space:]]+nullok(_secure)?([[:space:]]|$)/\2/g' "$CA" && log "Removed 'nullok' — empty passwords can no longer log in"
fi

# Complexity
PWQ_ARGS="retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 maxrepeat=3 usercheck=1 enforce_for_root"
if $HAVE_PWQ; then
  backup_file /etc/security/pwquality.conf
  for kv in "minlen 12" "dcredit -1" "ucredit -1" "lcredit -1" "ocredit -1" "difok 3" "maxrepeat 3" "usercheck 1" "enforcing 1" "retry 3"; do
    set_conf /etc/security/pwquality.conf "${kv%% *}" "${kv#* }"
  done
  grep -qE '^[[:space:]]*enforce_for_root' /etc/security/pwquality.conf || echo enforce_for_root >>/etc/security/pwquality.conf
  if grep -qE '^[[:space:]]*password[[:space:]].*pam_pwquality\.so' "$CPW"; then
    sed -i -E "s/^([[:space:]]*password[[:space:]]+(\[[^]]*\]|[^[:space:]]+)[[:space:]]+pam_pwquality\.so).*/\1 $PWQ_ARGS/" "$CPW"
  else
    insert_before_first "$CPW" '^[[:space:]]*password[[:space:]].*pam_unix\.so' "password	requisite	pam_pwquality.so $PWQ_ARGS"
  fi
else
  warn "libpam-pwquality couldn't be installed (offline?) — password complexity NOT enforced. Run: apt install libpam-pwquality, then re-run."
fi
AUTHTOK=""; grep -qE 'pam_pwquality\.so' "$CPW" && AUTHTOK=" use_authtok"

# Password history
touch /etc/security/opasswd; chown root:root /etc/security/opasswd; chmod 600 /etc/security/opasswd
if $HAVE_PWHIST && ! grep -q pam_pwhistory "$CPW"; then
  insert_before_first "$CPW" '^[[:space:]]*password[[:space:]].*pam_unix\.so' "password	requisite	pam_pwhistory.so remember=5 enforce_for_root${AUTHTOK}"
fi
grep -q pam_pwhistory "$CPW" && sed -i -E '/pam_pwhistory\.so/{s/remember=[0-9]+/remember=5/; /remember=/!s/$/ remember=5/}' "$CPW"
# pam_unix: remember + minlen (some scoring checks look here), strong hashing (Debian uses yescrypt)
sed -i -E '/^[[:space:]]*password[[:space:]].*pam_unix\.so/{s/remember=[0-9]+/remember=5/; /remember=/!s/$/ remember=5/; /minlen=/!s/$/ minlen=12/}' "$CPW"
grep -qE '^[[:space:]]*password[[:space:]].*pam_unix\.so.*(sha512|yescrypt)' "$CPW" \
  || sed -i -E '/^[[:space:]]*password[[:space:]].*pam_unix\.so/s/$/ sha512/' "$CPW"

# Comment out "auth sufficient pam_permit.so" backdoors in any service file
for f in /etc/pam.d/*; do
  [[ -f $f ]] || continue
  if grep -qE '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_permit\.so' "$f"; then
    sed -i -E 's/^([[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_permit\.so.*)$/# \1   # BACKDOOR disabled by CP script/' "$f"
    warn "Disabled PAM backdoor 'auth sufficient pam_permit.so' in $f (lets anyone log in with any password)"
  fi
done

if pam_sanity_ok; then
  log "PAM: complexity (12+ chars, upper/lower/digit/symbol), history (5), lockout (3 tries in 15 min -> locked 10 min) configured"
  $HAVE_FAILLOCK && info "Unlock a locked user with:  sudo faillock --user NAME --reset"
else
  cp -a "$BACKUP/pam.d.orig/." /etc/pam.d/
  warn "PAM check FAILED — restored original /etc/pam.d so nobody gets locked out. Configure password policy manually."
fi

#--------------------------------- SUDOERS ------------------------------------
section "sudoers"
if ! command -v visudo >/dev/null 2>&1; then
  warn "sudo is not installed (and couldn't be installed) — sudoers hardening skipped. Fix: apt install sudo"
else
sudoers_apply() { # FILE SEDSCRIPT DESCRIPTION — only applied if visudo validates it
  local f=$1 tmp; tmp=$(mktemp)
  cp "$f" "$tmp"; sed -i -E "$2" "$tmp"
  if cmp -s "$f" "$tmp"; then rm -f "$tmp"; return 1; fi
  if visudo -cf "$tmp" >/dev/null 2>&1; then cat "$tmp" >"$f"; log "$3 ($f)"; rm -f "$tmp"; return 0; fi
  warn "Skipped sudoers edit in $f — it would have broken sudo"; rm -f "$tmp"; return 1
}
SUDO_FILES=(/etc/sudoers); for f in /etc/sudoers.d/*; do [[ -f $f && $f != *README ]] && SUDO_FILES+=("$f"); done
for f in "${SUDO_FILES[@]}"; do
  sudoers_apply "$f" 's/NOPASSWD:[[:space:]]*//g' "Removed NOPASSWD (sudo now requires a password)"
  sudoers_apply "$f" 's/,[[:space:]]*!authenticate//g; s/!authenticate[[:space:]]*,[[:space:]]*//g; s/^([[:space:]]*Defaults[^[:space:]]*[[:space:]]+)!authenticate[[:space:]]*$/# \1!authenticate  # disabled by CP script/' \
    "Removed '!authenticate' (sudo now requires a password)"
done
# Grants to people/groups that shouldn't have them
for f in "${SUDO_FILES[@]}"; do
  while IFS=: read -r n rest; do
    who=$(awk '{print $1}' <<<"$rest")
    [[ $who == root || $who == %sudo || $who == %admin ]] && continue
    if [[ $who == %* ]] || [[ $who == ALL ]] || ! in_list "$who" "${AUTH_ADMINS[@]}"; then
      echo "${Y}   $f line $n:${N} $rest"
      if ask_yn "Disable this sudo rule? (grants admin rights to '$who', who is not an authorized admin)"; then
        sudoers_apply "$f" "${n}s/^/# disabled by CP script: /" "Disabled sudo rule for $who"
      else review "sudo rule kept: $f:$n: $rest"; fi
    fi
  done < <(awk '{t=$0; sub(/^[[:space:]]+/,"",t)}
                t=="" || t ~ /^#/ || t ~ /^@include/ || t ~ /^(Defaults|User_Alias|Runas_Alias|Host_Alias|Cmnd_Alias|Cmd_Alias)/ {next}
                t ~ /=/ {print NR ":" $0}' "$f")
done
# /etc/sudoers must still read /etc/sudoers.d (our hardening file lives there)
grep -qE '^[[:space:]]*[@#]includedir[[:space:]]+/etc/sudoers\.d' /etc/sudoers \
  || sudoers_apply /etc/sudoers '$a @includedir /etc/sudoers.d' "Restored missing '@includedir /etc/sudoers.d'"
# The sudo group must keep admin rights — attackers delete this rule so real admins lose sudo
SUDO_GROUP_RULE=""
grep -hqE '^[[:space:]]*%sudo[[:space:]]+ALL[[:space:]]*=' /etc/sudoers /etc/sudoers.d/* 2>/dev/null || SUDO_GROUP_RULE='%sudo   ALL=(ALL:ALL) ALL'
chown root:root "${SUDO_FILES[@]}"; chmod 440 "${SUDO_FILES[@]}"
# Hardening Defaults (logged, pty-isolated, no password echo, short timeout).
SUDOH=/etc/sudoers.d/99-cp-hardening
cat >"$SUDOH" <<'SUDOEOF'
# Added by CyberPatriot hardening script
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults        use_pty
Defaults        logfile="/var/log/sudo.log"
Defaults        !visiblepw
Defaults        always_set_home
Defaults        timestamp_timeout=15
Defaults        passwd_tries=3
Defaults        passwd_timeout=1
SUDOEOF
[[ -n $SUDO_GROUP_RULE ]] && echo "$SUDO_GROUP_RULE" >>"$SUDOH"
chmod 440 "$SUDOH"
if visudo -cf "$SUDOH" >/dev/null 2>&1; then
  log "sudoers hardening: use_pty, command logging (/var/log/sudo.log), no visible password, 15-min timeout"
  [[ -n $SUDO_GROUP_RULE ]] && warn "The '%sudo ALL=(ALL:ALL) ALL' rule was missing (admins had no sudo) — restored it"
else rm -f "$SUDOH"; warn "sudoers hardening drop-in failed validation — skipped"; fi

if ! visudo -c >>"$LOG" 2>&1; then
  [[ -f $BACKUP/sudoers.orig ]] && cp -a "$BACKUP/sudoers.orig" /etc/sudoers
  [[ -d $BACKUP/sudoers.d.orig ]] && cp -a "$BACKUP/sudoers.d.orig/." /etc/sudoers.d/
  warn "sudoers failed validation — restored originals"
fi
{ echo "--- Active sudoers rules ---"; grep -hvE '^[[:space:]]*(#|$)' "${SUDO_FILES[@]}" "$SUDOH" 2>/dev/null | sed 's/^/   /'; echo; } >>"$REPORT"
fi

# Lock root ONLY once sudo really gives you full admin rights — on Debian, root may be your
# only way back in. ('sudo -l -U' asks sudo itself, so a deleted %sudo rule is caught too.)
if command -v sudo >/dev/null 2>&1 && sudo -l -U "$MAIN_USER" 2>/dev/null | grep -qE "$SUDO_ALL_RE"; then
  passwd -l root >>"$LOG" 2>&1 && log "Root account password locked (use sudo)"
else
  warn "Root was NOT locked: sudo doesn't give $MAIN_USER full admin rights yet. Fix sudo first, then run: passwd -l root"
fi

#------------------------------- LOGIN SCREEN ---------------------------------
section "Login screen (auto-login, guest, root login)"
if [[ -d /etc/gdm3 ]]; then
  # Debian's GDM reads /etc/gdm3/daemon.conf (Ubuntu renamed it custom.conf — also fixed if present)
  GDMCONFS=(/etc/gdm3/daemon.conf); [[ -f /etc/gdm3/custom.conf ]] && GDMCONFS+=(/etc/gdm3/custom.conf)
  for G3 in "${GDMCONFS[@]}"; do
    backup_file "$G3"
    ini_set "$G3" daemon AutomaticLoginEnable false
    ini_set "$G3" daemon TimedLoginEnable false
    ini_set "$G3" daemon AutomaticLogin ""
    ini_set "$G3" daemon TimedLogin ""
    ini_set "$G3" security AllowRoot false
    ini_set "$G3" security DisallowTCP true
  done
  GD=/etc/gdm3/greeter.dconf-defaults; backup_file "$GD"
  ini_set "$GD" "org/gnome/login-screen" disable-user-list true
  ini_set "$GD" "org/gnome/login-screen" disable-restart-buttons true
  # compile the greeter settings (the safe half of 'dpkg-reconfigure gdm3' — offered in full at the end)
  [[ -x /usr/share/gdm/generate-config ]] && run /usr/share/gdm/generate-config
  log "GDM (${GDMCONFS[*]}): auto/timed login off, root login off, user list + restart buttons hidden (applies after reboot)"
fi
if [[ -d /etc/lightdm ]] || is_installed lightdm; then
  LD=/etc/lightdm/lightdm.conf; backup_file "$LD"
  secs=("Seat:*"); grep -q '^\[SeatDefaults\]' "$LD" 2>/dev/null && secs+=("SeatDefaults")
  for s in "${secs[@]}"; do
    ini_set "$LD" "$s" allow-guest false
    ini_set "$LD" "$s" greeter-allow-guest false
    ini_set "$LD" "$s" autologin-guest false
    ini_set "$LD" "$s" autologin-user ""
    ini_set "$LD" "$s" autologin-user-timeout 0
    ini_set "$LD" "$s" greeter-hide-users true
    ini_set "$LD" "$s" greeter-show-manual-login true
  done
  for f in /etc/lightdm/lightdm.conf.d/*.conf; do
    [[ -f $f ]] || continue
    if grep -qE '^[[:space:]]*(autologin-user[[:space:]]*=[[:space:]]*[^[:space:]]|allow-guest[[:space:]]*=[[:space:]]*true)' "$f"; then
      backup_file "$f"; sed -i -E 's/^([[:space:]]*(autologin-user[[:space:]]*=|allow-guest[[:space:]]*=[[:space:]]*true).*)$/# \1  # disabled by CP script/' "$f"
      log "Disabled auto-login/guest override in $f"
    fi
  done
  log "LightDM: guest account and auto-login disabled (applies at next login)"
fi
if is_installed sddm; then
  SD=/etc/sddm.conf; backup_file "$SD"
  ini_set "$SD" Autologin User ""
  ini_set "$SD" Autologin Session ""
  for f in /etc/sddm.conf.d/*.conf; do
    [[ -f $f ]] && grep -qE '^[[:space:]]*User[[:space:]]*=[[:space:]]*[^[:space:]]' "$f" \
      && { backup_file "$f"; sed -i -E 's/^([[:space:]]*User[[:space:]]*=.*)$/# \1  # disabled by CP script/' "$f"; log "Disabled SDDM auto-login in $f"; }
  done
  log "SDDM: auto-login disabled"
fi

#-------------------------- ADVANCED LOGIN CONFIGS ----------------------------
section "Advanced login hardening (su, idle timeout, banners)"
# Authorized-use banners (also referenced by the SSH 'Banner' directive)
BANNER='Authorized access only. All activity is logged and monitored. Disconnect now if you are not an authorized user.'
for b in /etc/issue /etc/issue.net; do printf '%s\n' "$BANNER" >"$b"; chmod 644 "$b"; chown root:root "$b"; done
# Strip kernel-version disclosure from the dynamic MOTD
[[ -x /etc/update-motd.d/10-uname ]] && chmod -x /etc/update-motd.d/10-uname 2>/dev/null
log "Legal login banner set in /etc/issue and /etc/issue.net"

# Restrict 'su' to members of the sudo group (pam_wheel) so a standard user can't escalate.
# Debian's /etc/pam.d/su has several commented pam_wheel examples; only the first
# "required" one becomes active, placed after pam_rootok so root can still su.
SU=/etc/pam.d/su
WHEEL_LINE='auth       required   pam_wheel.so use_uid group=sudo'
if [[ -f $SU ]] && pam_module_exists pam_wheel.so; then
  backup_file "$SU"
  if grep -qE '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_wheel\.so.*trust' "$SU"; then
    warn "/etc/pam.d/su had 'pam_wheel.so trust' (passwordless su for a group) — disabled"
  fi
  awk -v wl="$WHEEL_LINE" '
    /^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_wheel\.so.*trust/ { print "# " $0 "   # disabled by CP script"; next }
    !done && /^[[:space:]]*#?[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_wheel\.so/ && !/deny/ { print wl; done=1; next }
    { print }' "$SU" >"$SU.cptmp"
  if ! grep -qxF "$WHEEL_LINE" "$SU.cptmp"; then
    awk -v wl="$WHEEL_LINE" '{ print } !d && /^[[:space:]]*auth[[:space:]].*pam_rootok\.so/ { print wl; d=1 }' "$SU.cptmp" >"$SU.cptmp2" \
      && mv "$SU.cptmp2" "$SU.cptmp"
  fi
  if grep -qxF "$WHEEL_LINE" "$SU.cptmp"; then cat "$SU.cptmp" >"$SU"; log "su restricted to members of the 'sudo' group (pam_wheel)"
  else warn "Couldn't place pam_wheel in $SU (no pam_rootok line?) — left unchanged"; fi
  rm -f "$SU.cptmp" "$SU.cptmp2"
fi

# Idle-session auto-logout (15 min) for interactive shells
cat >/etc/profile.d/99-cp-autologout.sh <<'TMOUTEOF'
# Auto-logout idle shells (CyberPatriot hardening)
if [ -z "${TMOUT:-}" ]; then
  TMOUT=900
  readonly TMOUT 2>/dev/null || true
  export TMOUT
fi
TMOUTEOF
chmod 644 /etc/profile.d/99-cp-autologout.sh
log "Idle shells auto-logout after 15 minutes"

# login.defs: strong hashing cost + sane account defaults
set_conf /etc/login.defs SHA_CRYPT_MIN_ROUNDS 65536 $'\t'
set_conf /etc/login.defs USERGROUPS_ENAB yes $'\t'
set_conf /etc/login.defs DEFAULT_HOME no $'\t'
set_conf /etc/login.defs LOG_UNKFAIL_ENAB no $'\t'

# securetty: Debian 12 normally has none; if one was planted, strip network ttys from it
if [[ -f /etc/securetty ]]; then
  backup_file /etc/securetty
  sed -i -E '/^[[:space:]]*(pts\/?[0-9]*|ssh)[[:space:]]*$/d' /etc/securetty
  info "Removed any pts/ssh entries from /etc/securetty"
fi

{ echo "--- Login config summary ---"
  echo "   su group       : $(getent group sudo | cut -d: -f4)"
  echo "   TMOUT          : 900s (idle auto-logout)"
  echo "   Password aging : $(awk '/^PASS_MAX_DAYS/{print $2}' /etc/login.defs) max / $(awk '/^PASS_MIN_DAYS/{print $2}' /etc/login.defs) min days"
  echo; } >>"$REPORT"

#-------------------------------- FIREWALL ------------------------------------
section "Firewall (UFW)"
is_installed ufw || apt_install ufw
ssh_ports() {
  local p; p=$(mkdir -p /run/sshd; sshd -T 2>/dev/null | awk '$1=="port"{print $2}' | sort -u)
  [[ -z $p ]] && p=$(awk 'tolower($1)=="port"{print $2}' /etc/ssh/sshd_config 2>/dev/null)
  echo "${p:-22}"
}
if command -v ufw >/dev/null; then
  # Debian's nftables.service runs "flush ruleset" when it starts — at boot that would
  # wipe UFW's rules. firewalld would fight UFW too. Turn them off BEFORE enabling UFW.
  for fw in nftables firewalld; do
    if systemctl is-enabled --quiet "$fw" 2>/dev/null || systemctl is-active --quiet "$fw" 2>/dev/null; then
      run systemctl disable --now "$fw"
      log "Disabled $fw.service (it would override/flush UFW's rules)"
      review "Note: $fw.service was enabled and has been disabled so UFW is the only firewall."
    fi
  done
  { echo "--- UFW rules BEFORE the script (look for odd 'allow' ports) ---"; ufw status numbered 2>&1; echo; } >>"$REPORT"
  [[ -f /etc/default/ufw ]] && sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
  run ufw default deny incoming; run ufw default allow outgoing; run ufw default deny routed
  allow() { run ufw allow "$@" && info "Firewall allows $*"; }
  if $NEED_SSH;   then for p in $(ssh_ports); do allow "$p/tcp"; done; fi
  if $NEED_FTP;   then allow 20/tcp; allow 21/tcp
    pmin=$(awk -F= '/^pasv_min_port/{print $2}' /etc/vsftpd.conf 2>/dev/null); pmax=$(awk -F= '/^pasv_max_port/{print $2}' /etc/vsftpd.conf 2>/dev/null)
    [[ -n $pmin && -n $pmax ]] && allow "$pmin:$pmax/tcp"; fi
  if $NEED_SAMBA; then allow 137/udp; allow 138/udp; allow 139/tcp; allow 445/tcp; fi
  if $NEED_WEB;   then allow 80/tcp; allow 443/tcp; fi
  if $NEED_DNS;   then allow 53/tcp; allow 53/udp; fi
  if $NEED_MAIL;  then for p in 25 465 587 110 995 143 993; do allow "$p/tcp"; done; fi
  if $NEED_NFS;   then allow 2049; allow 111; fi
  if $NEED_TELNET; then allow 23/tcp; fi
  if $NEED_VNC;   then allow 5900/tcp; allow 3389/tcp; fi
  if $DB_REMOTE;  then $NEED_MYSQL && allow 3306/tcp; $NEED_PGSQL && allow 5432/tcp; fi
  run ufw logging on
  run ufw --force enable
  run systemctl enable ufw
  if ufw status | grep -q "Status: active"; then log "UFW firewall enabled (deny incoming by default, only required services allowed)"
  else warn "UFW did not enable — check 'sudo ufw status'"; fi
else
  warn "UFW is not installed and couldn't be installed (APT broken/offline?) — NO firewall configured."
fi

#--------------------------------- SYSCTL -------------------------------------
section "Kernel & network hardening (sysctl)"
backup_file /etc/sysctl.conf /etc/sysctl.d
CPSYSCTL=/etc/sysctl.d/99-cyberpatriot.conf

SYSCTLS=(
  # --- address space / kernel hardening ---
  "kernel.randomize_va_space=2"          # full ASLR
  "kernel.dmesg_restrict=1"              # hide kernel log from non-root
  "kernel.kptr_restrict=1"               # hide kernel pointers (CIS L1 = 1)
  "kernel.yama.ptrace_scope=1"           # restrict ptrace to child procs
  "kernel.sysrq=0"                       # disable magic SysRq key
  "kernel.core_uses_pid=1"
  "kernel.kexec_load_disabled=1"         # block loading a new kernel at runtime
  "kernel.unprivileged_bpf_disabled=1"   # no unprivileged eBPF
  "net.core.bpf_jit_harden=2"
  "fs.suid_dumpable=0"                   # no core dumps from setuid programs
  "fs.protected_hardlinks=1"
  "fs.protected_symlinks=1"
  "fs.protected_fifos=2"
  "fs.protected_regular=2"
  # --- IPv4 network ---
  "net.ipv4.ip_forward=0"                # not a router
  "net.ipv4.tcp_syncookies=1"            # SYN-flood protection
  "net.ipv4.tcp_max_syn_backlog=20480"
  "net.ipv4.tcp_synack_retries=2"
  "net.ipv4.tcp_syn_retries=5"
  "net.ipv4.tcp_rfc1337=1"               # protect against TIME-WAIT assassination
  "net.ipv4.conf.all.rp_filter=1"        # reverse-path (anti-spoof) filter
  "net.ipv4.conf.default.rp_filter=1"
  "net.ipv4.conf.all.accept_source_route=0"
  "net.ipv4.conf.default.accept_source_route=0"
  "net.ipv4.conf.all.accept_redirects=0"
  "net.ipv4.conf.default.accept_redirects=0"
  "net.ipv4.conf.all.secure_redirects=0"
  "net.ipv4.conf.default.secure_redirects=0"
  "net.ipv4.conf.all.send_redirects=0"
  "net.ipv4.conf.default.send_redirects=0"
  "net.ipv4.conf.all.log_martians=1"
  "net.ipv4.conf.default.log_martians=1"
  "net.ipv4.icmp_echo_ignore_broadcasts=1"
  "net.ipv4.icmp_ignore_bogus_error_responses=1"
  # --- IPv6 network ---
  "net.ipv6.conf.all.forwarding=0"
  "net.ipv6.conf.all.accept_source_route=0"
  "net.ipv6.conf.default.accept_source_route=0"
  "net.ipv6.conf.all.accept_redirects=0"
  "net.ipv6.conf.default.accept_redirects=0"
  "net.ipv6.conf.all.accept_ra=0"
  "net.ipv6.conf.default.accept_ra=0"
  "net.ipv6.conf.all.router_solicitations=0"
  "net.ipv6.conf.default.router_solicitations=0"
  "net.ipv6.conf.all.accept_ra_rtr_pref=0"
  "net.ipv6.conf.default.accept_ra_rtr_pref=0"
  "net.ipv6.conf.all.accept_ra_pinfo=0"
  "net.ipv6.conf.default.accept_ra_pinfo=0"
  "net.ipv6.conf.all.accept_ra_defrtr=0"
  "net.ipv6.conf.default.accept_ra_defrtr=0"
  "net.ipv6.conf.all.autoconf=0"
  "net.ipv6.conf.default.autoconf=0"
  "net.ipv6.conf.all.dad_transmits=0"
  "net.ipv6.conf.default.dad_transmits=0"
  "net.ipv6.conf.default.max_addresses=1"
  # --- ARP / layer-2 anti-spoofing ---
  "net.ipv4.conf.all.arp_ignore=1"
  "net.ipv4.conf.all.arp_announce=2"
  "net.ipv4.conf.all.drop_gratuitous_arp=1"
  "net.ipv4.conf.all.proxy_arp=0"
  "net.ipv4.conf.default.proxy_arp=0"
  "net.ipv4.conf.all.shared_media=0"
  "net.ipv4.conf.default.shared_media=0"
  "net.ipv4.conf.all.mc_forwarding=0"
  "net.ipv4.conf.all.bootp_relay=0"
  # --- memory / misc ---
  "vm.mmap_min_addr=65536"
)
$DISABLE_IPV6 && SYSCTLS+=("net.ipv6.conf.all.disable_ipv6=1" "net.ipv6.conf.default.disable_ipv6=1" "net.ipv6.conf.lo.disable_ipv6=1")

# Write to the canonical file (grep-friendly) AND a high-precedence drop-in,
# and comment out any conflicting value already set in an editable sysctl dir.
{ echo "# CyberPatriot kernel/network hardening — overrides earlier files"; } >"$CPSYSCTL"
for kv in "${SYSCTLS[@]}"; do
  kv=${kv%%#*}; kv=${kv// /}; [[ -z $kv ]] && continue
  k=${kv%%=*}; v=${kv#*=}; kre=${k//./\\.}
  set_conf /etc/sysctl.conf "$k" "$v" "="
  echo "$k=$v" >>"$CPSYSCTL"
  for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf; do
    [[ -f $f && $f != "$CPSYSCTL" && ! -L $f ]] || continue
    if grep -qE "^[[:space:]]*${kre}[[:space:]]*=" "$f" && ! grep -qE "^[[:space:]]*${kre}[[:space:]]*=[[:space:]]*${v}[[:space:]]*$" "$f"; then
      sed -i -E "s|^([[:space:]]*${kre}[[:space:]]*=.*)$|# \1   # overridden by CP script|" "$f"
      info "Commented out conflicting $k in $f"
    fi
  done
done
chmod 644 "$CPSYSCTL"
run sysctl --system
run sysctl -p /etc/sysctl.conf

# VERIFY every value actually took effect. This catches an override from ANY source
# (e.g. /usr/lib/sysctl.d or an attacker drop-in). Anything that won't stick is
# forced with -w and, if still wrong, reported along with the overriding file.
MISS=0; CHECKED=0
for kv in "${SYSCTLS[@]}"; do
  kv=${kv%%#*}; kv=${kv// /}; [[ -z $kv ]] && continue
  k=${kv%%=*}; v=${kv#*=}
  cur=$(sysctl -n "$k" 2>/dev/null) || continue      # key absent (e.g. ipv6 off) — skip
  ((CHECKED++)); cur=${cur//[[:space:]]/}
  if [[ $cur != "$v" ]]; then
    sysctl -w "$k=$v" >/dev/null 2>&1
    cur=$(sysctl -n "$k" 2>/dev/null); cur=${cur//[[:space:]]/}
    if [[ $cur != "$v" ]]; then
      ((MISS++)); warn "sysctl $k is '$cur' but should be '$v'"
      src=$(grep -rlsE "^[[:space:]]*${k//./\\.}[[:space:]]*=" /etc/sysctl.conf /etc/sysctl.d /run/sysctl.d /usr/lib/sysctl.d /usr/local/lib/sysctl.d 2>/dev/null | grep -vxF "$CPSYSCTL" | tr '\n' ' ')
      [[ -n $src ]] && review "[!] sysctl $k overridden by: $src"
    fi
  fi
done
if ((MISS==0)); then log "sysctl: all $CHECKED applicable keys verified live (ASLR, rp_filter, syncookies, no redirects/forwarding, kptr/dmesg restricted, etc.)"
else warn "$MISS sysctl value(s) could not be enforced — see REVIEW-ME.txt (a reboot may also be required)."; fi

{ echo "--- Effective sysctl hardening values (verify against CIS / the README) ---"
  for kv in "${SYSCTLS[@]}"; do kv=${kv%%#*}; kv=${kv// /}; [[ -z $kv ]] && continue
    k=${kv%%=*}; printf '   %-45s = %s\n' "$k" "$(sysctl -n "$k" 2>/dev/null || echo '(n/a)')"; done
  echo; } >>"$REPORT"

mkdir -p /etc/security/limits.d
printf '* hard core 0\n* soft core 0\nroot hard core 0\n' >/etc/security/limits.d/99-cp-nocore.conf
log "Core dumps disabled (sysctl + limits.conf)"

#-------------------------------- SERVICES ------------------------------------
section "Services"
# Unmask README-critical services first, so the restart checks below test the CONFIG
# (a masked service can't restart, and that would wrongly roll back the hardening).
for g in "${CRIT_GROUPS[@]}"; do for u in ${g#*|}; do
  [[ $(systemctl is-enabled "$u" 2>/dev/null) == masked* ]] && { run systemctl unmask "$u"; log "Unmasked critical service $u (it had been masked)"; }
done; done

# ---- SSH ----
if $NEED_SSH; then
  is_installed openssh-server || apt_install openssh-server
  if [[ -f /etc/ssh/sshd_config ]]; then
    mkdir -p /run/sshd
    ssh-keygen -A >>"$LOG" 2>&1      # missing host keys make 'sshd -t' fail (and would undo the hardening)
    sshd -t >>"$LOG" 2>&1 || warn "sshd_config was ALREADY broken before the script: $(sshd -t 2>&1 | head -1)"
    snap=$(snapshot /etc/ssh/sshd_config /etc/ssh/sshd_config.d); backup_file /etc/ssh/sshd_config /etc/ssh/sshd_config.d
    for kv in "PermitRootLogin no" "PermitEmptyPasswords no" "PasswordAuthentication yes" "X11Forwarding no" "MaxAuthTries 3" \
              "LoginGraceTime 60" "IgnoreRhosts yes" "HostbasedAuthentication no" "PermitUserEnvironment no" \
              "ClientAliveInterval 300" "ClientAliveCountMax 3" "LogLevel VERBOSE" "UsePAM yes" "StrictModes yes" \
              "AllowAgentForwarding no" "AllowTcpForwarding no" "PubkeyAuthentication yes" "Banner /etc/issue.net"; do
      k=${kv%% *}; v=${kv#* }
      sshd_set /etc/ssh/sshd_config "$k" "$v"
      # Debian's sshd_config starts with "Include sshd_config.d/*.conf" and the FIRST value wins,
      # so a planted drop-in would override the main file — fix existing keys there too.
      for d in /etc/ssh/sshd_config.d/*.conf; do [[ -f $d ]] && sshd_set "$d" "$k" "$v" 1; done
    done
    chown root:root /etc/ssh/sshd_config; chmod 600 /etc/ssh/sshd_config
    chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null; chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null
    if sshd -t >>"$LOG" 2>&1; then
      # "Protocol 2" / "UsePrivilegeSeparation yes" are on most checklists but are obsolete in
      # OpenSSH 9 — add each one only if sshd still accepts the file with it.
      for kv in "Protocol 2" "UsePrivilegeSeparation yes"; do
        cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.cptest
        sshd_set /etc/ssh/sshd_config.cptest "${kv%% *}" "${kv#* }"
        sshd -t -f /etc/ssh/sshd_config.cptest >>"$LOG" 2>&1 && cat /etc/ssh/sshd_config.cptest >/etc/ssh/sshd_config
        rm -f /etc/ssh/sshd_config.cptest
      done
      if systemctl is-enabled ssh.socket >/dev/null 2>&1; then run systemctl restart ssh.socket; run systemctl try-restart ssh.service
      else run systemctl enable ssh; run systemctl restart ssh || run systemctl restart sshd; fi
      sleep 1
      if systemctl is-active --quiet ssh || systemctl is-active --quiet ssh.socket || systemctl is-active --quiet sshd; then
        log "SSH hardened: root login off, empty passwords off, X11 off, max 3 tries (password logins still allowed)"
      else warn "SSH is not running after restart — check 'systemctl status ssh'"; fi
    else
      restore_snapshot "$snap"; warn "New sshd_config failed 'sshd -t' — rolled back. Harden SSH by hand."
    fi
    rm -rf "$snap"
  fi
else
  svc_disable ssh sshd ssh.socket
  safe_purge openssh-server
fi

# ---- FTP ----
if $NEED_FTP; then
  if is_installed vsftpd && [[ -f /etc/vsftpd.conf ]]; then
    F=/etc/vsftpd.conf; snap=$(snapshot "$F"); backup_file "$F"
    for kv in anonymous_enable=NO anon_upload_enable=NO anon_mkdir_write_enable=NO anon_other_write_enable=NO \
              local_enable=YES write_enable=YES chroot_local_user=YES allow_writeable_chroot=YES xferlog_enable=YES \
              hide_ids=YES ls_recurse_enable=NO; do
      set_conf "$F" "${kv%%=*}" "${kv#*=}" "="
    done
    chmod 600 "$F"
    if svc_restart_ok vsftpd; then
      log "vsftpd: anonymous access off, users chrooted"
      rm -rf "$snap"; snap=$(snapshot "$F")
      if [[ -f /etc/ssl/certs/ssl-cert-snakeoil.pem && -f /etc/ssl/private/ssl-cert-snakeoil.key ]]; then
        grep -qE '^rsa_cert_file=' "$F" || set_conf "$F" rsa_cert_file /etc/ssl/certs/ssl-cert-snakeoil.pem "="
        grep -qE '^rsa_private_key_file=' "$F" || set_conf "$F" rsa_private_key_file /etc/ssl/private/ssl-cert-snakeoil.key "="
        set_conf "$F" ssl_enable YES "="
        # offer TLS without REQUIRING it — forced TLS breaks plain FTP logins the README may rely on
        set_conf "$F" force_local_logins_ssl NO "="; set_conf "$F" force_local_data_ssl NO "="
        if svc_restart_ok vsftpd; then log "vsftpd: SSL/TLS enabled (optional for clients)"
          review "vsftpd: TLS is available but not forced. If the README wants encrypted FTP only, set force_local_logins_ssl=YES and force_local_data_ssl=YES in /etc/vsftpd.conf"
        else restore_snapshot "$snap"; svc_restart_ok vsftpd; warn "vsftpd would not start with SSL — SSL left off"; fi
      fi
    else
      restore_snapshot "$snap"; svc_restart_ok vsftpd; warn "vsftpd failed to restart with new config — rolled back"
    fi
    rm -rf "$snap"
  fi
  if is_installed pure-ftpd || is_installed pure-ftpd-common; then
    mkdir -p /etc/pure-ftpd/conf; echo yes >/etc/pure-ftpd/conf/NoAnonymous; echo yes >/etc/pure-ftpd/conf/ChrootEveryone
    svc_restart_ok pure-ftpd && log "pure-ftpd: anonymous off, chroot on" || warn "pure-ftpd not running — check it"
  fi
  { is_installed proftpd-basic || is_installed proftpd-core; } && \
    review "[!] proftpd installed: remove/disable any <Anonymous> block in /etc/proftpd/proftpd.conf and set 'RootLogin off'"
else
  svc_disable vsftpd pure-ftpd proftpd tftpd-hpa
  for p in vsftpd pure-ftpd pure-ftpd-common proftpd-basic proftpd-core ftpd inetutils-ftpd tftpd-hpa tftpd atftpd; do safe_purge "$p"; done
fi

# ---- Samba ----
if $NEED_SAMBA; then
  if [[ -f /etc/samba/smb.conf ]]; then
    F=/etc/samba/smb.conf; snap=$(snapshot "$F"); backup_file "$F"
    ini_set "$F" global "restrict anonymous" 2 " = "
    ini_set "$F" global "server min protocol" SMB2 " = "
    ini_set "$F" global "usershare allow guests" no " = "
    if ! $SAMBA_GUEST; then
      ini_set "$F" global "map to guest" never " = "
      sed -i -E 's/^([[:space:]]*(guest ok|public)[[:space:]]*=[[:space:]]*)yes/\1no/I' "$F"
    fi
    if testparm -s "$F" >/dev/null 2>&1; then
      svc_restart_ok smbd && log "Samba hardened (no anonymous/guest, SMB1 off)" || warn "smbd not running after restart"
      unit_exists nmbd && run systemctl restart nmbd
    else restore_snapshot "$snap"; warn "smb.conf failed testparm — rolled back"; fi
    rm -rf "$snap"
    if command -v pdbedit >/dev/null; then
      for su in $(pdbedit -L 2>/dev/null | cut -d: -f1); do
        if in_list "$su" "${AUTH_ALL[@]}"; then
          [[ $su == "$MAIN_USER" && $CHANGE_MAIN_PW != true ]] && continue   # keep YOUR Samba password as-is
          (echo "$PW"; echo "$PW") | smbpasswd -s "$su" >>"$LOG" 2>&1 && info "Samba password updated for $su"
        else smbpasswd -x "$su" >>"$LOG" 2>&1 && log "Removed unauthorized Samba user $su"; fi
      done
    fi
    { echo "--- Samba shares (check paths/permissions against README) ---"; testparm -s 2>/dev/null | grep -E '^\[|path|guest|writ|read only'; echo; } >>"$REPORT"
  fi
else
  svc_disable smbd nmbd samba samba-ad-dc
  safe_purge samba
fi

# ---- Web ----
if $NEED_WEB; then
  if is_installed apache2; then
    snap=$(snapshot /etc/apache2 /etc/php); backup_file /etc/apache2
    SEC=/etc/apache2/conf-available/security.conf
    if [[ -f $SEC ]]; then
      set_conf "$SEC" ServerTokens Prod " "; set_conf "$SEC" ServerSignature Off " "; set_conf "$SEC" TraceEnable Off " "
      run a2enconf security
    fi
    for f in /etc/apache2/apache2.conf /etc/apache2/sites-available/*.conf; do
      [[ -f $f ]] && sed -i -E '/^[[:space:]]*Options[[:space:]]/{s/\+Indexes/-Indexes/g; s/([[:space:]])Indexes([[:space:]]|$)/\1\2/g; s/^([[:space:]]*Options)[[:space:]]*$/\1 None/}' "$f"
    done
    for ini in /etc/php/*/apache2/php.ini /etc/php/*/fpm/php.ini /etc/php/*/cgi/php.ini; do
      [[ -f $ini ]] || continue
      set_conf "$ini" expose_php Off; set_conf "$ini" display_errors Off; set_conf "$ini" allow_url_include Off; set_conf "$ini" log_errors On
    done
    if apache2ctl configtest >>"$LOG" 2>&1 && svc_restart_ok apache2; then
      log "Apache: ServerTokens Prod, ServerSignature Off, TRACE off, directory listing off; PHP expose_php/display_errors off"
    else
      # only wipe /etc/apache2 if the snapshot really holds a copy of it
      if [[ -d $snap/etc/apache2 ]]; then rm -rf /etc/apache2; restore_snapshot "$snap"; fi
      svc_restart_ok apache2; warn "Apache config failed test — rolled back"
    fi
    rm -rf "$snap"
  fi
  if is_installed nginx-common || is_installed nginx; then
    NG=/etc/nginx/nginx.conf; snap=$(snapshot "$NG"); backup_file "$NG"
    if grep -qE '^[[:space:]]*#?[[:space:]]*server_tokens' "$NG"; then
      sed -i -E 's/^([[:space:]]*)#?[[:space:]]*server_tokens[[:space:]]+[a-z]+;/\1server_tokens off;/' "$NG"
    else sed -i -E '0,/^[[:space:]]*http[[:space:]]*\{/s//&\n\tserver_tokens off;/' "$NG"; fi
    if nginx -t >>"$LOG" 2>&1; then run systemctl reload nginx; log "Nginx: server_tokens off"
    else restore_snapshot "$snap"; warn "nginx config test failed — rolled back"; fi
    rm -rf "$snap"
  fi
  { echo "--- PHP files in web roots (look for web shells: eval, base64_decode, system, shell_exec) ---"
    grep -rlsE 'eval\(|base64_decode\(|shell_exec\(|system\(|passthru\(|exec\(' /var/www /srv 2>/dev/null --include='*.php' | head -50; echo; } >>"$REPORT"
else
  svc_disable apache2 nginx lighttpd
  for p in apache2 apache2-bin nginx nginx-core nginx-full nginx-light nginx-extras nginx-common lighttpd; do safe_purge "$p"; done
fi

# ---- MariaDB / MySQL (Debian 12's "mysql" is MariaDB) ----
if $NEED_MYSQL; then
  for cnf in /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mysql.conf.d/mysqld.cnf; do
    [[ -f $cnf ]] || continue
    snap=$(snapshot "$cnf"); backup_file "$cnf"
    $DB_REMOTE || ini_set "$cnf" mysqld bind-address 127.0.0.1 " = "
    ini_set "$cnf" mysqld local-infile 0 " = "
    svcn=mysql; unit_exists mariadb && svcn=mariadb
    if svc_restart_ok "$svcn"; then log "MariaDB/MySQL: local-only bind (unless remote needed), LOCAL INFILE off ($cnf)"
    else restore_snapshot "$snap"; svc_restart_ok "$svcn"; warn "Database failed to restart — rolled back $cnf"; fi
    rm -rf "$snap"
  done
  review "[!] MariaDB: log in with 'sudo mariadb' and check for users with no password / '%' host: SELECT user,host,plugin FROM mysql.user;"
else
  svc_disable mariadb mysql
  for p in $(installed_matching 'default-mysql-server' 'mariadb-server*' 'mysql-server*'); do safe_purge "$p"; done
fi

# ---- PostgreSQL ----
if $NEED_PGSQL; then
  for pc in /etc/postgresql/*/main/postgresql.conf; do
    [[ -f $pc ]] || continue
    snap=$(snapshot "$pc"); backup_file "$pc"
    $DB_REMOTE || set_conf "$pc" listen_addresses "'localhost'"
    if svc_restart_ok postgresql; then log "PostgreSQL: listens on localhost only ($pc)"
    else restore_snapshot "$snap"; svc_restart_ok postgresql; warn "PostgreSQL failed restart — rolled back"; fi
    rm -rf "$snap"
  done
  { echo "--- PostgreSQL 'trust' auth lines (no password needed — change to scram-sha-256 if safe) ---"
    grep -HnE '^[^#]*[[:space:]]trust([[:space:]]|$)' /etc/postgresql/*/main/pg_hba.conf 2>/dev/null; echo; } >>"$REPORT"
else
  svc_disable postgresql
  for p in $(installed_matching 'postgresql' 'postgresql-[0-9]*'); do safe_purge "$p"; done
fi

# ---- DNS ----
if $NEED_DNS; then
  O=/etc/bind/named.conf.options
  if [[ -f $O ]]; then
    snap=$(snapshot "$O"); backup_file "$O"
    grep -qE '^[[:space:]]*version[[:space:]]' "$O" || sed -i -E '0,/^[[:space:]]*options[[:space:]]*\{/s//&\n\tversion "not disclosed";/' "$O"
    grep -qE '^[[:space:]]*allow-transfer' "$O" || sed -i -E '0,/^[[:space:]]*options[[:space:]]*\{/s//&\n\tallow-transfer { none; };/' "$O"
    if named-checkconf >>"$LOG" 2>&1; then
      { svc_restart_ok named || svc_restart_ok bind9; } && log "BIND: version hidden, zone transfers blocked"
    else restore_snapshot "$snap"; warn "named-checkconf failed — rolled back"; fi
    rm -rf "$snap"
  fi
else
  svc_disable named bind9
  safe_purge bind9
fi

# ---- Mail (Debian installs Exim by default) ----
purge_mail_servers() {
  svc_disable postfix dovecot exim4 sendmail
  local p
  for p in postfix dovecot-core dovecot-imapd dovecot-pop3d exim4 exim4-daemon-light exim4-daemon-heavy exim4-base exim4-config sendmail sendmail-bin; do safe_purge "$p"; done
}
if $NEED_MAIL; then
  if command -v postconf >/dev/null; then
    backup_file /etc/postfix/main.cf
    postconf -e 'disable_vrfy_command = yes' 'smtpd_banner = $myhostname ESMTP' >>"$LOG" 2>&1
    postfix check >>"$LOG" 2>&1 && svc_restart_ok postfix && log "Postfix: VRFY disabled, banner hides version"
  fi
  if is_installed exim4-base; then
    review "[!] Exim is the mail server: check dc_local_interfaces in /etc/exim4/update-exim4.conf.conf ('127.0.0.1 ; ::1' = local only) matches what the README needs."
  fi
else
  purge_mail_servers
fi

# ---- Printing ----
if ! $NEED_PRINT; then svc_disable cups cups.socket cups.path cups-browsed; fi

# ---- NFS ----
if $NEED_NFS; then
  if [[ -f /etc/exports ]] && grep -q no_root_squash /etc/exports; then
    backup_file /etc/exports; sed -i 's/no_root_squash/root_squash/g' /etc/exports; run exportfs -ra
    log "NFS: no_root_squash -> root_squash"
  fi
else
  svc_disable nfs-server nfs-kernel-server rpcbind rpcbind.socket
  safe_purge nfs-kernel-server; safe_purge rpcbind
fi

# ---- Network printer/device discovery (not needed without printing) ----
$NEED_PRINT || svc_disable avahi-daemon.socket avahi-daemon

# ---- Other servers you answered about up front ----
for e in "${SERVER_REMOVE[@]}"; do
  IFS='|' read -r pkg unit desc <<<"$e"
  svc_disable "$unit"
  [[ $desc == *"(service only)"* ]] || safe_purge "$pkg"
done
for e in "${SERVER_KEEP[@]}"; do IFS='|' read -r pkg unit desc <<<"$e"; review "Kept (README-required): $desc ($pkg) — check its config by hand."; done

# ---- README-critical services must be ENABLED and RUNNING (attackers like to stop/mask them) ----
section "Critical services: enabled & running"
ensure_running() { # NAME UNIT... — prefers whichever unit is already enabled
  local name=$1 u pick=""; shift
  for u in "$@"; do unit_exists "$u" && systemctl is-enabled --quiet "$u" 2>/dev/null && { pick=$u; break; }; done
  if [[ -z $pick ]]; then for u in "$@"; do unit_exists "$u" && { pick=$u; break; }; done; fi
  if [[ -z $pick ]]; then warn "README needs $name, but none of these is installed: $* — install it!"; return 1; fi
  systemctl unmask "$pick" >>"$LOG" 2>&1
  systemctl enable "$pick" >>"$LOG" 2>&1      # (static units can't be "enabled" — that's fine)
  systemctl start "$pick" >>"$LOG" 2>&1
  if systemctl is-active --quiet "$pick"; then log "Critical service $name ($pick) is enabled and running"
  else warn "Critical service $name ($pick) would not start — check: systemctl status $pick"; fi
}
for g in "${CRIT_GROUPS[@]}"; do read -ra us <<<"${g#*|}"; ensure_running "${g%%|*}" "${us[@]}"; done
$NEED_SAMBA && unit_exists nmbd && ensure_running "Samba NetBIOS" nmbd
$NEED_MAIL && unit_exists dovecot && ensure_running "Dovecot" dovecot
((${#CRIT_GROUPS[@]})) || info "No critical services were listed."

#--------------------------- PROHIBITED SOFTWARE ------------------------------
section "Prohibited & hacking tools"
# Classic CyberPatriot point-scorers. safe_purge refuses anything that would drag a
# desktop/critical package with it, and pin_orphans keeps a later autoremove harmless.
PROHIBITED=(
  john john-data johnny hashcat hydra hydra-gtk medusa ncrack
  aircrack-ng kismet reaver wifite cowpatty pixiewps bully fern-wifi-cracker
  fcrackzip lcrack rarcrack sipcrack pdfcrack
  nmap zenmap masscan nikto wpscan dirb gobuster dmitry
  ophcrack ophcrack-cli chntpw crunch cupp cewl
  hping3 nbtscan ettercap-common ettercap-graphical ettercap-text-only dsniff
  netcat netcat-traditional netcat-openbsd ncat socat sbd cryptcat pnetcat
  nc6 netcat6 sock socket
  metasploit-framework armitage sqlmap beef-xss set
  wireshark wireshark-qt tshark tcpdump ngrep
  gnome-games aisleriot gnome-mahjongg gnome-mines gnome-sudoku gnome-chess five-or-more four-in-a-row
  gnome-2048 gnome-klotski gnome-nibbles gnome-robots gnome-taquin gnome-tetravex hitori iagno
  lightsoff quadrapassel swell-foop tali
  freeciv freeciv-client-gtk wesnoth wesnoth-core
  hunt zaproxy burpsuite
  nis talk talkd ytalk finger fingerd rsh-client rsh-server rsh-redone-client rsh-redone-server
  rlogin rusersd rwhod rexec rstat
  prelink
  p0f yersinia macchanger driftnet netdiscover arp-scan sslstrip mitmproxy bettercap responder
  wapiti skipfish zmap amap thc-ipv6 unicornscan wfuzz ffuf feroxbuster sqlninja
  steghide stegosuite outguess tor torbrowser-launcher proxychains proxychains4
  teamviewer anydesk rustdesk
  minetest supertux supertuxkart 0ad pingus frozen-bubble kpat ksudoku kmines gnuchess xboard openttd
  nethack-console bsdgames pacman4console moon-buggy ninvaders greed freedoom chromium-bsu extremetuxracer
  neverball neverputt armagetronad openarena hedgewars warzone2100 lincity-ng
  deluge deluged transmission-cli transmission-daemon transmission-gtk qbittorrent rtorrent ktorrent amule
  frostwire vuze
)
PROHIBITED+=(logkeys xspy lkl uberkey THC-Keylogger)
for p in "${PROHIBITED[@]}"; do safe_purge "$p"; done
for app in "${FLATPAK_REMOVE[@]}"; do
  flatpak uninstall --system -y --noninteractive "$app" >>"$LOG" 2>&1 && log "Removed Flatpak app $app" || warn "Could not remove Flatpak app $app"
done
for sn in "${SNAP_REMOVE[@]}"; do snap remove --purge "$sn" >>"$LOG" 2>&1 && log "Removed snap $sn" || warn "Could not remove snap $sn"; done
{ echo "--- Per-user Flatpak apps (remove prohibited ones as that user: flatpak uninstall --user APP) ---"
  if command -v flatpak >/dev/null; then for u in $(human_users); do
    runuser -u "$u" -- flatpak list --user --app --columns=application 2>/dev/null | sed "s/^/   $u: /"; done; fi
  echo; } >>"$REPORT"
review "[!] If README lists a network tool (nmap/wireshark/tcpdump) or a game as REQUIRED, reinstall it; this script removed all of them."

# Leftover nc binary that no package owns (after the netcat packages are gone)
if [[ -L /usr/bin/nc || -e /usr/bin/nc ]] && ! pkg_owned /usr/bin/nc && ! is_installed netcat-openbsd && ! is_installed netcat-traditional; then
  quarantine /usr/bin/nc && log "Quarantined leftover /usr/bin/nc (no package owns it)"
fi

# Telnet server (never leave a telnet *server*; client is usually harmless)
if ! $NEED_TELNET; then
  svc_disable inetutils-telnetd telnetd
  for p in telnetd inetutils-telnetd telnetd-ssl; do safe_purge "$p"; done
fi
# inetd super-servers (unless a service that needs them is active)
if ! $NEED_TELNET && ! $NEED_FTP; then
  svc_disable openbsd-inetd xinetd inetutils-inetd
  for p in openbsd-inetd xinetd inetutils-inetd rlinetd; do safe_purge "$p"; done
fi
# Remote desktop if not required
if ! $NEED_VNC; then
  svc_disable x11vnc xrdp vnc4server tightvncserver
  for p in x11vnc vnc4server tightvncserver tigervnc-standalone-server tigervnc-scraping-server xrdp; do safe_purge "$p"; done
fi

#------------------------- UNWANTED / SPY SOFTWARE ----------------------------
section "Privacy / telemetry / backdoors"
svc_disable apport whoopsie kerneloops
for p in popularity-contest apport whoopsie kerneloops; do safe_purge "$p"; done
# Zeitgeist activity logger
for p in zeitgeist zeitgeist-core zeitgeist-datahub; do safe_purge "$p"; done
log "Usage/crash reporters (popularity-contest etc.) and activity loggers removed or disabled"
pin_orphans

#--------------------------- STARTUP PERSISTENCE ------------------------------
section "Startup items, cron & services audit"
build_pkgfiles
# rc.local
if [[ -f /etc/rc.local ]] && grep -qvE '^[[:space:]]*(#|exit 0|$)' /etc/rc.local; then
  { echo "--- /etc/rc.local commands (run as root at every boot) ---"; grep -vE '^[[:space:]]*(#|$)' /etc/rc.local | sed 's/^/   /'; echo; } >>"$REPORT"
  warn "/etc/rc.local runs these commands as root at every boot:"
  grep -vE '^[[:space:]]*(#|$)' /etc/rc.local | sed 's/^/        /'
  if ask_yn "   Neutralize /etc/rc.local? (yes unless the README needs these commands)"; then
    backup_file /etc/rc.local; cp -a /etc/rc.local "$QUAR/etc_rc.local" 2>/dev/null
    printf '#!/bin/sh -e\nexit 0\n' >/etc/rc.local; chmod 755 /etc/rc.local; log "Neutralized /etc/rc.local (copy in $QUAR)"
  fi
fi
# crontabs — never blindly wiped: shown for review, obvious reverse shells flagged
{ echo "--- Scheduled tasks (cron/at). Look for curl|wget|bash -i|nc|/dev/tcp|base64 ---"
  for d in /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
    [[ -d $d ]] && grep -rslE 'curl|wget|/dev/tcp|nc |ncat|bash -i|base64|python -c|perl -e' "$d" 2>/dev/null | sed "s/^/   suspicious: /"
  done
  echo "  /etc/crontab:"; grep -vE '^[[:space:]]*(#|$)' /etc/crontab 2>/dev/null | sed 's/^/     /'
  for u in root $(human_users); do
    c=$(crontab -l -u "$u" 2>/dev/null | grep -vE '^[[:space:]]*(#|$)')
    [[ -n $c ]] && echo "  crontab ($u):" && sed 's/^/     /' <<<"$c"
  done
  echo; } >>"$REPORT"

# Prints why a command looks malicious (line 1) plus "FILE:<path>" for each unpackaged
# file it runs. No output = looks fine. Used for cron, systemd and autostart entries.
cron_job_problem() { # COMMAND [extra-reason]
  local cmd=$1 why=${2:-} p files=()
  grep -qEi -- "$SUSP" <<<"$cmd" && why+="${why:+; }reverse-shell/downloader pattern"
  grep -qEi -- '(python[0-9.]*|perl|ruby|php|node|bash|sh)[[:space:]]+[^-/[:space:]][^[:space:]]*\.(py|pl|rb|php|js|sh)([[:space:]]|$)' <<<"$cmd" \
    && why+="${why:+; }runs a script by relative path"
  while IFS= read -r p; do
    [[ -f $p ]] || continue
    pkg_owned "$p" && continue
    is_protected "$p" && continue
    why+="${why:+; }runs $p (no package installed it)"; files+=("$p")
  done < <(grep -oE '/[A-Za-z0-9._+@/-]+' <<<"$cmd" | sort -u)
  [[ -z $why ]] && return 0
  printf '%s\n' "$why"; ((${#files[@]})) && printf 'FILE:%s\n' "${files[@]}"
  return 0
}
# stop + quarantine the files a bad job runs (like: pkill -f kneelB4zod.py; rm kneelB4zod.py)
disable_job_files() { local f; for f in "$@"; do kill_running "$f"; quarantine "$f" && log "Stopped & quarantined $f"; done; }

section "Cron jobs (e.g. '* * * * * root python3 /usr/share/zod/kneelB4zod.py')"
CRON_HITS=0
for cf in /etc/crontab /etc/cron.d/*; do
  [[ -f $cf ]] || continue
  is_protected "$cf" && continue
  note=""; [[ $cf != /etc/crontab ]] && ! pkg_owned "$cf" && note="cron file not installed by any package"
  mapfile -t CL <"$cf"
  for ln in "${CL[@]}"; do
    t=${ln#"${ln%%[![:space:]]*}"}
    [[ -z $t || $t == \#* || $t =~ ^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*= ]] && continue
    read -r f1 f2 f3 f4 f5 f6 rest <<<"$t"
    if [[ $f1 == @* ]]; then cmd="$f3 $f4 $f5 $f6 $rest"; else cmd=$rest; fi
    out=$(cron_job_problem "$cmd" "$note"); [[ -z $out ]] && continue
    why=$(head -1 <<<"$out"); mapfile -t jf < <(sed -n 's/^FILE://p' <<<"$out")
    ((CRON_HITS++))
    echo "${Y}   $cf:${N} $t"; echo "      why: $why"
    review "[!] Suspicious cron job in $cf ($why): $t"
    if ask_yn "   Disable this cron job${jf:+ and stop/quarantine ${jf[*]}}?"; then
      backup_file "$cf"; comment_line "$cf" "$ln" "disabled by CP script"
      disable_job_files "${jf[@]}"; log "Disabled cron job in $cf: $t"
    fi
  done
done
# Per-user crontabs (crontab -u USER -l)
for ct in /var/spool/cron/crontabs/*; do
  [[ -f $ct ]] || continue
  cu=$(basename "$ct")
  if ! id "$cu" &>/dev/null; then quarantine "$ct" && warn "Quarantined crontab of non-existent user '$cu'"; continue; fi
  tmpct=$(mktemp); crontab -l -u "$cu" >"$tmpct" 2>/dev/null; changed=0
  mapfile -t CL <"$tmpct"
  for ln in "${CL[@]}"; do
    t=${ln#"${ln%%[![:space:]]*}"}
    [[ -z $t || $t == \#* || $t =~ ^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*= ]] && continue
    read -r f1 f2 f3 f4 f5 rest <<<"$t"
    if [[ $f1 == @* ]]; then cmd="$f2 $f3 $f4 $f5 $rest"; else cmd=$rest; fi
    out=$(cron_job_problem "$cmd"); [[ -z $out ]] && continue
    why=$(head -1 <<<"$out"); mapfile -t jf < <(sed -n 's/^FILE://p' <<<"$out")
    ((CRON_HITS++))
    echo "${Y}   crontab of $cu:${N} $t"; echo "      why: $why"
    review "[!] Suspicious job in $cu's crontab ($why): $t"
    if ask_yn "   Disable this cron job${jf:+ and stop/quarantine ${jf[*]}}?"; then
      comment_line "$tmpct" "$ln" "disabled by CP script"; changed=1; disable_job_files "${jf[@]}"
    fi
  done
  if ((changed)); then
    cp -a "$ct" "$BACKUP/crontab.$cu" 2>/dev/null
    crontab -u "$cu" "$tmpct" >>"$LOG" 2>&1 && log "Updated $cu's crontab (bad jobs commented out)"
  fi
  rm -f "$tmpct"
done
((CRON_HITS)) || info "No suspicious cron jobs found."
# Scripts dropped into the cron.daily/hourly/... folders
CRONDIR_FILES=()
for d in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.yearly; do
  for f in "$d"/*; do
    [[ -f $f ]] || continue; is_protected "$f" && continue
    # unpackaged script, or a package's script that now contains a reverse shell (modified!)
    if ! pkg_owned "$f" || grep -qEi -- "$REVSH" "$f" 2>/dev/null; then CRONDIR_FILES+=("$f"); fi
  done
done
quarantine_files "scripts in /etc/cron.hourly|daily|weekly|monthly that no package installed (or that contain a reverse shell)" "${CRONDIR_FILES[@]}"
{ echo "--- at jobs (atq) ---"; atq 2>/dev/null | sed 's/^/   /'
  echo "--- /etc/anacrontab ---"; grep -vE '^[[:space:]]*(#|$)' /etc/anacrontab 2>/dev/null | sed 's/^/   /'; echo; } >>"$REPORT"

section "/etc/init.d boot scripts"
# Every normal init script comes from a package — anything else is suspect.
INITD_HITS=0
for f in /etc/init.d/*; do
  [[ -f $f ]] || continue
  case $(basename "$f") in README|skeleton|.depend.*) continue ;; esac
  pkg_owned "$f" && continue; is_protected "$f" && continue
  ((INITD_HITS++)); n=$(basename "$f")
  warn "Init script not installed by any package: $f"
  grep -vE '^[[:space:]]*(#|$)' "$f" | head -8 | sed 's/^/        /'
  if ask_yn "   Disable & quarantine $f ? (no if the README needs it)"; then
    systemctl disable --now "$n" >>"$LOG" 2>&1; run update-rc.d -f "$n" remove
    quarantine "$f" && log "Quarantined init script $f"
  fi
done
((INITD_HITS)) || info "No unpackaged scripts in /etc/init.d."

section "Desktop autostart entries"
AUTO_HITS=0
for f in /etc/xdg/autostart/*.desktop /home/*/.config/autostart/*.desktop /root/.config/autostart/*.desktop; do
  [[ -f $f ]] || continue
  pkg_owned "$f" && continue; is_protected "$f" && continue
  ex=$(grep -m1 -E '^[[:space:]]*Exec=' "$f" | cut -d= -f2-)
  note=""; [[ $f == /etc/* ]] && note="system autostart entry not installed by any package"
  out=$(cron_job_problem "$ex" "$note"); [[ -z $out ]] && continue
  why=$(head -1 <<<"$out"); mapfile -t jf < <(sed -n 's/^FILE://p' <<<"$out")
  ((AUTO_HITS++))
  warn "Suspicious autostart entry $f ($why)"; echo "        Exec=$ex"
  review "[!] Autostart entry $f: Exec=$ex ($why)"
  if ask_yn "   Quarantine this autostart entry${jf:+ and stop/quarantine ${jf[*]}}?"; then
    disable_job_files "${jf[@]}"; quarantine "$f" && log "Quarantined autostart entry $f"
  fi
done
((AUTO_HITS)) || info "No suspicious autostart entries."
run systemctl daemon-reload
# cron/at access
( cd /etc || exit; rm -f cron.deny at.deny; printf 'root\n' >cron.allow; printf 'root\n' >at.allow; chown root:root cron.allow at.allow; chmod 600 cron.allow at.allow )
log "cron/at restricted to root"
# Lock down ownership & permissions on all cron/at locations
for f in /etc/crontab /etc/cron.allow /etc/at.allow; do [[ -e $f ]] && { chown root:root "$f"; chmod 600 "$f"; }; done
for d in /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.yearly; do
  [[ -d $d ]] && { chown root:root "$d"; chmod 700 "$d"; }
done
[[ -d /var/spool/cron/crontabs ]] && { chown root:crontab /var/spool/cron/crontabs 2>/dev/null; chmod 1730 /var/spool/cron/crontabs 2>/dev/null; }
[[ -d /etc/cron.d ]] && find /etc/cron.d -type f -exec chmod 600 {} \; 2>/dev/null
log "cron file/directory ownership & permissions hardened (root-owned, not world-accessible)"
# Enabled services that listen but aren't required — just list them
{ echo "--- Enabled services (disable anything you don't recognize) ---"; systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null | awk '{print "   " $1}'; echo
  echo "--- Listening sockets (match each to an authorized service) ---"; (ss -tulpnH 2>/dev/null || netstat -tulpn 2>/dev/null) | sed 's/^/   /'; echo; } >>"$REPORT"

#--------------------- SSH KEYS & BACKDOOR PERSISTENCE ------------------------
section "SSH keys & persistence backdoors"
# Attackers' #1 Linux persistence trick is dropping their public key into a
# user's authorized_keys. Every planted key is usually a scored vulnerability.

mapfile -t AKFILES < <(find /home /root /etc/ssh -xdev \( -name authorized_keys -o -name authorized_keys2 \) -type f 2>/dev/null)
if ((${#AKFILES[@]})); then
  review "--- SSH authorized_keys found (each line = someone who can log in with NO password) ---"
  for akf in "${AKFILES[@]}"; do
    nkeys=$(grep -cvE '^[[:space:]]*(#|$)' "$akf" 2>/dev/null)
    ((nkeys)) || continue
    owner=$(stat -c '%U' "$akf" 2>/dev/null)
    echo "${Y}   $akf (owner: $owner, $nkeys key(s))${N}"
    review "  $akf  (owner=$owner, $nkeys key)"
    while read -r keyline; do
      [[ -z $keyline || $keyline == \#* ]] && continue
      review "      key: ...${keyline: -50}"
    done <"$akf"
    if ask_yn "   Remove ALL SSH keys from $akf? (do this unless YOU put a key there)"; then
      backup_file "$akf"; cp -a "$akf" "$QUAR/$(echo "$akf" | tr / _)" 2>/dev/null; : >"$akf"
      log "Cleared planted SSH keys from $akf (backup in $QUAR)"
    else review "    (kept $akf — verify these keys are yours)"; fi
  done
  review ""
else info "No authorized_keys files found."; fi

# .ssh directory / key permissions
for d in /home/*/.ssh /root/.ssh; do
  [[ -d $d ]] || continue; u=$(stat -c '%U' "$(dirname "$d")")
  chown -R "$u": "$d" 2>/dev/null; chmod 700 "$d" 2>/dev/null
  chmod 600 "$d"/authorized_keys* "$d"/id_* 2>/dev/null; chmod 644 "$d"/*.pub 2>/dev/null
done
info "Tightened ~/.ssh permissions (700 dir, 600 keys)"

# ld.so.preload — classic userland-rootkit hook
if [[ -s /etc/ld.so.preload ]]; then
  backup_file /etc/ld.so.preload
  review "[!] /etc/ld.so.preload is NOT empty (rootkit hook?): $(tr '\n' ' ' </etc/ld.so.preload)"
  if grep -qvE '^[[:space:]]*(#|$)' /etc/ld.so.preload; then
    warn "/etc/ld.so.preload contains entries (often a rootkit). Saved a backup; review it in REVIEW-ME.txt."
    sed 's/^/        /' /etc/ld.so.preload
    grep -qE '/tmp/|/dev/shm/|/var/tmp/|/home/' /etc/ld.so.preload && echo "        ^ points into a writable folder — almost certainly a rootkit"
    if ask_yn "   Empty /etc/ld.so.preload? (yes unless the README needs it — normally it doesn't exist)"; then
      cp -a /etc/ld.so.preload "$QUAR/ld.so.preload"; : >/etc/ld.so.preload
      log "Emptied /etc/ld.so.preload (copy in $QUAR)"
    fi
  fi
fi

# systemd persistence (the modern replacement for evil cron jobs)
section "systemd units & timers"
{ echo "--- Enabled systemd TIMERS (modern persistence — verify each) ---"
  systemctl list-timers --all --no-legend 2>/dev/null | sed 's/^/   /'
  echo "--- Unit files under /etc/systemd/system (admin-added — scrutinize) ---"
  find /etc/systemd/system -maxdepth 2 \( -name '*.service' -o -name '*.timer' \) 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"
declare -A UNITC=() SEENDIR=()
for base in /etc/systemd/system /run/systemd/system /lib/systemd/system /usr/lib/systemd/system; do
  [[ -d $base ]] || continue
  rb=$(readlink -f "$base"); [[ -n ${SEENDIR[$rb]:-} ]] && continue; SEENDIR[$rb]=1   # /lib == /usr/lib on Debian 12
  while IFS= read -r unit; do
    ru=$(readlink -f "$unit")
    if pkg_owned "$ru"; then   # package units may mention /tmp etc. — only flag a real reverse shell
      grep -qEi -- "^[[:space:]]*Exec[A-Za-z]*=.*($REVSH)" "$ru" && UNITC[$ru]="a PACKAGE unit that now runs a reverse shell (modified!)"
    else UNITC[$ru]="runs a reverse-shell/downloader command"; fi
  done < <(grep -rslEi "^[[:space:]]*Exec[A-Za-z]*=.*($SUSP)" "$rb" 2>/dev/null)
done
for unit in /etc/systemd/system/*.{service,timer,socket,path} /lib/systemd/system/*.{service,timer} \
            /home/*/.config/systemd/user/*.{service,timer} /root/.config/systemd/user/*.{service,timer}; do
  [[ -f $unit && ! -L $unit ]] || continue
  ru=$(readlink -f "$unit"); pkg_owned "$ru" && continue
  [[ -n ${UNITC[$ru]:-} ]] || UNITC[$ru]="unit file not installed by any package"
done
for unit in "${!UNITC[@]}"; do
  is_protected "$unit" && continue
  uname=$(basename "$unit")
  ex=$(grep -hE '^[[:space:]]*(Exec[A-Za-z]*|OnCalendar|OnBootSec|OnUnitActiveSec|Unit)=' "$unit" 2>/dev/null | head -4)
  out=$(cron_job_problem "$ex"); jf=(); mapfile -t jf < <(sed -n 's/^FILE://p' <<<"$out")
  warn "systemd unit $unit: ${UNITC[$unit]}"
  sed 's/^/        /' <<<"$ex"
  review "[!] Suspicious systemd unit: $unit (${UNITC[$unit]})"; review "$(sed 's/^/      /' <<<"$ex")"
  if ask_yn "   Disable & quarantine $uname${jf:+ and stop/quarantine ${jf[*]}}? (no if the README needs it)"; then
    case $unit in /home/*|/root/*) ;; *) systemctl disable --now "$uname" >>"$LOG" 2>&1 ;; esac
    disable_job_files "${jf[@]}"
    quarantine "$unit" && log "Quarantined systemd unit $unit"
  fi
done
run systemctl daemon-reload

# Shell / profile persistence
section "Login-script persistence"
RC_FILES=(/etc/profile /etc/bash.bashrc /etc/environment)
for f in /etc/profile.d/* /etc/update-motd.d/*; do [[ -f $f ]] && RC_FILES+=("$f"); done
for h in /root /home/*; do
  for n in .bashrc .bash_profile .bash_login .profile .bash_logout .bash_aliases .zshrc .xprofile .xsessionrc; do
    [[ -f "$h/$n" ]] && RC_FILES+=("$h/$n")
  done
done
HITS=0
for f in "${RC_FILES[@]}"; do
  is_protected "$f" && continue
  mapfile -t hl < <(grep -nEi -- "$SUSP|^[[:space:]]*alias[[:space:]]+(sudo|su|passwd|ls|cd|cat|apt|apt-get|ufw|systemctl|ps|ss|netstat)=" "$f" 2>/dev/null)
  for h in "${hl[@]}"; do
    n=${h%%:*}; l=${h#*:}
    [[ $l =~ ^[[:space:]]*# ]] && continue
    # "alias ls='ls --color=auto'" is Debian's default — an alias that just runs itself is fine
    if ! grep -qEi -- "$SUSP" <<<"$l" && [[ $l =~ alias[[:space:]]+([A-Za-z-]+)=[\'\"]?([^[:space:]\'\"]*) ]] \
       && [[ ${BASH_REMATCH[2]} == "${BASH_REMATCH[1]}" ]]; then continue; fi
    ((HITS++))
    warn "Suspicious line in startup file $f (line $n): $l"
    if ask_yn "   Comment out that line?"; then
      backup_file "$f"; sed -i "${n}s/^/# disabled by CP script: /" "$f"; log "Commented out line $n of $f"
    fi
  done
done
((HITS==0)) && info "No reverse-shell/downloader lines or command-hijacking aliases in login scripts."

# PATH sanity: a PATH containing '.' or an empty entry runs programs from the current folder.
# (The files are only READ — running them could execute a planted backdoor as root.)
PATHRE="PATH=[\"']?(\\.|:)|::|:\\.(:|[\"']|[[:space:]]|\$)|:[\"']?([[:space:]]|\$)"
while IFS= read -r hit; do review "[!] PATH contains '.' or an empty entry (fix it): $hit"; done < <(
  grep -HnE '^[^#]*PATH=' /etc/environment /etc/profile /etc/bash.bashrc /etc/profile.d/* /root/.bashrc /root/.profile /root/.bash_profile 2>/dev/null \
  | grep -E -- "$PATHRE")

#---------------------- BACKDOOR PROCESSES & PORTS ----------------------------
section "Backdoor processes & listening ports"
echo "   Each hit is shown with the reason. Only say yes to things you recognize as malicious"
echo "   (a script from a weird folder, netcat, something listening on an odd port)."
# Like 'ss -tulnp' + 'pkill -f': finds programs/scripts no package installed that are
# running (or listening on a port), shows them, and asks before killing anything.
declare -A LISTEN=()
while IFS= read -r l; do
  la=$(awk '{print $1 " " $5}' <<<"$l")
  for pid in $(grep -oE 'pid=[0-9]+' <<<"$l" | cut -d= -f2 | sort -u); do LISTEN[$pid]+="$la, "; done
done < <(ss -tulpnH 2>/dev/null)
{ echo "--- Listening ports and the program behind each (forensics often asks about these) ---"
  for pid in "${!LISTEN[@]}"; do
    exe=$(readlink "/proc/$pid/exe" 2>/dev/null); tag=""
    [[ -n $exe ]] && ! pkg_owned "${exe% (deleted)}" && tag="   <-- NOT from any package"
    printf '   pid %-7s %-40s %s%s\n' "$pid" "${exe:-?}" "${LISTEN[$pid]%, }" "$tag"
  done; echo; } >>"$REPORT"
INTERP_RE='^(python[0-9.]*|perl[0-9.]*|ruby[0-9.]*|php[0-9.]*|node|nodejs|lua[0-9.]*|bash|sh|dash|zsh|ksh|busybox)$'
NETCAT_RE='^(nc|nc\.traditional|nc\.openbsd|netcat|ncat|socat|cryptcat|sbd)$'
NFLAG=0
for d in /proc/[0-9]*; do
  pid=${d#/proc/}
  [[ -n ${SAFE_PID[$pid]:-} ]] && continue
  ppid=$(awk '/^PPid:/{print $2}' "$d/status" 2>/dev/null)
  [[ $ppid == "$$" ]] && continue                            # this script's own helpers
  exe=$(readlink "$d/exe" 2>/dev/null) || continue          # kernel threads have no exe
  argv=(); mapfile -d '' -t argv 2>/dev/null <"$d/cmdline" || continue
  ((${#argv[@]})) || continue
  cmd="${argv[*]}"
  is_protected "$exe $cmd" && continue
  [[ $exe == /snap/* ]] && continue
  real=${exe% (deleted)}; base=$(basename "$real"); why=""; files=(); skip=0
  if [[ $exe == *" (deleted)" ]]; then
    # a package upgrade replaces a running program's file — that's normal, not malware
    if ! { [[ -f $real ]] && pkg_owned "$real"; }; then why="its program was deleted from disk while running (malware trick)"; fi
  elif [[ -f $real ]] && ! pkg_owned "$real"; then why="program not installed by any package"; files+=("$real"); fi
  if [[ $base =~ $NETCAT_RE ]]; then why+="${why:+; }netcat/socat (backdoor tool)"
  elif [[ $base =~ $INTERP_RE ]]; then
    for a in "${argv[@]:1}"; do
      [[ -z $a || $a == -* ]] && continue
      [[ $a == /* ]] || a=$(readlink -f -- "$d/cwd/$a" 2>/dev/null)
      [[ -n $a && -f $a ]] || continue
      if [[ $a == "$SELF" ]] || is_protected "$a"; then skip=1; break; fi
      pkg_owned "$a" && continue
      why+="${why:+; }runs script $a (no package installed it)"; files+=("$a")
    done
    ((skip)) && continue
    [[ -z $why && -n ${LISTEN[$pid]:-} ]] && why="shell/interpreter listening on the network"
  fi
  [[ -z $why ]] && continue
  [[ -n ${LISTEN[$pid]:-} ]] && why+="; LISTENING on ${LISTEN[$pid]%, }"
  ((NFLAG++))
  puser=$(stat -c %U "$d" 2>/dev/null)
  unit=$(sed -n 's#^0::/system\.slice/\(.*\.service\)$#\1#p' "$d/cgroup" 2>/dev/null)
  echo "${Y}   PID $pid ($puser): ${cmd:0:160}${N}"; echo "      why: $why"; [[ -n $unit ]] && echo "      started by: $unit"
  review "[!] Suspicious process PID $pid user=$puser: $cmd  ($why)${unit:+  service=$unit}"
  if ask_yn "   Kill it${files:+, quarantine ${files[*]}}${unit:+, and disable $unit}? (NO unless you're sure — the wrong kill can log you out)"; then
    [[ -n $unit ]] && systemctl disable --now "$unit" >>"$LOG" 2>&1
    kill -9 "$pid" 2>/dev/null
    disable_job_files "${files[@]}"
    log "Killed suspicious process $pid: ${cmd:0:120}"
  fi
done
((NFLAG)) || info "No suspicious processes or listening backdoors found."

#------------------------ MEDIA, ARCHIVES & TOOLS -----------------------------
section "Media, archives & unauthorized files (whole disk)"
# Searches EVERYWHERE (not just /home) and skips files a package installed, so system
# sounds/icons are never offered — only planted or downloaded files show up.
SCAN_ROOTS=(/ /home /root /opt /srv /var /tmp /usr)
PRUNE=(-path /proc -o -path /sys -o -path /dev -o -path /run -o -path /snap -o -path /var/lib/flatpak
       -o -path /var/lib/docker -o -path /var/cache -o -path /var/log -o -path /var/lib/dpkg -o -path /var/lib/apt
       -o -path /usr/lib -o -path /usr/src -o -path /root/cp-backups -o -path "$QUAR" -o -path "$OUT"
       -o -path '*/.cache' -o -path '*/.mozilla' -o -path '*/.local/share/flatpak' -o -name node_modules
       -o -name site-packages -o -name dist-packages)
# Files of a README-required website / Samba share are its content, not "prohibited media"
$NEED_WEB && PRUNE+=(-o -path /var/www -o -path /srv/www -o -path /srv/http)
if $NEED_SAMBA && command -v testparm >/dev/null; then
  while IFS= read -r sp; do [[ -d $sp && $sp != / && $sp != /home ]] && PRUNE+=(-o -path "$sp"); done \
    < <(testparm -s 2>/dev/null | awk -F' = ' '/^[[:space:]]*path = /{print $2}')
fi
fs_find() { find "${SCAN_ROOTS[@]}" -xdev \( "${PRUNE[@]}" \) -prune -o "$@" -print 2>/dev/null | sort -u; }
build_pkgfiles

MEDIA_EXT='mp3|mp4|m4a|m4b|aac|flac|ogg|oga|opus|wav|wma|aiff?|mid|midi|mov|avi|mkv|flv|wmv|mpe?g|webm|m4v|3gp|vob|gif|bmp'
mapfile -t MEDIA < <(fs_find -type f -regextype posix-extended -iregex ".*\.(${MEDIA_EXT})" | not_pkg_owned)
quarantine_files "media files (audio/video) that no package installed" "${MEDIA[@]}"

mapfile -t PICS < <(find /home /root -xdev \( -path '*/.cache' -o -path '*/.mozilla' -o -path '*/.config' -o -path '*/.local/share' \
    -o -path '*/.icons' -o -path '*/.themes' -o -path '*/.thumbnails' -o -path "$OUT" \) -prune -o \
    -type f -regextype posix-extended -iregex '.*\.(jpe?g|png|tiff?|heic|webp)' -print 2>/dev/null)
quarantine_files "picture files in home folders (only quarantine ones the README prohibits — pick [e]ach or [n]one if unsure)" "${PICS[@]}"

ARCH_RE='.*\.(zip|rar|7z|tar|tgz|tbz2?|txz|tar\.(gz|bz2|xz|zst)|deb|whl|jar|apk|exe|msi)'
mapfile -t ARCH < <(fs_find -type f -regextype posix-extended -iregex "$ARCH_RE" | not_pkg_owned)
quarantine_files "archives / installers that no package installed (tools hide in these, e.g. /usr/games/pyrdp-master.zip)" "${ARCH[@]}"

mapfile -t SYSSCRIPTS < <(find /usr/share /usr/local /usr/games /opt /var /tmp /dev/shm -xdev \
    \( -path /var/lib -o -path /var/cache -o -path /var/log -o -path /var/www -o -path /var/backups -o -path /var/mail \
       -o -name dist-packages -o -name site-packages -o -name node_modules -o -path "$QUAR" \) -prune -o \
    -type f -regextype posix-extended -iregex '.*\.(py|pl|rb|sh|elf)' -print 2>/dev/null | sort -u | not_pkg_owned \
    | grep -vEi -- "$CP_PROTECT_RE" | grep -vxF -- "$SELF")
quarantine_files "scripts in system folders that no package installed (e.g. /usr/share/zod/kneelB4zod.py)" "${SYSSCRIPTS[@]}"

mapfile -t UNPKG < <(find /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /usr/games /usr/local/games /opt -xdev -maxdepth 3 \
    -type f -perm /111 2>/dev/null | sort -u | not_pkg_owned | grep -vEi -- "$CP_PROTECT_RE")
quarantine_files "programs that no package installed (hacking tools copied in by hand, renamed netcat, ...)" "${UNPKG[@]}"

{ echo "--- Scripts in home folders (your own scripts are normal; look for hacking tools / backdoors) ---"
  find /home /root -xdev \( -path '*/.cache' -o -path '*/.local/lib' -o -path "$OUT" \) -prune -o -type f \
    -regextype posix-extended -iregex '.*\.(py|pl|rb|sh)' -print 2>/dev/null | grep -vxF -- "$SELF" | head -80 | sed 's/^/   /'
  echo "--- pip-installed Python packages (hacking libraries sometimes hide here) ---"
  ls -1 /usr/local/lib/python3*/dist-packages 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"

# Files with no owner (deleted-user leftovers) and world-writable files
{ echo "--- Files owned by no user/group (orphaned — often from deleted attackers) ---"
  find / -xdev \( -nouser -o -nogroup \) -not -path '/proc/*' 2>/dev/null | head -60 | sed 's/^/   /'
  echo "--- World-writable files (chmod o-w the ones that shouldn't be) ---"
  find / -xdev -type f -perm -0002 -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null | head -60 | sed 's/^/   /'
  echo "--- World-writable directories WITHOUT sticky bit (should have it: chmod +t) ---"
  find / -xdev -type d -perm -0002 ! -perm -1000 -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null | head -40 | sed 's/^/   /'
  echo "--- All SUID/SGID binaries (compare to a clean system) ---"
  find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -not -path '/proc/*' 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"

#------------------------------- APPARMOR -------------------------------------
section "AppArmor (mandatory access control)"
if [[ ${APT_OK:-true} == true ]]; then apt_install apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra; fi
if command -v aa-enforce >/dev/null 2>&1; then
  run systemctl enable --now apparmor
  # Don't force a too-strict profile onto a service the README needs, and don't
  # re-enable profiles Debian deliberately ships disabled.
  AA_SKIP='^$|libreoffice|thunderbird|firefox|chromium|evince|totem|pidgin|irssi|linphone|transmission'   # desktop apps
  $NEED_SSH   && AA_SKIP+='|sshd'
  $NEED_FTP   && AA_SKIP+='|ftpd'
  $NEED_SAMBA && AA_SKIP+='|smbd|nmbd|samba|winbind'
  $NEED_WEB   && AA_SKIP+='|apache|httpd|nginx|php|lighttpd'
  $NEED_MYSQL && AA_SKIP+='|mysql|mariadb'
  $NEED_PGSQL && AA_SKIP+='|postgres'
  $NEED_DNS   && AA_SKIP+='|named|bind'
  $NEED_MAIL  && AA_SKIP+='|dovecot|postfix|exim|sendmail'
  $NEED_PRINT && AA_SKIP+='|cups'
  $NEED_NFS   && AA_SKIP+='|nfs|rpc|mountd'
  enf=0; AA_SKIPPED=()
  for prof in /etc/apparmor.d/*; do
    [[ -f $prof ]] || continue
    b=$(basename "$prof")
    case "$b" in README|*.dpkg-*|*.disabled-by-cp) continue ;; esac
    [[ -e /etc/apparmor.d/disable/$b ]] && continue
    if grep -qEi -- "$AA_SKIP" <<<"$b"; then AA_SKIPPED+=("$b"); continue; fi
    aa-enforce "$prof" >>"$LOG" 2>&1 && ((enf++))
  done
  log "AppArmor enabled; set $enf profile(s) to enforce mode"
  ((${#AA_SKIPPED[@]})) && info "Left as-is (their service is required): ${AA_SKIPPED[*]}"
  { echo "--- AppArmor status ---"; aa-status 2>/dev/null | head -20 | sed 's/^/   /'; echo; } >>"$REPORT"
else warn "AppArmor tools unavailable (offline?) — enable manually: sudo apt install apparmor-utils && sudo systemctl enable --now apparmor"; fi

#---------------------- CIS-STYLE CONFIG HARDENING ----------------------------
section "Extra config hardening (CIS-style)"
run systemctl mask ctrl-alt-del.target
run systemctl mask debug-shell.service
run systemctl daemon-reload
log "Ctrl-Alt-Del reboot and systemd debug-shell disabled"

# Account inactivity: lock accounts 30 days after password expiry
useradd -D -f 30 >>"$LOG" 2>&1
if grep -qE '^INACTIVE=' /etc/default/useradd; then sed -i 's/^INACTIVE=.*/INACTIVE=30/' /etc/default/useradd; else echo 'INACTIVE=30' >>/etc/default/useradd; fi
for u in "${AUTH_ALL[@]}"; do id "$u" &>/dev/null && is_human "$u" && chage --inactive 30 "$u" >>"$LOG" 2>&1; done
log "Inactive-account lock set to 30 days"

# Blacklist uncommon/unused filesystem & protocol modules (attack surface)
cat >/etc/modprobe.d/cp-hardening.conf <<'EOF'
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install udf /bin/true
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
log "Blacklisted unused filesystem/network modules (cramfs, hfs, dccp, sctp, ...)"
if ask_yn "Also disable USB storage (blocks USB flash drives — safe in a contest VM)?"; then
  echo 'install usb-storage /bin/true' >>/etc/modprobe.d/cp-hardening.conf
  log "USB storage module disabled"
fi

# Stricter default umask for interactive shells too (not just login.defs)
echo 'umask 027' >/etc/profile.d/99-cp-umask.sh; chmod 644 /etc/profile.d/99-cp-umask.sh

# passwd / group database integrity (read-only report)
{ echo "--- passwd/group integrity (pwck -r / grpck -r) — investigate anything listed ---"
  pwck -r 2>&1 | sed 's/^/   /'; grpck -r 2>&1 | sed 's/^/   /'; echo; } >>"$REPORT"

{ echo "--- System accounts with a real login shell (should usually be nologin/false) ---"
  awk -F: -v min="$UID_MIN" '$3>0 && $3<min && $7 !~ /(nologin|false|sync)$/ {print "   " $1 "  (uid " $3 ", shell " $7 ")"}' /etc/passwd
  echo; } >>"$REPORT"

#--------------------------- CORE FILE PERMISSIONS ----------------------------
section "Core file permissions"
fix_perm() { local m=$1 own=$2 f=$3; [[ -e $f ]] || return; chown "$own" "$f" 2>/dev/null; chmod "$m" "$f" 2>/dev/null; }
fix_perm 644 root:root  /etc/passwd
fix_perm 644 root:root  /etc/group
fix_perm 640 root:shadow /etc/shadow
fix_perm 640 root:shadow /etc/gshadow
fix_perm 644 root:root  /etc/hosts
fix_perm 644 root:root  /etc/hostname
fix_perm 644 root:root  /etc/os-release
fix_perm 600 root:root  /boot/grub/grub.cfg
fix_perm 600 root:root  /etc/crontab
fix_perm 644 root:root  /etc/fstab
fix_perm 1777 root:root /tmp
fix_perm 1777 root:root /var/tmp
chmod 600 /etc/passwd- /etc/group- 2>/dev/null
chmod 600 /etc/shadow- /etc/gshadow- 2>/dev/null
[[ -f /etc/sudoers ]] && chmod 440 /etc/sudoers 2>/dev/null
[[ -d /etc/cron.d ]] && chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly 2>/dev/null
# Home directories shouldn't be world-readable
for d in /home/*; do
  [[ -d $d ]] || continue; u=$(basename "$d")
  id "$u" &>/dev/null && { chmod 750 "$d" 2>/dev/null; chown "$u": "$d" 2>/dev/null; }
done
log "Permissions set on passwd/shadow/group/sudoers/grub/crontab and home directories"
# default umask
if grep -qE '^[[:space:]]*UMASK' /etc/login.defs; then sed -i -E 's/^[[:space:]]*UMASK.*/UMASK\t\t027/' /etc/login.defs; else set_conf /etc/login.defs UMASK 027 $'\t'; fi
grep -qE '^[[:space:]]*session[[:space:]]+optional[[:space:]]+pam_umask\.so' /etc/pam.d/common-session \
  || echo 'session optional pam_umask.so' >>/etc/pam.d/common-session

#---------------------- ADDITIONAL HARDENING (point-earners) ------------------
section "SUID backdoors, weak hashes, rhosts, world-writable"

# 1) SUID/SGID on a shell, interpreter or core tool = instant-root backdoor.
#    Symlinks/alternatives are resolved, so e.g. /usr/bin/awk -> mawk is checked too,
#    and each real file is only handled once (Debian 12 has merged /bin -> /usr/bin).
NEVER_SUID=(
  /bin/bash /usr/bin/bash /bin/sh /bin/dash /usr/bin/dash /bin/zsh /usr/bin/zsh /usr/bin/ksh
  /usr/bin/vi /usr/bin/vim /usr/bin/vim.basic /usr/bin/vim.tiny /bin/nano /usr/bin/nano /usr/bin/emacs
  /usr/bin/less /usr/bin/more /bin/more /usr/bin/man /usr/bin/pico
  /usr/bin/awk /usr/bin/gawk /usr/bin/mawk /usr/bin/sed
  /usr/bin/perl /usr/bin/python2 /usr/bin/python3 /usr/bin/python /usr/bin/ruby /usr/bin/php /usr/bin/node /usr/bin/tclsh
  /usr/bin/find /bin/cp /usr/bin/cp /bin/mv /usr/bin/mv /bin/tar /usr/bin/tar /usr/bin/dd /bin/dd
  /usr/bin/env /usr/bin/xargs /usr/bin/ftp /usr/bin/scp /usr/bin/rsync /usr/bin/ed /usr/bin/ex
  /usr/bin/nmap /usr/bin/tcpdump /usr/bin/ncat /usr/bin/nc /bin/nc /usr/bin/socat
  /usr/bin/wget /usr/bin/curl /usr/bin/base64 /usr/bin/gdb /usr/bin/make /usr/bin/git
  /usr/bin/bzip2 /usr/bin/gzip /usr/bin/zip /usr/bin/xterm /usr/bin/lua5.1 /usr/bin/lua5.2 /usr/bin/lua5.3 /usr/bin/lua5.4
)
declare -A SEEN_SUID=()
stripped=0
for f in "${NEVER_SUID[@]}"; do
  [[ -e $f ]] || continue
  rf=$(readlink -f -- "$f") || continue
  [[ -f $rf && -z ${SEEN_SUID[$rf]:-} ]] || continue
  SEEN_SUID[$rf]=1
  m=$(stat -c '%A' "$rf" 2>/dev/null)
  if [[ $m == ???s* || $m == ??????s* ]]; then
    review "[!] SUID/SGID removed from $rf (was $(stat -c '%a' "$rf"))"
    chmod u-s,g-s "$rf" 2>/dev/null && { warn "Removed SUID/SGID from $rf (setuid shell/tool = root backdoor)"; ((stripped++)); }
  fi
done
((stripped)) && log "Stripped SUID/SGID from $stripped shell/interpreter/tool binary(ies)" || info "No backdoor SUID shells/tools found."
mapfile -t BADSUID < <(find / /home /tmp /var /opt /usr -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | sort -u \
    | not_pkg_owned | grep -vEi -- "$CP_PROTECT_RE")
quarantine_files "SUID/SGID programs that no package installed (a copied root shell is a classic backdoor)" "${BADSUID[@]}"

# Surface any OTHER unexpected SUID/SGID binaries vs. a normal Debian 12 baseline.
BASELINE='^/usr/bin/(sudo|su|passwd|chsh|chfn|chage|gpasswd|newgrp|mount|umount|fusermount3?|pkexec|at|crontab|ssh-agent|expiry|wall|write|bsd-write|dotlockfile|ntfs-3g|vmware-user-suid-wrapper|Xorg)$|^/usr/sbin/(unix_chkpwd|pppd|mount\.nfs|mount\.cifs|exim4|postdrop|postqueue)$|^/usr/lib(exec)?/.*(dbus|polkit|openssh|eject|xorg|Xorg|utempter|camel-lock-helper|chrome-sandbox|chromium|spice|vmware|virtualbox).*|^/bin/(su|mount|umount|ping|fusermount)$'
{ echo "--- Unexpected SUID/SGID binaries (not in the normal Debian 12 set — investigate) ---"
  find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -not -path '/proc/*' 2>/dev/null | grep -vE "$BASELINE" | sed 's/^/   /'
  echo; } >>"$REPORT"

# 2) Weak password hashes: MD5 ($1$) or DES (no $). SHA-256/512, yescrypt, bcrypt are fine.
while IFS=: read -r name hash _; do
  [[ -z $name ]] && continue
  case "$hash" in
    ''|'*'|'!'*|'*'*) continue ;;                       # empty/locked -> handled elsewhere
    \$6\$*|\$5\$*|\$y\$*|\$7\$*|\$2a\$*|\$2b\$*|\$2y\$*|\$gy\$*) continue ;;  # strong
    \$1\$*) wk="MD5" ;;
    *) wk="DES/crypt" ;;
  esac
  if is_human "$name"; then
    if [[ $name == "$MAIN_USER" ]]; then
      warn "YOUR account ($name) uses a weak $wk password hash — run 'passwd' to rehash it."
    else
      echo "$name:$PW" | chpasswd && log "Rehashed weak $wk password for $name"
    fi
  else
    passwd -l "$name" >>"$LOG" 2>&1 && log "Locked system account $name (had a weak $wk hash)"
  fi
done < <(cat /etc/shadow)

# 3) rlogin / rsh trust files = passwordless login. Quarantine them.
mapfile -t TRUSTF < <(find /root /home -maxdepth 3 \( -name .rhosts -o -name .shosts \) -type f 2>/dev/null; \
                      for g in /etc/hosts.equiv /etc/shosts.equiv /etc/ssh/shosts.equiv; do [[ -f $g ]] && echo "$g"; done)
for f in "${TRUSTF[@]}"; do
  [[ -f $f ]] || continue
  backup_file "$f"; mv "$f" "$QUAR/$(echo "$f" | tr / _)" 2>/dev/null \
    && warn "Quarantined trust file $f (allows passwordless rlogin/rsh)"
done
# .netrc (plaintext creds) and .forward (can run commands) — surface only
{ for h in /root /home/*; do
    [[ -f $h/.netrc ]] && echo "   [!] plaintext creds file: $h/.netrc"
    [[ -f $h/.forward ]] && echo "   [!] mail .forward (can pipe to a command): $h/.forward -> $(cat "$h/.forward" 2>/dev/null)"
  done; } >>"$REPORT"

# 4) World-writable dirs need the sticky bit; world-writable files are a risk.
fixed=0
while IFS= read -r d; do [[ -d $d ]] && chmod +t "$d" 2>/dev/null && ((fixed++)); done < <(
  find / -xdev -type d -perm -0002 ! -perm -1000 -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null)
((fixed)) && log "Added sticky bit to $fixed world-writable director(ies)"
mapfile -t WWF < <(find / -xdev -type f -perm -0002 -not -path '/proc/*' -not -path '/sys/*' -not -path '/dev/*' -not -path '/run/*' 2>/dev/null)
if ((${#WWF[@]})); then
  review "--- World-writable files (anyone can modify these) ---"; printf '   %s\n' "${WWF[@]}" >>"$REPORT"; review ""
  if ask_yn "Remove world-write permission from ${#WWF[@]} world-writable file(s)? (recommended)"; then
    for f in "${WWF[@]}"; do chmod o-w "$f" 2>/dev/null; done
    log "Removed world-write from ${#WWF[@]} files"
  fi
fi

# 5) Lock down /root
chmod 700 /root 2>/dev/null; chown root:root /root 2>/dev/null
log "/root restricted to root (700)"

#----------------------------- BROWSER POLICY ---------------------------------
json_ok() { command -v python3 >/dev/null || return 0; python3 -c 'import json,sys;json.load(sys.stdin)' 2>/dev/null; }

section "Firefox ESR security policy"
# Enterprise policy: telemetry off, tracking protection on, no password saving.
read -r -d '' FF_POLICY <<'JSON'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "EnableTrackingProtection": { "Value": true, "Locked": true, "Cryptomining": true, "Fingerprinting": true },
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "DisablePocket": true,
    "DontCheckDefaultBrowser": true,
    "SanitizeOnShutdown": { "Cache": true },
    "AppAutoUpdate": true,
    "ExtensionUpdate": true,
    "SearchSuggestEnabled": false,
    "PopupBlocking": { "Default": true, "Locked": true },
    "Preferences": {
      "browser.safebrowsing.malware.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.phishing.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.remote.block_potentially_unwanted": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.remote.block_uncommon": { "Value": true, "Status": "locked" },
      "dom.disable_open_during_load": { "Value": true, "Status": "locked" },
      "xpinstall.whitelist.required": { "Value": true, "Status": "locked" }
    }
  }
}
JSON
if is_installed firefox-esr || is_installed firefox || [[ -d /usr/lib/firefox-esr || -d /usr/lib/firefox ]]; then
  if printf '%s' "$FF_POLICY" | json_ok; then
    # Debian's firefox-esr reliably reads its own distribution/ dir; /etc/firefox/policies is
    # also written for any other Firefox build.
    FFW=()
    for d in /usr/lib/firefox-esr/distribution /usr/lib/firefox/distribution /etc/firefox/policies; do
      case $d in /usr/lib/*) [[ -d ${d%/distribution} ]] || continue ;; esac
      mkdir -p "$d"; backup_file "$d/policies.json"
      printf '%s\n' "$FF_POLICY" >"$d/policies.json"; chmod 644 "$d/policies.json"; FFW+=("$d")
    done
    log "Firefox hardening policy installed in ${FFW[*]} (telemetry off, tracking protection on, no saved passwords)"
    review "Firefox: open about:policies — the policy should show as Active (restart Firefox first)."
  else warn "Firefox policy JSON failed to validate — not installed."; fi
else info "Firefox not installed — skipping browser policy."; fi

# Per-profile prefs too (the in-browser Settings > Privacy & Security toggles). Insecure
# user_pref lines an attacker planted are removed from prefs.js AND user.js.
FF_PREFS=(
  "browser.safebrowsing.malware.enabled true" "browser.safebrowsing.phishing.enabled true"
  "browser.safebrowsing.downloads.enabled true"
  "browser.safebrowsing.downloads.remote.block_potentially_unwanted true"
  "browser.safebrowsing.downloads.remote.block_uncommon true"
  "dom.disable_open_during_load true" "xpinstall.whitelist.required true"
  "signon.rememberSignons false" "privacy.donottrackheader.enabled true" "privacy.trackingprotection.enabled true"
  "datareporting.healthreport.uploadEnabled false" "toolkit.telemetry.enabled false"
)
nprof=0
for pj in /home/*/.mozilla/firefox/*/prefs.js /root/.mozilla/firefox/*/prefs.js; do
  [[ -f $pj ]] || continue
  pd=$(dirname "$pj"); owner=$(stat -c %U "$pd"); ujs="$pd/user.js"
  pgrep -u "$owner" -x 'firefox-esr|firefox' >/dev/null 2>&1 \
    && warn "Firefox is open for $owner — close it (it rewrites prefs.js on exit); user.js still applies at next start."
  backup_file "$pj" "$ujs"; touch "$ujs"
  for kv in "${FF_PREFS[@]}"; do
    k=${kv% *}; v=${kv##* }; kre=${k//./\\.}
    sed -i -E "/user_pref\(\"${kre}\",/d" "$pj" "$ujs"
    printf 'user_pref("%s", %s);\n' "$k" "$v" | tee -a "$pj" >>"$ujs"
  done
  chown "$owner": "$pj" "$ujs" 2>/dev/null; ((nprof++))
done
((nprof)) && log "Firefox: safe browsing, pop-up blocking, add-on install warnings, no saved passwords set in $nprof profile(s)"

# Chromium / Chrome enterprise policy (the README's browser is often Chromium):
# safe browsing on, pop-ups & dangerous downloads blocked, no password/autofill saving.
if is_installed chromium || is_installed google-chrome-stable || [[ -d /etc/chromium || -d /etc/opt/chrome ]]; then
  read -r -d '' CHROME_POLICY <<'JSON'
{
  "SafeBrowsingProtectionLevel": 2,
  "SafeBrowsingEnabled": true,
  "PasswordManagerEnabled": false,
  "AutofillAddressEnabled": false,
  "AutofillCreditCardEnabled": false,
  "MetricsReportingEnabled": false,
  "BlockThirdPartyCookies": true,
  "DefaultPopupsSetting": 2,
  "DownloadRestrictions": 1,
  "DefaultGeolocationSetting": 2,
  "DefaultNotificationsSetting": 2,
  "DnsOverHttpsMode": "automatic",
  "ComponentUpdatesEnabled": true,
  "BackgroundModeEnabled": false
}
JSON
  if printf '%s' "$CHROME_POLICY" | json_ok; then
    wrote=0
    for d in /etc/chromium/policies/managed /etc/opt/chrome/policies/managed; do
      mkdir -p "$d" 2>/dev/null || continue
      printf '%s\n' "$CHROME_POLICY" >"$d/cp-hardening.json"; chmod 644 "$d/cp-hardening.json"; ((wrote++))
    done
    log "Chromium/Chrome hardening policy installed ($wrote location(s): safe browsing, pop-up & dangerous-download blocking, no saved passwords)"
    review "Chromium: open chrome://policy to confirm the policy loaded."
  else warn "Chromium policy JSON failed to validate — not installed."; fi
else info "Chromium/Chrome not installed — skipping."; fi

CHROME_PY='
import json, sys
p = sys.argv[1]
with open(p) as fh: d = json.load(fh)
def put(path, val):
    cur = d
    for k in path[:-1]:
        if not isinstance(cur.get(k), dict): cur[k] = {}
        cur = cur[k]
    cur[path[-1]] = val
put(["safebrowsing", "enabled"], True)                  # block dangerous sites/downloads
put(["safebrowsing", "enhanced"], True)                 # "Enhanced protection"
put(["profile", "default_content_setting_values", "popups"], 2)   # block pop-ups
put(["profile", "password_manager_enabled"], False)
put(["credentials_enable_service"], False)
put(["autofill", "profile_enabled"], False)
put(["autofill", "credit_card_enabled"], False)
with open(p + ".cptmp", "w") as fh: json.dump(d, fh)
'
if command -v python3 >/dev/null; then
  for pf in /home/*/.config/chromium/*/Preferences /home/*/.config/google-chrome/*/Preferences /root/.config/chromium/*/Preferences; do
    [[ -f $pf ]] || continue
    owner=$(stat -c %U "$pf")
    if pgrep -u "$owner" -x 'chromium|chrome' >/dev/null 2>&1; then
      warn "Chromium is open for $owner — close it and set Settings > Privacy and security by hand (the policy still applies)."; continue; fi
    backup_file "$pf"
    if python3 -c "$CHROME_PY" "$pf" 2>>"$LOG" && [[ -s $pf.cptmp ]]; then
      cat "$pf.cptmp" >"$pf"; log "Chromium profile settings hardened: $pf"
    else warn "Couldn't update $pf (not valid JSON?) — set Settings > Privacy and security by hand."; fi
    rm -f "$pf.cptmp"
  done
fi

#---------------------------- GNOME DESKTOP SETTINGS --------------------------
section "GNOME desktop settings (screen lock, automatic updates, autorun)"
if command -v dconf >/dev/null 2>&1; then
  mkdir -p /etc/dconf/profile /etc/dconf/db/local.d/locks
  DP=/etc/dconf/profile/user
  if [[ ! -f $DP ]]; then printf 'user-db:user\nsystem-db:local\n' >"$DP"
  elif ! grep -qx 'system-db:local' "$DP"; then backup_file "$DP"; echo 'system-db:local' >>"$DP"; fi
  cat >/etc/dconf/db/local.d/00-cp-hardening <<'EOF'
[org/gnome/desktop/screensaver]
lock-enabled=true
lock-delay=uint32 0
idle-activation-enabled=true

[org/gnome/desktop/session]
idle-delay=uint32 900

[org/gnome/desktop/media-handling]
automount-open=false
autorun-never=true

[org/gnome/software]
allow-updates=true
download-updates=true
download-updates-notify=true
EOF
  cat >/etc/dconf/db/local.d/locks/00-cp-hardening <<'EOF'
/org/gnome/desktop/screensaver/lock-enabled
/org/gnome/desktop/screensaver/lock-delay
/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/media-handling/autorun-never
/org/gnome/software/download-updates
EOF
  if dconf update >>"$LOG" 2>&1; then log "GNOME: screen locks after 15 min idle, autorun off, GNOME Software automatic updates on (locked)"
  else warn "'dconf update' failed — GNOME desktop defaults not applied"; fi
else info "dconf not installed (not a GNOME desktop?) — skipping GNOME settings."; fi

#------------------------------ AUDITING TOOLS --------------------------------
section "Security auditing tools"
if [[ ${APT_OK:-true} == true ]]; then
  if apt_install auditd; then
    apt_install audispd-plugins >/dev/null 2>&1
    run systemctl enable --now auditd; log "auditd installed & enabled"
  fi
  if apt_install aide aide-common; then
    log "AIDE (file integrity monitor) installed — initialise later with: sudo aideinit (slow)"
    review "[!] Optional: run 'sudo aideinit' to build the AIDE integrity database (takes several minutes)."
  fi
fi
unit_exists acct && run systemctl enable --now acct

# Watch rules for files attackers tamper with. Written AFTER auditd is installed, and only
# for paths that exist: one missing path makes auditctl stop loading the rest. (Debian 12
# logs to the journal by default, so /var/log/auth.log often doesn't exist.)
if [[ -d /etc/audit/rules.d ]]; then
  AUDF=/etc/audit/rules.d/cp-hardening.rules
  : >"$AUDF"
  for spec in "/etc/passwd identity" "/etc/shadow identity" "/etc/group identity" "/etc/gshadow identity" \
              "/etc/sudoers scope" "/etc/sudoers.d/ scope" "/etc/ssh/sshd_config sshd" "/var/log/auth.log authlog" \
              "/etc/pam.d/ pam" "/etc/crontab cron" "/etc/cron.d/ cron"; do
    p=${spec% *}; k=${spec##* }
    [[ -e $p ]] && echo "-w $p -p wa -k $k" >>"$AUDF"
  done
  chmod 640 "$AUDF"
  if command -v augenrules >/dev/null && augenrules --load >>"$LOG" 2>&1; then
    log "auditd watch rules loaded for passwd/shadow/sudoers/sshd/pam/cron"
  else warn "auditd rules written to $AUDF but didn't load (immutable '-e 2' rules? reboot to apply)"; fi
fi

#---------------------------- AUTOMATIC UPDATES -------------------------------
# The knobs a scoring engine reads: APT::Periodic counters, unattended-upgrades'
# security origins, and the systemd timers that actually run it.
section "Automatic updates (security + daily checks)"
if [[ ${APT_OK:-true} == true ]]; then
  apt_install unattended-upgrades     # (not apt-listchanges: it makes later manual apt runs stop in a pager)
fi

# 1) APT::Periodic. 20auto-upgrades is the standard file; 10periodic is kept in sync if present.
write_periodic() {
  cat >"$1" <<'EOF'
APT::Periodic::Enable "1";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Verbose "1";
EOF
  chmod 644 "$1"
}
backup_file /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/10periodic
write_periodic /etc/apt/apt.conf.d/20auto-upgrades
write_periodic /etc/apt/apt.conf.d/10periodic
log "APT::Periodic set: update lists daily, download upgrades, run unattended-upgrade, autoclean weekly"

# 2) Debian's 50unattended-upgrades uses Origins-Pattern. Re-activate the security,
#    point-release and -updates lines (an attacker may have commented them out).
U50=/etc/apt/apt.conf.d/50unattended-upgrades
if [[ -f $U50 ]]; then
  backup_file "$U50"
  sed -i -E 's@^[[:space:]]*//[[:space:]]*("origin=Debian,codename=\$\{distro_codename\}(-security|-updates)?(,label=Debian(-Security)?)?";)@        \1@' "$U50"
  # NEVER auto-install proposed-updates or backports — re-comment if someone enabled them
  sed -i -E 's@^([[:space:]]*)("origin=Debian,codename=\$\{distro_codename\}-proposed-updates";)@\1// \2@' "$U50"
  sed -i -E 's@^([[:space:]]*)("o=Debian Backports,[^"]*";)@\1// \2@' "$U50"
  log "unattended-upgrades: Debian security + updates origins enabled (proposed-updates/backports left off)"
else
  warn "50unattended-upgrades not found — relying on the drop-in below for origins."
fi

# 3) Safety drop-in. Critically: NO automatic reboot and NO autoremove during the round.
cat >/etc/apt/apt.conf.d/52cyberpatriot-unattended <<'EOF'
// Added by CyberPatriot hardening script — safety overrides for unattended-upgrades.
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
Unattended-Upgrade::Remove-New-Unused-Dependencies "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "false";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Mail "";
Unattended-Upgrade::SyslogEnable "true";
// If 50unattended-upgrades is missing or was gutted, these keep Debian security updates on:
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename},label=Debian-Security";
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};
EOF
chmod 644 /etc/apt/apt.conf.d/52cyberpatriot-unattended
log "Safety overrides set: no auto-reboot, no auto-remove (protects the desktop)"

# 4) Make sure the machinery that RUNS all this is enabled (an attacker may have masked it)
for t in apt-daily.timer apt-daily-upgrade.timer; do
  systemctl unmask "$t" >>"$LOG" 2>&1
  systemctl enable --now "$t" >>"$LOG" 2>&1
done
systemctl unmask unattended-upgrades.service >>"$LOG" 2>&1
run systemctl enable --now unattended-upgrades
log "apt-daily + apt-daily-upgrade timers unmasked and enabled; unattended-upgrades service on"

# 5) Validate the config parses, and dry-run the updater if we can.
if apt-config dump >/dev/null 2>>"$LOG"; then
  info "APT auto-update config parses cleanly."
else
  warn "An APT config file has a syntax error — run 'sudo apt-config dump' to find it."
fi
if command -v unattended-upgrade >/dev/null 2>&1 && [[ ${APT_OK:-true} == true ]]; then
  wait_for_apt
  if unattended-upgrade --dry-run >>"$LOG" 2>&1; then info "unattended-upgrade --dry-run succeeded."
  else warn "unattended-upgrade --dry-run reported a problem (see log) — check origins/network."; fi
fi
{ echo "--- Automatic-update settings in effect ---"
  apt-config dump 2>/dev/null | grep -iE 'APT::Periodic|Unattended-Upgrade::(Origins-Pattern|Allowed-Origins|Automatic-Reboot|Remove-Unused)' | sed 's/^/   /'
  echo "   Timers:"; systemctl is-enabled apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null | sed 's/^/     /'
  echo; } >>"$REPORT"
log "Daily update checks + automatic security upgrades fully configured"

#-------------------------------- UPDATES -------------------------------------
if [[ $UPDATE_MODE != s && ${APT_OK:-true} == true ]]; then
  section "Installing updates (this can take a while)"
  wait_for_apt; apt-get update -q >>"$LOG" 2>&1
  if [[ $UPDATE_MODE == f ]]; then
    echo "   Full upgrade running... (watch progress in another terminal: tail -f '$LOG')"
    wait_for_apt; apt-get upgrade "${APT_OPTS[@]}" >>"$LOG" 2>&1
    wait_for_apt; apt-get "${APT_OPTS[@]}" --with-new-pkgs upgrade >>"$LOG" 2>&1
    wait_for_apt; apt-get dist-upgrade "${APT_OPTS[@]}" >>"$LOG" 2>&1     # stays on bookworm: sources are pinned
    run dpkg --configure -a
    log "Full system upgrade complete (Debian $CODENAME point-release + security updates)"
  else
    CRIT=(bash sudo openssl libssl3 openssh-server openssh-client libpam-modules libpam-runtime libpam0g
          linux-image-amd64 firefox-esr chromium apache2 nginx nginx-core vsftpd samba bind9 libc6 dpkg apt
          mariadb-server postgresql exim4-daemon-light postfix systemd tar gzip wget curl sysstat)
    TO_UP=(); for p in "${CRIT[@]}"; do is_installed "$p" && TO_UP+=("$p"); done
    ((${#TO_UP[@]})) && { wait_for_apt; apt-get install "${APT_OPTS[@]}" --only-upgrade "${TO_UP[@]}" >>"$LOG" 2>&1; }
    log "Critical packages upgraded: ${TO_UP[*]}"
  fi
  review "Note: a kernel update only takes effect after a reboot."
fi

# Verify Shellshock is already patched (don't "test" by running the exploit)
if command -v dpkg >/dev/null; then
  bv=$(dpkg-query -W -f='${Version}' bash 2>/dev/null)
  info "bash version: $bv (Shellshock was fixed long before Debian 12)"
fi

#------------------------- MALWARE & INTEGRITY SCANS --------------------------
section "Malware & integrity scanners"
# These find planted backdoors/trojaned binaries. They only REPORT (never auto-delete).
if [[ ${APT_OK:-true} != true ]]; then
  warn "No working APT/internet — skipping scanner installs. Run them later once online."
else
  SCAN_SUMMARY=()

  # debsums: find package files that were modified after install (trojaned binaries)
  if apt_install debsums; then
    echo "   Checking system binaries against package checksums (debsums)..."
    changed=$(debsums -s 2>&1 | grep -vE 'no md5sums|^$' )
    { echo "--- debsums: MODIFIED or MISSING packaged files (a changed /usr/bin/* is a red flag) ---"
      [[ -n $changed ]] && sed 's/^/   /' <<<"$changed" || echo "   (none reported)"; echo; } >>"$REPORT"
    [[ -n $changed ]] && { warn "debsums found modified/missing system files — check REVIEW-ME.txt"; SCAN_SUMMARY+=("debsums: FLAGGED files"); } || SCAN_SUMMARY+=("debsums: clean")
  fi

  # chkrootkit
  if apt_install chkrootkit; then
    echo "   Running chkrootkit..."
    ck=$(chkrootkit 2>/dev/null | grep -iE 'INFECTED|vulnerable|suspicious' | grep -vi 'not infected')
    { echo "--- chkrootkit hits (INFECTED/suspicious) ---"; [[ -n $ck ]] && sed 's/^/   /' <<<"$ck" || echo "   (none)"; echo; } >>"$REPORT"
    [[ -n $ck ]] && { warn "chkrootkit reported possible infection — check REVIEW-ME.txt"; SCAN_SUMMARY+=("chkrootkit: HITS"); } || SCAN_SUMMARY+=("chkrootkit: clean")
  fi

  # rkhunter
  if apt_install rkhunter; then
    echo "   Running rkhunter (this takes a minute)..."
    sed -i 's/^UPDATE_MIRRORS=.*/UPDATE_MIRRORS=1/; s/^MIRRORS_MODE=.*/MIRRORS_MODE=0/; s/^WEB_CMD=.*/WEB_CMD=""/' /etc/rkhunter.conf 2>/dev/null
    run rkhunter --update; run rkhunter --propupd
    rkhunter --check --sk --nocolors >>"$LOG" 2>&1
    rk=$(grep -iE 'Warning' /var/log/rkhunter.log 2>/dev/null | sort -u)
    { echo "--- rkhunter warnings (some are benign; investigate hidden files/ports/procs) ---"
      [[ -n $rk ]] && sed 's/^/   /' <<<"$rk" | head -60 || echo "   (none)"; echo; } >>"$REPORT"
    [[ -n $rk ]] && SCAN_SUMMARY+=("rkhunter: warnings (review)") || SCAN_SUMMARY+=("rkhunter: clean")
  fi

  # ClamAV: update signatures then scan the places malware hides.
  # It loads ~1.5 GB of signatures into RAM — on a small VM that can freeze the desktop or get
  # GNOME killed, so it only runs when there's enough free memory.
  if apt_install clamav clamav-freshclam; then
    memkb=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    if (( ${memkb:-0} < 1600000 )); then
      warn "ClamAV scan skipped: only $(( ${memkb:-0} / 1024 )) MB RAM free (it needs ~1.5 GB). Later, when idle: sudo clamscan -ri /home /tmp /opt"
      SCAN_SUMMARY+=("ClamAV: skipped (low RAM)")
    else
      echo "   Updating ClamAV signatures (freshclam)..."
      run systemctl stop clamav-freshclam
      freshclam >>"$LOG" 2>&1 || info "freshclam didn't fully update (rate-limited/offline?) — using the signatures already present"
      if compgen -G '/var/lib/clamav/*.c[vl]d' >/dev/null; then
        echo "   Scanning (this can take several minutes)..."
        SCANLOG="$LOGDIR/clamav-scan.txt"
        nice -n 10 clamscan -ri --max-filesize=200M --max-scansize=400M \
          --exclude-dir='^/proc' --exclude-dir='^/sys' --exclude-dir='^/dev' --exclude-dir='^/run' \
          /home /root /tmp /var/tmp /var/www /srv /opt /usr/local /etc >"$SCANLOG" 2>>"$LOG"
        infected=$(awk -F': ' '/Infected files:/{print $2}' "$SCANLOG")
        { echo "--- ClamAV results (full log: $SCANLOG) ---"
          grep -E 'FOUND$' "$SCANLOG" | sed 's/^/   /'; echo "   Infected files: ${infected:-0}"; echo; } >>"$REPORT"
        if [[ ${infected:-0} =~ ^[0-9]+$ ]] && (( infected > 0 )); then warn "ClamAV found ${infected} infected file(s) — listed in REVIEW-ME.txt"; SCAN_SUMMARY+=("ClamAV: ${infected} infected"); else SCAN_SUMMARY+=("ClamAV: clean"); fi
      else
        warn "No ClamAV virus signatures could be downloaded (offline?) — ClamAV scan skipped."
      fi
      run systemctl start clamav-freshclam
    fi
  fi

  ((${#SCAN_SUMMARY[@]})) && log "Scan summary: ${SCAN_SUMMARY[*]}"
fi

# A tool's "Recommends" can pull Debian's default mail server (Exim) back in — remove it again.
if ! $NEED_MAIL && [[ -n $(installed_matching 'exim4-daemon-*' postfix sendmail-bin dovecot-core) ]]; then
  info "A mail server was re-installed as a dependency — removing it again."
  purge_mail_servers
fi
pin_orphans

#------------------------------- INVENTORIES ----------------------------------
section "System inventories (for manual comparison)"
dpkg -l >"$LOGDIR/packages.txt" 2>/dev/null
apt-mark showmanual >"$LOGDIR/manual-packages.txt" 2>/dev/null
( ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null ) >"$LOGDIR/listening-ports.txt"
systemctl list-unit-files --state=enabled >"$LOGDIR/enabled-services.txt" 2>/dev/null
ps auxww >"$LOGDIR/processes.txt" 2>/dev/null
cp -a /etc/passwd /etc/group "$LOGDIR/" 2>/dev/null
awk -F: '($2!="*"&&$2!="!"&&$2!~/^!/){print $1}' /etc/shadow >"$LOGDIR/accounts-with-passwords.txt" 2>/dev/null
last -20 >"$LOGDIR/recent-logins.txt" 2>/dev/null
lastlog >"$LOGDIR/lastlog.txt" 2>/dev/null
log "Inventories written to $LOGDIR"

#-------------------------------- FINAL CHECKS --------------------------------
section "Final sanity checks"
PROBLEMS=0
command -v sudo >/dev/null || { warn "sudo is NOT installed — don't log out of your root shell until it is: apt install sudo"; ((PROBLEMS++)); }
id "$MAIN_USER" | grep -qw sudo || { warn "YOU ($MAIN_USER) are not in the sudo group! Fix NOW in your root terminal: usermod -aG sudo $MAIN_USER"; ((PROBLEMS++)); }
if command -v sudo >/dev/null && ! sudo -l -U "$MAIN_USER" 2>/dev/null | grep -qE "$SUDO_ALL_RE"; then
  warn "sudo does NOT give $MAIN_USER full admin rights — fix /etc/sudoers (visudo) before you log out!"; ((PROBLEMS++)); fi
[[ -f /boot/grub/grub.cfg ]] && chmod 600 /boot/grub/grub.cfg 2>/dev/null   # a kernel update rewrites it as 444
if command -v visudo >/dev/null; then visudo -c >/dev/null 2>&1 || { warn "sudoers is INVALID — fix before logout!"; ((PROBLEMS++)); }; fi
pam_sanity_ok || { warn "PAM looks broken — keep your root shell open and verify you can log in!"; ((PROBLEMS++)); }
if $NEED_SSH; then mkdir -p /run/sshd; sshd -t >/dev/null 2>&1 || { warn "sshd_config invalid"; ((PROBLEMS++)); }; fi
extra_uid0=$(awk -F: '$3==0{print $1}' /etc/passwd | grep -vx root | tr '\n' ' ')
[[ -n $extra_uid0 ]] && { warn "Still UID-0 accounts besides root: $extra_uid0"; ((PROBLEMS++)); }
dup=$(awk -F: '{c[$3]++} END{for(u in c) if(c[u]>1) print u}' /etc/passwd)
[[ -n $dup ]] && warn "Duplicate UID(s): $dup"
for g in "${CRIT_GROUPS[@]}"; do
  ok=0; for u in ${g#*|}; do systemctl is-active --quiet "$u" 2>/dev/null && ok=1; done
  ((ok)) || { warn "README-critical service '${g%%|*}' is NOT running (${g#*|}) — penalty risk! Check: systemctl status"; ((PROBLEMS++)); }
done

{ echo; echo "=== QUICK MANUAL CHECKLIST (things a script shouldn't automate) ==="
  echo " [ ] Re-read the README; do every FORENSICS question and scored task it lists."
  echo " [ ] Confirm the admin/standard-user split matches the README exactly."
  echo " [ ] Firefox ESR / Chromium, LibreOffice and the kernel are fully updated."
  echo " [ ] Review enabled-services.txt and listening-ports.txt; disable anything unexplained."
  echo " [ ] Look over the SUID/SGID, world-writable and orphaned-file lists above."
  echo " [ ] Check /etc/hosts for bogus redirects; check browser homepage/proxy settings."
  echo " [ ] For each required service, verify its config against CIS / the README."
  echo " [ ] Empty the trash of deleted users only after you've answered forensics questions."
  echo; } >>"$REPORT"

# /etc/hosts: anything beyond localhost/this hostname/IPv6 defaults is shown and you decide
HN=$(hostname 2>/dev/null); HNF=$(hostname -f 2>/dev/null)
HOSTS_OK="^(localhost|localhost\.localdomain|ip6-localhost|ip6-loopback|ip6-allnodes|ip6-allrouters|ip6-localnet|ip6-mcastprefix|ip6-allhosts${HN:+|${HN//./\\.}|${HN//./\\.}\..*}${HNF:+|${HNF//./\\.}})$"
mapfile -t HL </etc/hosts; HCH=0
for ln in "${HL[@]}"; do
  t=${ln%%#*}; read -r ip names <<<"$t"; [[ -z $ip ]] && continue
  hbad=0; [[ $ip =~ ^(127\.|::1$|fe00::|ff0[0-9]::) ]] || hbad=1
  for nm in $names; do [[ ${nm,,} =~ $HOSTS_OK ]] || hbad=1; done
  ((hbad)) || continue
  echo "${Y}   /etc/hosts:${N} $ln"
  review "[!] Unusual /etc/hosts entry: $ln"
  if ask_yn "   Comment out this /etc/hosts entry? (yes unless the README needs it)"; then
    backup_file /etc/hosts; comment_line /etc/hosts "$ln" "disabled by CP script"; ((HCH++)); fi
done
((HCH)) && log "Disabled $HCH unusual /etc/hosts entr(ies) (redirects/blocks)"
chmod 644 /etc/hosts; chown root:root /etc/hosts
{ echo "--- /etc/resolv.conf nameservers (verify these are expected, not attacker DNS) ---"
  grep -E '^[[:space:]]*nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/   /'; echo; } >>"$REPORT"

#---------------------------------- DONE --------------------------------------
chown -R "$MAIN_USER": "$OUT" 2>/dev/null
find "$OUT" -type d -exec chmod 700 {} + 2>/dev/null
find "$OUT" -type f -exec chmod 600 {} + 2>/dev/null

section "Done"
log "Hardening finished in $(ts)."
echo
echo "${G}${W}================= SCRIPT COMPLETE =================${N}"
echo " Removed packages : ${#REMOVED_PKGS[@]}"
echo " Report (READ IT) : ${W}$REPORT${N}"
echo " Full log         : $LOG"
echo " Backups of /etc  : $BACKUP/etc.tar.gz"
echo " Quarantine       : $QUAR"
if ((PROBLEMS)); then
  echo "${R}${W} $PROBLEMS CRITICAL ISSUE(S) — fix them before you log out (see above).${N}"
else
  echo "${G} No critical issues detected by the self-check.${N}"
fi
echo
echo "${Y}DO THIS NOW, before logging out, using the root terminal you kept open:${N}"
echo "   1. Open REVIEW-ME.txt and work through it — a lot of points live there."
echo "   2. In a NEW terminal:  su - $MAIN_USER   then:  sudo echo ok   (confirm login + sudo still work)."
echo "      (If you were just added to the sudo group, log out and back in first.)"
echo "      3 wrong passwords now LOCK an account for 10 minutes. To unlock early (from a root shell):"
echo "      faillock --user NAME --reset"
echo "   3. Only then close your spare root shell."
echo
echo "${C}Reminder: the biggest point gains are the README's scored tasks and forensics${N}"
echo "${C}questions — this script handles the generic hardening, not the scenario-specific items.${N}"
if is_installed gdm3; then
  echo
  echo "${Y}Login-screen settings take effect after 'dpkg-reconfigure gdm3' + a reboot.${N}"
  echo "   If you get stuck at the login screen afterwards, Ctrl+Alt+F3 gives a text console to fix it."
  if ask_yn "Run 'dpkg-reconfigure gdm3' now? (do this LAST — it may restart the login screen)"; then
    dpkg-reconfigure gdm3 >>"$LOG" 2>&1 && echo "${G}[+]${N} Done — reboot when you're ready (sudo reboot)."
  else echo "   Later: sudo dpkg-reconfigure gdm3 && sudo reboot"; fi
fi
