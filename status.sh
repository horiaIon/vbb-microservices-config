#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

if [ -f "config/onyx-request.properties" ]
then
    ${BASEDIR}/bin/onyx-request.sh status $*
else
    echo "config/onyx-request.properties is missing, looks loke we are trying to undeploy !"
fi