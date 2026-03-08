# 🔒 Backup Automation

A production-style Bash script that automates directory backups
using rsync and cron — protecting critical data with scheduled,
incremental backups, retention policy, and full logging.

---

## 📌 Why Backup Automation Matters

Manual backups get forgotten. Automated backups with retention
policies are standard practice in every production Linux environment.
This project demonstrates real sysadmin responsibility and
automation thinking.

---

## 🎯 What This Script Does

- ✅ Backs up `/etc`, `/home`, and `/var/www/html`
- ✅ Uses rsync for fast incremental backups
- ✅ Supports remote server backup over SSH
- ✅ Pre-flight checks before every backup run
- ✅ Auto-deletes backups older than 30 days (retention policy)
- ✅ Generates a backup manifest (file count + total size)
- ✅ Checks disk space after every backup
- ✅ Color-coded terminal output
- ✅ Timestamped log file for full audit trail

---

## 🛠️ Tools & Concepts Used

| Tool / Command | Purpose |
|---|---|
| `rsync -az` | Incremental, compressed file sync |
| `cron` | Schedule automatic backups |
| `find` | Locate and delete old backups |
| `df` | Disk space check after backup |
| `tee` | Output to terminal and log simultaneously |
| Bash functions | Modular, readable script structure |

---

## 💻 Environment

- **OS:** Rocky Linux 9 / RHEL 9
- **Shell:** Bash
- **Backup Destination:** `/backup/local/`
- **Log File:** `/var/log/backup-automation.log`

---

## 🚀 How to Run
```bash
# Give execute permission
chmod +x backup-automation.sh

# Run local backup
./backup-automation.sh

# Run with remote destination
./backup-automation.sh --remote user@192.168.1.200:/backups
```

---

## ⏰ Schedule with Cron
```bash
# Open crontab editor
crontab -e

# Run every day at 2:00 AM
0 2 * * * /path/to/backup-automation.sh >> /var/log/backup.log 2>&1

# Run every Sunday at 3:00 AM
0 3 * * 0 /path/to/backup-automation.sh >> /var/log/backup.log 2>&1
```

---

## ⚙️ Configuration

Edit the top section of the script to customize:
```bash
BACKUP_SOURCES=(
    "/etc"
    "/home"
    "/var/www/html"
)

BACKUP_DEST_LOCAL="/backup/local"
RETENTION_DAYS=30
LOG_FILE="/var/log/backup-automation.log"
```

---

## 📋 Sample Output
```
╔══════════════════════════════════════════════╗
║       🔒 Automated Backup System              ║
╚══════════════════════════════════════════════╝

── Pre-flight Checks ───────────────────────────
  ✔  rsync is available
  ✔  Source exists: /etc (12M)
  ✔  Source exists: /home (245M)
  ✔  Backup directory created: /backup/local/2025-01-15_02-00-01

── Running Backup ──────────────────────────────
  ✔  Backup successful: /etc
  ✔  Backup successful: /home

── Applying Retention Policy ───────────────────
  ✔  Deleted 2 old backup(s) older than 30 days

── Disk Space Summary ──────────────────────────
  Total      : 50G
  Used       : 12G
  Available  : 38G
  ✔  Backup disk space OK (24% used)

── Backup Summary ──────────────────────────────
  Backup Size : 257M
  Log File    : /var/log/backup-automation.log
```

---

## 📁 Backup Structure
```
/backup/local/
└── 2025-01-15_02-00-01/
    ├── etc/
    ├── home/
    ├── var/www/html/
    └── MANIFEST.txt        ← auto-generated summary
```

---

## 📋 Skills Demonstrated

- Bash scripting and automation
- rsync for incremental backups
- cron job scheduling
- Retention policy implementation
- Remote backup over SSH
- Pre-flight validation checks
- Log management and audit trails

---

## 👤 Author

**Hubaib** — Desktop Engineer | Linux Enthusiast
📍 IIM Kozhikode
🔗 [GitHub Profile](https://github.com/kphubaib)
