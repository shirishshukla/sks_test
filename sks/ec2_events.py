###
# Description: List active aws ec2 events
# Owner: Shirish Shukla
# Version: v1.0 - Initial
# Requirement
# - AWS configure
# - python3
# - pip3 install datetime
# - pip3 install pytz
###

import boto3
from datetime import datetime as dt
from pytz import timezone

EventStateCode=[ 'instance-reboot', 'system-reboot', 'system-maintenance', 'instance-retirement', 'instance-stop' ]
REGIONS = [region['RegionName'] for region in boto3.client('ec2').describe_regions()['Regions']]

LIST=[]
for REGION in REGIONS:
    EC2C = boto3.client('ec2', REGION)
    EC2R = boto3.resource('ec2', REGION)
    Events = EC2C.describe_instance_status(Filters=[{'Name': 'event.code', 'Values': EventStateCode }])['InstanceStatuses']
    for event in Events:
        #print(event)
        InstAZ      = event['AvailabilityZone']
        InstID      = event['InstanceId']
        EventCode   = event['Events'][0]['Code']
        EventSchDt  = dt.strftime(event['Events'][0]['NotBefore'].astimezone(timezone('Asia/Calcutta')), '%Y-%b-%d %H:%M %p %Z') # Convert to IST TimeZone
        try:
            InstName = [ tg['Value'] for tg in EC2R.Instance(InstID).tags if tg['Key'] == 'Name' ][0]
        except:
            InstName = InstID
            pass
        DATA="{},{},{},{}".format(InstAZ, InstName, EventCode, EventSchDt)
     #  print("{}: {}, {}, {}".format(InstAZ, InstName, EventCode, EventSchDt))
        LIST.append(DATA)

##
c1=[]; c2=[]; c3=[]
for data in LIST:
    VAL = data.split(',')
    c1.append(len(VAL[0]))
    c2.append(len(VAL[1]))
    c3.append(len(VAL[2]))
if c1 and c2 and c3:
    c11 = max(c1) + 2 ; c22 = max(c2) + 2; c33 = max(c3) + 2

    LIST2=[]
    for data in LIST:
        VAL = data.split(',')
        LIST2.append("{:{}}  {:{}}  {:{}}  {}".format(VAL[0], c11, VAL[1], c22, VAL[2], c33, VAL[3]))

    cnt=max([ len(val) for val in LIST2 ]) + 2
    pt='*'
    print(cnt*pt)
    print("{:{}}  {:{}}  {:{}}  {}".format(' Region/AZ', c11, ' Instance Name', c22, ' Event', c33, ' Schedule Date'))
    print(cnt*pt)

    for data in LIST2:
        print(' {}'.format(data))
    print(cnt*pt)

## END ##
