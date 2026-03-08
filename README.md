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
