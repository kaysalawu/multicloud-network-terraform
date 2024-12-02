#!/bin/bash

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

apt update
apt install -y unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3
apt install -y awscli

# cloud-init install for docker did not work so installing manually here
apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker version
docker compose version

# test scripts (ipv4)

# ping-ipv4
cat <<'EOF' >/usr/local/bin/ping-ipv4
# ping-ipv4
echo -e "\n ping ipv4 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  name=$(echo $target | jq -r '.name')
  ipv4=$(echo $target | jq -r '.ipv4 // ""')
  if [[ -n "$ipv4" ]]; then
    result=$(timeout 3 ping -4 -qc2 -W1 $ipv4 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')
    echo "$name - $ipv4 - $result"
  fi
done
EOF
chmod a+x /usr/local/bin/ping-ipv4

# curl-ipv4
cat <<'EOF' >/usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  name=$(echo $target | jq -r '.name')
  ipv4=$(echo $target | jq -r '.ipv4 // ""')
  curl=$(echo $target | jq -r '.curl // true')
  if [[ "$curl" == "true" && -n "$ipv4" ]]; then
    result=$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null $ipv4)
    echo "$result - $name [$ipv4]"
  fi
done
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4
cat <<'EOF' >/usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  host=$(echo $target | jq -r '.host')
  curl=$(echo $target | jq -r '.curl // true')
  if [[ "$curl" == "true" ]]; then
    result=$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null $host)
    echo "$result - $host"
  fi
done
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4
cat <<'EOF' >/usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  name=$(echo $target | jq -r '.name')
  ipv4=$(echo $target | jq -r '.ipv4 // ""')
  if [[ -n "$ipv4" ]]; then
    echo -e "\n$name"
    echo -e "-------------------------------------"
    timeout 9 tracepath -4 $ipv4
  fi
done
EOF
chmod a+x /usr/local/bin/trace-ipv4

# ptr-ipv4
cat <<'EOF' >/usr/local/bin/ptr-ipv4
echo -e "\n PTR ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ptr, false) ~}
%{~ if try(target.ipv4, "") != "" ~}
arpa_zone=$(dig -x ${target.ipv4} | grep "QUESTION SECTION" -A 1 | tail -n 1 | awk '{print $1}')
ptr_record=$(timeout 3 dig -x ${target.ipv4} +short)
echo "${target.name} - ${target.ipv4} --> $ptr_record [$arpa_zone]"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ptr-ipv4

# ping-dns6
cat <<'EOF' >/usr/local/bin/ping-dns6
echo -e "\n ping dns ipv6 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  host=$(echo $target | jq -r '.host')
  ping=$(echo $target | jq -r '.ping // true')
  if [[ "$ping" == "true" ]]; then
    resolved_ip=$(timeout 3 dig AAAA +short $host | tail -n1)
    result=$(timeout 3 ping -6 -qc2 -W1 $host 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')
    echo "$host - $resolved_ip - $result"
  fi
done
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-dns6
cat <<'EOF' >/usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  host=$(echo $target | jq -r '.host')
  curl=$(echo $target | jq -r '.curl // true')
  if [[ "$curl" == "true" ]]; then
    result=$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null $host)
    echo "$result - $host"
  fi
done
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-dns6
cat <<'EOF' >/usr/local/bin/trace-dns6
echo -e "\n trace ipv6 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  name=$(echo $target | jq -r '.name')
  host=$(echo $target | jq -r '.host')
  echo -e "\n$name"
  echo -e "-------------------------------------"
  timeout 9 tracepath -6 $host
done
EOF
chmod a+x /usr/local/bin/trace-dns6

# other scripts

# dns-info
cat <<'EOF' >/usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# traffic gen (ipv4)

## light
cat <<'EOF' >/usr/local/bin/light-traffic
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  probe=$(echo $target | jq -r '.probe // false')
  if [[ "$probe" == "true" ]]; then
    count=$(echo $target | jq -r '.count // "5"')
    protocol=$(echo $target | jq -r '.protocol // "tcp"')
    port=$(echo $target | jq -r '.port // "80,8080"')
    host=$(echo $target | jq -r '.host // empty')
    nping -c $count --$protocol-connect -p $port $host > /dev/null 2>&1
  fi
done
EOF
chmod a+x /usr/local/bin/light-traffic

## heavy
cat <<'EOF' >/usr/local/bin/heavy-traffic
#!/bin/bash
i=0
while [ $i -lt 5 ]; do
  cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
    ab -n $1 -c $2 $(echo $target | jq -r '.host') > /dev/null 2>&1
  done
  let i=i+1
  sleep 5
done
EOF
chmod a+x /usr/local/bin/heavy-traffic

# traffic gen (ipv6)

## light
cat <<'EOF' >/usr/local/bin/light-traffic-ipv6
echo -e "\n light traffic ipv6 ...\n"
cat /usr/local/bin/targets.json | jq -c '.[]' | while IFS= read -r target; do
  probe=$(echo $target | jq -r '.probe // false')
  if [[ "$probe" == "true" ]]; then
    count=$(echo $target | jq -r '.count // "5"')
    protocol=$(echo $target | jq -r '.protocol // "tcp"')
    port=$(echo $target | jq -r '.port // "80,8080"')
    host=$(echo $target | jq -r '.host // empty')
    nping -c $count -6 --$protocol-connect -p $port $host > /dev/null 2>&1
  fi
done
EOF
chmod a+x /usr/local/bin/light-traffic-ipv6

# systemctl services

cat <<EOF > /etc/systemd/system/flaskapp.service
[Unit]
Description=Manage Docker Compose services for FastAPI
After=docker.service
Requires=docker.service

[Service]
Type=simple
Environment="HOSTNAME=$(hostname)"
ExecStart=/usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-80.yml up -d && \
          /usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-8080.yml up -d
ExecStop=/usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-80.yml down && \
         /usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-8080.yml down
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp.service
systemctl restart flaskapp.service

# crontabs

cat <<'EOF' >/etc/cron.d/traffic-gen
%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
*/1 * * * * /usr/local/bin/light-traffic 2>&1 > /dev/null
%{ endif ~}
%{ if TARGETS_HEAVY_TRAFFIC_GEN != [] ~}
*/1 * * * * /usr/local/bin/heavy-traffic 15 1 2>&1 > /dev/null
*/2 * * * * /usr/local/bin/heavy-traffic 3 1 2>&1 > /dev/null
*/3 * * * * /usr/local/bin/heavy-traffic 8 2 2>&1 > /dev/null
*/5 * * * * /usr/local/bin/heavy-traffic 5 1 2>&1 > /dev/null
%{ endif ~}
EOF

crontab /etc/cron.d/traffic-gen
