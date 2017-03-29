#!/usr/bin/env bash

ask_for_swarm_manager_ip() {
    while true; do
        printf "Enter the IP address of the swarm manager host: "
        set +e
        read -t 60 _swarm_manager_ip < /dev/tty
        set -e
        if [ -z "$_swarm_manager_ip" ]; then
            continue
        else
			   SWARM_MANAGER_HOST=${_swarm_manager_ip}
				return
        fi
    done
}


ask_for_private_ip() {
    _count=0
    _ipv4_count=0
    _saveifs=$IFS;
    IFS=' ';
    while read -r _line; do
        set -- $_line;
        if [ "$2" == "lo" ]; then
            continue
        fi
        _ip=`echo $4 | cut -d'/' -f1`
        if [ "$_ip" == "$PRIVATE_ADDRESS" ]; then
          printf "'%s' appears to be valid\n" $PRIVATE_ADDRESS
          return
        fi
        if [ "$3" == "inet" ]; then
            _inet4_iface=$2
            _inet4_address=$_ip

            _iface_names[$((_count))]=$2
            _iface_addrs[$((_count))]=$_ip
            let "_count += 1"
        fi
    done <<< "$(ip -4 -o addr && ip -6 -o addr)"
    IFS=$_saveifs;

    if [ "$_count" -eq "0" ]; then
        echo >&2 "Error: The installer couldn't discover any valid network interfaces on this machine."
        echo >&2 "Check your network configuration and re-run this script again."
        exit 1
    elif [ "$_count" -eq "1" ]; then
        PRIVATE_ADDRESS=${_inet4_address}
        printf "The installer will use network interface '%s' (with IP address '%s')\n" ${_inet4_iface} ${_inet4_address}
        return
    fi
    printf "The installer was unable to automatically detect the private IP address of this machine.\n"
    printf "Please choose one of the following network interfaces:\n"
    for i in $(seq 0 $((_count-1))); do
        printf "[%d] %-5s\t%s\n" $i ${_iface_names[$i]} ${_iface_addrs[$i]}
    done
    while true; do
        printf "Enter desired number (0-%d): " $((_count-1))
        set +e
        read -t 60 chosen < /dev/tty
        set -e
        if [ -z "$chosen" ]; then
            continue
        fi
        if [ "$chosen" -ge "0" ] && [ "$chosen" -lt "$_count" ]; then
            PRIVATE_ADDRESS=${_iface_addrs[$chosen]}
            printf "The installer will use network interface '%s' (with IP address '%s').\n" ${_iface_names[$chosen]} $PRIVATE_ADDRESS
            return
        fi
    done
}

discover_swarm_manager_ip() {
    if [ -n "$SWARM_MANAGER_HOST" ]; then
            printf "Using swarm manager address supplied in parameter: '%s'\n" $SWARM_MANAGER_HOST
        return
    fi

    ask_for_swarm_manager_ip
}

discover_private_ip() {
    if [ -n "$PRIVATE_ADDRESS" ]; then
            printf "Validating local address supplied in parameter: '%s'\n" $PRIVATE_ADDRESS
            ask_for_private_ip
        return
    fi

    ask_for_private_ip
}


install_docker_engine() {
    apt-get update
    apt-get -y install apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | tee /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
    apt-get -y install docker-engine=1.12.3-0~trusty
    apt-cache policy docker-engine
}

join_swarm() {
	 docker run -d --restart=always --name=swarm_agent swarm join --advertise=${PRIVATE_ADDRESS}:2375 consul://${SWARM_MANAGER_HOST}:8500
}

configure_docker() {
    echo DOCKER_OPTS='"'-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://${SWARM_MANAGER_HOST}:8500 --cluster-advertise=${PRIVATE_ADDRESS}:2375'"' >> /etc/default/docker
    service docker restart
}

################################################################################
# Execution starts here
################################################################################
printf "Determining swarm manager address\n"
discover_swarm_manager_ip

printf "Determining local address\n"
discover_private_ip

printf "Installing...\n"
install_docker_engine
join_swarm
configure_docker
