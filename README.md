# Cron Persistence Detection Lab with Wazuh FIM

A safe detection-engineering lab demonstrating how a Linux cron job can be used for persistence and how Wazuh File Integrity Monitoring (FIM) detects creation, modification, and removal of the cron artifact.

> **Safety:** The scheduled command is harmless. It only appends a test message to `/tmp/cron_test.log`. Run this lab only in an authorized test environment.

## Lab Overview

| Component | Details |
|---|---|
| Wazuh Manager | `10.0.2.6` |
| Ubuntu Target | `10.0.2.7` |
| Wazuh Agent | `ubuntu-target-10.0.2.7` (ID `003`) |
| Persistence Artifact | `/etc/cron.d/poc_persistence` |
| Test Output | `/tmp/cron_test.log` |
| Detection | Wazuh File Integrity Monitoring |
| MITRE ATT&CK | [T1053.003 – Scheduled Task/Job: Cron](https://attack.mitre.org/techniques/T1053/003/) |

## Detection Workflow

```text
Cron Job Created/Modified
        ↓
Wazuh Agent FIM
        ↓
Wazuh Manager
        ↓
Rule 550 – Integrity checksum changed
        ↓
Analyst Validation and Containment
        ↓
Rule 553 – File deleted
```

## Repository Structure

```text
.
├── README.md
├── config/
│   └── wazuh-fim-config.xml
├── detection/
│   └── wazuh-alert-details.md
├── scripts/
│   └── cron-persistence-simulation.sh
└── screenshots/
    └── README.md
```

## 1. Configure Wazuh FIM

On the Ubuntu target, edit:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Add the monitored cron locations inside the `<syscheck>` section:

```xml
<directories check_all="yes" realtime="yes">/etc/cron.d</directories>
<directories check_all="yes">/etc/crontab</directories>
<directories check_all="yes" realtime="yes">/var/spool/cron</directories>
<frequency>60</frequency>
```

Restart and verify the Wazuh agent:

```bash
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-agent
```

## 2. Simulate Cron Persistence

Create the harmless cron job:

```bash
echo '*/2 * * * * root echo "Cron persistence test executed" >> /tmp/cron_test.log' | sudo tee /etc/cron.d/poc_persistence
sudo chmod 644 /etc/cron.d/poc_persistence
ls -l /etc/cron.d/poc_persistence
cat /etc/cron.d/poc_persistence
```

Wait at least two minutes, then validate execution:

```bash
cat /tmp/cron_test.log
```

## 3. Generate a Modification Alert

```bash
sudo sh -c 'echo "# FIM test" >> /etc/cron.d/poc_persistence'
```

Search the Wazuh dashboard for:

```text
poc_persistence
Syscheck
rule.id:550
```

Expected result:

- **Rule 550:** Integrity checksum changed
- Decoder: `syscheck_integrity_changed`
- File path, root ownership, timestamps, and MD5/SHA1/SHA256 changes recorded

## 4. Containment and Removal

Quarantine the persistence artifact:

```bash
sudo mkdir -p /etc/cron.quarantine
sudo mv /etc/cron.d/poc_persistence /etc/cron.quarantine/
```

Verify containment:

```bash
ls -l /etc/cron.d/poc_persistence
ls -l /etc/cron.quarantine/poc_persistence
```

Expected result:

- The active cron file is no longer present
- **Rule 553:** File deleted
- `/tmp/cron_test.log` stops receiving new entries

## Detection Evidence

| Event | Wazuh Rule | Expected Evidence |
|---|---:|---|
| Cron file created/modified | 550 | Path, hashes, timestamps, ownership |
| Cron file removed/quarantined | 553 | Deleted path and agent information |
| Execution validation | N/A | New entries in `/tmp/cron_test.log` |

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
|---|---|---|
| Persistence | Scheduled Task/Job: Cron | T1053.003 |

## Key Outcome

The lab successfully demonstrated cron-based persistence in a controlled Ubuntu environment. Wazuh FIM detected integrity changes to the cron artifact, preserved useful forensic metadata, and generated a deletion alert after containment.
