#!/bin/sh
black='\033[0;30m';     white='\033[1;37m'
blue='\033[0;34m';      lightBlue='\033[1;34m'
green='\033[0;32m';     lightGreen='\033[1;32m'
cyan='\033[0;36m';      lightCyan='\033[1;36m'
red='\033[0;31m';       lightRed='\033[1;31m'
purple='\033[0;35m';    lightPurple='\033[1;35m'
darkGray='\033[1;30m';  lightGray='\033[0;37m'
brown='\033[0;33m';     yellow='\033[1;33m'
nocolor='\033[0m';      clr_eol='\r\033[K'${nocolor}

success() {
    echo -e "${clr_eol}[${green}OK${nocolor}] $*"
    return 0
}

failure() {
    echo -e "${clr_eol}[${red}FAILED${nocolor}] $*"
    return 0
}

passed() {
    echo -e "${clr_eol}[${yellow}PASSED${nocolor}] $*"
    return 0
}

warning() {
    echo -e "${clr_eol}[${yellow}WARNING${nocolor}] $*"
    return 0
}

isFunction() {
    declare -Ff "$1" >/dev/null;
}
