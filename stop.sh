#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

${BASEDIR}/bin/onyx-request.sh stop $*