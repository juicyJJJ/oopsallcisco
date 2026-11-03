#!/usr/bin/env bash
#==============================================================================
#  CyberPatriot Linux Hardening Script
#  Ubuntu 20.04 / 22.04 / 24.04  and  Linux Mint 20 / 21 / 22
#
#  HOW TO RUN
#     sed -i 's/\r$//' cyberpatriot_ubuntu.sh   # only if copied from Windows/Google Docs
#     sudo bash cyberpatriot_ubuntu.sh
#
#  BEFORE YOU RUN IT
#   1. Answer the FORENSICS QUESTIONS first. This script removes users,
#      software and media files those questions often ask about.
#   2. Read the README. Have ready: authorized admins, authorized standard
#      users, and every service the README calls "critical"/"required".
#   3. Open a SECOND terminal, run `sudo -i`, and leave it open until you've
#      confirmed you can still log in and use sudo. It's your safety net.
#
#  SAFETY DESIGN
#   * Nothing destructive happens without showing you what and asking first.
#   * Every config edit is backed up to /root/cp-backups and VALIDATED
#     (sshd -t, visudo -c, apache2ctl configtest, testparm, named-checkconf,
#     PAM module check, service restart check). Failed validation = rollback.
#   * Services the README needs are hardened, never removed.
#   * Packages are only purged if apt confirms it won't also remove the
#     desktop or a critical package. No `apt autoremove` (it can delete the
#     whole desktop after a purge).
#   * Your own account is never deleted, demoted or locked.
#   * Anything that looks like the CyberPatriot scoring engine is skipped.
#==============================================================================

if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
if [[ $EUID -ne 0 ]]; then echo "This script must be run as root:  sudo bash $0"; exit 1; fi

export DEBIAN_FRONTEND=noninteractive
export UCF_FORCE_CONFFOLD=1
export NEEDRESTART_SUSPEND=1
APT_OPTS=(-y -q -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
umask 022

if [[ -t 1 ]]; then R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; W=$'\e[1m'; N=$'\e[0m'
else R=; G=; Y=; C=; W=; N=; fi
TTY=/dev/tty
{ : <"$TTY"; } 2>/dev/null || TTY=/dev/stdin

#----------------------------- main user / paths ------------------------------
MAIN_USER=${SUDO_USER:-}
if [[ -z $MAIN_USER || $MAIN_USER == root ]]; then
  read -rp "Enter YOUR username (the account you log in with): " MAIN_USER <"$TTY"
fi
if ! id "$MAIN_USER" &>/dev/null; then echo "User '$MAIN_USER' does not exist."; exit 1; fi
MAIN_HOME=$(getent passwd "$MAIN_USER" | cut -d: -f6)
DESKTOP=$(sudo -u "$MAIN_USER" xdg-user-dir DESKTOP 2>/dev/null)
[[ -n $DESKTOP && $DESKTOP != "$MAIN_HOME" && -d $DESKTOP ]] || DESKTOP="$MAIN_HOME/Desktop"

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
  echo "CyberPatriot script review list — $(date)"
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
    read -rp "${Y}[?]${N} $1 [y/n]: " ans <"$TTY"
    case "${ans,,}" in y|yes) return 0 ;; n|no) return 1 ;; esac
    echo "    Please type y or n."
  done
}
ask() { local __v; read -rp "${Y}[?]${N} $1 " __v <"$TTY"; printf '%s' "$__v"; }

#-------------------------------- utilities -----------------------------------
in_list()        { local x=$1 e; shift; for e in "$@"; do [[ $e == "$x" ]] && return 0; done; return 1; }
group_members()  { getent group "$1" | cut -d: -f4 | tr ',' ' '; }
user_in_group()  { group_members "$2" | tr ' ' '\n' | grep -qxF -- "$1"; }
backup_file()    { local f; for f in "$@"; do [[ -e $f ]] && cp -a --parents "$f" "$BACKUP/files/" 2>/dev/null; done; }
uid_of()         { id -u "$1" 2>/dev/null; }

UID_MIN=$(awk '/^[[:space:]]*UID_MIN/{print $2}' /etc/login.defs); UID_MIN=${UID_MIN:-1000}
UID_MAX=$(awk '/^[[:space:]]*UID_MAX/{print $2}' /etc/login.defs); UID_MAX=${UID_MAX:-60000}
human_users()    { awk -F: -v min="$UID_MIN" -v max="$UID_MAX" '$3>=min && $3<=max {print $1}' /etc/passwd; }
is_human()       { local u; u=$(uid_of "$1") || return 1; (( u >= UID_MIN && u <= UID_MAX )); }

# Anything that looks like the CyberPatriot scoring engine / VM tools / README is never touched.
CP_PROTECT_RE='cyberpatriot|ccs|css|scor(e|ing)|aeacus|forensic|readme|vbox|virtualbox|vmware|vmtools|open-vm'
is_protected()   { grep -qEi -- "$CP_PROTECT_RE" <<<"$1"; }

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

# ini_set FILE SECTION KEY VALUE [SEP]  — section-aware (gdm, lightdm, smb.conf, my.cnf)
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
    pgrep -x 'apt|apt-get|dpkg|aptitude|unattended-upgr' >/dev/null 2>&1
  fi
}
wait_for_apt() {
  local n=0
  while apt_busy; do
    ((n == 0)) && info "Another package manager (probably automatic updates) is running — waiting..."
    sleep 5; ((n++))
    ((n >= 180)) && { warn "Package manager still busy after 15 minutes; continuing anyway."; break; }
  done
}
apt_install() {
  wait_for_apt
  apt-get install "${APT_OPTS[@]}" "$@" >>"$LOG" 2>&1
  local rc=$?; ((rc)) && warn "apt-get install $* failed (rc=$rc) — no internet? See log."
  return $rc
}

# Packages that must never be removed as a side effect of purging something else.
PROTECT_BASE='ubuntu-desktop|ubuntu-desktop-minimal|ubuntu-minimal|ubuntu-standard|ubuntu-server|ubuntu-session|kubuntu-desktop|xubuntu-desktop|lubuntu-desktop|mint-meta-.*|mintupdate|mintsystem|cinnamon|cinnamon-core|cinnamon-session|mate-core|xfce4|gdm3|lightdm|sddm|slick-greeter|gnome-shell|gnome-session|gnome-session-bin|nautilus|nemo|gnome-control-center|gnome-terminal|xorg|xserver-xorg|xserver-xorg-core|network-manager|network-manager-gnome|systemd|systemd-sysv|sudo|apt|dpkg|libpam-runtime|libpam-modules|login|passwd|ufw|snapd|firefox|policykit-1|polkitd|pkexec|unattended-upgrades|update-manager|update-notifier|software-properties-gtk|software-properties-common|linux-generic.*|linux-image-generic.*|open-vm-tools.*|virtualbox-guest-.*|ubuntu-release-upgrader-.*'
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
    [[ -n $others ]] && info "(apt also removed: $others)"
  else
    warn "Failed to remove $p (see log)"
  fi
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
pam_module_exists() { find /usr/lib /lib/ /usr/lib64 /lib64/ -maxdepth 4 -name "$1" 2>/dev/null | grep -q .; }
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
. /etc/os-release 2>/dev/null
OS_NAME=${PRETTY_NAME:-unknown}
CODENAME=${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}
IS_MINT=false; [[ ${ID:-} == linuxmint || ${ID_LIKE:-} == *mint* ]] && IS_MINT=true

clear
cat <<EOF
${C}=========================================================================
   CyberPatriot Ubuntu / Mint hardening script
=========================================================================${N}
 Detected OS : $OS_NAME  (base codename: ${CODENAME:-?})
 Your account: $MAIN_USER
 Logs/report : $OUT
 Backups     : $BACKUP
EOF
if [[ ${ID:-} != ubuntu && $IS_MINT != true && ${ID_LIKE:-} != *ubuntu* ]]; then
  echo "${R}This does not look like Ubuntu or Mint.${N}"; ask_yn "Continue anyway?" || exit 0
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
  read -rsp "${Y}[?]${N} New password for all OTHER authorized users (Enter = ${DEFAULT_PW}): " PW <"$TTY"; echo
  if [[ -z $PW ]]; then PW=$DEFAULT_PW; break; fi
  if (( ${#PW} < 12 )) || ! [[ $PW =~ [A-Z] && $PW =~ [a-z] && $PW =~ [0-9] && $PW =~ [^A-Za-z0-9] ]]; then
    echo "    Needs 12+ characters with upper, lower, digit and symbol."; continue; fi
  read -rsp "    Confirm: " PW2 <"$TTY"; echo
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
svc_q NEED_MYSQL  "MySQL / MariaDB required?" mysql-server mysql-server-8.0 mariadb-server
svc_q NEED_PGSQL  "PostgreSQL required?" postgresql
if $NEED_MYSQL || $NEED_PGSQL; then svc_q DB_REMOTE "   ...must OTHER computers connect to the database? (usually NO)"; fi
svc_q NEED_DNS    "DNS server (BIND9) required?" bind9
svc_q NEED_MAIL   "Mail server (Postfix / Dovecot) required?" postfix dovecot-core
svc_q NEED_PRINT  "Printing (CUPS) required?" cups
svc_q NEED_NFS    "NFS file sharing required?" nfs-kernel-server
svc_q NEED_TELNET "Telnet server required? (almost never)" telnetd inetutils-telnetd
svc_q NEED_VNC    "Remote desktop (VNC / xrdp) required?" x11vnc xrdp tigervnc-standalone-server tightvncserver
DISABLE_IPV6=false
ask_yn "Does the README say to DISABLE IPv6? (normally NO)" && DISABLE_IPV6=true

echo
echo "Install updates at the END of the script?"
echo "   f = FULL upgrade (best for points; 10-40 minutes)"
echo "   c = critical packages only (bash, sudo, openssl, ssh, kernel, firefox, ...)"
echo "   s = skip"
while true; do
  read -rp "${Y}[?]${N} Choice [f/c/s]: " UPDATE_MODE <"$TTY"; UPDATE_MODE=${UPDATE_MODE,,}
  [[ $UPDATE_MODE =~ ^[fcs]$ ]] && break
done

# Protect packages belonging to required services from being purged as collateral
EXTRA=""
$NEED_SSH    && EXTRA+="|openssh-server|openssh-sftp-server|ssh"
$NEED_FTP    && EXTRA+="|vsftpd|pure-ftpd.*|proftpd.*"
$NEED_SAMBA  && EXTRA+="|samba|samba-common|samba-common-bin|samba-.*"
$NEED_WEB    && EXTRA+="|apache2.*|libapache2-.*|php.*|nginx.*|lighttpd"
$NEED_MYSQL  && EXTRA+="|mysql-.*|mariadb-.*"
$NEED_PGSQL  && EXTRA+="|postgresql.*"
$NEED_DNS    && EXTRA+="|bind9.*"
$NEED_MAIL   && EXTRA+="|postfix.*|dovecot.*|exim4.*|sendmail.*"
$NEED_PRINT  && EXTRA+="|cups.*"
$NEED_NFS    && EXTRA+="|nfs-kernel-server|nfs-common|rpcbind"
$NEED_TELNET && EXTRA+="|telnetd|inetutils-telnetd|telnetd-ssl|telnet|inetutils-telnet|openbsd-inetd|xinetd"
$NEED_VNC    && EXTRA+="|x11vnc|tigervnc.*|tightvncserver|vnc4server|xrdp"
PROTECT_PKG_RE="^(${PROTECT_BASE}${EXTRA})$"

echo
echo "${W}Summary:${N} SSH=$NEED_SSH FTP=$NEED_FTP Samba=$NEED_SAMBA Web=$NEED_WEB MySQL=$NEED_MYSQL PostgreSQL=$NEED_PGSQL"
echo "         DNS=$NEED_DNS Mail=$NEED_MAIL Print=$NEED_PRINT NFS=$NEED_NFS Telnet=$NEED_TELNET VNC=$NEED_VNC IPv6-off=$DISABLE_IPV6 Updates=$UPDATE_MODE"
ask_yn "Start hardening now?" || exit 0
review "Answers: SSH=$NEED_SSH FTP=$NEED_FTP Samba=$NEED_SAMBA Web=$NEED_WEB MySQL=$NEED_MYSQL PgSQL=$NEED_PGSQL DNS=$NEED_DNS Mail=$NEED_MAIL Print=$NEED_PRINT NFS=$NEED_NFS"
review ""

###############################################################################
#  PHASE 2 — HARDENING
###############################################################################
section "Backups"
tar -czpf "$BACKUP/etc.tar.gz" /etc 2>>"$LOG" && log "Full backup of /etc -> $BACKUP/etc.tar.gz"
cp -a /etc/pam.d "$BACKUP/pam.d.orig"
cp -a /etc/sudoers "$BACKUP/sudoers.orig"
[[ -d /etc/sudoers.d ]] && cp -a /etc/sudoers.d "$BACKUP/sudoers.d.orig"
[[ -d /var/spool/cron ]] && cp -a /var/spool/cron "$BACKUP/spool-cron"
info "Restore a file later with:  sudo tar -xzpf $BACKUP/etc.tar.gz -C / etc/path/to/file"

section "Clearing immutable flags (a trick used to block fixes)"
if command -v lsattr >/dev/null; then
  for f in /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers /etc/sudoers.d/* /etc/hosts \
           /etc/login.defs /etc/ssh/sshd_config /etc/sysctl.conf /etc/crontab /etc/rc.local /etc/pam.d/* \
           /etc/apt/sources.list /etc/lightdm/lightdm.conf /etc/gdm3/custom.conf /etc/security/*.conf; do
    [[ -f $f && ! -L $f ]] || continue
    a=$(lsattr -d "$f" 2>/dev/null | awk '{print $1}')
    [[ $a == *i* || $a == *a* ]] && chattr -i -a "$f" 2>>"$LOG" && warn "Removed immutable/append-only flag from $f"
  done
fi

#--------------------------------- APT ----------------------------------------
section "APT sources & package manager"
wait_for_apt; run dpkg --configure -a

# Official package hosts for Ubuntu and Mint (country mirrors like us.archive.* match).
OFFHOST='(([a-z0-9-]+\.)*(archive|security|ports|esm)\.ubuntu\.com|old-releases\.ubuntu\.com|([a-z0-9-]+\.)*linuxmint\.com)'
OFFICIAL="https?://${OFFHOST}(/.*)?"
# host of the first URI on a one-line "deb ..." entry (skips [opt=..] blocks)
line_host() { awk '{for(i=1;i<=NF;i++) if($i ~ /:\/\//){u=$i; sub(/^[a-z]+:\/\//,"",u); sub(/\/.*/,"",u); sub(/:.*/,"",u); print tolower(u); exit}}' <<<"$1"; }
is_off_host() { [[ $1 =~ ^${OFFHOST}$ ]]; }

fix_apt_sources() {
  local A=${APTDIR:-/etc/apt}
  local SL="$A/sources.list" SLD="$A/sources.list.d" f
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

  # 3) 'cdrom:' sources make 'apt update' hang waiting for a disc -> comment out
  for f in "$SL" "$SLD"/*.list; do
    [[ -f $f ]] || continue
    if grep -qE '^[[:space:]]*deb([[:space:]]|-src[[:space:]]).*cdrom:' "$f"; then
      backup_file "$f"
      sed -i -E 's@^([[:space:]]*deb([[:space:]]|-src[[:space:]]).*cdrom:.*)@# \1   # cdrom disabled by CP script@' "$f"
      warn "Commented out a 'cdrom:' APT source in $f (it blocks apt update)"
    fi
  done

  # 4) Make sure the OFFICIAL repos (main + -updates + -security) are present & enabled
  has_pocket() { # $1 = "" | -updates | -security
    grep -rhsE "^[[:space:]]*deb([[:space:]]|-src[[:space:]])+(\[[^]]*\][[:space:]]+)?${OFFICIAL}[[:space:]]+${CODENAME}$1[[:space:]]" \
      "$SL" "$SLD"/ 2>/dev/null | grep -q .
  }
  if [[ -n $CODENAME ]]; then
    if [[ -f $SLD/ubuntu.sources ]] && ! $IS_MINT; then
      local S="$SLD/ubuntu.sources"
      if ! grep -qE "^[[:space:]]*Suites:.*${CODENAME}-security" "$S" \
         || ! grep -qE "^[[:space:]]*Suites:.*${CODENAME}-updates" "$S" \
         || grep -qiE '^[[:space:]]*Enabled:[[:space:]]*no' "$S"; then
        backup_file "$S"
        cat >"$S" <<EOF
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: ${CODENAME} ${CODENAME}-updates ${CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: ${CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
        log "Restored official Ubuntu sources (incl. -updates and -security) in $S"
      else info "Official deb822 sources already present in $S"; fi
    else
      local S; if $IS_MINT; then S="$SLD/official-package-repositories.list"; else S="$SL"; fi
      touch "$S"; backup_file "$S"
      # Re-enable commented-out official lines (the "Software & Updates" checkboxes)
      sed -i -E "s@^#[[:space:]]*(deb([[:space:]]|-src[[:space:]])+(\[[^]]*\][[:space:]]+)?${OFFICIAL}[[:space:]]+${CODENAME}(-updates|-security|-backports)?[[:space:]])@\1@" "$S"
      has_pocket ""          || echo "deb http://archive.ubuntu.com/ubuntu/ ${CODENAME} main restricted universe multiverse" >>"$S"
      has_pocket "-updates"  || echo "deb http://archive.ubuntu.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse" >>"$S"
      has_pocket "-security" || echo "deb http://security.ubuntu.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse" >>"$S"
      log "Official ${CODENAME}, ${CODENAME}-updates and ${CODENAME}-security repositories enabled ($S)"
      $IS_MINT && ! grep -qsE "^[[:space:]]*deb[[:space:]]+https?://([a-z0-9.-]+\.)?linuxmint\.com" "$S" \
        && review "[!] Mint repo (packages.linuxmint.com) not found in $S — verify Mint's own repos are present."
    fi
  else
    warn "Could not detect the release codename — NOT touching sources.list. Verify it by hand."
  fi

  # 5) Flag (and optionally disable) THIRD-PARTY / attacker-added repos.
  #    One-line .list files first (PPAs are usually one file each).
  local reported=0
  for f in "$SLD"/*.list; do
    [[ -f $f ]] || continue
    local foreign=()
    while IFS= read -r ln; do
      local h; h=$(line_host "$ln"); [[ -z $h ]] && continue
      is_off_host "$h" || foreign+=("$h")
    done < <(grep -E '^[[:space:]]*deb([[:space:]]|-src[[:space:]])' "$f" | grep -vE 'cdrom:')
    if ((${#foreign[@]})); then
      reported=1
      warn "Third-party APT repo in $f -> ${foreign[*]}"
      review "[!] Third-party repo file: $f  (hosts: ${foreign[*]})"
      if ask_yn "   Disable $f ? (do this unless the README requires this repo)"; then
        backup_file "$f"; mv "$f" "$f.disabled-by-cp"
        log "Disabled third-party repo file $f (renamed .disabled-by-cp)"
      else review "    (kept $f — confirm it is required)"; fi
    fi
  done
  #    deb822 .sources files (skip the official ubuntu.sources we manage above)
  for f in "$SLD"/*.sources; do
    [[ -f $f ]] || continue
    [[ $(basename "$f") == ubuntu.sources ]] && ! $IS_MINT && continue
    local uris; uris=$(grep -iE '^[[:space:]]*URIs:' "$f" | sed -E 's/^[^:]*:[[:space:]]*//')
    local bad=0 u h
    for u in $uris; do h=$(line_host "deb $u x y"); [[ -z $h ]] && continue; is_off_host "$h" || bad=1; done
    if ((bad)); then
      reported=1
      warn "Third-party deb822 repo in $f -> $uris"
      review "[!] Third-party deb822 repo: $f  ($uris)"
      if ask_yn "   Disable $f ?"; then backup_file "$f"; mv "$f" "$f.disabled-by-cp"; log "Disabled $f"; fi
    fi
  done
  #    Lines inside the MAIN sources.list (comment just the offending line)
  if [[ -f $SL ]]; then
    while IFS= read -r ln; do
      local h; h=$(line_host "$ln"); [[ -z $h ]] && continue
      if ! is_off_host "$h"; then
        reported=1
        warn "Third-party repo line in $SL -> $h"
        review "[!] Third-party repo line in $SL: $ln"
        if ask_yn "   Comment out this line in $SL ? ($h)"; then
          backup_file "$SL"
          # exact full-line match via awk (line contains [ ] . * etc. — not regex-safe)
          awk -v t="$ln" '$0==t{print "# " $0 "   # third-party disabled by CP script"; next} {print}' "$SL" >"$SL.cptmp" && cat "$SL.cptmp" >"$SL"
          rm -f "$SL.cptmp"
          log "Commented out third-party repo line in $SL"
        fi
      fi
    done < <(grep -E '^[[:space:]]*deb([[:space:]]|-src[[:space:]])' "$SL" | grep -vE 'cdrom:')
  fi
  ((reported==0)) && info "No third-party/unofficial APT repositories found."
}
fix_apt_sources

{ echo "--- ACTIVE APT repositories after cleanup (should be official only, unless README requires more) ---"
  grep -rhsvE '^[[:space:]]*(#|$)' "${APTDIR:-/etc/apt}/sources.list" "${APTDIR:-/etc/apt}/sources.list.d"/*.list 2>/dev/null | sed 's/^/   /'
  grep -rhsE '^[[:space:]]*(URIs|Suites|Enabled):' "${APTDIR:-/etc/apt}/sources.list.d"/*.sources 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"
wait_for_apt
if apt-get update -q >>"$LOG" 2>&1; then
  log "apt-get update OK"; APT_OK=true
else
  APT_OK=false
  warn "apt-get update reported errors — a repo may be unreachable/misconfigured. Offending lines:"
  apt-get update 2>&1 | grep -iE '^(E:|W:|Err:)' | sed 's/^/     /' | tee -a "$LOG" >>"$REPORT"
fi

#--------------------------------- USERS --------------------------------------
section "Users & groups"
REAL_PW_CHANGED=()
for u in "${TO_CREATE[@]}"; do
  if useradd -m -s /bin/bash "$u" >>"$LOG" 2>&1; then log "Created user $u (listed in README)"; else warn "Could not create user $u"; fi
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
  IFS=',' read -ra mm <<<"$members"
  for m in "${mm[@]}"; do [[ -n $m ]] && id "$m" &>/dev/null && usermod -aG "$g" "$m" && log "Added $m to group $g"; done
done

# Passwords + aging (chpasswd runs BEFORE the new PAM policy so it can't be rejected)
for u in "${AUTH_ALL[@]}"; do
  id "$u" &>/dev/null && is_human "$u" || continue
  [[ $u == "$MAIN_USER" && $CHANGE_MAIN_PW != true ]] && continue
  if echo "$u:$PW" | chpasswd >>"$LOG" 2>&1; then
    chage -M 90 -m 7 -W 14 "$u" >>"$LOG" 2>&1
    REAL_PW_CHANGED+=("$u")
  else warn "Could not set password for $u"; fi
done
((${#REAL_PW_CHANGED[@]})) && log "Secure password + aging (max 90/min 7/warn 14) set for: ${REAL_PW_CHANGED[*]}"

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

passwd -l root >>"$LOG" 2>&1 && log "Root account password locked (use sudo)"

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
log "login.defs: max age 90, min age 7, warn 14 days, 3 login retries"

# Record suspicious PAM lines BEFORE regenerating (forensics + backdoor evidence)
{ echo "--- Suspicious PAM lines found (pam_permit 'sufficient' / pam_exec are classic backdoors) ---"
  grep -nHE '^[^#]*(sufficient[[:space:]]+pam_permit\.so|pam_exec\.so)' /etc/pam.d/* 2>/dev/null; echo; } >>"$REPORT"

is_installed libpam-pwquality || apt_install libpam-pwquality cracklib-runtime
HAVE_PWQ=false;      pam_module_exists pam_pwquality.so && HAVE_PWQ=true
HAVE_CRACKLIB=false; pam_module_exists pam_cracklib.so  && HAVE_CRACKLIB=true
HAVE_FAILLOCK=false; pam_module_exists pam_faillock.so  && HAVE_FAILLOCK=true
HAVE_TALLY2=false;   pam_module_exists pam_tally2.so    && HAVE_TALLY2=true
HAVE_PWHIST=false;   pam_module_exists pam_pwhistory.so && HAVE_PWHIST=true

if $HAVE_FAILLOCK; then
  cat >/usr/share/pam-configs/faillock <<'EOF'
Name: Lock accounts after repeated failed logins (pam_faillock)
Default: yes
Priority: 0
Auth-Type: Primary
Auth:
        [default=die]   pam_faillock.so authfail deny=5 unlock_time=900
EOF
  cat >/usr/share/pam-configs/faillock_notify <<'EOF'
Name: pam_faillock pre-check and reset counter on success
Default: yes
Priority: 1024
Auth-Type: Primary
Auth:
        requisite       pam_faillock.so preauth deny=5 unlock_time=900
Account-Type: Primary
Account:
        required        pam_faillock.so
EOF
  backup_file /etc/security/faillock.conf
  set_conf /etc/security/faillock.conf deny 5
  set_conf /etc/security/faillock.conf unlock_time 900
  set_conf /etc/security/faillock.conf fail_interval 900
  pam-auth-update --force --enable faillock faillock_notify >>"$LOG" 2>&1
else
  pam-auth-update --package --force >>"$LOG" 2>&1
fi
info "PAM common-* files regenerated cleanly with pam-auth-update (removes planted lines)"

CA=/etc/pam.d/common-auth; CACC=/etc/pam.d/common-account; CPW=/etc/pam.d/common-password

# Null passwords must not authenticate
if [[ -n $(getent shadow "$MAIN_USER" | cut -d: -f2) ]]; then
  sed -i -E 's/[[:space:]]+nullok(_secure)?([[:space:]]|$)/\2/g' "$CA" && log "Removed 'nullok' — empty passwords can no longer log in"
fi

# Lockout on older releases (pam_tally2 exists only on Ubuntu <= 20.04)
if ! $HAVE_FAILLOCK && $HAVE_TALLY2; then
  grep -q pam_tally2 "$CA"   || insert_before_first "$CA" '^auth[[:space:]]' 'auth	required	pam_tally2.so onerr=fail deny=5 unlock_time=1800 audit'
  grep -q pam_tally2 "$CACC" || insert_before_first "$CACC" '^account[[:space:]]' 'account	required	pam_tally2.so'
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
elif $HAVE_CRACKLIB; then
  CLARGS="retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 maxrepeat=3 reject_username enforce_for_root"
  if grep -qE 'pam_cracklib\.so' "$CPW"; then
    sed -i -E "s/^([[:space:]]*password[[:space:]]+(\[[^]]*\]|[^[:space:]]+)[[:space:]]+pam_cracklib\.so).*/\1 $CLARGS/" "$CPW"
  else
    insert_before_first "$CPW" '^[[:space:]]*password[[:space:]].*pam_unix\.so' "password	requisite	pam_cracklib.so $CLARGS"
  fi
fi
AUTHTOK=""; grep -qE 'pam_(pwquality|cracklib)\.so' "$CPW" && AUTHTOK=" use_authtok"

# Password history
touch /etc/security/opasswd; chown root:root /etc/security/opasswd; chmod 600 /etc/security/opasswd
if $HAVE_PWHIST && ! grep -q pam_pwhistory "$CPW"; then
  insert_before_first "$CPW" '^[[:space:]]*password[[:space:]].*pam_unix\.so' "password	requisite	pam_pwhistory.so remember=5 enforce_for_root${AUTHTOK}"
fi
grep -q pam_pwhistory "$CPW" && sed -i -E '/pam_pwhistory\.so/{s/remember=[0-9]+/remember=5/; /remember=/!s/$/ remember=5/}' "$CPW"
# pam_unix: remember + minlen (some scoring checks look here), strong hashing
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
  log "PAM: complexity (12+ chars, upper/lower/digit/symbol), history (5), lockout (5 tries / 15 min) configured"
  $HAVE_FAILLOCK && info "Unlock a locked user with:  sudo faillock --user NAME --reset"
  $HAVE_TALLY2 && ! $HAVE_FAILLOCK && info "Unlock a locked user with:  sudo pam_tally2 --user NAME --reset"
else
  cp -a "$BACKUP/pam.d.orig/." /etc/pam.d/
  warn "PAM check FAILED — restored original /etc/pam.d so nobody gets locked out. Configure password policy manually."
fi

#--------------------------------- SUDOERS ------------------------------------
section "sudoers"
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
chmod 440 "$SUDOH"
if visudo -cf "$SUDOH" >/dev/null 2>&1; then log "sudoers hardening: use_pty, command logging (/var/log/sudo.log), no visible password, 15-min timeout"
else rm -f "$SUDOH"; warn "sudoers hardening drop-in failed validation — skipped"; fi

if ! visudo -c >>"$LOG" 2>&1; then
  cp -a "$BACKUP/sudoers.orig" /etc/sudoers
  [[ -d $BACKUP/sudoers.d.orig ]] && cp -a "$BACKUP/sudoers.d.orig/." /etc/sudoers.d/
  warn "sudoers failed validation — restored originals"
fi
{ echo "--- Active sudoers rules ---"; grep -hvE '^[[:space:]]*(#|$)' "${SUDO_FILES[@]}" | sed 's/^/   /'; echo; } >>"$REPORT"

#------------------------------- LOGIN SCREEN ---------------------------------
section "Login screen (guest account, auto-login)"
if [[ -d /etc/gdm3 ]]; then
  G3=/etc/gdm3/custom.conf; backup_file "$G3"
  ini_set "$G3" daemon AutomaticLoginEnable false
  ini_set "$G3" daemon TimedLoginEnable false
  ini_set "$G3" security AllowRoot false
  ini_set "$G3" security DisallowTCP true
  log "GDM: automatic/timed login disabled, root login disabled (applies at next login)"
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

#-------------------------------- FIREWALL ------------------------------------
#-------------------------- ADVANCED LOGIN CONFIGS ----------------------------
section "Advanced login hardening (su, idle timeout, console)"
# Authorized-use banners (also referenced by the SSH 'Banner' directive)
BANNER='Authorized access only. All activity is logged and monitored. Disconnect now if you are not an authorized user.'
for b in /etc/issue /etc/issue.net; do printf '%s\n' "$BANNER" >"$b"; chmod 644 "$b"; chown root:root "$b"; done

# Restrict 'su' to members of the sudo group (pam_wheel) so a standard user can't escalate
SU=/etc/pam.d/su
if [[ -f $SU ]] && pam_module_exists pam_wheel.so; then
  backup_file "$SU"
  if grep -qE '^[[:space:]]*#?[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_wheel\.so' "$SU"; then
    sed -i -E 's@^[[:space:]]*#?[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_wheel\.so.*@auth       required   pam_wheel.so use_uid group=sudo@' "$SU"
  else
    sed -i '1i auth       required   pam_wheel.so use_uid group=sudo' "$SU"
  fi
  log "su restricted to members of the 'sudo' group (pam_wheel)"
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

# securetty: never allow root login over a network (pts) tty
if [[ -f /etc/securetty ]]; then
  backup_file /etc/securetty
  sed -i -E '/^[[:space:]]*(pts\/?[0-9]*|ssh)[[:space:]]*$/d' /etc/securetty
  info "Removed any pts/ssh entries from /etc/securetty"
fi
# pam_securetty should guard console root login
grep -rqsE '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_securetty\.so' /etc/pam.d/login ||   review "Consider confirming console root login is restricted (pam_securetty in /etc/pam.d/login)."

{ echo "--- Login config summary ---"
  echo "   su group       : $(getent group sudo | cut -d: -f4)"
  echo "   TMOUT          : 900s (idle auto-logout)"
  echo "   Password aging : $(awk '/^PASS_MAX_DAYS/{print $2}' /etc/login.defs) max / $(awk '/^PASS_MIN_DAYS/{print $2}' /etc/login.defs) min days"
  echo; } >>"$REPORT"

section "Firewall (UFW)"
is_installed ufw || apt_install ufw
ssh_ports() {
  local p; p=$(mkdir -p /run/sshd; sshd -T 2>/dev/null | awk '$1=="port"{print $2}' | sort -u)
  [[ -z $p ]] && p=$(awk 'tolower($1)=="port"{print $2}' /etc/ssh/sshd_config 2>/dev/null)
  echo "${p:-22}"
}
if command -v ufw >/dev/null; then
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
  "kernel.panic_on_oops=1"
)
$DISABLE_IPV6 && SYSCTLS+=("net.ipv6.conf.all.disable_ipv6=1" "net.ipv6.conf.default.disable_ipv6=1" "net.ipv6.conf.lo.disable_ipv6=1")

# Write to the canonical file (grep-friendly) AND a high-precedence drop-in,
# and comment out any conflicting value already set in an editable sysctl dir.
{ echo "# CyberPatriot kernel/network hardening — overrides earlier files"; } >"$CPSYSCTL"
for kv in "${SYSCTLS[@]}"; do
  kv=${kv%%#*}; kv=${kv// /}; [[ -z $kv ]] && continue
  k=${kv%%=*}; v=${kv#*=}; kre=${k//./\\.}
  set_conf /etc/sysctl.conf "$k" "$v"
  echo "$k = $v" >>"$CPSYSCTL"
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

# VERIFY every value actually took effect. This is the real guarantee: it catches
# an override from ANY source (e.g. /usr/lib/sysctl.d or an attacker drop-in) that
# wins at boot. Anything that won't stick is forced with -w and, if still wrong,
# reported along with the file that's overriding it.
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

# ---- SSH ----
if $NEED_SSH; then
  is_installed openssh-server || apt_install openssh-server
  if [[ -f /etc/ssh/sshd_config ]]; then
    mkdir -p /run/sshd
    sshd -t >>"$LOG" 2>&1 || warn "sshd_config was ALREADY broken before the script: $(sshd -t 2>&1 | head -1)"
    snap=$(snapshot /etc/ssh/sshd_config /etc/ssh/sshd_config.d); backup_file /etc/ssh/sshd_config /etc/ssh/sshd_config.d
    for kv in "PermitRootLogin no" "PermitEmptyPasswords no" "Protocol 2" "X11Forwarding no" "MaxAuthTries 3" \
              "LoginGraceTime 60" "IgnoreRhosts yes" "HostbasedAuthentication no" "PermitUserEnvironment no" \
              "ClientAliveInterval 300" "ClientAliveCountMax 3" "LogLevel VERBOSE" "UsePAM yes" "StrictModes yes" \
              "AllowAgentForwarding no" "AllowTcpForwarding no" "PubkeyAuthentication yes" "Banner /etc/issue.net"; do
      k=${kv%% *}; v=${kv#* }
      sshd_set /etc/ssh/sshd_config "$k" "$v"
      for d in /etc/ssh/sshd_config.d/*.conf; do [[ -f $d ]] && sshd_set "$d" "$k" "$v" 1; done
    done
    chown root:root /etc/ssh/sshd_config; chmod 600 /etc/ssh/sshd_config
    chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null; chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null
    if sshd -t >>"$LOG" 2>&1; then
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
              local_enable=YES chroot_local_user=YES allow_writeable_chroot=YES xferlog_enable=YES \
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
        if svc_restart_ok vsftpd; then log "vsftpd: SSL/TLS enabled"
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
  is_installed proftpd-basic || is_installed proftpd-core && \
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
      rm -rf /etc/apache2; restore_snapshot "$snap"; svc_restart_ok apache2; warn "Apache config failed test — rolled back"
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

# ---- MySQL / MariaDB ----
if $NEED_MYSQL; then
  for cnf in /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mariadb.conf.d/50-server.cnf; do
    [[ -f $cnf ]] || continue
    snap=$(snapshot "$cnf"); backup_file "$cnf"
    $DB_REMOTE || ini_set "$cnf" mysqld bind-address 127.0.0.1 " = "
    ini_set "$cnf" mysqld local-infile 0 " = "
    svcn=mysql; unit_exists mariadb && ! unit_exists mysql && svcn=mariadb
    if svc_restart_ok "$svcn"; then log "MySQL/MariaDB: local-only bind (unless remote needed), LOCAL INFILE off ($cnf)"
    else restore_snapshot "$snap"; svc_restart_ok "$svcn"; warn "Database failed to restart — rolled back $cnf"; fi
    rm -rf "$snap"
  done
  review "[!] MySQL: log in with 'sudo mysql' and check for users with no password / '%' host: SELECT user,host,plugin FROM mysql.user;"
else
  svc_disable mysql mariadb
  for p in $(installed_matching 'mysql-server*' 'mariadb-server*'); do safe_purge "$p"; done
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

# ---- Mail ----
if $NEED_MAIL; then
  if command -v postconf >/dev/null; then
    backup_file /etc/postfix/main.cf
    postconf -e 'disable_vrfy_command = yes' 'smtpd_banner = $myhostname ESMTP' >>"$LOG" 2>&1
    postfix check >>"$LOG" 2>&1 && svc_restart_ok postfix && log "Postfix: VRFY disabled, banner hides version"
  fi
else
  svc_disable postfix dovecot exim4 sendmail
  for p in postfix dovecot-core dovecot-imapd dovecot-pop3d exim4 exim4-base exim4-daemon-light sendmail sendmail-bin; do safe_purge "$p"; done
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
  safe_purge nfs-kernel-server
fi

# ---- Network printer/device discovery (not needed without printing) ----
$NEED_PRINT || svc_disable avahi-daemon.socket avahi-daemon

#--------------------------- PROHIBITED SOFTWARE ------------------------------
section "Prohibited & hacking tools"
# These are classic CyberPatriot point-scorers. safe_purge refuses anything that
# would drag a desktop/critical package with it, so it won't break the system.
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
  aisleriot gnome-mahjongg gnome-mines gnome-sudoku
  freeciv freeciv-client-gtk wesnoth wesnoth-core
  hunt dsniff zaproxy burpsuite
  nis talk talkd ytalk finger fingerd rsh-client rsh-server rsh-redone-client rsh-redone-server
  rlogin rusersd rwhod rexec rstat
  snmpd prelink
  deluge deluged transmission-cli transmission-daemon transmission-gtk qbittorrent rtorrent ktorrent amule
  frostwire vuze
)
PROHIBITED+=(logkeys xspy lkl uberkey THC-Keylogger)
for p in "${PROHIBITED[@]}"; do safe_purge "$p"; done
# wireshark/tcpdump: if the README names them as allowed, say so manually
review "[!] If README lists a network tool (nmap/wireshark/tcpdump) as REQUIRED, reinstall it; this script removed all of them."

# Netcat traditional symlink
[[ -L /usr/bin/nc || -e /usr/bin/nc ]] && ! is_installed netcat-openbsd && ! is_installed netcat-traditional && rm -f /usr/bin/nc 2>/dev/null

# Telnet server (never leave a telnet *server*; client is usually harmless)
if ! $NEED_TELNET; then
  svc_disable inetutils-telnetd telnetd
  for p in telnetd inetutils-telnetd telnetd-ssl; do safe_purge "$p"; done
fi
# inetd super-servers (unless a service that needs them is active)
if ! $NEED_TELNET && ! $NEED_FTP; then
  svc_disable openbsd-inetd xinetd
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
for p in popularity-contest apport whoopsie; do safe_purge "$p"; done
# Zeitgeist activity logger
for p in zeitgeist zeitgeist-core zeitgeist-datahub; do safe_purge "$p"; done
log "Crash reporters / activity loggers removed or disabled"

#--------------------------- STARTUP PERSISTENCE ------------------------------
section "Startup items, cron & services audit"
# rc.local
if [[ -f /etc/rc.local ]] && grep -qvE '^[[:space:]]*(#|exit 0|$)' /etc/rc.local; then
  backup_file /etc/rc.local
  { echo "--- /etc/rc.local had commands (saved to backup, then neutralized) ---"; grep -vE '^[[:space:]]*(#|$)' /etc/rc.local; echo; } >>"$REPORT"
  printf '#!/bin/sh -e\nexit 0\n' >/etc/rc.local; chmod 755 /etc/rc.local
  warn "/etc/rc.local contained startup commands — review them in REVIEW-ME.txt (neutralized)"
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
for d in /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /var/spool/cron/crontabs; do
  [[ -d $d ]] || continue
  grep -rslE '/dev/tcp/|bash -i|nc -e|ncat -e|mkfifo .*(nc|sh)|base64 -d[[:space:]]*\|[[:space:]]*(ba)?sh' "$d" 2>/dev/null | while read -r f; do
    is_protected "$f" && continue
    backup_file "$f"; mv "$f" "$QUAR/$(echo "$f" | tr / _)" 2>/dev/null \
      && warn "Quarantined cron file with reverse-shell pattern: $f (copy in $QUAR)"
  done
done
run systemctl daemon-reload
# cron/at access
( cd /etc || exit; rm -f cron.deny at.deny; printf 'root\n' >cron.allow; printf 'root\n' >at.allow; chown root:root cron.allow at.allow; chmod 600 cron.allow at.allow )
log "cron/at restricted to root"
# Lock down ownership & permissions on all cron/at locations
for f in /etc/crontab /etc/cron.allow /etc/at.allow; do [[ -e $f ]] && { chown root:root "$f"; chmod 600 "$f"; }; done
for d in /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.yearly; do
  [[ -d $d ]] && { chown root:root "$d"; chmod 700 "$d"; }
done
[[ -d /var/spool/cron ]] && chmod 700 /var/spool/cron /var/spool/cron/* 2>/dev/null
[[ -d /var/spool/cron/crontabs ]] && { chown root:crontab /var/spool/cron/crontabs 2>/dev/null; chmod 1730 /var/spool/cron/crontabs 2>/dev/null; }
[[ -d /etc/cron.d ]] && find /etc/cron.d -type f -exec chmod 600 {} \; 2>/dev/null
log "cron file/directory ownership & permissions hardened (root-owned, not world-accessible)"
# Enabled services that listen but aren't required — just list them
{ echo "--- Enabled services (disable anything you don't recognize) ---"; systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null | awk '{print "   " $1}'; echo
  echo "--- Listening sockets (match each to an authorized service) ---"; (ss -tulpnH 2>/dev/null || netstat -tulpn 2>/dev/null) | sed 's/^/   /'; echo; } >>"$REPORT"

#------------------------------- MEDIA FILES ----------------------------------
#--------------------- SSH KEYS & BACKDOOR PERSISTENCE ------------------------
section "SSH keys & persistence backdoors"
# Attackers' #1 Linux persistence trick is dropping their public key into a
# user's authorized_keys. Every planted key is usually a scored vulnerability.
SUSP='/dev/tcp/|/dev/udp/|bash -i|sh -i|nc [^|]*-e|ncat [^|]*-e|mkfifo|base64[[:space:]]+-d|python[0-9]?[[:space:]]+-c|perl[[:space:]]+-e|socat|/tmp/|curl[^|]*\||wget[^|]*\|'

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
    if grep -qE '/tmp/|/dev/shm/|/var/tmp/|/home/' /etc/ld.so.preload; then
      cp -a /etc/ld.so.preload "$QUAR/ld.so.preload"; : >/etc/ld.so.preload
      warn "Entries pointed at writable dirs (near-certain rootkit) — cleared it (copy in $QUAR)."
    fi
  fi
fi

# systemd persistence (the modern replacement for evil cron jobs)
section "systemd units & timers"
{ echo "--- Enabled systemd TIMERS (modern persistence — verify each) ---"
  systemctl list-timers --all --no-legend 2>/dev/null | sed 's/^/   /'
  echo "--- Unit files under /etc/systemd/system (admin-added — scrutinize) ---"
  find /etc/systemd/system -maxdepth 2 -name '*.service' -o -name '*.timer' 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"
for base in /etc/systemd/system /run/systemd/system /lib/systemd/system /usr/lib/systemd/system; do
  [[ -d $base ]] || continue
  grep -rslEi "ExecStart=.*($SUSP)" "$base" 2>/dev/null | while read -r unit; do
    is_protected "$unit" && continue
    uname=$(basename "$unit")
    warn "systemd unit looks like a reverse shell / downloader: $unit"
    review "[!] Suspicious systemd unit: $unit"
    review "      $(grep -iE 'ExecStart=' "$unit" | head -1)"
    if ask_yn "   Disable & quarantine suspicious unit $uname?"; then
      systemctl disable --now "$uname" >>"$LOG" 2>&1
      backup_file "$unit"; mv "$unit" "$QUAR/$(echo "$unit" | tr / _)" 2>/dev/null
      systemctl daemon-reload; log "Quarantined malicious systemd unit $uname"
    fi
  done
done

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
{ echo "--- Login/shell scripts containing suspicious commands (reverse shells, downloaders) ---"
  for f in "${RC_FILES[@]}"; do
    m=$(grep -nEi "$SUSP" "$f" 2>/dev/null)
    [[ -n $m ]] && { echo "   $f:"; sed 's/^/        /' <<<"$m"; }
  done; echo; } >>"$REPORT"
for f in "${RC_FILES[@]}"; do grep -qEi "$SUSP" "$f" 2>/dev/null && { warn "Suspicious line in startup file: $f (see REVIEW-ME.txt)"; ((HITS++)); }; done
((HITS==0)) && info "No obvious reverse-shell/downloader lines in login scripts."

# root PATH sanity
if grep -qE '(^|:)(\.|)(:|$)' <<<"${PATH}"; then review "[!] root's PATH contains '.' or an empty element — fix in /root/.bashrc /etc/profile"; fi

section "Media & unauthorized files"
if ask_yn "Scan for media files (mp3, mp4, etc.) in user home folders? (list first; you choose per file whether to delete)"; then
  mapfile -t MEDIA < <(find /home /root -type f \
    \( -iname '*.mp3' -o -iname '*.mp4' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.flac' -o -iname '*.ogg' \
       -o -iname '*.wav' -o -iname '*.wma' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.mkv' -o -iname '*.flv' \
       -o -iname '*.wmv' -o -iname '*.mpg' -o -iname '*.mpeg' -o -iname '*.webm' -o -iname '*.m4v' -o -iname '*.3gp' \
       -o -iname '*.gif' -o -iname '*.bmp' \) 2>/dev/null)
  if ((${#MEDIA[@]})); then
    printf '%s\n' "${MEDIA[@]}" >"$LOGDIR/media-files.txt"
    echo "Found ${#MEDIA[@]} media files (full list: $LOGDIR/media-files.txt)."
    review "--- Media files found (delete the ones the README prohibits) ---"
    printf '   %s\n' "${MEDIA[@]}" >>"$REPORT"; review ""
    if ask_yn "Move ALL ${#MEDIA[@]} media files to quarantine ($QUAR)? (recoverable, not deleted)"; then
      for f in "${MEDIA[@]}"; do is_protected "$f" && continue; mkdir -p "$QUAR/media$(dirname "$f")"; mv "$f" "$QUAR/media$f" 2>/dev/null; done
      log "Moved media files to $QUAR/media (restore any you need)"
    else info "Media files left in place — listed in REVIEW-ME.txt"; fi
  else info "No media files found."; fi
fi

# Files with no owner (deleted-user leftovers) and world-writable files
# Archives & scripts in user areas (hiding spots for tools/backdoors, e.g. a pyrdp .zip).
{ echo "--- Archives in home/tmp/opt (verify contents; attackers hide tools here) ---"
  find /home /root /tmp /var/tmp /opt -xdev -type f \
    \( -iname '*.zip' -o -iname '*.tar' -o -iname '*.tar.gz' -o -iname '*.tgz' -o -iname '*.gz' \
       -o -iname '*.7z' -o -iname '*.rar' -o -iname '*.bz2' -o -iname '*.xz' \) 2>/dev/null | head -80 | sed 's/^/   /'
  echo "--- Loose scripts in odd locations (.py/.sh/.pl outside normal dirs — verify each) ---"
  find /home /root /tmp /var/tmp /opt /usr/share /usr/local -xdev -type f \
    \( -iname '*.py' -o -iname '*.sh' -o -iname '*.pl' -o -iname '*.rb' \) 2>/dev/null \
    | grep -vE '^/usr/share/(doc|locale|man|help|icons|applications|python3)' | head -80 | sed 's/^/   /'
  echo; } >>"$REPORT"

{ echo "--- Files owned by no user/group (orphaned — often from deleted attackers) ---"
  find / -xdev \( -nouser -o -nogroup \) -not -path '/proc/*' 2>/dev/null | head -60 | sed 's/^/   /'
  echo "--- World-writable files (chmod o-w the ones that shouldn't be) ---"
  find / -xdev -type f -perm -0002 -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null | head -60 | sed 's/^/   /'
  echo "--- World-writable directories WITHOUT sticky bit (should have it: chmod +t) ---"
  find / -xdev -type d -perm -0002 ! -perm -1000 -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null | head -40 | sed 's/^/   /'
  echo "--- Unexpected SUID/SGID binaries (compare to a clean system) ---"
  find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -not -path '/proc/*' 2>/dev/null | sed 's/^/   /'
  echo; } >>"$REPORT"

#--------------------------- CORE FILE PERMISSIONS ----------------------------
#------------------------------- APPARMOR -------------------------------------
section "AppArmor (mandatory access control)"
if [[ ${APT_OK:-true} == true ]]; then apt_install apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra; fi
if command -v aa-status >/dev/null 2>&1; then
  run systemctl enable --now apparmor
  enf=0
  for prof in /etc/apparmor.d/*; do
    [[ -f $prof ]] || continue
    case "$(basename "$prof")" in disable|local|abstractions|tunables|force-complain) continue ;; esac
    aa-enforce "$prof" >>"$LOG" 2>&1 && ((enf++))
  done
  log "AppArmor enabled; set $enf profile(s) to enforce mode"
  { echo "--- AppArmor status ---"; aa-status 2>/dev/null | head -20 | sed 's/^/   /'; echo; } >>"$REPORT"
else warn "AppArmor tools unavailable (offline?) — enable manually: sudo systemctl enable --now apparmor"; fi

#---------------------- CIS-STYLE CONFIG HARDENING ----------------------------
section "Extra config hardening (CIS-style)"
# Disable Ctrl-Alt-Del reboot (the old upstart method no longer works on systemd)
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

# Authorized-use login banner (sometimes scored; harmless otherwise)
BANNER='Authorized access only. All activity may be monitored and reported.'
printf '%s\n' "$BANNER" >/etc/issue
printf '%s\n' "$BANNER" >/etc/issue.net
chmod 644 /etc/issue /etc/issue.net
# Strip distro version disclosure from the dynamic MOTD header
[[ -f /etc/update-motd.d/10-help-text ]] && chmod -x /etc/update-motd.d/10-help-text 2>/dev/null
log "Legal login banner set in /etc/issue and /etc/issue.net"

# Stricter default umask for interactive shells too (not just login.defs)
echo 'umask 027' >/etc/profile.d/99-cp-umask.sh; chmod 644 /etc/profile.d/99-cp-umask.sh

# passwd / group database integrity (read-only report)
{ echo "--- passwd/group integrity (pwck -r / grpck -r) — investigate anything listed ---"
  pwck -r 2>&1 | sed 's/^/   /'; grpck -r 2>&1 | sed 's/^/   /'; echo; } >>"$REPORT"

# Ensure no non-root account has a GID/UID that duplicates root, and nologin on system accounts without it
{ echo "--- System accounts with a real login shell (should usually be nologin/false) ---"
  awk -F: -v min="$UID_MIN" '$3>0 && $3<min && $7 !~ /(nologin|false|sync)$/ {print "   " $1 "  (uid " $3 ", shell " $7 ")"}' /etc/passwd
  echo; } >>"$REPORT"

section "Core file permissions"
fix_perm() { local m=$1 o=$2 f=$3; [[ -e $f ]] || return; chown "$o" "$f" 2>/dev/null; chmod "$m" "$f" 2>/dev/null; }
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
chmod 440 /etc/sudoers 2>/dev/null
[[ -d /etc/cron.d ]] && chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly 2>/dev/null
# Home directories shouldn't be world-readable
for d in /home/*; do
  [[ -d $d ]] || continue; u=$(basename "$d")
  id "$u" &>/dev/null && { chmod 750 "$d" 2>/dev/null; chown "$u": "$d" 2>/dev/null; }
done
log "Permissions set on passwd/shadow/group/sudoers/grub/crontab and home directories"
# root's PATH and default umask
grep -qE '^[[:space:]]*UMASK' /etc/login.defs && sed -i -E 's/^[[:space:]]*UMASK.*/UMASK\t\t027/' /etc/login.defs || set_conf /etc/login.defs UMASK 027 $'\t'
grep -qxF 'session optional pam_umask.so' /etc/pam.d/common-session || echo 'session optional pam_umask.so' >>/etc/pam.d/common-session

#------------------------------ AUDITING TOOLS --------------------------------
#---------------------- ADDITIONAL HARDENING (point-earners) ------------------
section "SUID backdoors, weak hashes, rhosts, world-writable"

# 1) SUID/SGID on a shell, interpreter or core tool = instant-root backdoor.
#    These must NEVER be setuid on a normal box, so strip the bit (recoverable).
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
stripped=0
for pat in "${NEVER_SUID[@]}"; do
  for f in $pat; do
    [[ -f $f && ! -L $f ]] || continue
    m=$(stat -c '%A' "$f" 2>/dev/null)
    if [[ $m == ???s* || $m == ??????s* ]]; then
      review "[!] SUID/SGID removed from $f (was $(stat -c '%a' "$f"))"
      chmod u-s,g-s "$f" 2>/dev/null && { warn "Removed SUID/SGID from $f (setuid shell/tool = root backdoor)"; ((stripped++)); }
    fi
  done
done
((stripped)) && log "Stripped SUID/SGID from $stripped shell/interpreter/tool binary(ies)" || info "No backdoor SUID shells/tools found."

# Surface any OTHER unexpected SUID/SGID binaries vs. a normal-system baseline.
BASELINE='/usr/bin/(sudo|su|passwd|chsh|chfn|gpasswd|newgrp|mount|umount|fusermount3?|pkexec|at|crontab|ssh-agent|expiry|wall|write)$|/usr/lib/.*(dbus|polkit|openssh|eject|xorg|snapd|utempter).*|/bin/(su|mount|umount|ping|fusermount)$|/usr/sbin/(pppd|mount.nfs)$'
{ echo "--- Unexpected SUID/SGID binaries (compare to a clean image; investigate anything odd) ---"
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
      warn "YOUR account ($name) uses a weak $wk password hash — run 'passwd' to rehash it as SHA-512."
    else
      echo "$name:$PW" | chpasswd && log "Rehashed weak $wk password for $name (SHA-512)"
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

# 5) Lock down /root and verify home ownership
chmod 700 /root 2>/dev/null; chown root:root /root 2>/dev/null
log "/root restricted to root (700)"

#----------------------------- BROWSER POLICY ---------------------------------
section "Firefox security policy"
# Enterprise policy: telemetry off, tracking protection on, no password saving, auto-update on.
if is_installed firefox || is_installed firefox-esr || [[ -d /etc/firefox || -d /usr/lib/firefox ]] || (command -v snap >/dev/null && snap list firefox >/dev/null 2>&1); then
  mkdir -p /etc/firefox/policies
  cat >/etc/firefox/policies/policies.json <<'JSON'
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
    "SearchSuggestEnabled": false
  }
}
JSON
  chmod 644 /etc/firefox/policies/policies.json
  if command -v python3 >/dev/null && python3 -c 'import json,sys;json.load(open("/etc/firefox/policies/policies.json"))' 2>/dev/null; then
    log "Firefox hardening policy installed (telemetry off, tracking protection on, no saved passwords)"
  else warn "Firefox policy JSON failed to validate — removing it."; rm -f /etc/firefox/policies/policies.json; fi
  review "Note: the Firefox policy applies to the .deb/Mint Firefox; Snap Firefox may need the same settings set in-app."
else info "Firefox not installed — skipping browser policy."; fi

# Chromium / Chrome enterprise policy (the README's browser is often Chromium):
# safe browsing on, pop-ups & dangerous downloads blocked, no password/autofill saving.
if is_installed chromium || is_installed chromium-browser || is_installed google-chrome-stable \
   || [[ -d /etc/chromium || -d /etc/chromium-browser ]] || (command -v snap >/dev/null && snap list chromium >/dev/null 2>&1); then
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
  "DownloadRestrictions": 3,
  "DefaultGeolocationSetting": 2,
  "DefaultNotificationsSetting": 2,
  "DnsOverHttpsMode": "automatic",
  "ComponentUpdatesEnabled": true,
  "BackgroundModeEnabled": false
}
JSON
  wrote=0
  for d in /etc/chromium/policies/managed /etc/chromium-browser/policies/managed /etc/opt/chrome/policies/managed; do
    mkdir -p "$d" 2>/dev/null || continue
    printf '%s\n' "$CHROME_POLICY" >"$d/cp-hardening.json"; chmod 644 "$d/cp-hardening.json"; ((wrote++))
  done
  if command -v python3 >/dev/null && printf '%s' "$CHROME_POLICY" | python3 -c 'import json,sys;json.load(sys.stdin)' 2>/dev/null; then
    log "Chromium/Chrome hardening policy installed ($wrote location(s): safe browsing, pop-up & dangerous-download blocking, no saved passwords)"
  else
    warn "Chromium policy JSON failed to validate — removing it."
    rm -f /etc/chromium/policies/managed/cp-hardening.json /etc/chromium-browser/policies/managed/cp-hardening.json /etc/opt/chrome/policies/managed/cp-hardening.json
  fi
  review "Note: browser policy applies to the .deb/Mint Chromium; a Snap Chromium may need the same settings set in-app (Settings > Privacy/Security)."
else info "Chromium/Chrome not installed — skipping."; fi

#------------------------------- AUDIT RULES ----------------------------------
# Only if auditd is present; watch the files attackers tamper with.
if [[ -d /etc/audit/rules.d ]]; then
  cat >/etc/audit/rules.d/cp-hardening.rules <<'AUD'
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope
-w /etc/ssh/sshd_config -p wa -k sshd
-w /var/log/auth.log -p wa -k authlog
-w /etc/pam.d/ -p wa -k pam
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
AUD
  command -v augenrules >/dev/null && augenrules --load >>"$LOG" 2>&1
  run systemctl restart auditd
  log "auditd watch rules installed for passwd/shadow/sudoers/sshd/pam/cron"
fi

section "Security auditing tools"
if [[ ${APT_OK:-true} == true ]]; then
  apt_install auditd audispd-plugins && { run systemctl enable --now auditd; log "auditd installed & enabled"; }
  if apt_install aide aide-common; then
    log "AIDE (file integrity monitor) installed — initialise later with: sudo aideinit (slow)"
    review "[!] Optional: run 'sudo aideinit' to build the AIDE integrity database (takes several minutes)."
  fi
  # libpam-tmpdir and apt-listbugs are low-risk hardening extras
  apt_install libpam-tmpdir >/dev/null 2>&1
fi
# Enable process accounting if present
unit_exists acct && run systemctl enable --now acct

#---------------------------- AUTOMATIC UPDATES -------------------------------
# Full "Software & Updates -> Updates" configuration. These are the exact knobs
# the GUI (and the scoring engine) read: the APT::Periodic counters, the
# unattended-upgrades security origin, and the systemd timers that run it.
section "Automatic updates (security + daily checks)"
if [[ ${APT_OK:-true} == true ]]; then
  apt_install unattended-upgrades update-notifier-common apt-listchanges
fi

# 1) APT::Periodic — what "Software & Updates" writes. 20auto-upgrades is the
#    modern file; 10periodic is the legacy one (kept in sync so either check passes).
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
[[ -f /etc/apt/apt.conf.d/10periodic ]] && write_periodic /etc/apt/apt.conf.d/10periodic
log "APT::Periodic set: update lists daily, download upgrades, run unattended-upgrade, autoclean weekly"

# 2) unattended-upgrades: make sure the SECURITY (and -updates) origins are active.
#    We only uncomment the distro's own default origin lines, so the codename
#    expands correctly on both Ubuntu and Mint — no hand-crafted origins to get wrong.
U50=/etc/apt/apt.conf.d/50unattended-upgrades
if [[ -f $U50 ]]; then
  backup_file "$U50"
  sed -i -E 's@^//([[:space:]]*"\$\{distro_id\}:\$\{distro_codename\}-security";)@        \1@' "$U50"
  sed -i -E 's@^//([[:space:]]*"\$\{distro_id\}:\$\{distro_codename\}-updates";)@        \1@'  "$U50"
  sed -i -E 's@^//([[:space:]]*"\$\{distro_id\}ESMApps:\$\{distro_codename\}-apps-security";)@        \1@' "$U50"
  sed -i -E 's@^//([[:space:]]*"\$\{distro_id\}ESM:\$\{distro_codename\}-infra-security";)@        \1@'   "$U50"
  # NEVER auto-enable -proposed or -backports (unstable) — re-comment if someone did
  sed -i -E 's@^([[:space:]]*)("\$\{distro_id\}:\$\{distro_codename\}-(proposed|backports)";)@\1// \2@' "$U50"
  log "unattended-upgrades: security + updates origins enabled (proposed/backports left off)"
else
  warn "50unattended-upgrades not found — relying on the drop-in below for origins."
fi

# 3) Safety drop-in (highest precedence). Critically: NO automatic reboot and NO
#    autoremove during the round, so the updater can't take the box down or pull
#    out the desktop. These override anything above.
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
// If 50unattended-upgrades is missing, these ensure security still auto-installs:
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
        "${distro_id}ESMApps:${distro_codename}-apps-security";
        "${distro_id}ESM:${distro_codename}-infra-security";
        "Ubuntu:${distro_codename}-security";
};
EOF
chmod 644 /etc/apt/apt.conf.d/52cyberpatriot-unattended
log "Safety overrides set: no auto-reboot, no auto-remove (protects the desktop)"

# 4) Make sure the machinery that RUNS all this is actually enabled — an attacker
#    may have masked the timers so updates silently never run.
for t in apt-daily.timer apt-daily-upgrade.timer; do
  systemctl unmask "$t" >>"$LOG" 2>&1
  systemctl enable --now "$t" >>"$LOG" 2>&1
done
systemctl unmask unattended-upgrades.service >>"$LOG" 2>&1
run systemctl enable --now unattended-upgrades
log "apt-daily + apt-daily-upgrade timers unmasked and enabled; unattended-upgrades service on"

# 5) Validate the config actually parses, and dry-run the updater if we can.
if apt-config dump >/dev/null 2>>"$LOG"; then
  info "APT auto-update config parses cleanly."
else
  warn "An APT config file has a syntax error — run 'sudo apt-config dump' to find it."
fi
if command -v unattended-upgrade >/dev/null 2>&1 && [[ ${APT_OK:-true} == true ]]; then
  if unattended-upgrade --dry-run >>"$LOG" 2>&1; then info "unattended-upgrade --dry-run succeeded."
  else warn "unattended-upgrade --dry-run reported a problem (see log) — check origins/network."; fi
fi
{ echo "--- Automatic-update settings in effect ---"
  apt-config dump 2>/dev/null | grep -iE 'APT::Periodic|Unattended-Upgrade::(Allowed-Origins|Automatic-Reboot|Remove-Unused)' | sed 's/^/   /'
  echo "   Timers:"; systemctl is-enabled apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null | sed 's/^/     /'
  echo; } >>"$REPORT"
log "Daily update checks + automatic security upgrades fully configured"

#-------------------------------- UPDATES -------------------------------------
if [[ $UPDATE_MODE != s && ${APT_OK:-true} == true ]]; then
  section "Installing updates (this can take a while)"
  wait_for_apt; apt-get update -q >>"$LOG" 2>&1
  if [[ $UPDATE_MODE == f ]]; then
    echo "   Full upgrade running... (watch progress in another terminal: tail -f '$LOG')"
    apt-get upgrade "${APT_OPTS[@]}" >>"$LOG" 2>&1
    apt-get "${APT_OPTS[@]}" --with-new-pkgs upgrade >>"$LOG" 2>&1
    apt-get dist-upgrade "${APT_OPTS[@]}" >>"$LOG" 2>&1
    log "Full system upgrade complete"
  else
    CRIT=(bash sudo openssl libssl3 libssl1.1 openssh-server openssh-client libpam-modules libpam-runtime
          linux-generic linux-image-generic firefox apache2 nginx-core vsftpd samba bind9 libc6 dpkg apt
          mysql-server mariadb-server tar gzip wget curl sysstat)
      TO_UP=(); for p in "${CRIT[@]}"; do is_installed "$p" && TO_UP+=("$p"); done
    ((${#TO_UP[@]})) && apt-get install "${APT_OPTS[@]}" --only-upgrade "${TO_UP[@]}" >>"$LOG" 2>&1
    log "Critical packages upgraded: ${TO_UP[*]}"
  fi
  # Firefox via snap
  if command -v snap >/dev/null && snap list firefox >/dev/null 2>&1; then run snap refresh firefox; log "Firefox (snap) refreshed"; fi
fi

# Verify Shellshock is already patched (don't "test" by running the exploit)
if command -v dpkg >/dev/null; then
  bv=$(dpkg-query -W -f='${Version}' bash 2>/dev/null)
  info "bash version: $bv (Shellshock was fixed in 4.3-7ubuntu1.4 / all supported releases)"
fi

#------------------------------- INVENTORIES ----------------------------------
#------------------------- MALWARE & INTEGRITY SCANS --------------------------
section "Malware & integrity scanners"
# These directly find the planted backdoors/trojaned binaries the scoring
# engine rewards. They only REPORT (never auto-delete) — you review findings.
if [[ ${APT_OK:-true} != true ]]; then
  warn "No working APT/internet — skipping scanner installs. Run them later once online."
else
  SCAN_SUMMARY=()

  # debsums: find package files that were modified after install (trojaned binaries)
  if apt_install debsums; then
    echo "   Checking system binaries against package checksums (debsums)..."
    changed=$(debsums -s 2>&1 | grep -vE 'no md5sums|^$' )
    { echo "--- debsums: MODIFIED or MISSING packaged files (a changed /bin/* is a red flag) ---"
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

  # ClamAV: update signatures then scan the places malware hides
  if apt_install clamav clamav-freshclam; then
    echo "   Updating ClamAV signatures (freshclam)..."
    run systemctl stop clamav-freshclam
    if freshclam >>"$LOG" 2>&1; then
      echo "   Scanning (this can take several minutes)..."
      SCANLOG="$LOGDIR/clamav-scan.txt"
      clamscan -ri --max-filesize=200M --max-scansize=400M \
        --exclude-dir='^/proc' --exclude-dir='^/sys' --exclude-dir='^/dev' --exclude-dir='^/run' \
        /home /root /tmp /var/tmp /var/www /srv /opt /usr/local /etc >"$SCANLOG" 2>>"$LOG"
      infected=$(awk -F': ' '/Infected files:/{print $2}' "$SCANLOG")
      { echo "--- ClamAV results (full log: $SCANLOG) ---"
        grep -E 'FOUND$' "$SCANLOG" | sed 's/^/   /'; echo "   Infected files: ${infected:-0}"; echo; } >>"$REPORT"
      if [[ ${infected:-0} -gt 0 ]]; then warn "ClamAV found ${infected} infected file(s) — listed in REVIEW-ME.txt"; SCAN_SUMMARY+=("ClamAV: ${infected} infected"); else SCAN_SUMMARY+=("ClamAV: clean"); fi
      run systemctl start clamav-freshclam
    else
      warn "freshclam could not download virus signatures (offline?) — ClamAV scan skipped."
    fi
  fi

  ((${#SCAN_SUMMARY[@]})) && log "Scan summary: ${SCAN_SUMMARY[*]}"
fi

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
id "$MAIN_USER" | grep -qw sudo || { warn "YOU ($MAIN_USER) are not in the sudo group! Fix NOW in your root terminal: usermod -aG sudo $MAIN_USER"; ((PROBLEMS++)); }
visudo -c >/dev/null 2>&1 || { warn "sudoers is INVALID — fix before logout!"; ((PROBLEMS++)); }
pam_sanity_ok || { warn "PAM looks broken — keep your root shell open and verify you can log in!"; ((PROBLEMS++)); }
if $NEED_SSH; then mkdir -p /run/sshd; sshd -t >/dev/null 2>&1 || { warn "sshd_config invalid"; ((PROBLEMS++)); }; fi
extra_uid0=$(awk -F: '$3==0{print $1}' /etc/passwd | grep -vx root | tr '\n' ' ')
[[ -n $extra_uid0 ]] && { warn "Still UID-0 accounts besides root: $extra_uid0"; ((PROBLEMS++)); }
dup=$(awk -F: '{c[$3]++} END{for(u in c) if(c[u]>1) print u}' /etc/passwd)
[[ -n $dup ]] && warn "Duplicate UID(s): $dup"

{ echo; echo "=== QUICK MANUAL CHECKLIST (things a script shouldn't automate) ==="
  echo " [ ] Re-read the README; do every FORENSICS question and scored task it lists."
  echo " [ ] Confirm the admin/standard-user split matches the README exactly."
  echo " [ ] Firefox/Chrome, LibreOffice, and the kernel are fully updated (Software Updater)."
  echo " [ ] Review enabled-services.txt and listening-ports.txt; disable anything unexplained."
  echo " [ ] Look over the SUID/SGID, world-writable and orphaned-file lists above."
  echo " [ ] Check /etc/hosts for bogus redirects; check browser homepage/proxy settings."
  echo " [ ] For each required service, verify its config against CIS / the README."
  echo " [ ] Empty the trash of deleted users only after you've answered forensics questions."
  echo; } >>"$REPORT"

# Harden /etc/hosts only if clearly tampered (don't wipe legitimate entries blindly)
if grep -qE '(^|[[:space:]])(0\.0\.0\.0|127\.0\.0\.1)[[:space:]]+.*(update|security|ubuntu|microsoft|google|antivirus|clamav)' /etc/hosts; then
  backup_file /etc/hosts
  review "[!] /etc/hosts may contain entries that block update/security sites — inspect it (backup saved)."
  warn "/etc/hosts has suspicious redirect entries — review it (not auto-edited to avoid breaking name resolution)."
fi
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
echo "   3. Only then close your spare root shell."
echo
echo "${C}Reminder: the biggest point gains are the README's scored tasks and forensics${N}"
echo "${C}questions — this script handles the generic hardening, not the scenario-specific items.${N}"
