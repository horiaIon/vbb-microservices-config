#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

if [ -f "config/vbb-app.properties" ]
then
    ${BASEDIR}/bin/vbb-app.sh restart $*
else
    echo "config/vbb-app.properties is missing, looks like we are trying to undeploy !"
fi