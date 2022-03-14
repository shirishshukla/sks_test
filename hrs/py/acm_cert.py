##
# Description: Renew ACM Certificates
#    - If going to expire in next \"DAYS_BEFORE_RENEW\" days
#    - And ACTION=True
##

import boto3
from datetime import datetime as dt, timedelta, timezone

# REGIONS
REGIONS = [region['RegionName'] for region in boto3.client('ec2').describe_regions()['Regions']]
TOCERTS = ['PENDING_VALIDATION', 'ISSUED', 'INACTIVE', 'EXPIRED'] #'VALIDATION_TIMED_OUT'|'REVOKED'|'FAILED']
DAYS_BEFORE_RENEW = 30
ACTION = False #True/False Whether to renew or not ??

# Main
if __name__ == "__main__":
    for REGION in REGIONS:
        print('Region:', REGION)
        ACMC = boto3.client('acm', REGION)
        RESP = ACMC.list_certificates(CertificateStatuses=TOCERTS)
        ACMLIST = [ c['CertificateArn'] for c in RESP['CertificateSummaryList'] ]
        while 'NextToken' in RESP:
            RESP = ACMC.list_certificates(CertificateStatuses=TOCERTS, NextToken=RESP['NextToken'])
            ACMLIST += [ c['CertificateArn'] for c in RESP['CertificateSummaryList'] ]
        for ACM in ACMLIST:
            # get cert expire data
            print(f'==> ACM {ACM}')
            CERT = ACMC.describe_certificate(CertificateArn=ACM)['Certificate']
            print(CERT)
            ACM_NOTAFTER = CERT['NotAfter'] if 'NotAfter' in CERT else False
            ACM_RenewalEligibility = CERT['RenewalEligibility'] if 'RenewalEligibility' in CERT else False
            if ACM_NOTAFTER and ACM_RenewalEligibility:
                PendingDays = int(ACM_RenewalEligibility - dt.now(timezone.utc)).days
                print(f'-> Expire in {PendingDays} days')
                if ACM_NOTAFTER and PendingDays < DAYS_BEFORE_RENEW:
                    # Renew ACM
                    print('Try Renew now')
                    try:
                        if ACTION:
                            RESP = ACMC.renew_certificate(CertificateArn=ACM)
                            print(f'SUCCESS: with cert renewal')
                    except Exception as err:
                        print(f'FAILED: with cert renewal, \nERROR: {err}')
                        pass

## END
