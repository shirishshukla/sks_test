####
## Description: Read server list form JSONInputFile
####

import re, sys, json, time
import requests

JSONInputFile=sys.argv[1] or 'input_list.json'
TPMonitorURL='https://raw.githubusercontent.com/shirishshukla/sks_test/master/rt1/t.html'
TPCountThreshold = 20

print('Json Input file: ', JSONInputFile)

def matchSrv(url, srv):
    try:
        htmlContent=requests.get(url, verify=True).text
        JSON = re.compile('<td>{}</td><td>Online</td><td>([0-9])\d+</td>'.format(srv), re.DOTALL)
        matches = JSON.search(htmlContent)
        if(not matches):
            print('No match found for {}'.format(srv))
        else:
            return int(matches.group(0).split('<td>')[-1].split('</td>')[0])
    except Exception as err:
        print(err)
        pass
    return False

# read input file
waitSec=2     # wait 2 sec
maxWait=300   # 5 mins
for SERVER in json.load(open(JSONInputFile,'r')):
    memeberName = SERVER['bigIPPoolMemberName']
    print('-----------------------------', memeberName)
    # check TP Status
    TPCount = matchSrv(TPMonitorURL, memeberName)
    print('TPCount: ', TPCount)
    if(TPCount):
        if(TPCount < TPCountThreshold):
            print('{} TPCount {} < {}, GOOD-TO-GO'.format(SERVER, TPCount, TPCountThreshold, maxWait))
        else:
            # wait until TPCount < TPCountThreshold
            cnt=1 # counter
            while TPCount > TPCountThreshold and cnt*waitSec <= maxWait:
                print('..wait..')
                TPCount = matchSrv(TPMonitorURL, memeberName)
                time.sleep(waitSec)
                cnt+=waitSec
            # if TP count not stablized in maxWait seconds
            if cnt*waitSec <= maxWait:
                print('{} TPCount {} < {}, GOOD-TO-GO'.format(SERVER, TPCount, TPCountThreshold, maxWait))
                maxWait = int(maxWait - cnt*waitSec)
            else:
                print('{} TPCount still {} > {} in {} seconds'.format(SERVER, TPCount, TPCountThreshold, maxWait))
                sys.exit(1)

## END
