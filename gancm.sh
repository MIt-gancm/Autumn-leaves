#字体颜色
########################################################
RED='\e[1;31m'    # 红 ${RED}
GREEN='\e[1;32m'  # 绿 ${GREEN}
YELLOW='\e[1;33m' # 黄 ${YELLOW}
BLUE='\e[1;34m'   # 蓝 ${BLUE}
PINK='\e[1;35m'   # 粉红 ${PINK}
RES='\e[0m'       # 清除颜色 ${RES}
##字体颜色

ERROR="[${RED}错误${RES}]:" # ${ERROR}
WORRY="[${YELLOW}警告${RES}]:" # ${WORRY 
SUSSEC="[${GREEN}成功${RES}]:" # ${SUSSEC}
INFO="[${BLUE}信息${RES}]:" # ${INFO}

#常用变量和函数
########################################################
case "$(uname -m)" in
	aarch64)
		archurl="arm64" 
		;;
	armv7l)
		archurl="armhf" 
		;;
	x86_64)
		archurl="amd64" 
		;;
esac

variable() {
	source ${HOME}/.gancm/config/config.sh
}
self_install() {
	case ${2} in
	pip)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "${RED}目前并没有安装 ${1} 正在安装${RES}"
			pip install -y ${1}
		fi
		;;
	pip3)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "${RED}目前并没有安装 ${1} 正在安装${RES}"
			pip3 install -y ${1}
		fi
		;;
	apt)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "${RED}目前并没有安装 ${1} 正在安装${RES}"
			apt install -y ${1}
		fi
		;;
	pkg)
		if [ ! -f "$(command -v ${1})" ]; then
			echo -e "${RED}目前并没有安装 ${1} 正在安装${RES}"
			pkg install -y ${1}
		fi
		;;
	esac
}
hcjx() {
	echo -e "${GREEN}请按回车键继续下一条指令...${RES}"
	read -r
}
validity_git() {
	source ${HOME}/.gancm/config/config.sh
	if [ "${git}" = "" ]; then
		wheregit=$(
			whiptail --title "选择默认安装源" --menu "以后的每次安装会优先考虑默认安装源" 15 60 4 \
				"1" "Github" \
				"2" "Gitee" \
				"0" "退出" 3>&1 1>&2 2>&3
		)
		case ${wheregit} in
		1)
			Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
			return 0
			;;
		2)
			Modify_the_variable git gitee.com ${HOME}/.gancm/config/config.sh
			return 0
			;;
		0)
			echo -e " 未选择默认修改为 ${YELLOW}Github${RES} "
			Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
			return 0
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
	if [ ! -d ${HOME}/.gancm/TEM ]; then
		mkdir ${HOME}/.gancm/TEM
	fi
}
validity() {
	validity_dir
	validity_git
}
Modify_the_variable() {
	sed -i "s/^${1}=.*/${1}=${2}/" ${3}
	#使用格式
	#Modify_the_variable 变量名 变量值 变量存储位置
	#Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
	#更改变量
}
list_dir() {
    current_index=1
    list=$(ls $1)
    list_items=($list)
    list_names=""

    for item in $list; do
        list_names+=" ${current_index} ${item}"
        let current_index++
    done
    user_choice=$(whiptail --title "选择" --menu "选择功能" 15 70 8 0 返回上级 ${list_names} 3>&1 1>&2 2>&3)
    # 选择结果 ${list_items[$((user_choice-1))]}
}
apt_up() {
	source ${HOME}/.gancm/config/config.sh
	current_timestamp=$(date +%s)
	if [ "${last_time_aptup}" = "" ] ;then
		apt update -y & apt upgrade -y
		Modify_the_variable last_time_aptup ${current_timestamp} ${HOME}/.gancm/config/config.sh
	else
		time_difference=$(($current_timestamp - $last_time_aptup))
        # 5天的秒数
        five_days_seconds=$((5 * 24 * 60 * 60))
		if [ $five_days_seconds -le $time_difference  ]; then
            apt update -y & apt upgrade -y
			Modify_the_variable last_time_aptup ${current_timestamp} ${HOME}/.gancm/config/config.sh
        fi
	fi
}
#函数

#变量

case ${1} in
-h | --help)
	echo -e "
	待添加
	"
	hcjx
	;;
*)
	apt_up
	case $(uname -o) in
	Android)
		self_install jq pkg
		self_install wget pkg
		self_install whiptail pkg
		self_install bc pkg
		validity
		variable 
		source ${HOME}/.gancm/local/Android/Android_menu $1 $2 $3
		;;
	*)
		self_install jq apt
		self_install wget apt
		self_install whiptail apt
		self_install bc apt
		validity
		variable 
		source ${HOME}/.gancm/local/Linux/Linux_menu $1 $2 $3
		;;
	esac
	;;
esac
