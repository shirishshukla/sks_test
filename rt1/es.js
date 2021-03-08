#///////////////////////////////////////////////////////////////////////////////
#//
#// Script to stream cloudtrail events gz file to AWS ElasticSearch
#//
#///////////////////////////////////////////////////////////////////////////////

## Prerequisite if botocore vendored request not present
# pip3 install --target python requests
# zip -r requests.zip python
# AWS:
#   - console > lambda > layers > create layer =>
#   - console > functions > create function => in the "designer" box select layers and then "add layers." Choose custom layers and select your layer.
########

# required: python 3.6+

import json
import gzip
import datetime
import hashlib
import hmac
import boto3
import os
import tempfile
# import requests
from botocore.vendored import requests

##########################################################################
# variables to be set in the lambda environment
esHost = os.environ.get('ES_HOST') or 'vpc......us-west-2.es.amazonaws.com'

# ctl-YYYY-MM-DD
indexName = os.environ.get('ES_INDEX') or 'ctl'
csIndexDir = os.environ.get('ES_INDEX_DIR') or 'cloudtrail'

# Retry count # if failed to stream to ES retry 3 times ..
maxRetry = 3

# List of events to be ignored
ignoreEventsList = ['describeInstanceHealth', 'test']
##########################################################################

# Do not Change
content_type = 'application/json'

# defines a s3 boto client
s3 = boto3.client('s3')

# main function, started by lambda
def lambda_handler(event, context):
    # attribute bucket and file name/path to variables
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # minimal error handling
    if( bucket == None or key == None ):
        return

    # where to save the downloaded file
    localFile = tempfile.NamedTemporaryFile(mode='w+b',delete=False)

    # downloads file to above temp path
    s3.download_fileobj(bucket, key, localFile)
    localFile.close()
    # uncompress and load to variable
    gzfile = gzip.open(localFile.name, "r")

    # loads contents of the Records key into variable (our actual cloudtrail log entries!)
    eventsList = json.loads(gzfile.readlines()[0])

    if 'Records' not in eventsList:
        print('Not CloudTrail logs ignoring.')
        return

    eventCount = 1
    # For each events ...
    for record in eventsList['Records']:
        # Ignore ceertain unwanted events
        if ( record['eventName'] == ignoreEventsList ):
            continue

        # pop out eventVersion key, as of no use
        record.pop('eventVersion', None)

        # adds @timestamp field = time of the event, can be used is main key in ES
        record['@timestamp'] = record['eventTime']
        record['@id'] = record['eventID']

        # removes amazonaws.com from eventsources, eg. cloudformation.amazonaws.com will be cloudformation
        record['eventSource'] = record['eventSource'].split('.')[0]
        data = json.dumps(record).encode('utf-8')

        # Extract index date format for ES, i.e ctl-2020-12-27/_cloudtrail
        event_date = record['eventTime'].split('T')[0]

        # url endpoint for ES cluster domain
        url = 'https://' + esHost + '/' + indexName + '-' + event_date + '/' + csIndexDir
        #print('Total Events: {} url : {}\n'.format(eventCount, url))

        # Post Event to ES
        tm = datetime.datetime.utcnow()
        amz_date = tm.strftime('%Y%m%dT%H%M%SZ')
        headers = {'Content-Type':content_type,'X-Amz-Date':amz_date}

        # sends the json to elasticsearch
        ret = requests.post(url, data=data, headers=headers)
        #print('Attempt 1 status code: {}'.format(ret.status_code))
        if ret.status_code == 201:
            print('Successfully posted to ES')
        else:
            print('Failed to post event {} to ES, Retrying... {} times'.format(data, maxRetry))
            # If Failed to post to ES ... retry 3 more times
            retry_counter = 1
            while (ret.status_code != 201) and (retry_counter <= maxRetry):
                print('Attempt: {}'.format(retry_counter))
                # send the data to ES again
                ret = requests.post(url, data=data, headers=headers)
                print('Status Code: {}'.format(ret.status_code))
                if ret.status_code == 201:
                    print('Successfully posted to ES')
                    break
                else:
                    print('Failed to post event to ES, Retrying...')
                time.sleep(2) # sleep for 2 seconds
                retry_counter += 1

        eventCount += 1

    # cleanup local vars
    localFile.close()
    os.unlink(localFile.name)
    print('Processed: {} events in {}'.format(eventCount, localFile.name) )

## END
