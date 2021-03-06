#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

CMD=./govc/govc_linux_amd64

function setPropertyMapping() {
  if [ -e out.json ]; then
    mv out.json in.json
  fi
  $JQ_CMD --arg key $1 \
     --arg value $2 \
     '(.PropertyMapping[] | select(.Key == $key)).Value = $value' \
                in.json >out.json
}

function setNetworkMapping() {
  if [ -e out.json ]; then
    mv out.json in.json
  fi
  $JQ_CMD --arg value $1 \
     '(.NetworkMapping[]).Network = $value' \
                in.json >out.json
}

function removeUnwantedNodes() {
  if [ -e out.json ]; then
    mv out.json in.json
  fi

  $JQ_CMD 'del(.Deployment)' in.json >out.json
}

function setVMName() {
  if [ -e out.json ]; then
    mv out.json in.json
  fi

  $JQ_CMD --arg value $1 \
     '(.).Name = $value' \
                in.json >out.json
}

function setDiskProvision() {
  if [ -e out.json ]; then
    mv out.json in.json
  fi

  $JQ_CMD --arg value $1 \
     '(.).DiskProvisioning = $value' \
                in.json >out.json
}

function setPowerOn() {
  if [ -e out.json ]; then
    mv out.json in.json
  fi

  if [ $1 ]; then
    $JQ_CMD '(.).PowerOn = true' \
                  in.json >out.json
  fi
}

function update() {
  rm -rf out.json

  setPropertyMapping ip0 $OPS_MGR_IP
  setPropertyMapping netmask0 $OM_NETMASK
  setPropertyMapping gateway $OM_GATEWAY
  setPropertyMapping DNS $OM_DNS_SERVERS
  setPropertyMapping ntp_servers $OM_NTP_SERVERS
  setPropertyMapping admin_password $OPS_MGR_SSH_PWD
  setPropertyMapping custom_hostname $OPS_MGR_HOST

  setNetworkMapping $OM_VM_NETWORK
  setVMName $OM_VM_NAME
  setDiskProvision $OM_DISK_TYPE
  setPowerOn $OM_VM_POWER_STATE
  removeUnwantedNodes

  cat out.json
}

FILE_PATH=`find ./pivnet-product/ -name *.ova`

echo $FILE_PATH

$CMD import.spec $FILE_PATH | python -m json.tool > om-import.json

mv om-import.json in.json

update

$CMD import.ova -options=out.json $FILE_PATH

rm *.json
