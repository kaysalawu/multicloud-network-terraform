#! /bin/bash

# !!! DO NOT USE THIS MACHINE FOR PRODUCTION !!!

export CLOUD_ENV=aws
exec > /var/log/$CLOUD_ENV-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "${USERNAME}:${PASSWORD}" | chpasswd
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

HOST_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
hostnamectl set-hostname $HOST_NAME
sed -i "s/127.0.0.1.*/127.0.0.1 $HOST_NAME/" /etc/hosts

echo 'PS1="\\h:\\w\\$ "' >> /etc/bash.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /root/.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /home/ubuntu/.bashrc

# disable systemd-resolved as it conflicts with dnsmasq on port 53
systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "$(hostname -I | cut -d' ' -f1) $(hostname)" >> /etc/hosts

apt update
apt install -y tcpdump dnsutils net-tools
apt install -y unbound

touch /etc/unbound/unbound.log
chmod a+x /etc/unbound/unbound.log

cat <<EOF > /etc/unbound/unbound.conf
server:
        port: 53
        do-ip4: yes
        do-ip6: yes
        do-udp: yes
        do-tcp: yes

        interface: 0.0.0.0
        interface: ::0

        access-control: 0.0.0.0 deny
        access-control: ::0 deny
        %{~ for prefix in ACCESS_CONTROL_PREFIXES ~}
        access-control: ${prefix} allow
        %{~ endfor ~}

        # local data records
        %{~ for tuple in ONPREM_LOCAL_RECORDS ~}
        local-data: "${tuple.name} ${tuple.ttl} IN ${tuple.type} ${tuple.rdata}"
        %{~ endfor ~}

        # hosts redirected to PrivateLink
        %{~ for tuple in REDIRECTED_HOSTS ~}
        %{~ for host in tuple.hosts ~}
        local-zone: ${host} redirect
        %{~ endfor ~}
        %{~ endfor ~}

        %{~ for tuple in REDIRECTED_HOSTS ~}
        %{~ for host in tuple.hosts ~}
        local-data: "${host} ${tuple.ttl} ${tuple.class} ${tuple.type} ${tuple.record}"
        %{~ endfor ~}
        %{~ endfor ~}

%{~ for tuple in FORWARD_ZONES }
forward-zone:
        name: "${tuple.zone}"
        %{~ for target in tuple.targets ~}
        forward-addr: ${target}
        %{~ endfor ~}
%{~ endfor ~}
EOF

systemctl enable unbound
systemctl restart unbound
apt install resolvconf
resolvconf -u
