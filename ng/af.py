##
# Description:
##

import sys
import requests
import hashlib


## Variables
ARTIFACTORY_URL='https://artifactory.cloud.sks.com/artifactory/x-maven-int-east-local/myidentity/devskslocal'  #do not end with /
artifactName='identityfile.war'
AF_USERNAME=''
AF_PASSWORD=''


## function upload artifact to artifactory
def uploadToArtifactory(artifactName, TARGET_PATH):
    try:
        print('Uploading artifact: {} to Artifactory: {}'.format(artifactName, TARGET_PATH))

        # api header
        HEADERS = {'content-type': 'application/java-archive',
                   'X-Checksum-Md5': hashlib.md5(open(artifactName).read()).hexdigest(),
                   'X-Checksum-Sha1': hashlib.sha1(open(artifactName).read()).hexdigest()
                }

        print()
        # upload
        #with open(artifactName, 'rb') as artifact:
        #    ret = requests.put(TARGET_PATH,
        #                    auth=(AF_USERNAME, AF_PASSWORD),
        #                    data=artifact, headers=HEADERS
        #        )

        ## validate
        #STATUS_CODE=ret.status_code
        #if STATUS_CODE != 201:
        #    print("Something went wrong, status code: ", STATUS_CODE)
        #else:
        #    print("Successfully uploaded artifact {}, available at url: {}".format(artifactName, ret.json()['downloadUri']))
        #    return True
    except Exception as err:
        print('Failed with error: {}'.format(str(err)))

    return False


## main function call
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("""
            Invalid Input Paramameters
            Syntax: python script.py EID MMDDYY
        """)
        sys.exit(1)
    EID=sys.argv[1]
    DATEINPUT=sys.argv[2] # in MMDDYY format
    TARGET_PATH = '/'.join([ARTIFACTORY_URL, str(EID), str(DATEINPUT)])

    print('ARTIFACTORY URL:', TARGET_PATH)
    uploadToArtifactory(artifactName, TARGET_PATH)


## END
