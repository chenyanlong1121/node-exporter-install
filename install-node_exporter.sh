#!/bin/bash

if [ $# != 2 ];then
echo -e "\e[33m USAGE: sh install-node_exporter.sh  本机IP  pushgateway地址  \e[0m"
echo -e '\e[33m e.g. : sh install-node_exporter.sh   172.20.41.35  172.17.1.34:30009  \e[0m' 
echo -e "\e[33m pushgateway部署在看K8s集群的monitoring空间下，若不存在  \e[0m"
echo -e "\e[33m 把pushgateway.yaml拷贝至主节点上  \e[0m"
echo -e "\e[33m 在K8s集群主节点执行kubectl apply -f pushgateway.yaml  \e[0m"
exit 1;
fi

NATIVE_IP=$1
PUSHGATEWAY_ADDR=$2

echo -e "\e[32m 本机IP是：${NATIVE_IP} \e[0m"
echo -e "\e[32m pushgateway地址是：${PUSHGATEWAY_ADDR} \e[0m"


read -r -p "请确认上述配置,是否继续? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo -e "\e[32m 开始安装node_exporter  \e[0m"
	#判断是否已安装
        if [ ! -d "/usr/local/exporter"  ];then
	  mkdir /usr/local/exporter -pv 
          tar xf node_exporter-1.3.1.linux-amd64.tar.gz  -C /usr/local/exporter/
          ls /usr/local/exporter/
          ln -s  /usr/local/exporter/node_exporter-1.3.1.linux-amd64/ /usr/local/exporter/node_exporter
	  cp config.yml /usr/local/exporter/node_exporter
	  cp node_exporter.service  /usr/lib/systemd/system/
	  cp pushgateway.sh  /root/
          chmod 777 /root/pushgateway.sh
          #创建用户组
	  groupadd prometheus
	  #创建用户并添加至用户组
	  useradd  prometheus -g prometheus
	  #目录授权
	  chown -R prometheus:prometheus /usr/local/exporter
          systemctl daemon-reload
	  systemctl restart node_exporter
	  systemctl enable  node_exporter

	  sed -i "s#native_ip#${NATIVE_IP}#g"  /root/pushgateway.sh
          sed -i "s#pushgateway_addr#${PUSHGATEWAY_ADDR}#g"  /root/pushgateway.sh
	  match_content_result=$(cat /var/spool/cron/root  |grep pushgateway)
	echo ${match_content_result}
	  #开启定时任务：定时推送数据至pushgateway
	  if [ "${match_content_result}" == "" ];then
            cat >> /var/spool/cron/root  << EOF
* * * * * sleep 10;/root/pushgateway.sh >> /root/pushgateway.log 2>&1
* * * * * sleep 20;/root/pushgateway.sh >> /root/pushgateway.log 2>&1
* * * * * sleep 30;/root/pushgateway.sh >> /root/pushgateway.log 2>&1
* * * * * sleep 40;/root/pushgateway.sh >> /root/pushgateway.log 2>&1
* * * * * sleep 50;/root/pushgateway.sh >> /root/pushgateway.log 2>&1
EOF
	  fi
          echo -e "\e[32m 命令说明： \e[0m"
	  echo -e "\e[32m 停止命令：systemctl stop    node_exporter \e[0m"
	  echo -e "\e[32m 启动命令：systemctl start   node_exporter \e[0m"
	  echo -e "\e[32m 重启命令：systemctl restart node_exporter \e[0m"
          echo -e "\e[32m 状态命令：systemctl status  node_exporter \e[0m"
	  echo -e "\e[32m 状态命令里面包含着安装信息与service信息等 \e[0m"
         
        else
          echo -e "\e[33m node_exporter已安装，跳过此安装  \e[0m"
        fi
        ;;

    [nN][oO]|[nN])
        echo "退出安装"
        ;;

    *)
        echo "无效选项"
        exit 1
        ;;
esac

