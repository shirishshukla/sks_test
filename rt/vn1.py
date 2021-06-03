##
#
##

import boto3
import json

S3R = boto3.resource('s3')

# CURRENT BUCKET POLICY
def getBucketPolicy(bucketPolicy):
    try:
        currPolicy = json.loads(bucketPolicy.policy)
    except Exception:
        currPolicy = {'Version': '2012-10-17', 'Statement': []}
        pass
    return currPolicy


# Policy Statement to be added
def addPolicyStatement(bucketName):
    # Policy statement to be added
    addThisPolicyStmt = [
        {
          "Sid": "AllowSSLRequestOnly1",
          "Effect": "Deny",
          "Principal": {
            "AWS": "*"
          },
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::"+bucketName+"/*",
            "arn:aws:s3:::"+bucketName
          ],
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        }
    ]
    return addThisPolicyStmt


## *******  Main ******* ##
for bucket in S3R.buckets.all():
    bucketName = bucket.name
    print('\n')
    print('------------- Bucket {} ------------'.format(bucketName))
    currentPolicy = getBucketPolicy(bucketName)
    addThisNewStatement = addPolicyStatement(bucketName)
    if currentPolicy and addThisNewStatement:
        #currentPolicy['Statement'].append(addThisNewStatement)
        # Is statement already exist in bucket policy
        IsToAddNewStmt=False
        for toAddstmt in addThisNewStatement:
            IsStmtExist=False
            for currStmt in currentPolicy['Statement']:
                if toAddstmt == currStmt:
                    print('Bucket: {}, Policy Statement already exist,  {}'.format(bucketName, toAddstmt))
                    IsStmtExist=True
            if not IsStmtExist:
                IsToAddNewStmt=True
                print('Bucket: {}, Policy Statement to be ADDED,  {}'.format(bucketName, toAddstmt))
                currentPolicy['Statement'].append(toAddstmt)

        # Is there any new statement to be added
        if IsToAddNewStmt:
            print('Bucket: {}, Updating Policy statement: {}'.format(bucketName, currentPolicy))
            # update bucket policy Statement
            #UC#bucketPolicy.put(Policy=currentPolicy)
        else:
            print('Bucket: {}, No Change in bucket Policy'.format(bucketName))
    else:
        print('Script Failure ....')

## END
