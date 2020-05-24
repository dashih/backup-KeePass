# backup-KeePass
This bash script is designed to be run by cron very frequently. It will only keep a downloaded file if it is different from the latest backup file.

## Dependencies
wget, jq, openssl, mailx/dovecot/postfix

## Instructions
1. Clone this repo
2. Copy `config_templ.json` to `config.json` and set all fields
    a. `backupDir` - Directory to store backup files. Use full path.
    b. `downloadUrl` - Url to download KeePass database file. See below if you are using OneDrive
3. Run the script in cron. Every 10 minutes recommended.

## Obtain OneDrive download link
Just generating a share link does not work with Onedrive. Use these instructions to generate a link that can get be retrieved using wget or curl.

http://metadataconsulting.blogspot.com/2014/05/how-to-get-direct-download-link-from.html
