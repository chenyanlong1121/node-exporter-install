#!/bin/bash 

NATIVE_IP="native_ip"
PUSHGATEWAY_ADDR="pushgateway_addr"
HOSTNAME=`hostname`
CONTEXT=`curl -u prometheus:supconit http://localhost:9100/metrics `

job_name="server_metrics"
instance_name=${HOSTNAME}"|"${NATIVE_IP}

cat <<EOF | curl -u prometheus:supconit --data-binary @- http://${PUSHGATEWAY_ADDR}/metrics/job/$job_name/instance/$instance_name

$CONTEXT

EOF
