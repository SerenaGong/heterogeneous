#!/usr/bin/env bash
#
# Automate running of iperf3 on Cloudera cluster nodes for network throughput tests

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
            echo "Cleaning up iperf3 process on $SERVER"
           sshpass -f sshpasswd ssh "$OPT_USER@$SERVER" "ps aux | grep 'iperf3' | awk '{print \$2}' | xargs kill" > /dev/null 2>&1
            kill SSH_PID > /dev/null 2>&1
    fi
    }

function write_summary {
    cat > "$OUTPUTDIR/summary.txt" <<EOL
{
    "start_time" : "${STARTTIME}",
    "iperf_server_cmd" : "${CMD_IPERF_SERVER}",
    "iperf_client_cmd" : "${CMD_IPERF_CLIENT} <SERVER>"
}
EOL
}


function usage() {
    local SCRIPT_NAME=
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    echo
    echo "IPERF Cluster Network Benchmark Utility v$VERSION"
    echo
    echo "$(tput bold)USAGE:$(tput sgr0)"
    echo "  ./${SCRIPT_NAME} [OPTIONS]"
    echo
    echo "$(tput bold)OPTIONS:$(tput sgr0)"
    echo "  $(tput bold)-h, --hostfile $(tput sgr0)<arg>"
    echo "        File containing the list of hosts (default hosts.lst)."
    echo
    echo "  $(tput bold)-u, --sshuser $(tput sgr0)<arg>"
    echo "        User account used for SSH to the hosts. This account must be able to"
    echo "        SSH without specifying a password."
    echo
    echo "$(tput bold)IPERF OPTIONS:$(tput sgr0)"
    echo "  $(tput bold)-p, --port $(tput sgr0)<arg>"
    echo "        Set server port to listen on/connect to (default 5201)"
    echo
    echo "  $(tput bold)-P, --parallel $(tput sgr0)<arg>"
    echo "        Number of parallel client streams to run (default 5)."
    echo
    echo "  $(tput bold)-t, --time $(tput sgr0)<arg>"
    echo "        Time in seconds to transmit for (default 10 secs)."
}

OPT_USER="root"     # username for passwordless ssh access
OPT_PORT=5201       # port server will listen on
OPT_THREADS=5       # number of parallel client threads sending data
OPT_DURATION=10     # duration of transmitting data
OPT_HOSTFILE="hosts"

HOSTS=()

if [[ $# -eq 0 ]]; then
    usage
    die
fi

while [[ $# -gt 0 ]]; do
    KEY=$1
    shift
    case ${KEY} in
        -h|--hostfile)      OPT_HOSTFILE="$1";      shift;;
        -u|--sshuser)       OPT_USER="$1";          shift;;
        -p|--port)          OPT_PORT="$1";          shift;;
        -t|--time)          OPT_DURATION="$1";      shift;;
        --help)             OPT_USAGE=true;;
        *)                  OPT_USAGE=true
                            err "Unknown option: ${KEY}"
                            break;;
    esac
done


if [ -z "${OPT_HOSTFILE}" ] && [ -z "${OPT_CMURL}" ]; then
    die "Please specify a hostfile or Cloudera Manager URL."
fi


    if [[ -r "${OPT_HOSTFILE}" ]]; then
        IFS=$'\n' read -d '' -r -a HOSTS < "${OPT_HOSTFILE}"
    else
        die "Unable to read file ${OPT_HOSTFILE}."
    fi

if [ ${#HOSTS[@]} -lt 2 ]; then
    die "Need more than 1 hosts to perform tests, only found ${#HOSTS[@]}."
fi

info "Starting network tests"

STARTTIME=$(date "+%Y-%m-%d %H:%M:%S")
CMD_IPERF_SERVER="iperf3 -s -1 -i 0 -p $OPT_PORT"
CMD_IPERF_CLIENT="iperf3 -t $OPT_DURATION -P $OPT_THREADS -4 -p $OPT_PORT -i 0 -J -c "
COMPLETED=0

OUTPUTDIR="RESULTS-"$(date -d"${STARTTIME}" "+%y%m%d-%H%M%S")

if [ ! -d "$OUTPUTDIR" ]; then
        mkdir "$OUTPUTDIR"
fi

write_summary

trap cleanup EXIT

SERVER=""
CLIENT=""

for i in "${!HOSTS[@]}"; do

        SERVER="${HOSTS[$i]}"
        OUTFILE="$OUTPUTDIR/$SERVER.json"
        echo "[" > "$OUTFILE"

        info "===== Staring iperf3 server on $SERVER ====="

        for j in "${!HOSTS[@]}"; do
                CLIENT="${HOSTS[$j]}"

                if [ "$SERVER" != "$CLIENT" ]; then
                        info "Testing throughput from $CLIENT -> $SERVER"

                        sshpass -f sshpasswd ssh "$OPT_USER@$SERVER" "$CMD_IPERF_SERVER" > /dev/null 2>&1 &

                        sleep 5 #give some time for the server process to load

                        echo "{ \"client\": \"$CLIENT\"," >> "$OUTFILE"
                        echo "  \"result\":" >> "$OUTFILE"

                        clientcmd="$CMD_IPERF_CLIENT $SERVER"
                       sshpass -f sshpasswd  ssh "$OPT_USER@$CLIENT" "$clientcmd" >> "$OUTFILE"
			echo "}," >> "$OUTFILE"
                fi
        done
        echo "]" >> "$OUTFILE"
done

# Post-processing - remove last comma from each result json files
for FILE in "$OUTPUTDIR/*.json"; do
	sed -i 'x;${s/,$//;p;x;};1d' $FILE
done

