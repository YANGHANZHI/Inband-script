# Function:Parallel ping node-list,find dead nodes or Ok nodes.
#!/bin/bash
# pping - Parallel Ping YHPC Compute Nodes
# 
# Copyright (c) 2010-2013 School of Computer, NUDT
# Written by Hongjia Cao, hjcao@nudt.edu.cn
#
ulimit -SHn 1000000

sysctl -w net.core.rmem_max=67108864 &> /dev/null
sysctl -w net.core.wmem_max=67108864 &> /dev/null
sysctl -w net.core.wmem_default=67108864 &> /dev/null
sysctl -w net.core.rmem_default=67108864 &> /dev/null
sysctl -w net.core.netdev_max_backlog=250000 &> /dev/null
sysctl -w net.core.optmem_max=67108864 &> /dev/null
sysctl -w net.ipv4.tcp_sack=1 &> /dev/null
sysctl -w net.ipv4.tcp_syn_retries=5 &> /dev/null
sysctl -w net.ipv4.tcp_mem="67108864     67108864        67108864" &> /dev/null
sysctl -w net.ipv4.tcp_wmem="1048576        4194304   16777216" &> /dev/null
sysctl -w net.ipv4.tcp_rmem="1048576        4194304   16777216" &> /dev/null
sysctl -w net.ipv4.neigh.default.gc_thresh3=30000 &> /dev/null
INVERSE=0
PARA=4096
PARSABLE=0

usage() {
	cat <<__EOM__
Usage: pping [options] <nodelist>

-v         inVerse output: output live nodes.
-p <para>  specify Parallelism. default is 4096.
-P	   Parsable output: just target nodename.
__EOM__

}

# parse argument
while getopts "hp:Pv" opt; do
	case $opt in
	h )
		usage
		exit 0
		;;
	p )
		PARA=$OPTARG
		;;
	P )
		PARSABLE=1
		;;
	v )
		INVERSE=1
		;;
	? )
		usage
		exit 1
		;;
	esac
done
shift $(($OPTIND - 1))

NODELIST=$1

if [[ -z "$NODELIST" ]]; then 
	usage
	exit 1
fi

hn=`hostname`

ping_node() {
	if ping -c 1 -w 10  $1 2>&1 >/dev/null; then
		if [[ "$INVERSE" == "1" ]]; then
			if [[ "$PARSABLE" == "1" ]]; then
				echo "$1"
			else
				echo "$hn <------> $1"
			fi
		fi
	else
		if [[ "$INVERSE" == "0" ]]; then
			if [[ "$PARSABLE" == "1" ]]; then
				echo "$1"
			else
				echo "$hn <---X---> $1"
			fi
		fi
	fi
}

n=0
for x in `yhcontrol show hostnames "$NODELIST"`; do 
	if [[ $n -gt $PARA ]]; then
		n=0
		wait
		sleep 0.1
	fi
	ping_node $x &
	n=$((n+1))
done

wait
