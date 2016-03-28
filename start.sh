#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

TARFILE=vbb-app-16.4.13-SNAPSHOT-distrib.tar.gz
if [ -f "${TARFILE}" ]
then
    cd ..
    tar xzvf $BASEDIR/$TARFILE
    rm -f $BASEDIR/$TARFILE
    cd $BASEDIR
fi

if [ -f "config/vbb-app.properties" ]
then
    ${BASEDIR}/bin/vbb-app.sh start $*
else
    echo "config/vbb-app.properties is missing, looks loke we are trying to undeploy !"
fi