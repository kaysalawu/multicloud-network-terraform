#! /bin/bash

export CLOUD_ENV=aws
exec > /var/log/$CLOUD_ENV-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y python3-pip python3-dev python3-venv unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3
apt install -y python3-flask python3-requests
apt install -y awscli
apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker version
docker compose version

mkdir -p /var/flaskapp/flaskapp/{static,templates}

cat <<EOF >/var/flaskapp/flaskapp/__init__.py
import socket
from flask import Flask, request
app = Flask(__name__)

@app.route("/")
def default():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['Hostname'] = hostname
    data_dict['server-ipv4'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

@app.route("/path1")
def path1():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH1-APP'
    data_dict['Hostname'] = hostname
    data_dict['server-ipv4'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

@app.route("/path2")
def path2():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH2-APP'
    data_dict['Hostname'] = hostname
    data_dict['server-ipv4'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

if __name__ == "__main__":
    app.run(host= '0.0.0.0', port=80, debug = True)
EOF

cat <<EOF >/etc/systemd/system/flaskapp.service
[Unit]
Description=Script for flaskapp service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /var/flaskapp/flaskapp/__init__.py
ExecStop=/usr/bin/pkill -f /var/flaskapp/flaskapp/__init__.py
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp.service
systemctl restart flaskapp.service


# test scripts (ipv4)
#---------------------------

# ping-ipv4
cat <<'EOF' >/usr/local/bin/ping-ipv4
echo -e "\n ping ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, false) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo "${target.name} - ${target.ipv4} -$(timeout 3 ping -4 -qc2 -W1 ${target.ipv4} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4
cat <<'EOF' >/usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, false) ~}
echo "${target.host} - $(timeout 3 dig +short ${target.host} | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 ${target.host} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4
cat <<'EOF' >/usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.ipv4}) - ${target.name} [${target.ipv4}]"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4
cat <<'EOF' >/usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.host}) - ${target.host}"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4
cat <<'EOF' >/usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, false) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo -e "\n${target.name}"
echo -e "-------------------------------------"
timeout 9 tracepath -4 ${target.ipv4}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
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

# test scripts (ipv6)
#---------------------------

# ping-dns6
cat <<'EOF' >/usr/local/bin/ping-dns6
echo -e\n " ping dns ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, false) ~}
echo "${target.host} - $(timeout 3 dig AAAA +short ${target.host} | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 ${target.host} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-dns6
cat <<'EOF' >/usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.host}) - ${target.host}"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-dns6
cat <<'EOF' >/usr/local/bin/trace-dns6
echo -e "\n trace ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, false) ~}
echo -e "\n${target.name}"
echo -e "-------------------------------------"
timeout 9 tracepath -6 ${target.host}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/trace-dns6

# other scripts
#---------------------------

# dns-info
cat <<'EOF' >/usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# traffic generators (ipv4)
#---------------------------

# light-traffic generator
%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
cat <<'EOF' >/usr/local/bin/light-traffic
%{ for target in TARGETS_LIGHT_TRAFFIC_GEN ~}
%{~ if try(target.probe, false) ~}
nping -c ${try(target.count, "5")} --${try(target.protocol, "tcp")}-connect -p ${try(target.port, "80,8080")} ${try(target.host, target.ip)} > /dev/null 2>&1
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/light-traffic
%{ endif ~}

# heavy-traffic generator
%{ if TARGETS_HEAVY_TRAFFIC_GEN != [] ~}
cat <<'EOF' >/usr/local/bin/heavy-traffic
#! /bin/bash
i=0
while [ $i -lt 5 ]; do
  %{ for target in TARGETS_HEAVY_TRAFFIC_GEN ~}
  ab -n $1 -c $2 ${target} > /dev/null 2>&1
  %{ endfor ~}
  let i=i+1
  sleep 5
done
EOF
chmod a+x /usr/local/bin/heavy-traffic
%{ endif ~}

# traffic generators (ipv6)
#---------------------------

# light-traffic generator
%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
cat <<'EOF' >/usr/local/bin/light-traffic-ipv6
%{ for target in TARGETS_LIGHT_TRAFFIC_GEN ~}
%{~ if try(target.probe, false) ~}
nping -c ${try(target.count, "5")} -6 --${try(target.protocol, "tcp")}-connect -p ${try(target.port, "80,8080")} ${try(target.host, target.ip)} > /dev/null 2>&1
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/light-traffic-ipv6
%{ endif ~}

# systemctl services
#---------------------------

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
#---------------------------

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
