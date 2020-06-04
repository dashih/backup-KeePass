#!/bin/sh

# Get script directory, following symlinks
scriptDir="$(dirname "$(readlink -f "$0")")"

# Parse config
configFile=$scriptDir/config.json
backupDir=`cat $configFile | jq -r ".backupDir"`
monitorFile=`cat $configFile | jq -r ".monitorFile"`
monitorDir=`dirname $monitorFile`
stateFile="$backupDir/state.json"

#
# Functions.
#

# Update state file
function writeStateFile {
    cat > $stateFile <<- EOF
{
    "latestBackup": "$1",
    "latestBackupTime": "`date +"%m.%d.%Y at %r"`",
    "numBackups": $2
}
EOF
}

# Copy the monitored file if it has changed
function copyIfChanged {
    # Ensure the file exists
    if [ ! -e $monitorFile ]
    then
        echo "$monitorFile was deleted!" | mailx -s "KeePass db was deleted!" dss4f@dannyshih.net
    else
        # Hash the latest and new files
        latestBackupFileName=`cat $stateFile | jq -r ".latestBackup"`
        latestHash=`sha256sum $backupDir/$latestBackupFileName | awk '{print $1}'`
        newHash=`sha256sum $monitorFile | awk '{print $1}'`
        if [ "$newHash" == "$latestHash" ]
        then
            echo "Same file";
        else
            # If the hashes differ, copy over the monitored file and update state.
            tmpFile=`mktemp`
            newFileName=`echo $tmpFile | cut -d'.' -f2`.kdbx
            newFile=$backupDir/$newFileName
            mv $tmpFile $newFile

            cp $monitorFile $newFile

            numBackups=`cat $stateFile | jq -r ".numBackups"`
            writeStateFile $newFileName $(($numBackups + 1))

            # Send email only when there's a legit new file.
            read -r -d '' emailMsg <<EOF
<p style="font-family: monospace">`cat $stateFile | jq -r ".latestBackup"`</p>
<p>`cat $stateFile | jq -r ".latestBackupTime"`</p>
<p>There are <b>`cat $stateFile | jq -r ".numBackups"`</b> historical backup files.</p>
EOF

            echo -e $emailMsg | mailx -s "$(echo -e "New KeePass Backup\nContent-Type: text/html")" dss4f@dannyshih.net
        fi
    fi
}

#
# Script start
#

# Initialize if necessary
if [ ! -d $backupDir ]
then
    # Create backup dir
    mkdir $backupDir
fi

if [ ! -f $backupDir/state.json ]
then
    # Initialize state. Trickery here: we set state.json as the "initial backup"
    # so the monitored file will definitely be copied in the next step.
    writeStateFile "state.json" 0
fi

copyIfChanged

# Set up inotify
inotifywait -m -e modify,close_write,moved_to,moved_from,move_self,delete,delete_self,unmount $monitorDir |
while read events;
do
    copyIfChanged
done
