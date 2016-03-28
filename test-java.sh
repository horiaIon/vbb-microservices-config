#!/bin/sh

#### need 2 args:
## First is a path pointing on java installation directory
## Second is a minimal version (1.6 == 6, 1.7 == 7 ...)
function checkJava() {
        local java_home=$1
        local version_min=$2
        local java_cmd="${java_home}/bin/java"

        [ -z "$java_home" ] && failure "Missing first arg: java_home location" && return 1
        [ -z "$version_min" ] && failure "We do not perform check on minimal version, second arg missing"

        [ ! -d "$java_home" ] && failure "java_home path does not exist: $java_home" && return 1
        [ ! -x "$java_cmd" ] && failure "Java not found (or not executable) at: $java_cmd" && return 1

        success "Found java at ${java_cmd}"

        if [ ! -z "$version_min" ]
        then
                java_version=`$java_cmd -version 2>&1 | grep "version" | awk -F'[ "]+' '{print $3}' | cut -d'.' -f2`
                [[ "${java_version}" -lt "${version_min}" ]] && echo "ERROR: Wrong java version, expected is >= $version_min, found: ${java_version}" && return 2
                success "Java version is greater or equal $version_min  ${JAVA_VERSION}"
        fi
        return 0
}

