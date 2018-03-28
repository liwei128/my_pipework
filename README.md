# my_pipework
使Docker容器拥有可被宿主机以外的机器直接访问的独立IP

运行方式 ./dip.sh  dockerName  dockerIp

dockerName为容器名

dockerIp为容器指定的IP地址


ps:恢复原有IP配置，只需要运行 ./restartIp.sh
