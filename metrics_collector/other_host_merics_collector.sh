#!/usr/bin/env bash
#

VERSION=0.1

function info() {
    echo "$(date) [$(tput setaf 2)INFO $(tput sgr0)] $*"
}

function err() {
    echo "$(date) [$(tput setaf 1)ERROR$(tput sgr0)] $*"
}

function warn() {
    echo "$(date) [$(tput setaf 3)WARN $(tput sgr0)] $*"
}

function debug() {
    if [[ $DEBUG_MODE ]]; then
        echo "$(date) [$(tput setaf 2)DEBUG$(tput sgr0)] $*"
    fi
}

function die() {
    err "$@"
    exit 2
}


function cleanup {
    if [ "$COMPLETED" == "1" ]; then
            echo ""
            echo "Tests completed"
    else
            echo ""
            echo "Terminating script... stopping tests"
    fi
    }

function usage() {
    local SCRIPT_NAME=HOST_MONITOR
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    echo
    echo "Host monitor Utility v$VERSION"
    echo
    echo "$(tput bold)USAGE:$(tput sgr0)"
    echo "  ./${SCRIPT_NAME} [OPTIONS]"
}


info "Starting tests"
info "top CPU intensive processes"

STARTTIME=$(date "+%Y-%m-%d-%H-%M-%S")
COMPLETED=0

OUTPUTDIR="RESULTS-"$(date -d"${STARTTIME}" "+%y%m%d-%H%M%S")

if [ ! -d "$OUTPUTDIR" ]; then
        mkdir "$OUTPUTDIR"
fi


function topcpu() {
ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10 >> $OUTPUTDIR/top-cpu-$(STARTTIME)
}

function topmem() {
ps -eo pmem,pid,user,args | sort -k 1 -r | head -10 >> $OUTPUTDIR/top-mem-$(STARTTIME)
}

function diskthroughput() {
ioutput=`dd bs=8k count=256k if=/dev/zero of=/tmp/dd_test_sample.img conv=fdatasync`
echo $ioutput| tail -1 >> $OUTPUTDIR/disk-thru-$(STARTTIME) 
} 


