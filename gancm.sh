# # 脚本功能概述
# 该脚本主要用于系统管理和软件包的安装维护，支持 Linux 和 Android 系统。它包含了颜色定义、错误和信息提示、系统架构判断、软件包安装函数、目录有效性检查、Git 默认源设置、变量修改以及菜单选择等功能。

# # 主要函数说明
# - `variable`: 加载配置文件。
# - `self_install`: 根据传入的参数，使用对应的包管理器安装指定的软件包。
# - `hcjx`: 提示用户按回车键继续。
# - `validity_git`: 设置 Git 默认源。
# - `validity_dir`: 检查并创建必要的目录。
# - `validity`: 执行目录和 Git 源的有效性检查。
# - `Modify_the_variable`: 修改配置文件中的变量值。
# - `list_dir`: 显示目录列表供用户选择。
# - `apt_up`: 更新和升级 APT 包管理器的软件包。

# # 使用说明
# 脚本通过命令行参数执行不同的操作，支持 `-h` 或 `--help` 参数显示帮助信息。主要执行流程包括系统架构判断、软件包安装、目录和 Git 源检查，以及根据系统类型加载相应的菜单。
#字体颜色
########################################################
RED='\e[1;31m'                   # 红 ${RED}
GREEN='\e[1;32m'                 # 绿 ${GREEN}
YELLOW='\e[1;33m'                # 黄 ${YELLOW}
BLUE='\e[1;34m'                  # 蓝 ${BLUE}
PINK='\e[1;35m'                  # 粉红 ${PINK}
RES='\e[0m'                      # 清除颜色 ${RES}
##字体颜色

ERROR="[${RED}错误${RES}]:"    # ${ERROR}
WORRY="[${YELLOW}警告${RES}]:" # ${WORRY}
SUSSEC="[${GREEN}成功${RES}]:" # ${SUSSEC}
INFO="[${BLUE}信息${RES}]:"    # ${INFO}

#常用变量和函数
########################################################
declare -A arch_map=(["aarch64"]="arm64" ["armv7l"]="armhf" ["x86_64"]="amd64")
archurl="${arch_map[$(uname -m)]}"

variable() {
	source ${HOME}/.gancm/config/config.sh
}
#!/bin/bash
log() {
	#log文件名
	local fileName="${HOME}/.gancm/log.log"
	#log文件最大存储log行数（此处设置最大存储log行数是100行）
	local fileMaxLen=100
	#超过log最大存储行数后需要从顶部开始删除的行数（此处设置的是删除第1到第10行的数据）
	local fileDeleteLen=10
	if test $fileName; then
		#记录log
		echo "[$(date +%y/%m/%d-%H:%M:%S)]:$*" >>$fileName
		#获取log文件实际行数
		loglen=$(grep -c "" $fileName)

		if [ $loglen -gt $fileMaxLen ]; then
			#从顶部开始删除对应行数的log
			sed -i '1,'$fileDeleteLen'd' $fileName
		fi
	else
		echo "[$(date +%y/%m/%d-%H:%M:%S)]:$*" >$fileName
	fi
}

# testdate=100
# #记录输出的字符串
# log "test string"
# #记录输出的数据
# log "testdate=$testdate"
# #记录输出的运算
# log $[1+2]
# #记录命令输出的信息
# log $(printf "this is cmd test %s\n" "this is cmd output string")

self_install() {
	if ! command -v "$1" &>/dev/null; then
		echo -e "${RED}未安装 $1，正在安装...${RES}"
		case $2 in
		pip | pip3 | apt | pkg) $2 install -y "$1" ;;
		*) echo -e "${YELLOW}未知的安装方式: $2${RES}" ;;
		esac
	fi
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
				"3" "Github反代" \
				"0" "退出" 3>&1 1>&2 2>&3
		)
		case ${wheregit} in
		1)
			Modify_the_variable git "http:\/\/github.com\/" ${HOME}/.gancm/config/config.sh
			Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/MIt-gancm\/Autumn-leaves\/refs\/heads\/main\/" ${HOME}/.gancm/config/config.sh
			return 0
			;;
		2)
			Modify_the_variable git "http:\/\/gitee.com\/" ${HOME}/.gancm/config/config.sh
			Modify_the_variable rawgit "https:\/\/raw.giteeusercontent.com\/MIt-gancm\/Autumn-leaves\/raw\/main\/" ${HOME}/.gancm/config/config.sh
			return 0
			;;
		3)
			Modify_the_variable git "https:\/\/dl.gancm.us.kg\/http:\/\/github.com\/" ${HOME}/.gancm/config/config.sh
			Modify_the_variable rawgit "https:\/\/dl.gancm.us.kg\/https:\/\/raw.githubusercontent.com\/MIt-gancm\/Autumn-leaves\/refs\/heads\/main\/" ${HOME}/.gancm/config/config.sh
			return 0
			;;
		0)
			echo -e " 未选择默认修改为 ${YELLOW}Github${RES} "
			Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/MIt-gancm\/Autumn-leaves\/refs\/heads\/main\/" ${HOME}/.gancm/config/config.sh
			return 0
			;;
		esac
	fi
}
validity_dir() {
	mkdir -p ${HOME}/.gancm/{download,config}
	mkdir -p ${HOME}/.back
	mkdir -p ${HOME}/.TEMP
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
	if [[ -z "${last_time_aptup}" || $((current_timestamp - last_time_aptup)) -ge $((5 * 24 * 60 * 60)) ]]; then
		apt update -y && apt upgrade -y
		Modify_the_variable last_time_aptup ${current_timestamp} ${HOME}/.gancm/config/config.sh
	fi
}
#函数

case ${1} in
-h | --help)
	echo -e "
-h | --help\t\t\t\t显示帮助信息
-s | --start [Android/Linux]\t启动脚本固定版本 [功能]

\t\tAndroid:
\t\t\tinstall proot\t\t安装proot工具
\t\t\tstart proot\t\t启动proot服务

\t\tLinux:
\t\t\tdownload_JAVA|dj\t下载JAVA环境（别名dj）
\t\t\tinstall_MC_SERVER|imcs\t安装MC_SERVER服务（别名imcs）
\t\t\tstart_MC_SERVER|smcs\t启动MC_SERVER服务（别名smcs）
\t\t\trm_MC_SERVER|rmcs\t移除MC_SERVER服务（别名rmcs）

\t\t\tinstallMCSManager | imcsm安装我的世界面板（别名imcsm）
\t\t\tstartMCSManager | startcsm\t启动我的世界面板（别名startcsm）
\t\t\tstopMCSManager | stopcsm\t停止我的世界面板（别名stopcsm）

\t\t\tinstallNapCatQQ | inQQ\t安装NapCatQQ（别名inQQ）
\t\t\tstartNapCatQQ | startnQQ\t启动NapCatQQ（别名startnQQ）
\t\t\tstartNapCatQQB | startnQQB\t后台启动NapCatQQ（后台）（别名startnQQB）
\t\t\tstopNapCatQQ | stopnQQ\t停止NapCatQQ（别名stopnQQ）
"
	hcjx
	;;
-s | --start)
	case $2 in
	Android | A)
		log "指定加载安卓功能"
		source ${HOME}/.gancm/local/Android/Android_menu $3 $4 $5
		;;
	Linux | L)
		log "指定加载Linux功能"
		source ${HOME}/.gancm/local/Linux/Linux_menu $3 $4 $5
		;;
	esac
	;;
*)
	apt_up
	log "初始化完成"
	case $(uname -o) in
	Android)
		log "加载安卓功能"
		self_install jq pkg
		self_install git apt
		self_install wget pkg
		self_install whiptail pkg
		self_install tmux pkg
		self_install bc pkg
		validity
		variable
		source ${HOME}/.gancm/function/update.sh
		log "检查更新"
		source ${HOME}/.gancm/local/Android/Android_menu $1 $2 $3
		;;
	*)
		log "加载Linux功能"
		self_install jq apt
		self_install git apt
		self_install wget apt
		self_install whiptail apt
		self_install tmux apt
		self_install bc apt
		validity
		variable
		source ${HOME}/.gancm/function/update.sh
		log "检查更新"
		source ${HOME}/.gancm/local/Linux/Linux_menu $1 $2 $3
		;;
	esac
	;;
esac
