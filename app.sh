#!/bin/sh

BASEDIR=`dirname $0`/..
cd $BASEDIR
BASEDIR=`pwd`

# Source other shell utilities.
[ ! -f "./bin/util.sh" ] && echo "Cannot find ./bin/util.sh" && exit 1
. ./bin/util.sh
[ ! -f "./bin/test-java.sh" ] && echo "Cannot find ./bin/test-java.sh" && exit 1
. ./bin/test-java.sh

success "Starting vbb-app into directory: $PWD"

for file in "./bin/extra[0-9]*-vbb-app.sh"; do
    [ -r "$file" ] && source "$file" &&  success "$file loaded !"
done
unset file


## make missing directories
mkdir -p ./logs
REGEX_RD=".*--remote-debug.*"

### Variables coming from deploy-it
export VBB_JAVA_HOME="$HOME/jdk8" #

[ ! -d "${VBB_JAVA_HOME}" ] &&  export VBB_JAVA_HOME=${JAVA_HOME}
###
JAVA_CMD=${VBB_JAVA_HOME}/bin/java

jarFile="./lib/vbb-app.jar"
remoteDebugOption="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"
prog="vbb-app"
timeoutForPID="10"
timeoutForKill=${timeoutForPID}
configDir="${BASEDIR}/config"
runDir="${BASEDIR}/run"
logDir="${BASEDIR}/logs"
PROG_PATTERN_GREP="vbb-app"
OUTPUT_FILE="${logDir}/${prog}.out"
PID_FILE="$runDir/application.pid"

#Be sure to put JVM_ARGS && exec last (in order to reference previous variables)
JVM_ARGS="-Xmx512m"
[[ $* =~ $REGEX_RD ]] && JVM_ARGS="${remoteDebugOption} ${JVM_ARGS}"
exec="${JAVA_CMD} ${JVM_ARGS} -jar ${jarFile}"

checkStateFull() {
    confFile="$configDir/${prog}.properties"

    [ ! -f ${confFile} ] && failure "Failed to find config file: ${confFile}" && return 2

    declare -A props
    while read -r; do
      [[ $REPLY = *=* ]] || continue
      props[${REPLY%%=*}]=${REPLY#*=}
    done < ${confFile}

    if [ ${props["eureka.client.serviceUrl.defaultZone"]+_} ]
    then
        echo "Wait 10s, to be sure eureka has clean-up dead instance"
        sleep 10
        IFS=, read eurekaUrl others <<< "${props[eureka.client.serviceUrl.defaultZone]}apps/${prog}"
        httpCode=$(curl -sk -o /dev/null -I -w '%{http_code}' ${eurekaUrl})
        [ $? -ne 0 ] && failure "Failed to retreive status from: ${eurekaUrl}" && return 2
        if [ "${httpCode}" = "200" ]
        then
            failure "This microservice is flagged as stateFull and an instance is already registered at ${eurekaUrl}"
            warning "It could take time for eureka to detect that a microservice is down (ping timeout)"
            return 1;
        else
            warning "No other instance registered. take care that no other are starting at sametime: ${eurekaUrl} "
        fi
    else
        failure "Property '' Not found into ${confFile}"
        return 3
    fi
}

start() {
    mkdir -p ${runDir} ${logDir}
    [ ! -d "$configDir" ] && failure "missing config directory $configDir" && exit 6

	currentPid=`jpid`

    if [ ! -z "${currentPid}" ]
    then
       failure "${prog} is already running (pid=${currentPid})" && exit 1
   	   return 1
     fi

    # declare this variable into ./bin/vbb-app-extra.sh for instance
    if [[  -n "$IS_STATEFULL" && "$IS_STATEFULL" = "true" ]]
    then
        checkStateFull
        [ $? -ne 0 ] && return 2
    fi

    CMD_LINE="$exec --spring.config.name=vbb-app --spring.pidfile=$PID_FILE $* > $OUTPUT_FILE 2>&1 &"
    # if not running, start it up here, usually something like "daemon $exec"
    eval ${CMD_LINE}

    for ((i = 0 ; i < ${timeoutForPID} ; i++ ))
    do
        if [ -f ${PID_FILE} ]
        then
            break
        else
            warning "Wait process to start (writing $PID_FILE) ..."
            sleep 1
        fi
    done

    currentPid=$(jpid)
    retval=$?

    if [ ${retval} -eq 0 ]
    then
        success "$prog started. pid: $currentPid"
    else
        failure "$PID_FILE not found, process may have start but could no be killed safely"
    fi

    return ${retval}
}

stop() {
    currentPid=$(jpid)
    retval=0;
    if [ "x${currentPid}" != "x" ]
    then
        killOption=""
        if [ -n "$COMSPEC" -a -x "$COMSPEC" ]
        then
           killOption="-f"
        fi

        safeKill "-TERM" ${currentPid} ${killOption}
        [ $? -ne 0 ] && safeKill "-KILL" ${currentPid} ${killOption}

        /bin/kill -0 ${currentPid}  2> /dev/null
        retval=$?
        [ ${retval} -ne 0 ] && rm -f ${PID_FILE}

        #kill -0 $1 2> /dev/null
        [ ${retval} -ne 0 ] && success  "$prog with pid: $currentPid killed" && return 0
        [ ${retval} -eq 0 ] && failure "$prog with pid $currentPid still alive" && return ${retval}
    else
        warning "Failed to kill $prog, no pid found"
        retval=0
    fi

    return $retval
}

safeKill() {
    killSig=$1
    killPid=$2
    killOption=$3

    for ((i = 0 ; i < ${timeoutForKill} ; i++ ))
    do
        warning "Kill ${killOption} ${killSig} '${killPid}' ..."
        /bin/kill ${killOption} ${killSig} ${killPid}  2> /dev/null
        sleep 1
        /bin/kill -0 ${killPid}  2> /dev/null
        retval=$?
        if [ ${retval} -ne 0 ]
        then
            return 0
        else
            warning "Wait process $currentPid is finishing ..."
        fi
    done

    return 1
}


jpid() {
    if [ -f ${PID_FILE} ]
    then
        echo `cat ${PID_FILE}`
    else
        return 6;
    fi
}

reload() {
    restart
}

force_reload() {
    restart
}

rh_status() {
    # run checks to determine if the service is running or use generic status
    currentPid=`jpid`
    if [ $? -eq 0 ]
    then
        if [ "x${currentPid}" != "x" ]
        then
            /bin/kill -0 ${currentPid} 2> /dev/null
            if [ $? -ne 0 ]
            then
    	        warning " ${PID_FILE} exist but contains pid: $currentPid that doesn't exist"
    	        retval=1
            else
    	        success "$prog is running, pid: $currentPid"
    	        retval=0
            fi
        else
            warning "No pid found into ${PID_FILE}"
            retval=1
    	fi
    else
    	warning "$prog is not running, no ${PID_FILE} found"
    	retval=1
    fi

    return ${retval}
}

rh_status_q() {
    rh_status 2>&1
}

jdump() {
    jstack="${VBB_JAVA_HOME}/bin/jstack"
    [ ! -x "${jstack}" ] && echo "$jstack not found" && return 1
    currentPid=`jpid`
    if [ $? -eq 0 ]
    then
        timestamp=$(date +%Y%m%d-%H_%M_%S)
        ${jstack} -l ${currentPid} > "${BASEDIR}/logs/$prog-$timestamp.dump"
        retval=$?
    else
        echo "$prog is not running"
        retval=1
    fi
}

checkJava ${VBB_JAVA_HOME} 8
if [ ! -f "${jarFile}" ]
then
    echo "${jarFile} doesn't exist"
    exit 2
fi

firstArg=$1
shift

case "${firstArg}" in
    start)
        start $*
        ;;
    stop)
        stop $*
        ;;
    restart)
        stop
        sleep 2
        start $*
        ;;
    reload)
        rh_status_q || exit 7
        ${firstArg}
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    dump)
        jdump
        ;;
    *)
        warning $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|dump}"
        exit 2
esac
exit $?