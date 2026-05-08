#!/bin/sh

## dmx-curl.sh
##
## curl based api tool for DMX on a busybox shell
##
## Written by Juergen Neumann <juergen@dmx.systems>
## Copyright (c) DMX Systems <https://dmx.systems>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
## MA 02110-1301, USA.


set -e

USERNAME='admin'
PASSWORD=''
PROTOCOL='http'
HOST='localhost'
PORT='8080'
URL='core/topic/0'
CONFIGFILE='conf/config.properties'
HOST_URL="${PROTOCOL}://${HOST}:${PORT}/${URL}"
JSESSIONID=''
PAYLOAD=''


## curl write JSON

# For example, I have an API URL https://api.example.com/v2/login,
# that is used to authenticate the application. Now passing the
# username and password in JSON format using the curl command line tool.

# curl -X POST -H "Content-Type: application/json" \
# -d '{"username":"abc","password":"abc"}' \
# https://api.example.com/v2/login

# You can also write the username and password in a user.json file. Now use this file to pass the JSON data to curl command line.

# curl -X POST -H "Content-Type: application/json" \
# -d @user.json \
# https://api.example.com/v2/login


#BusyBox v1.29.3 (2019-01-24 07:45:07 UTC) multi-call binary.
#
#Usage: getopt [OPTIONS] [--] OPTSTRING PARAMS
#
#    -a		Allow long options starting with single -
#    -l LOPT[,...]	Long options to recognize
#    -n PROGNAME	The name under which errors are reported
#    -o OPTSTRING	Short options to recognize
#    -q		No error messages on unrecognized options
#    -Q		No normal output
#    -s SHELL	Set shell quoting conventions
#    -T		Version test (exits with 4)
#    -u		Don't quote output


get_session_id() {
    #HOST_URL='http://localhost:8080/core/topic/0'
    #USERNAME='admin'
    #PASSWORD=''
    BASE64=$( echo -n "${USERNAME}:${PASSWORD}" | base64 )
    # AUTH="Authorization: Basic ${BASE64}"
    AUTH="Authorization: LDAP ${BASE64}"
    # echo "curl -sS -H ${AUTH} (${USERNAME}:${PASSWORD}) ${HOST_URL}"
    # SESSIONID="$( curl -sS -H "${AUTH}" "${HOST_URL}" -i 2>&1 | grep "JSESSIONID" | cut -d'=' -f2 | cut -d';' -f1 )"
    SESSIONID="$( curl -sS -H "${AUTH}" "${HOST_URL}" -i 2>&1 | grep "JSESSIONID" | cut -d'=' -f2 | cut -d';' -f1 )"
    echo "${SESSIONID}"
}


print_json() {
    local JSON="$1"
    local PRETTY_JSON="$( echo "${JSON}" | awk -f JSON.awk - )"
    ## echo -e jsonResponse | awk -f JSON.awk | egrep '\["items",[0-9]+,"id"\]'
    echo "${PRETTY_JSON}"
}


post_json() {
    local JSON="$1"
    if [ -z "${JSESSIONID}" ]; then
        JSESSIONID="$( get_session_id )"
    fi
    local JSON='{ "children": { "dmx.notes.text": "body", "dmx.notes.title": "title" }, "typeUri": "dmx.notes.note" }'
    echo "JSON: ${JSON}"
    local PARAM="children=false"
    ## from ${var}
    #RESPONSE="$( curl -sS --cookie "JSESSIONID=${JSESSIONID}" -X POST -H "Content-Type: application/json" "${HOST_URL}" -d "${JSON}" 2>&1 )"
    ## from file
    RESPONSE="$( curl -sS --cookie "JSESSIONID=${JSESSIONID}" -X POST -H "Content-Type: application/json" "${HOST_URL}" -d @note.json 2>&1 )"
    print_json "${RESPONSE}"
}


#Example:
#
#O=`getopt -l bb: -- asb:c:: "$@"` || exit 1
OPTS="$( getopt -l bb:ii:UU:uu:PP:pp: -- ai:jsvb:U:u:P:p:c:: "$@" )" || exit 1
eval set -- "${OPTS}"
while true; do
    case "$1" in
    -a) echo A; shift;;
    -b|--bb) echo "B:'$2'"; shift 2;;
    -c) case "$2" in
	  "") echo C; shift 2;;
	  *) echo "C:'$2'"; shift 2;;
	esac;;
    ##
    -i|--JSESSIONID) JSESSIONID="$2"; shift 2;;
    -j) print_json; shift;;
    -U|--URL) HOST_URL="$2"; shift 2;;
    -u|--username) USERNAME="$2"; shift 2;;
    -P|--POST) PAYLOAD="$2"; shift 2;;
    -p|--password) PASSWORD="$2"; shift 2;;
    -s) get_session_id; shift;;
    -v) set -x; shift;;
    ##
    --) shift; break;;
    *) echo Error; exit 1;;
    esac
done


if [ -n "${PAYLOAD}" ]; then
    post_json "${PAYLOAD}"
fi

echo "done."


exit 0

##

# try to get pw from config file
if [ -f ${CONFIGFILE} ]; then
    #PASSWORD="$( cat ${CONFIGFILE} | grep "dm4.security.initial_admin_password =" | cut -d'=' -f2 | sed 's/\ //g' )"
    PASSWORD="$( cat ${CONFIGFILE} | grep "dmx.security.initial_admin_password =" | cut -d'=' -f2 | sed 's/\ //g' )"
    PORT=$( cat ${CONFIGFILE} | grep "org.osgi.service.http.port =" | cut -d'=' -f2 | sed 's/\ //g' )
    HOST_URL="${PROTOCOL}://${HOST}:${PORT}/${URL}"
elif [ -n "$1" ] && [ -n "$2" ]; then
    HOST_URL="$1" # default: http://localhost:8080/core/topic/0
    USERNAME="$2" # default: admin
    PASSWORD="$3" # default: -Nan-
else
    echo "./dmx-curl.sh HOST_URL USERNAME [PASSWORD] (example: ./dmx-curl.sh http://localhost:8080/core/topic/0 admin)"
fi

BASE64=$( echo -n "${USERNAME}:${PASSWORD}" | base64 )
AUTH="Authorization: Basic ${BASE64}"
SESSIONID="$( curl -sS -H "${AUTH}" "${HOST_URL}" -i 2>&1 | grep "JSESSIONID" | cut -d'=' -f2 | cut -d';' -f1 )"

echo "${SESSIONID}"
