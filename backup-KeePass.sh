#!/bin/sh

# Parse config
scriptDir="$(dirname "$(readlink -f "$0")")"
configFile=$scriptDir/config.json
backupDir=`cat $configFile | jq -r ".backupDir"`
downloadUrl=`cat $configFile | jq -r ".downloadUrl"`

# State file and functions
stateFile="$backupDir/state.json"
function writeStateFile {
    cat > $stateFile <<- EOF
{
    "latestBackup": "$1",
    "latestBackupTime": "`date +"%m.%d.%Y at %r"`",
    "numBackups": $2
}
EOF
}

# Download
newFileName="`openssl rand -hex 8`.kdbx"
newFile="$backupDir/$newFileName"

wget -O $newFile $downloadUrl

if [ -e "$stateFile" ]
then
    # Hash the latest and new files
    latestBackupFileName=`cat $stateFile | jq -r ".latestBackup"`
    latestHash=`sha256sum $backupDir/$latestBackupFileName | awk '{print $1}'`
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
