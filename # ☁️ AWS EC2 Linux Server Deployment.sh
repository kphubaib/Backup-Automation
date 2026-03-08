#!/bin/bash
# =============================================================================
# Automated Backup Script using rsync
# Author: Hubaib
# Description: Backs up specified directories to a local or remote destination.
#              Supports incremental backups, retention policy, and logging.
# Usage:
#   Local:  ./backup-automation.sh
#   Remote: ./backup-automation.sh --remote user@192.168.1.200:/backups
# Cron:   0 2 * * * /path/to/backup-automation.sh >> /var/log/backup.log 2>&1
# =============================================================================

# ── Configuration ─────────────────────────────────────────────────────────────
BACKUP_SOURCES=(
    "/etc"
    "/home"
    "/var/www/html"
)

BACKUP_DEST_LOCAL="/backup/local"   # Local backup destination
REMOTE_DEST="${2:-}"                # Optional remote: user@host:/path
RETENTION_DAYS=30                   # Delete backups older than this many days
LOG_FILE="/var/log/backup-automation.log"
DATE_STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_DIR="${BACKUP_DEST_LOCAL}/${DATE_STAMP}"

# rsync options:
#   -a  Archive (preserves permissions, timestamps, symlinks, owner, group)
#   -v  Verbose
#   -z  Compress during transfer
#   --delete  Remove files from dest that no longer exist in source
#   --progress  Show progress per file
RSYNC_OPTS="-az --delete --progress --stats"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Logging ───────────────────────────────────────────────────────────────────
log() {
    local LEVEL="$1"
    local MSG="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $MSG" | tee -a "$LOG_FILE"
}

log_info()  { log "INFO " "$1"; echo -e "  ${GREEN}✔${RESET}  $1"; }
log_warn()  { log "WARN " "$1"; echo -e "  ${YELLOW}⚠${RESET}  $1"; }
log_error() { log "ERROR" "$1"; echo -e "  ${RED}✘${RESET}  $1"; }

# ── Pre-flight Checks ─────────────────────────────────────────────────────────
preflight_checks() {
    echo -e "\n${BOLD}── Pre-flight Checks ───────────────────────────${RESET}"

    # Check rsync is installed
    if ! command -v rsync &>/dev/null; then
        log_error "rsync is not installed. Install with: dnf install rsync -y"
        exit 1
    fi
    log_info "rsync is available: $(rsync --version | head -1)"

    # Check backup sources exist
    for SRC in "${BACKUP_SOURCES[@]}"; do
        if [[ -d "$SRC" ]]; then
            SIZE=$(du -sh "$SRC" 2>/dev/null | cut -f1)
            log_info "Source exists: $SRC (${SIZE})"
        else
            log_warn "Source not found (skipping): $SRC"
        fi
    done

    # Create local backup destination
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory created: $BACKUP_DIR"
}

# ── Perform Backup ────────────────────────────────────────────────────────────
run_backup() {
    echo -e "\n${BOLD}── Running Backup ──────────────────────────────${RESET}"

    local TOTAL_SUCCESS=0
    local TOTAL_FAIL=0

    for SRC in "${BACKUP_SOURCES[@]}"; do
        # Skip sources that don't exist
        [[ ! -d "$SRC" ]] && continue

        # Create destination subdirectory mirroring source path
        DEST_DIR="${BACKUP_DIR}${SRC}"
        mkdir -p "$DEST_DIR"

        echo -e "\n  ${CYAN}Backing up:${RESET} $SRC → $DEST_DIR"
        log "INFO " "Starting backup: $SRC"

        # Run rsync
        if rsync $RSYNC_OPTS "$SRC/" "$DEST_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
            log_info "Backup successful: $SRC"
            ((TOTAL_SUCCESS++))
        else
            log_error "Backup FAILED: $SRC"
            ((TOTAL_FAIL++))
        fi
    done

    echo ""
    log_info "Backup complete — Success: $TOTAL_SUCCESS | Failed: $TOTAL_FAIL"
}

# ── Remote Sync (optional) ────────────────────────────────────────────────────
sync_to_remote() {
    if [[ -z "$REMOTE_DEST" ]]; then
        return
    fi

    echo -e "\n${BOLD}── Syncing to Remote ───────────────────────────${RESET}"
    log "INFO " "Starting remote sync to: $REMOTE_DEST"

    if rsync $RSYNC_OPTS "$BACKUP_DIR/" "$REMOTE_DEST/${DATE_STAMP}/" 2>&1 | tee -a "$LOG_FILE"; then
        log_info "Remote sync successful: $REMOTE_DEST"
    else
        log_error "Remote sync FAILED: $REMOTE_DEST"
    fi
}

# ── Retention Policy ──────────────────────────────────────────────────────────
apply_retention() {
    echo -e "\n${BOLD}── Applying Retention Policy ───────────────────${RESET}"
    log "INFO " "Removing backups older than $RETENTION_DAYS days"

    # Find and delete old backups
    DELETED=$(find "$BACKUP_DEST_LOCAL" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -print -exec rm -rf {} \; 2>/dev/null | wc -l)

    if (( DELETED > 0 )); then
        log_info "Deleted $DELETED old backup(s) older than ${RETENTION_DAYS} days"
    else
        log_info "No old backups to clean up"
    fi
}

# ── Disk Space Check ──────────────────────────────────────────────────────────
check_disk_space() {
    echo -e "\n${BOLD}── Disk Space Summary ──────────────────────────${RESET}"
    USAGE=$(df -h "$BACKUP_DEST_LOCAL" | tail -1 | awk '{print $5}' | tr -d '%')

    df -h "$BACKUP_DEST_LOCAL" | tail -1 | awk '{
        printf "  Filesystem : %s\n  Total      : %s\n  Used       : %s\n  Available  : %s\n  Usage      : %s\n", $1, $2, $3, $4, $5
    }'

    if (( USAGE > 90 )); then
        log_warn "Backup disk is ${USAGE}% full — consider increasing storage or reducing retention"
    else
        log_info "Backup disk space OK (${USAGE}% used)"
    fi
}

# ── Generate Manifest ─────────────────────────────────────────────────────────
generate_manifest() {
    MANIFEST="${BACKUP_DIR}/MANIFEST.txt"
    {
        echo "Backup Manifest"
        echo "==============="
        echo "Date      : $(date)"
        echo "Hostname  : $(hostname)"
        echo "Sources   : ${BACKUP_SOURCES[*]}"
        echo "Dest      : $BACKUP_DIR"
        echo ""
        echo "File Count:"
        find "$BACKUP_DIR" -type f | wc -l
        echo ""
        echo "Total Size:"
        du -sh "$BACKUP_DIR"
    } > "$MANIFEST"

    log_info "Manifest created: $MANIFEST"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    echo -e "\n${BOLD}${CYAN}── Backup Summary ──────────────────────────────${RESET}"
    echo "  Hostname   : $(hostname)"
    echo "  Backup Dir : $BACKUP_DIR"
    echo "  Backup Size: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
    echo "  Log File   : $LOG_FILE"
    echo "  Timestamp  : $(date)"
    echo ""
}

# ── Cron Setup Instructions ───────────────────────────────────────────────────
show_cron_setup() {
    echo -e "${BOLD}── To Schedule with Cron ───────────────────────${RESET}"
    echo "  Run: crontab -e"
    echo ""
    echo "  # Daily at 2:00 AM"
    echo "  0 2 * * * /path/to/backup-automation.sh >> /var/log/backup.log 2>&1"
    echo ""
    echo "  # Weekly on Sunday at 3:00 AM"
    echo "  0 3 * * 0 /path/to/backup-automation.sh >> /var/log/backup.log 2>&1"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║       🔒 Automated Backup System              ║"
    echo "║       $(date '+%Y-%m-%d %H:%M:%S')            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"

    mkdir -p "$(dirname "$LOG_FILE")"
    log "INFO " "=== Backup job started ==="

    preflight_checks
    run_backup
    sync_to_remote
    apply_retention
    check_disk_space
    generate_manifest
    print_summary

    log "INFO " "=== Backup job completed ==="

    # Show cron setup hint if run interactively
    [[ -t 1 ]] && show_cron_setup
}

main "$@"
