#!/bin/bash

#########################################
# Author: Kasza Attila :: Eldacon Kft. 	#
# Date: 2016.07.30			#
# Version: 1.2				#
#########################################

# Check Bash version > 4.x
BASH_VERSION=$(dpkg -l | grep 'Bourne Again SHell' | awk -F' ' '{print $3}')
if [[ ${BASH_VERSION} =~ ^(1|2|3) ]]; then
  echo "This script works only with Bash version 4.x or higher."
  exit 1
fi

# Check pwgen is installed or not
dpkg -l | grep pwgen &> /dev/null
if [ $? -ne 0 ]; then
   echo "Please install pwgen with the following command, and try running the script again:
	sudo apt-get install pwgen"
   exit 2
fi

showusage() {
    echo "
  The correct usage of the script:

    $(basename $0) -f /path/to/input/file -d domain.apex [-g] [-e] [-p]

	Mandatory switches:

	  -f | --file     /path/to/input/file

	     The script assumes that:
		- each user is in new a line,
        	- the attributes are separated with spaces, and
		- structured as the following:
		FirstName LastName Email (...) GroupName

	  -d | --domain     example.com

	Optional standalone switches:

	  -g | --group      if present: search for groups in file
	  -e | --email 	    if present: search for emails in file
	  -p | --pw-expire  if present: set default expiry for passwords
	"
}

# Setting global variables from arguments
while [[ $# -gt 0 ]]; do
key="$1"
case $key in
    -f|--file)
    INPUT_FILE="$2"
    shift
    ;;
    -d|--domain)
    DC_NAME="$2"
    shift
    ;;
    -g|--group)
    GROUP_IN_FILE=1
    ;;
    -e|--email)
    EMAIL_IN_FILE=1
    ;;
    -p|--pw-expire)
    PW_NOEXPIRE=no
    ;;
    *|--help)
    showusage
    exit 0
    ;;
esac
shift
done

# GLOBAL VARIABLES - DO NOT EDIT!!!
DOMAIN=$(echo ${DC_NAME,,} | cut -d "." -f1)
TLD=$(echo ${DC_NAME,,} | cut -d "." -f2)
[ -z "$EMAIL_IN_FILE" ] && EMAIL_IN_FILE=0
[ -z "$GROUP_IN_FILE" ] && GROUP_IN_FILE=0
OUTPUT_FILE=${DC_NAME}-users-$(date +"%Y%m%d-%H%M").csv
echo "\"dn_suffix\",\"dn_rdn\",\"windowsUser_userPrincipalName\",\"windowsUser_password\",\"windowsUser_firstName\",\"windowsUser_lastName\",\"windowsUser_cn\",\"windowsUser_displayName\",\"windowsUser_initials\",\"windowsUser_description\",\"windowsUser_streetAddress\",\"windowsUser_postOfficeBox\",\"windowsUser_postalCode\",\"windowsUser_l\",\"windowsUser_state\",\"windowsUser_officeName\",\"windowsUser_mail\",\"windowsUser_otherMailbox\",\"windowsUser_telephoneNumber\",\"windowsUser_otherTelephone\",\"windowsUser_webSite\",\"windowsUser_otherWebSites\",\"windowsUser_deactivated\",\"windowsUser_noExpire\",\"windowsUser_requireCard\",\"windowsUser_pwdMustChange\",\"windowsUser_profilePath\",\"windowsUser_scriptPath\",\"windowsUser_homeDrive\",\"windowsUser_homeDirectory\",\"windowsUser_groups\",\"windowsUser_sAMAccountName\"" > $OUTPUT_FILE

# YOU CAN CHANGE THESE SETTINGS
# The default is that there are no password expiration for the generated users
[ -z "$PW_NOEXPIRE" ] && PW_NOEXPIRE=yes
# Default random password length
PW_LENGTH=12

# Global vars check
if [ ! -f "$INPUT_FILE" ]; then
  echo "File: $INPUT_FILE not found!
  Please check the correct path to the file."
  echo
  showusage
  exit 4
fi

if [[ ! $DC_NAME =~ ^[a-zA-Z0-9]{1,61}\.[a-zA-Z]{2,}$ ]]; then
  echo "Domain Name must be a correct apex zone value..
  i.e.: example.com"
  echo
  showusage
  exit 5
fi

# Readarray from file
readarray USERS < $INPUT_FILE

for USER in "${USERS[@]}"; do
  FN=$(echo ${USER} | awk '{print $1}')
  LN=$(echo ${USER} | awk '{print $2}')
  SAM="${FN,,}.${LN,,}"
  PASSWORD=$(pwgen -sB ${PW_LENGTH})
  [ $EMAIL_IN_FILE -eq 1 ] && EMAIL=$(echo ${USER,,} | awk '{print $3}')
  [ $GROUP_IN_FILE -eq 1 ] && GROUP=$(echo ${USER,,} | awk '{print $NF}')

  echo \"ou=People,dc=${DOMAIN},dc=${TLD}\",\"cn\",\"${SAM}\",\"${PASSWORD}\",\"${FN}\",\"${LN}\",\"${SAM}\",\"${FN} ${LN}\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"${EMAIL}\",\"\",\"\",\"\",\"\",\"\",\"\",\"${PW_NOEXPIRE}\",\"\",\"\",\"\",\"\",\"\",\"\",\"${GROUP}\",\"${SAM}\" >> $OUTPUT_FILE

  echo "${SAM} : ${PASSWORD}"

done

[ $? -eq 0 ] && echo "Generating file: ${OUTPUT_FILE} ... OK" || echo "Generating file: ${OUTPUT_FILE} ... FAILED"

exit 0
