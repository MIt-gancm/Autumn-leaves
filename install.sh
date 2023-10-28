#字体颜色
########################################################
RED='\e[1;31m'    # 红
GREEN='\e[1;32m'  # 绿
YELLOW='\e[1;33m' # 黄
BLUE='\e[1;34m'   # 蓝
PINK='\e[1;35m'   # 粉红
RES='\e[0m'       # 清除颜色
##字体颜色

#常用变量和函数
########################################################
variable() {
     source ${HOME}/.gancm/config/config.sh
}
gettime() {
	echo -e "${YELLOW}[$(date +"%Y-%m-%d %H:%M:%S")]${RES} "
}
self_install() {
	case ${2} in
	pip)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "$(gettime)${RED}目前并没有安装 ${1} 正在安装${RES}"
			pip install -y ${1}
		fi
		;;
	pip3)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "$(gettime)${RED}目前并没有安装 ${1} 正在安装${RES}"
			pip3 install -y ${1}
		fi
		;;
	apt)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "$(gettime)${RED}目前并没有安装 ${1} 正在安装${RES}"
			apt install -y ${1}
		fi
		;;
	esac
}
hcjx() {
	echo -e "${GREEN}请按回车键继续下一条指令...${RES}"
	read -r
}
validity_git() {
	if [ ! -f ${HOME}/.gancm/bot/variable.cfg ]; then
		wheregit=$(
			whiptail --title "选择默认安装源" --menu "以后的每次安装会优先考虑默认安装源" 15 60 4 \
			"Github" "1" \
			"Gitee" "2" \
			"0" "退出" 3>&1 1>&2 2>&3
		)
		case ${wheregit} in
		0)
			echo -e "$(gettime) 未选择默认修改为 ${YELLOW}Gitee${RES} "
			Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
			return 0
			;;
		*)
			Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
			;;
		esac
	fi
}
validity_dir() {
	if [ ! -d ${HOME}/.gancm/ ]; then
		mkdir ${HOME}/.gancm/
	fi
	if [ ! -d ${HOME}/.gancm/download ]; then
		mkdir ${HOME}/.gancm/download
	fi
	if [ ! -d ${HOME}/.gancm/config ]; then
		mkdir ${HOME}/.gancm/config
	fi
}
validity() {
	validity_dir
	validity_git

}
Modify_the_variable() {
     sed -i "s/^${1}=.*/${1}=${2}/"  ${3}
     #使用格式
     #Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
     #更改变量
}
variable
apt update -y
self_install wget 
self_install pv
self_install curl

