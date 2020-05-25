# backup-KeePass
Uses inotifywait to monitor my KeePass file.

## Dependencies
inotifywait, jq, openssl, mailx/dovecot/postfix

## Instructions
1. Clone this repo
2. Copy `config_templ.json` to `config.json` and set all fields
    1. `backupDir` - Directory to store backup files. Use full path.
    2. `monitorFile` - Path to the monitored file
3. Install `systemd_templ.service` to systemd and fill in paths.
