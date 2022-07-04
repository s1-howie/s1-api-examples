#!/bin/bash
# 
# NOTE: This script is designed to serve as an example for invoking Full Disk Scan actions to agents.
#
# NOTE: This script requires curl and jq
#

set -e # exit on failure

S1_CONSOLE_PREFIX=$1
S1_API_TOKEN=$2
S1_ACCOUNT_ID=$3
S1_SITE_ID=$4
S1_MGMT_URL="https://${S1_CONSOLE_PREFIX}.sentinelone.net"
S1_API_ENDPOINT='/web/api/v2.1/agents/actions/initiate-scan'

Color_Off='\033[0m'       # Text Resets
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Check if the S1_ACCOUNT_ID is in the right format/length
if ! [[ $S1_ACCOUNT_ID =~ ^[0-9]{18,19}$ ]]; then
    printf "\n${Red}ERROR:  Invalid format for S1_ACCOUNT_ID: $S1_ACCOUNT_ID ${Color_Off}\n"
    echo "SentinelOne Account IDs are generally 18-19 numeric characters in length."
    echo ""
    exit 1
fi

# Check if the S1_SITE_ID is in the right format/length
if ! [[ $S1_SITE_ID =~ ^[0-9]{18,19}$ ]]; then
    printf "\n${Red}ERROR:  Invalid format for S1_SITE_ID: $S1_SITE_ID ${Color_Off}\n"
    echo "SentinelOne Site IDs are generally 18-19 numeric characters in length."
    echo ""
    exit 1
fi

# Check if the API_KEY is in the right format
if ! [[ ${#S1_API_TOKEN} -eq 80 ]]; then
    printf "\n${Red}ERROR:  Invalid format for S1_API_TOKEN: $S1_API_TOKEN ${Color_Off}\n"
    echo "API Keys are generally 80 characters long and are alphanumeric."
    echo ""
    exit 1
fi


# Check if curl is installed.
function curl_check () {
    if ! [[ -x "$(which curl)" ]]; then
        printf "\n${Red}ERROR:  The curl utility cannot be found.  Please install it and ensure that it is accessible via PATH. ${Color_Off}\n"
        exit 1
    else
        printf "${Yellow}INFO:  curl is already installed.${Color_Off}\n"
    fi
}

function jq_check () {
    if ! [[ -x "$(which jq)" ]]; then
        printf "\n${Red}ERROR:  The jq utility cannot be found.  Please install it and ensure that it is accessible via PATH. ${Color_Off}\n"
        exit 1
    else
        printf "${Yellow}INFO:  jq is already installed.${Color_Off}\n"
    fi
}


function check_api_response () {
    if [[ $(cat response.txt | jq 'has("errors")') == 'true' ]]; then
        printf "\n${Red}ERROR:  Could not authenticate using the existing mgmt server and api key. ${Color_Off}\n"
        echo ""
        exit 1
    fi
}

generate_post_data()
{
  cat <<EOF
{
  "filter": {
    "accountIds": "${S1_ACCOUNT_ID}",
    "siteIds": "${S1_SITE_ID}"
  }
}
EOF
}

curl_check
jq_check

printf "\n${Purple}INFO:  Issuing Full Disk Scan command on agents within Account ID: $S1_ACCOUNT_ID Site ID: $S1_SITE_ID  ${Color_Off}\n"
curl -sX POST  -H "Authorization: ApiToken $S1_API_TOKEN" \
-H "Content-Type: application/json" \
-d "$(generate_post_data)" \
"$S1_MGMT_URL$S1_API_ENDPOINT" > response.txt
check_api_response

AGENTS_AFFECTED=$(cat response.txt | jq -r '.data.affected')

printf "\n${Purple}INFO:  Agents Affected: $AGENTS_AFFECTED  ${Color_Off}\n"

# Clean up
rm response.txt


