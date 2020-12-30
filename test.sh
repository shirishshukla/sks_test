## Script to add datasource in iws-standalone-full-ha_prime_source.xml
##SKS-master

# Variables
ToFILE=$1
jndiname=$2
poolname=$3
enabled=$4
usejavacontext=$5
connectionurl=$6
driver=$7
username=$8
password=$9

# Validate input
if [[ -z $ToFILE ]] || [ -z $jndiname ] || [ -z $poolname ] || [ -z $enabled ] || [ -z $usejavacontext ] || [ -z $connectionurl ] || [ -z $driver ] || [ -z $username ] || [ -z $password ]; then
   echo -e "Please pass all variable inputs "
   exit 0
fi

# get current line number
matchLineNo=$(grep -in '</datasource>' ${ToFILE} | tail -1 | awk -F: '{print $1+1}')

insertDataSource="\                <datasource jndi-name="$jndiname" pool-name="$poolname" enabled="$enabled" use-java-context="$usejavacontext">\n                    <connection-url>$connectionurl</connection-url>\n                    <driver>$driver</driver>\n                    <security>\n                        <user-name>$username</user-name>\n                        <password>$password</password>\n                    </security>\n                </datasource>"

# Insert at specific line
if [[ ! -z $matchLineNo ]] && [[ ! -z $insertDataSource ]]; then
    sed -i "${matchLineNo}i${insertDataSource}"  ${ToFILE}
else
    echo -e "Error to update $ToFILE"
    exit 0
fi

## END ##
