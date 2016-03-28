#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

${BASEDIR}/bin/vbb-app.sh stop $*