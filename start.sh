#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

TARFILE=onyx-request-16.4.13-SNAPSHOT-distrib.tar.gz
if [ -f "${TARFILE}" ]
then
    cd ..
    tar xzvf $BASEDIR/$TARFILE
    rm -f $BASEDIR/$TARFILE
    cd $BASEDIR
fi

if [ -f "config/onyx-request.properties" ]
then
    ${BASEDIR}/bin/onyx-request.sh start $*
else
    echo "config/onyx-request.properties is missing, looks loke we are trying to undeploy !"
fi