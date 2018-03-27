#接收用户参数
dockerName=$1
dockerIp=$2

#网卡信息
gateway=$(ip route show|grep '^default'|awk '{print $3}')
dip=$(ip addr|grep "inet"|grep -v "inet6"|awk '{print $2}'|cut  -d / -f 1|grep -v ".0.1$")

#校验用户输入参数
function checkParameter(){
      if [ "$dockerName" = "" -o "$dockerIp" = "" ];then
           echo "参数不能为空"
           exit 0
      fi

      #多网卡处理
      baseIp=$(echo ${dockerIp}|cut -d . -f1-3)
      dip=$(echo "$dip"|grep ^${baseIp})
      gateway=$(echo "$gateway"|grep ^${baseIp})
      name=$(ip addr|grep -B 2 ${dip}|sed -n "1p"|awk '{print $2}'|cut  -d : -f 1)
      echo "网关${gateway}  ip${dip}  网卡${name}"

      if [ "$dip" = "" ];then
           echo "ip地址${dockerIp}不合法"
           exit 0
      fi
      ping -c 2 ${dockerIp} &>/dev/null
      if [ $? = 0 ];then
           echo "${dockerIp} 已存在"
           exit 0

      fi

}
#为docker容器设置独立Ip
function setIp(){
        if [ ! "$name" = "br0" ];then
	     sudo brctl addbr br0
             sudo ip addr del dev ${name} ${dip}/24
	     sudo ip addr add ${dip}/24 dev br0
	     sudo ip link set dev br0 up
	     sudo ip route add default via ${gateway} dev br0
             sudo brctl addif br0 ${name} 
         fi
	msg=$(pipework br0 ${dockerName} ${dockerIp}/24@${gateway})
	if [ "$msg" = "" ];then
	   service network restart
	   echo "Success:${dockerName}-->${dockerIp}"
   	else
           echo "Fail:${msg}"
	fi
	echo "nameserver 114.114.114.114">> /etc/resolv.conf
}

#检查安装网桥工具
function installBridge(){
      bridge=$(yum list installed|grep 'bridge-utils')
      if [ "$bridge" = "" ];then
	  yum install -y bridge-utils
      fi
}
#检查安装git
function installGit(){
      gits=$(yum list installed|grep '^git')
      if [ "$gits" = "" ];then
          yum install -y git
      fi
}

#检查安装pipework
function installPipework(){
	if [ ! -e "/usr/local/bin/pipework" ];then
	   git clone https://github.com/jpetazzo/pipework.git
           cp  pipework/pipework /usr/local/bin/
           rm -rf pipework
        fi
	chmod +x /usr/local/bin/pipework
}


checkParameter
installGit
installBridge
installPipework
setIp
