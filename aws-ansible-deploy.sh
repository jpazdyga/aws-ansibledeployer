#!/bin/bash 

ansibleready() {
        state=`nc -z $pubip $sshport; echo $?`
        if [ "$state" -ne "0" ];
        then
                echo -e "\nWaiting for Ansible server's SSH daemon to start listening on port $sshport..."
                sleep 10
                ansibleready
        else
                echo -e "\nAnsible is now accessible ($pubip:$sshport) using ssh. Thanks!"
        fi
}

createcloudconfig() {

echo "#cloud-config

hostname: $shortname

coreos:
 etcd2:
   discovery: https://discovery.etcd.io/$discovery" > $cloudconfig
   echo '   advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
   initial-advertise-peer-urls: http://$private_ipv4:2380
   listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
   listen-peer-urls: http://$private_ipv4:2380
 fleet:
   public-ip: $private_ipv4
 units:
  - name: docker.service
    command: start
  - name: docker-ansible.service
    command: start
    content: |
     [Unit]
     Description=Docker hosted Ansible server
     Requires=docker.service
     After=docker.service

     [Service]
     TimeoutStartSec=0
     ExecStartPre=/usr/bin/docker pull jpazdyga/ansible' >> $cloudconfig
     echo "     ExecStart=/usr/bin/docker run --name ansible -d -p $sshport:22 jpazdyga/ansible" >> $cloudconfig
     echo '
     [Install]
     WantedBy=multi-user.target

users:
 - name: ansible
   groups:
     - sudo
     - docker
   ssh_authorized_keys:' >> $cloudconfig
echo "     - $authorizedkey" >> $cloudconfig
}

defineandstart() {

	instanceid=`./ebs-start-instance.py | cut -d':' -f2 | sed 's/]//g'`
        sleep 5
        privip=`./get_instance_ip.py private $instanceid`
	pubip=`./get_instance_ip.py public $instanceid`
	echo "Ansible server's private IP: $privip, public IP: $pubip"
}

if [ "$#" -ne "3" ];
then
	echo "Usage: $0 [server_shortname] [domainname] [ssh_listen_port]" 
	exit 1
fi

###     Things to be adjusted:  ###

cloudconfig="./cloud-config"

# Authorized keys for user 'core'
authorizedkey="ssh-rsa AAAAB3N................iOc7qeblJEUqrMXPij50LcE0ya10cmdAw=="

# generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
discovery="738........................e10"

# Machine shortname
shortname="$1"

# Machine domain name
domainname="$2"

# Machine name (FQDN)
fqdn=`echo -e "$shortname.$domainname"`

# TCP port to be user as listen port for SSH daemon:
sshport="$3"

createcloudconfig
defineandstart
ansibleready
