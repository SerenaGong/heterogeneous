Network Benchmark Utility v0.1

USAGE:
  ./iperf_collector.sh [OPTIONS]

OPTIONS:
  -h, --hostfile <arg>
        File containing the list of hosts (default hosts.lst).

  -u, --sshuser <arg>
        User account used for SSH to the hosts. This account must be able to
        SSH without specifying a password.

IPERF OPTIONS:
  -p, --port <arg>
        Set server port to listen on/connect to (default 5201)

  -P, --parallel <arg>
        Number of parallel client streams to run (default 5).

  -t, --time <arg>
        Time in seconds to transmit for (default 10 secs).
