#!/bin/bash

REPORT_CSV_FILE=$1
HTML_REPORT_FILE=$2

frontVer='<p align=left style=font-size:12px>'
frontUrl='<p align=left style=font-size:10px>'

sed -i "s/\"//g" "$REPORT_CSV_FILE"
sed -i "s/FAILURE/<font color=red><b>FAILURE<\/b><\/font>/g"  "$REPORT_CSV_FILE"
sed -i "s/SUCCESS/<font color=green>SUCCESS<\/font>/g"        "$REPORT_CSV_FILE"

report_gen() {

  > ${HTML_REPORT_FILE}.success
  echo '<table class=\"table1\" border=\"3\" bordercolor=\"black\">' | tee ${HTML_REPORT_FILE}
  header=true
  SORTVAL="FAILED"
  cnt=1

  while read LINE; do
    svc=$(echo $LINE | awk -F',' '{print $1}')
    ver=$(echo $LINE | awk -F',' '{print $2}')
    url=$(echo $LINE | awk -F',' '{print $3}')
    sts=$(echo $LINE | awk -F',' '{print $4}')

    if $header;then # for header
      echo "<tr><th>S.No.</th><th>${LINE//,/</th><th>}</th></tr>" | tee -a ${HTML_REPORT_FILE}
      header=false
    else
      ENTRY="<tr><td>$cnt</td><td>${frontVer}${ver}</td><td>${frontUrl}${url}</td><td>$sts</td></tr>"
      if echo $LINE | awk '{print $NF}' | grep FAILURE ; then # for failed
        echo $ENTRY | tee -a ${HTML_REPORT_FILE}
        ((cnt++))
      else # success
        echo $ENTRY | tee -a ${HTML_REPORT_FILE}.success
      fi
    fi
  done < ${REPORT_CSV_FILE}

  # final html file prep
  cat ${HTML_REPORT_FILE}.success | tee -a ${HTML_REPORT_FILE}
  echo "</table>" >> ${HTML_REPORT_FILE}

}

report_gen
