#!/bin/bash
# core/utils.sh - 通用工具函数

# 字体颜色定义
export RED='\e[1;31m' # 红色
export GREEN='\e[1;32m' # 绿色
export YELLOW='\e[1;33m' # 黄色
export BLUE='\e[1;34m' # 蓝色 
export PINK='\e[1;35m' # 粉色
export RES='\e[0m' # 结束颜色

# 定义颜色 (如果外部未定义)
[ -z "$INFO" ] && INFO="\033[32m[INFO]\033[0m"
[ -z "$ERROR" ] && ERROR="\033[31m[ERROR]\033[0m"
[ -z "$SUSSEC" ] && SUSSEC="\033[32m[SUCCESS]\033[0m"
[ -z "$WARN" ] && WARN="\033[33m[WARN]\033[0m"

LOG_FILE="${GANCM_ROOT}/logs/log.log"
LOG_MAX_SIZE=$((2 * 1024 * 1024)) # 日志最大 2MB
LOG_BACKUP_COUNT=3                # 保留3个备份文件

# 内部函数：去除颜色代码 (用于写入日志文件)
_strip_color() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}
# 内部函数：日志轮转 (当文件超过2MB时，备份并清空，比 sed 删除行性能高千倍)
_log_rotate() {
    local file="$1"
    local max_size=$((2 * 1024 * 1024)) # 2MB
    
    if [ -f "$file" ]; then
        local size=$(stat -c%s "$file" 2>/dev/null || wc -c <"$file")
        if [ "$size" -gt "$max_size" ]; then
            mv "$file" "${file}.bak" # 简单的轮转：只保留一份备份
            touch "$file"
        fi
    fi
}
# 核心日志记录逻辑
log() {
    local level_prefix="$1"  # 颜色前缀 (如 ${INFO})
    local raw_level="$2"     # 纯文本等级 (如 INFO)
    shift 2
    local message="$*"       # 消息内容
    
    local log_file="${GANCM_ROOT}/logs/log.log"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 1. 确保日志目录存在
    local log_dir=$(dirname "$log_file")
    [ ! -d "$log_dir" ] && mkdir -p "$log_dir"
    # 2. 检查日志轮转
    _log_rotate "$log_file"
    # 3. 构造日志内容
    # 终端显示用的 (带颜色)
    local screen_msg="${level_prefix} ${message}"
    # 文件记录用的 (纯文本: 时间 [等级] [PID] 消息)
    local file_msg="[${timestamp}] [${raw_level}] [$$]: $(_strip_color "${message}")"
    
    # 4. 写入文件 (始终执行)
    echo "$file_msg" >> "$log_file"
    # 5. 输出到终端 (根据参数决定)
    # 如果是 DEBUG_MODE，或者你想让错误信息(ERROR)始终显示，可以修改此处的判断逻辑
    if [ "$DEBUG_MODE" = true ] || [ "$is_output" = true ]; then
        echo -e "$screen_msg"
    fi
}
# 封装对外接口
log_info()  { log "${INFO}" "INFO" "$@"; }
log_succ()  { log "${SUSSEC}" "SUCCESS" "$@"; }
log_warn()  { log "${WORRY}" "WARN" "$@"; }
log_error() { 
    # 特殊处理：ERROR 无论是否 debug 模式都显示
    echo -e "${ERROR} $@" 
    log "${ERROR}" "ERROR" "$@" 
}


# 加载配置
load_config() {
    source "${GANCM_ROOT}/config/config.sh"
}

# 修改配置文件变量
# 用法: Modify_the_variable 变量名 新值 文件路径
Modify_the_variable() {
    local var_name=$1
    local new_val=$2
    local file_path=$3
    # 转义斜杠以防止 sed 报错
    local escaped_val=$(echo "$new_val" | sed 's/\//\\\//g')
    sed -i "s/^${var_name}=.*/${var_name}=${escaped_val}/" "${file_path}"
}

# 依赖安装检查
self_install() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}未安装 $1，正在安装...${RES}"
        ${package_manager} install -y "$1"
    fi
}

# 批量检查依赖
check_dependencies() {
    for pkg in "$@"; do
        self_install "$pkg"
    done
}

# 按回车继续
hcjx() {
    echo -e "${GREEN}请按回车键继续下一条指令...${RES}"
    read -r
}

# 初始化目录和基本设置
validity_check() {
    mkdir -p ${GANCM_ROOT}/{download,config,modules,core,lib}
    mkdir -p ${HOME}/.back
    mkdir -p ${HOME}/.TEMP
    
    # 首次运行检查 Git 源配置
    source "${GANCM_ROOT}/config/config.sh"
    if [ -z "${git}" ]; then
        validity_git
    fi
    # 首次运行检查自动更新配置
    if [ -z "${auto_upgrade}" ]; then
        validity_auto_upgrade
    fi
}

# Git 源选择 UI
validity_git() {
    local wheregit=$(whiptail --title "选择默认安装源" --menu "以后的每次安装会优先考虑默认安装源" 15 60 4 \
        "1" "Github" \
        "2" "Gitee" \
        "3" "Github反代" \
        "0" "退出" 3>&1 1>&2 2>&3)
        
    local config_file="${GANCM_ROOT}/config/config.sh"
    case ${wheregit} in
        1)
            Modify_the_variable git "https://github.com/" $config_file
            Modify_the_variable rawgit "https://raw.githubusercontent.com/MIt-gancm/Autumn-leaves/refs/heads/main/" $config_file
            ;;
        2)
            Modify_the_variable git "https://gitee.com/" $config_file
            Modify_the_variable rawgit "https://raw.giteeusercontent.com/MIt-gancm/Autumn-leaves/raw/main/" $config_file
            ;;
        3)
            Modify_the_variable git "https://dl.gancmcs.top/https://github.com/" $config_file
            Modify_the_variable rawgit "https://dl.gancmcs.top/https://raw.githubusercontent.com/MIt-gancm/Autumn-leaves/refs/heads/main/" $config_file
            ;;
        *)
            echo -e " 未选择默认修改为 ${YELLOW}Github${RES} "
            Modify_the_variable git "https://gitee.com/" $config_file
            Modify_the_variable rawgit "https://raw.githubusercontent.com/MIt-gancm/Autumn-leaves/refs/heads/main/" $config_file
            ;;
    esac
}

# 自动更新配置 UI
validity_auto_upgrade() {
    local choice=$(whiptail --title "自动更新设置" --menu "是否自动更新软件包(默认关闭)" 15 60 4 \
        "1" "开启" \
        "2" "关闭" \
        "0" "退出" 3>&1 1>&2 2>&3)
        
    local config_file="${GANCM_ROOT}/config/config.sh"
    case ${choice} in
        1)
            Modify_the_variable auto_upgrade "true" $config_file
            log_info "自动升级脚本开启"
            ;;
        *)
            Modify_the_variable auto_upgrade "false" $config_file
            log_info "自动升级脚本关闭"
            ;;
    esac
}

#打开目录
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
    # 选择了第 $user_choice 个选项
}

list_items() {
    current_index=1
	list="$@"
	list_items=($list)
	list_names=""

	for item in $list; do
		list_names+=" ${current_index} ${item}"
		let current_index++
	done
	user_choice=$(whiptail --title "选择" --menu "选择功能" 15 70 8 0 返回上级 ${list_names} 3>&1 1>&2 2>&3)
	# 选择结果 ${list_items[$((user_choice-1))]}
    # 选择了第 $user_choice 个选项
}

show_help() {
    echo -e "
-h | --help\t\t\t\t显示帮助信息
-s | --start [Android/Linux]\t启动脚本固定版本 [功能]
-D | --debuger 显示相对详细的运行日志

\t\tAndroid:
\t\t\tinstall proot\t\t安装proot工具
\t\t\tstart proot\t\t启动proot服务

\t\tLinux:
\t\t\tdownload_JAVA|dj\t下载JAVA环境
\t\t\tinstall_MC_SERVER|imcs\t安装MC_SERVER服务
\t\t\tstart_MC_SERVER|smcs\t启动MC_SERVER服务
\t\t\trm_MC_SERVER|rmcs\t移除MC_SERVER服务
\t\t\tinstallMCSManager|imcsm\t安装我的世界面板
"
    hcjx
}

