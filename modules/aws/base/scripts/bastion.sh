#! /bin/bash

exec > /var/log/aws-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

METADATA_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
hostnamectl set-hostname $METADATA_HOSTNAME
sed -i "s/127.0.0.1.*/127.0.0.1 $HOSTNAME/" /etc/hosts

echo 'PS1="\\h:\\w\\$ "' >> /etc/bash.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /root/.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /home/ubuntu/.bashrc

apt update
apt install -y awscli
