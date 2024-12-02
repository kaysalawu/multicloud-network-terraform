#!/bin/bash

char_pass="\u2714"
char_delete="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"
char_arrow="\u279C"

rg=$1
echo -e "\nResource group: $rg\n"

usage() {
  echo "Usage: $0 <resource-group>"
  echo "-h, --help       Display help"
}

if [ -z $rg ]; then
  usage && echo
  return 1
fi

get_bgp_peers(){
  # for each gateway display the bgp peer status
  mapfile -t gateways < <(az network vnet-gateway list -g $rg --query "[].name" -o tsv)
  for gw in "${gateways[@]}"; do
    echo -e "Gateway: $gw"
    echo -e "Route tables:"
    az network vnet-gateway list-bgp-peer-status -g $rg --name $gw --query 'value[].{Neighbor:neighbor, ASN:asn, localAddress:localAddress, routesReceived:routesReceived, State:state}' -o table
    echo
  done
}

get_bgp_peers

