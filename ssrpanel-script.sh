PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 7+
#	Description: ssrpanel后端一键安装脚本
#	Version: 0.1.4
#	Author: 壕琛
#	Blog: http://mluoc.top/
#=================================================

sh_ver="0.1.4"
github="https://raw.githubusercontent.com/mlch911/ssrpanel-script/master/ssrpanel-script.sh"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"



#开始菜单
start_menu(){
	clear
	echo && echo -e " ssrpanel后端 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
	  -- 壕琛小站 | ss.mluoc.tk --


	 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
	 ${Green_font_prefix}1.${Font_color_suffix} 安装依赖(只需执行一次，若重复执行会覆盖原有配置)
	 ${Green_font_prefix}2.${Font_color_suffix} 服务器配置
	 ${Green_font_prefix}3.${Font_color_suffix} 运行服务
	 ${Green_font_prefix}4.${Font_color_suffix} 开放防火墙
	 ${Green_font_prefix}5.${Font_color_suffix} 查看log
	 ${Green_font_prefix}6.${Font_color_suffix} 卸载全部
	 ${Green_font_prefix}7.${Font_color_suffix} 退出脚本
	————————————————————————————————" && echo

		# check_status
		# if [[ ${kernel_status} == "noinstall" ]]; then
		# 	echo -e " 当前状态: ${Green_font_prefix}未安装${Font_color_suffix} 加速内核 ${Red_font_prefix}请先安装内核${Font_color_suffix}"
		# else
		# 	echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} ${_font_prefix}${kernel_status}${Font_color_suffix} 加速内核 , ${Green_font_prefix}${run_status}${Font_color_suffix}"
		# fi

		sh_new_ver=$(wget --no-check-certificate -qO- "${github}"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
		if [[ ${sh_new_ver} != ${sh_ver} ]]; then
			Update_Shell
		fi


	echo
	read -p " 请输入数字 [0-8]:" num
	case "$num" in
		0)
		Update_Shell
		;;
		1)
		Install_Shell
		;;
		2)
		ServerSetup_Shell
		;;
		3)
		Run_Shell
		;;
		4)
		Firewalld_Shell
		;;
		5)
		Logs
		;;
		6)
		Uninstall
		;;
		7)
		exit 1
		;;
		*)
		clear
		echo -e "${Error}:请输入正确数字 [0-8]"
		sleep 2s
		start_menu
		;;
	esac
}

#更新脚本
Update_Shell(){
	echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- "${github}"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败 !" && sleep 2s && start_menu
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		read -p "(默认: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate ${github} && chmod +x ss-node-script.sh
			echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] ! 稍等片刻，马上运行 !"
			bash ss-node-script.sh
		else
			echo && echo "	已取消..." && echo
			start_menu
		fi
	else
		echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
		sleep 2s
		start_menu
	fi
}

#安装依赖
Install_Shell(){
	if [[ "${release}" == "centos" ]]; then
		# curl -fsSL get.docker.com | sh
		# curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
		# chmod +x /usr/local/bin/docker-compose
		# yum -y install epel-release
		# yum -y install python-pip
		# yum -y install unzip
		# pip install docker-compose

		yum -y remove docker docker-common container-selinux docker-selinux docker-engine docker-engine-selinux
		yum install -y yum-utils device-mapper-persistent-data lvm2 unzip
		yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
		yum makecache fast
		yum -y install docker-ce docker-compose
		systemctl enable docker
		systemctl start docker
		cd /root
		wget https://github.com/kszym2002/ssrpanel-be/releases/download/caddy-0.0.3/caddy-0.0.3.zip
		unzip caddy-0.0.3.zip
	fi

	echo -e "${Info}依赖安装结束！"
	sleep 3s
	start_menu
}

#服务器配置
ServerSetup_Shell(){
	cd /root/caddy-0.0.3/v2ray

	#设置node.id
	read -p " 请输入该节点的node.id :" node_id
	sed -i "17c node.id=${node_id}" config.properties

	#设置流量比例
	read -p " 请输入该节点的流量比例 :(不输入则为1.0)" traffic_rate_input
	traffic_rate="1.0"
	if  [ ${traffic_rate_input} ] ;then
		traffic_rate=${traffic_rate_input}
	fi
	sed -i "21c node.traffic-rate=${traffic_rate}" config.properties

	#设置服务器IP
	read -p ' 请输入ssrpanel服务器的IP(不输入则为127.0.0.1) :' mysql_host_input
	mysql_host="127.0.0.1"
	if  [ ${mysql_host_input} ] ;then
		mysql_host=${mysql_host_input}
	fi
	#设置服务器端口
	read -p ' 请输入ssrpanel服务器的端口(不输入则为3306) :' mysql_port_input
	mysql_port=3306
	if  [ ${mysql_port_input} ] ;then
		mysql_port=${mysql_port_input}
	fi
	#设置mysql服务器名
	read -p ' 请输入sspanel服务器的数据库名称(不输入则为ssrpanel) :' mysql_db_input
	mysql_db="ssrpanel"
	if  [ ${mysql_db_input} ] ;then
		mysql_db=${mysql_db_input}
	fi
	sed -i "25c datasource.url=jdbc:mysql://${mysql_host}:${mysql_port}/${mysql_db}?serverTimezone=GMT%2B8" config.properties

	#设置mysql服务器用户名
	read -p ' 请输入ssrpanel服务器的数据库用户名(不输入则为ssrpanel) :' mysql_user_input
	mysql_user="ssrpanel"
	if  [ ${mysql_user_input} ] ;then
		mysql_user=${mysql_user_input}
	fi
	sed -i "26c datasource.username=${mysql_db}" config.properties

	#设置mysql服务器密码
	read -p ' 请输入ssrpanel服务器的数据库密码(不输入则为ssrpanel) :' mysql_pass_input
	mysql_pass="ssrpanel"
	if  [ ${mysql_pass_input} ] ;then
		mysql_pass=${mysql_pass_input}
	fi
	sed -i "27c datasource.password=${mysql_pass}" config.properties

	cd /root/caddy-0.0.3/caddy
	#设置域名
	read -p " 请输入该节点的域名 :" domin
	sed -i "1c ${domin}" Caddyfile
	#设置邮箱
	read -p " 请输入绑定的邮箱 :" email
	sed -i "4c tls ${email}" Caddyfile

	cd /root/caddy-0.0.3/ssrmu
	sed -i "2c \    \"host\": \"v2.mluoc.tk\"," usermysql.json
	sed -i "3c \    \"port\": ${mysql_port}," usermysql.json
	sed -i "4c \    \"user\": \"${mysql_user}\"," usermysql.json
	sed -i "5c \    \"password\": \"${mysql_pass}\"," usermysql.json
	sed -i "6c \    \"db\": \"${mysql_db}\"," usermysql.json
	sed -i "7c \    \"node_id\": ${node_id}," usermysql.json
	sed -i "8c \    \"transfer_mul\": ${traffic_rate}," usermysql.json


	echo -e "${Info}服务器配置完成！"
	sleep 2s
	start_menu
}

#运行服务
Run_Shell(){
	cd /root/caddy-0.0.3
	read -p "是否运行服务 :(y/n)" run_input_a
	if [ ${run_input_a} == "y" ] ;then
		docker-compose up -d
		echo -e " ${Info} sspanel后端运行成功！"
		read -p "是否退出脚本 :(y/n)" run_input_b
		if [ ${run_input_b} == "y" ] ;then
			exit 1
		fi
		sleep 2s
		start_menu
	else
		start_menu
	fi
}

#开放防火墙
Firewalld_Shell(){
	clear
	echo -e " 请选择防火墙类型 :
	${Green_font_prefix}1.${Font_color_suffix} firewalld
	${Green_font_prefix}2.${Font_color_suffix} iptables
	————————————————————————————————"
	read -p "请输入数字 :" num
	if [ ${num} == "1" ] ;then
		echo -e " firewalld :
		${Green_font_prefix}1.${Font_color_suffix} 单端口
		${Green_font_prefix}2.${Font_color_suffix} 端口段
		————————————————————————————————"
		read -p "请输入数字 :" num
		if [ ${num} == "1" ] ;then
			read -p " 开放防火墙端口为 :" port_a
			firewall-cmd --permanent --zone=public --add-port=${port_a}/tcp
			firewall-cmd --permanent --zone=public --add-port=${port_a}/udp
			firewall-cmd --reload
		elif [ ${num} == "2" ] ;then
			read -p " 开放防火墙端口从 :" port_b
			read -p " 开放防火墙端口到 :" port_c
			firewall-cmd --permanent --zone=public --add-port=${port_b}-${port_c}/tcp
			firewall-cmd --permanent --zone=public --add-port=${port_b}-${port_c}/udp
			firewall-cmd --reload
		fi
	elif [ ${num} == "2" ] ;then
		echo -e " iptables :
		${Green_font_prefix}1.${Font_color_suffix} 单端口
		${Green_font_prefix}2.${Font_color_suffix} 端口段
		————————————————————————————————"
		read -p "请输入数字 :" num
		if [ ${num} == "1" ] ;then
			read -p " 开放防火墙端口为 :" port_a
			iptables -A INPUT -p tcp --dport ${port_a} -j ACCEPT
			iptables -A INPUT -p udp --dport ${port_a} -j ACCEPT
			service iptables save
			service iptables restart
		elif [ ${num} == "2" ] ;then
			read -p " 开放防火墙端口从 :" port_b
			read -p " 开放防火墙端口到 :" port_c
			iptables -A INPUT -p tcp --dport ${port_b}:${port_c} -j ACCEPT
			iptables -A INPUT -p udp --dport ${port_b}:${port_c} -j ACCEPT
			service iptables save
			service iptables restart
		fi
	fi
	echo -e " ${Info} 开放防火墙运行完成！"
	read -p "是否退出脚本 :(y/n)" firewalld_input
	if [ ${firewalld_input} == "y" ] ;then
		exit 1
	fi
	sleep 2s
	start_menu
}

#查看log
Logs(){
	clear
	cd /root/caddy-0.0.3
	docker-compose logs
	read -p "是否退出脚本 :(y/n)" logs_input
	if [ ${logs_input} == "y" ] ;then
		exit 1
	fi
	sleep 2s
	start_menu
}

#卸载全部
Uninstall(){
	clear
	cd /root/caddy-0.0.3
	read -p "是否确认卸载 :(y/n)" uninstall_input_a
	if [ ${uninstall_input_a} == "y" ] ;then
		docker-compose down
		read -p "卸载完毕，是否退出脚本 :(y/n)" uninstall_input_b
		if [ ${uninstall_input_b} == "y" ] ;then
			exit 1
		fi
		sleep 2s
		start_menu
	else
		start_menu
	fi
}

#############系统检测组件#############

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

#检查Linux版本
check_version(){
	if [[ -s /etc/redhat-release ]]; then
		version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
	else
		version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
	fi
	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="x64"
	else
		bit="x32"
	fi
}

#############系统检测组件#############

check_sys
check_version
[[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
start_menu