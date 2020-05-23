#!/bin/sh

# Backup directory
KeePassDir="/home/dss4f/KeePass-backups"

# State file and functions
stateFile="$KeePassDir/state.json"
function writeStateFile {
    cat > $stateFile <<- EOF
{
    "backupDir": "$KeePassDir",
    "latestBackup": "$1",
    "latestBackupTime": "`date +"%m.%d.%Y at %r"`",
    "numBackups": $2
}
EOF
}

# Download
downloadLink="`cat $KeePassDir/download`"
newFileName="`openssl rand -hex 8`.kdbx"
newFile="$KeePassDir/$newFileName"

wget -O $newFile $downloadLink

if [ -e "$stateFile" ]
then
    # Hash the latest and new files
    latestBackupFileName=`cat $stateFile | jq -r ".latestBackup"`
    latestHash=`sha256sum $KeePassDir/$latestBackupFileName | awk '{print $1}'`
    newHash=`sha256sum $newFile | awk '{print $1}'`
    if [ "$newHash" == "$latestHash" ]
    then
        # If the hashes match, the new file is the same, so discard it.
        rm $newFile

        # Exit to prevent sending an email (we run this a lot).
        exit 0
    else
        # If the hashes differ, keep the new file and update state.
        numBackups=`cat $stateFile | jq -r ".numBackups"`
        writeStateFile $newFileName $(($numBackups + 1))

    fi
else
    # If no state exists, keep the new file and initialize state.
    writeStateFile $newFileName 1
fi

# Send an email.
read -r -d '' emailMsg <<EOF
<p style="font-family: monospace">`cat $stateFile | jq -r ".latestBackup"`</p>
<p>`cat $stateFile | jq -r ".latestBackupTime"`</p>
<p>There are <b>`cat $stateFile | jq -r ".numBackups"`</b> historical backup files.</p>
EOF

echo -e $emailMsg | mailx -s "$(echo -e "New KeePass Backup\nContent-Type: text/html")" dss4f@dannyshih.net
