#!/bin/bash

set -e

HOSTNM="$1"
cleanupFolder="$2"
emailTxtFile='/tmp/.email_text.txt'
cleanupFilesList='/tmp/.clean_files.txt'
VG='overlay'

rm $emailTxtFile $cleanupFilesList $emailTxtFile.result || true

cd $cleanupFolder

# Add Hostname to report
echo '&nbsp' > $emailTxtFile
echo -e "****** Cleanup Report Of Host: $HOSTNM ******" >> $emailTxtFile

# Before cleanup FS utilization
echo '&nbsp' >> $emailTxtFile
echo -e "*** Before cleanup -> df -h | grep $VG" >> $emailTxtFile
df -h | grep $VG >> $emailTxtFile

# Cleanup
find $cleanupFolder -name "*.zip" -exec ls -ltr {} \; > $cleanupFilesList

# No of files to be cleaned-up
echo '&nbsp' >> $emailTxtFile
echo -e "*** Total number of files to be cleanup: `wc -l < $cleanupFilesList`" >> $emailTxtFile

if [[ -s $cleanupFilesList ]]; then
    # Files list to be deleted
    echo '&nbsp' >> $emailTxtFile
    echo -e "*** List of files to be cleaned up" >> $emailTxtFile
    cat $cleanupFilesList >> $emailTxtFile

    # Del Files
    find $cleanupFolder -name "*.zip" -exec rm -rf {} \;
    if [[ $? -eq 0 ]]; then
        echo "Above Files deleted successfully." >> $emailTxtFile

        # After cleanup FS utilization
        echo '&nbsp' >> $emailTxtFile
        echo -e "*** After cleanup -> df -h | grep $VG" >> $emailTxtFile
        df -h | grep $VG >> $emailTxtFile

    else
        echo '&nbsp' >> $emailTxtFile
        echo -e "*** CLEANUP FAILED. Please check manually." >> $emailTxtFile
        #echo $emailTxtFile | mailx -s "File System Log Cleanup from $(uname -n)" $emailTO
    fi
else
    echo -e "Nothing to cleanup!!"  >> $emailTxtFile
fi

IFS=$'\n'
for line in `cat $emailTxtFile`; do
   echo -e "${line}<br>" >> $emailTxtFile.result
done

cat $emailTxtFile.result

rm $emailTxtFile $cleanupFilesList

## END
