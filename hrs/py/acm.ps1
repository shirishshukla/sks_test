Using Namespace Microsoft.VisualBasic

# AMS ACM PCA - Cert Automation-Windows
Write-Host "Start certificate provisioning..."

# Param for PCA ARN
# The Amazon Resource Name (ARN) of the private certificate authority (CA) that will be used to issue the certificate.
# If you do not provide an ARN and you are trying to request a private certificate, ACM will attempt to issue a public certificate.
# example : "arn:aws:acm-pca:us-east-1:084234995962:certificate-authority/15c40a53-63c6-4571-999b-2ba159674f35"
$pcaArn="" #ADD_HERE

# Pass certPwd
# Enter a passphrase for encrypting the private key. You will need the passphrase later to decrypt the private key.
# **This passphrase will be required for decrypting the PEM encoded private key.
# example : "ChangeMe123"
$certPassphrase="" #ADD_HERE

# IdpToken
# Customer chosen string that can be used to distinguish between calls to RequestCertificate.
# If you call RequestCertificate multiple times with the same idempotency token within one hour, ACM recognizes that you are requesting only one certificate and will issue only one.
# example : "ChangeMe123"
$IdpToken="" #ADD_HERE

# Domain
# We need to bind the domain name regardless of whether you sign or configure the SSL certificate. Therefore, you need to specify the domain name when generating the certificate.
# example : "amsprod.healthcareit.net / or amsdev.healthcareit.net"
$Domain="" #ADD_HERE

Write-Host "Using Domain: $Domain"

$AWSREGION="" #ADD_HERE
#$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
Write-Host "Using AWSREGION: $AWSREGION"

## deduct days
$deductDays = 30

aws configure set default.region $AWSREGION

# Change Working Dir
$CERT_DRIVE="D"
certDir="$CERT_DRIVE:\cert"
If(!(test-path $certDir))
{
    New-Item -ItemType Directory -Force -Path $certDir
} else {
  Write-Host "$certDir already exists"
}

Set-Location -Path $certDir

# Get the FQDN
$HOSTNM=(Get-WmiObject win32_computersystem).DNSHostName
$myFQDN="$HOSTNM.$Domain"

Write-Host "FQDN: ${myFQDN}"

Write-Host "----"
Write-Host "Existing cert file(s):"
dir
Write-Host "----"

# Get the Latest Certificate Arn
#certArn=aws acm list-certificates --region $AWSREGION --certificate-statuses ISSUED --query CertificateSummaryList[].[CertificateArn,DomainName] --output text | grep "${myFQDN}" | cut -f1)
$CertArns=(Get-ACMCertificateList -CertificateStatus "ISSUED" | Where-Object DomainName -Match "$myFQDN").CertificateArn
if ($CertArns) {
  Write-Host "Found existing certificate(s)."
  if ($CertArns.count > 1){
    Write-Host "More then 1 certificate exists, selecting the latest one."
    $lastCertArn=""
    $lastCertExpDt=""
    foreach($certArn in $CertArns) {
      # Getting Cert Notafter Date
      $certInfo = Get-ACMCertificateDetail -CertificateArn $certArn
      $currCertExpDt=$certInfo.NotAfter
      Write-Host "--- $certArn - $currCertExpDt ---"
      if($lastCertExpDt){
        if(Get-date $currCertExpDt) -ge (Get-date $lastCertExpDt) {
          $lastCertExpDt=$currCertExpDt
          $lastCertArn=$currCertArn
        }
      }
      else {
          $lastCertExpDt=$currCertExpDt
          $lastCertArn=$currCertArn
      }
      $latestcertArn=$lastCertArn
    }

    if($latestcertArn){
      $certInfo = Get-ACMCertificateDetail -CertificateArn $latestcertArn
      $currCertExpDt=$certInfo.NotAfter
      $certType=$certInfo.Type
      Write-Host "Using Certificate ARN: $currCertExpDt, ExpireOn: $currCertExpDt, CertType: $certType"

      # For IMPORTED Certificates we have to make get-certificate call
      if ($certType == "IMPORTED"){
        $certInfo = Get-ACMCertificate -CertificateArn $latestcertArn

        # Get certificate
        $myCert=$certInfo.Certificate
        $myCert >servercert.crt
        Write-Host "Certificate: $myCert"

        # Get certificate chain
        $myCertChain=$certInfo.CertificateChain
        $myCertChain >certchain.crt
        Write-Host "CertificateChain: $myCertChain"

      # For PRIVATE Certificates we have to make export-certificate call
      elseIf ($certType == "PRIVATE"){
        $certInfo = Export-ACMCertificate -CertificateArn "$certArn" -Passphrase "$Certpassphrase"

        # Export certificate
        $myCert=$certInfo.Certificate
        $myCert >servercert.crt
        Write-Host "Certificate: $myCert"

        # Export certificate chain
        $myCertChain=$certInfo.CertificateChain
        $myCertChain >certchain.crt
        Write-Host "CertificateChain: $myCertChain"

        # Export Encrypted private key
        $myPrivateKey=$certInfo.PrivateKey
        $myPrivateKey >private_key.key
        Write-Host "PrivateKey: $myPrivateKey"

      } else {
          Write-Host "Invalid certificate type !!"
          exit 1
      }
      Write-Host "New cert file(s):"
      dir
    } else {
      Write-Host "Error obtaining certificate. Exiting."
      exit 1
    }
  }
} else {
  Write-Host "No valid certificate found so provisioning new one..."
  Write-Host "checking validity of CA"
  #caValidity=$(aws acm-pca describe-certificate-authority --certificate-authority-arn $pcaArn | jq -r .CertificateAuthority.NotAfter)
  $caAuthInfo = Get-PCACertificateAuthorityCertificate -CertificateAuthorityArn $pcaArn
  $caValidity=$caAuthInfo.CertificateAuthority.NotAfter

  # get age in days

  Add-Type -AssemblyName Microsoft.VisualBasic
  $TODAY = Get-Date
  $dateDiffDays = [DateAndTime]::DateDiff([DateInterval]::Day, $TODAY, $caValidity)
  $days = $dateDiffDays - $deductDays
  if (-not $dateDiffDays){
    Write-Host "Can not get days value = $days"
    exit 1
  }
  Write-Host "Ca Certificate Validity Expires in $days days"

  # Staging Variables for later use in CNF file
  $Country=$caAuthInfo.CertificateAuthority.CertificateAuthorityConfiguration.Subject.Country
  Write-Host "Country: $Country"

  $Organization=$caAuthInfo.CertificateAuthority.CertificateAuthorityConfiguration.Subject.Organization
  Write-Host "Organization: $Organization"

  $OrganizationalUnit=$caAuthInfo.CertificateAuthority.CertificateAuthorityConfiguration.Subject.OrganizationalUnit
  Write-Host "OrganizationalUnit: $OrganizationalUnit"

  State=$caAuthInfo.CertificateAuthority.CertificateAuthorityConfiguration.Subject.State
  Write-Host "State: $State"

  Locality=$caAuthInfo.CertificateAuthority.CertificateAuthorityConfiguration.Subject.Locality
  Write-Host "Locality: $Locality"

  $CommonName=${myFQDN}
  Write-Host "CommonName: $CommonName"

  #Creating CNF file for csr
  $cnfFile="test.cnf"
  Write-Host "Adding following content to the cnf file"
  $certData = @"
[ req ]
distinguished_name      = req_distinguished_name
prompt                  = no
[ req_distinguished_name ]
C = $Country
ST = $Organization
L = $Locality
O = $OrganizationalUnit
CN = $CommonName
"@

  $certData > $cnfFile
  dir

  #password file for OpenSSL
  $passFile="pass.txt"
  $certFilePrefix="test_cert_priv_key"
  $csr_file="${certFilePrefix}.csr"

  Write-Host "adding pass to pass file"
  $certPassphrase >$passFile

  if ($certPassphrase){
    Write-Host "Password not set in $passFile"
    exit 1
  }

  Write-Host "Creating csr file "
  dir
  Write-Host "----------------------------------"
  openssl req -new -config $cnfFile -newkey rsa:2048 -days 365 -keyout ${certFilePrefix}.pem -out $csr_file -passout file:${passFile}
  Write-Host "----------------------------------"

  if (Test-Path -path $csr_file){
    Write-Host "$csr_file not exists."
    exit 1
  }


  Write-Host "Issuing new Certificate using given csr file $csr_file"
  $certArn=(aws acm-pca issue-certificate --certificate-authority-arn "$pcaArn" --csr fileb://${csr_file} --signing-algorithm "SHA256WITHRSA" --validity Value=$days,Type="DAYS" --idempotency-token $IdpToken).CertificateArn
  Write-Host "New Certificate issued with $certArn"
  sleep 15
  dir

  # Get Certificate
  $myCert=(aws acm-pca get-certificate --certificate-authority-arn $pcaArn --certificate-arn $certArn)
  $myCert = $certInfo.Certificate
  $myCert >servercert.crt
  Write-Host "Certificate: $myCert"

  # Get certificate chain
  myCertChain=$certInfo.CertificateChain
  myCertChain >certchain.crt
  Write-Host "CertificateChain: ${myCertChain}"

  Write-Host "New cert file(s):"
  dir
  Write-Host "----"

  #Create Private Key for import call if the decrypted key is not present the import call will fail
  openssl rsa -in ${certFilePrefix}.pem -out PrivateKey.pem -passin file:${passFile}

  Write-Host "Importing Certificate To ACM"
  # Import Certificate to ACM
  myimportedCertArn=(aws acm import-certificate --certificate fileb://servercert.crt --private-key fileb://PrivateKey.pem --certificate-chain fileb://certchain.crt).CertificateArn
  Write-Host "Certificate succesfully imported with ARN:$myimportedCertArn"

  Write-Host "Cleanup ..."
  $delFiles = @("$cnfFile","$csr_file","$passFile", "PrivateKey.pem")
  rm $delFiles
}

Write-Host "Finished certificate provisioning."
