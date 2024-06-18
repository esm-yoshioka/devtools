#!/bin/bash

echo "=================================================="
echo " Note: If the line feed code is not LineFeed <LF> "
echo "       an error will occur.                       "
echo "=================================================="
##
#
# Usage:
#     ikev2_client -a <client_users.list> : add client
#     ikev2_client -r <client_users.list> : revoke client
#     ikev2_client -d <client_users.list> : delete client  ※deprecated
#
# [DRY-RUN mode]
#     ikev2_client -D <client_users.list>
#
# <client_users.list>
#    name
#
##

DRY_RUN=0
RUN_OPT=""

# get options
while getopts "ardD" OPT
do
    case $OPT in
        "a" ) RUN_OPT="--addclient";;
        "r" ) RUN_OPT="--revokeclient";;
        "d" ) RUN_OPT="--deleteclient";;
        "D" ) DRY_RUN=1;;
    esac
done
shift $(( $OPTIND - 1 ))

# help print
function print_usage {
    echo ""
    echo "$0 [-a(add)] <client_users.list>"
    echo "$0 [-r(revoke)] <client_users.list>"
    echo "$0 [-d(delete)] <client_users.list>"
    echo "$0 [-D(DRYRUN)] <client_users.list>"
    echo ""
}

if [ $# != 1 ]; then
    print_usage
    exit 1
fi

#===========================================================
# Shell option

USERCMD1=mkdir
CMDOPT="-p"
USERCMD2="sudo ikev2.sh"
USERLIST=$1
#-----------------------------------------------------------
# User option

HOMEDIR="/home/ubuntu/"
WORKDIR="vpn_ikev2/thcu-tachikawa/certs_2024_teacher/"
VPNPREFIX=thcu_tachikawa_
#===========================================================

# CHECK USERLIST
if [ ! -f ${USERLIST} ]; then
    echo "${USERLIST} no such file or directory"
    exit 1
fi

# CHECK OPTION
if [ -z ${RUN_OPT} ]; then
    echo "option not selected"
    exit 1
fi

# PROCESS
if [ ${DRY_RUN} -eq 1 ]; then
    echo "(DRY RUN)"
fi

echo "Execute this process?"
if [[ ${RUN_OPT} =~ .*"add".* ]]; then
    echo "${USERCMD1} ${CMDOPT} ${HOMEDIR}${WORKDIR}${VPNPREFIX}<parameter>/"
fi
echo "${USERCMD2} ${RUN_OPT} ${VPNPREFIX}<parameter>"
if [[ ${RUN_OPT} =~ .*"add".* ]]; then
    echo "mv ~/${VPNPREFIX}<parameter>* ${HOMEDIR}${WORKDIR}${VPNPREFIX}<parameter>/"
fi
read -p "ok? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

grep -v \^# ${USERLIST} | while read line
do
    USER_CERTS=${VPNPREFIX}${line}

    if [ ${DRY_RUN} -eq 1 ] ; then
        if [[ ${RUN_OPT} =~ .*"add".* ]]; then
            echo "${USERCMD1} ${CMDOPT} ${HOMEDIR}${WORKDIR}${USER_CERTS}/"
        fi
        echo "${USERCMD2} ${RUN_OPT} ${USER_CERTS}"
        if [[ ${RUN_OPT} =~ .*"add".* ]]; then
            echo "mv ~/${USER_CERTS}* ${HOMEDIR}${WORKDIR}${USER_CERTS}/"
        fi
    else
        if [[ ${RUN_OPT} =~ .*"add".* ]]; then
            ${USERCMD1} ${CMDOPT} ${HOMEDIR}${WORKDIR}${USER_CERTS}/
        fi
        yes | ${USERCMD2} ${RUN_OPT} ${USER_CERTS}
        if [[ ${RUN_OPT} =~ .*"add".* ]]; then
            mv ~/${USER_CERTS}* ${HOMEDIR}${WORKDIR}${USER_CERTS}/
        fi
    fi

done

exit 0
