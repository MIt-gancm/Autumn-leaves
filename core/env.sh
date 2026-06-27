#!/bin/bash
# core/env.sh - 系统与环境检测

# 架构映射
declare -A arch_map=(["aarch64"]="arm64" ["armv7l"]="armhf" ["x86_64"]="amd64")
export archurl="${arch_map[$(uname -m)]}"

# 获取 Linux 发行版
get_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/issue ]; then
        local issue_content=$(cat /etc/issue | awk '{print $1; exit}')
        echo "$issue_content" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# 检测包管理器
detect_package_manager() {
    if [ -d "/data/data/com.termux/files/usr" ]; then
        echo "pkg"
        return
    fi

    local distro=$(get_linux_distro)
    case "$distro" in
        "ubuntu"|"debian"|"linuxmint"|"pop"|"kali") echo "apt" ;;
        "centos"|"rhel"|"rocky"|"almalinux") echo "yum" ;;
        "fedora") echo "dnf" ;;
        "arch"|"manjaro"|"endeavouros") echo "pacman" ;;
        "opensuse"|"suse") echo "zypper" ;;
        *)
            if command -v apt >/dev/null 2>&1; then echo "apt";
            elif command -v dnf >/dev/null 2>&1; then echo "dnf";
            elif command -v yum >/dev/null 2>&1; then echo "yum";
            elif command -v pacman >/dev/null 2>&1; then echo "pacman";
            elif command -v zypper >/dev/null 2>&1; then echo "zypper";
            else echo "unknown"; fi
            ;;
    esac
}

# 全局包管理器变量
export package_manager=$(detect_package_manager)

# 获取系统类型 (Android/Linux)
get_system_type() {
    case $(uname -o) in
        Android) echo "Android" ;;
        *) echo "Linux" ;;
    esac
}

# 系统级自动更新 (apt update等)
check_auto_update() {
    load_config
    local current_timestamp=$(date +%s)
    # 如果 last_time_aptup 为空或超过 5 天
    if [[ -z "${last_time_aptup}" || $((current_timestamp - last_time_aptup)) -ge $((5 * 24 * 60 * 60)) ]]; then
        if [ "${auto_upgrade}" = "true" ]; then
            log "执行系统包管理器更新..."
            $package_manager update -y && $package_manager upgrade -y
            Modify_the_variable last_time_aptup ${current_timestamp} "${GANCM_ROOT}/config/config.sh"
        fi
    fi
}

# 调试信息显示
debuger() {
    # 强制开启颜色输出，因为这是专门的调试命令
    echo -e "\n${BLUE}================= [系统全维调试信息] =================${RES}"
    
    echo -e "${INFO} 脚本根目录: ${GANCM_ROOT}"
    
    # --- 系统基础信息 ---
    if [ -f /etc/os-release ]; then
        local os_name=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)
        echo -e "${INFO} 操作系统  : ${os_name}"
    else
        echo -e "${INFO} 操作系统  : $(uname -srm)"
    fi
    echo -e "${INFO} 内核版本  : $(uname -r)"
    echo -e "${INFO} 运行时间  : $(uptime -p)"
    
    # --- 硬件资源 ---
    # 内存使用率
    local mem_usage=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    echo -e "${INFO} 内存使用  : ${mem_usage}"
    # 磁盘根目录使用率
    local disk_usage=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
    echo -e "${INFO} 磁盘使用  : ${disk_usage}"
    # 系统负载
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${INFO} 系统负载  :${load_avg}"
    # --- 网络信息 (兼容旧版 ifconfig 和新版 ip addr) ---
    local ip_addr=""
    if command -v ip >/dev/null 2>&1; then
        ip_addr=$(ip -4 addr | grep -v '127.0.0.1' | grep -v 'lo' | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    else
        ip_addr=$(ifconfig | grep inet | grep -vE 'inet6|127.0.0.1' | awk '{print $2}' | head -n 1)
    fi
    echo -e "${INFO} 本机 IP   : ${ip_addr:-"未检测到"}"
    # --- 配置与日志 ---
    local config_file="${GANCM_ROOT}/config/config.sh"
    echo -e "\n${PINK}--- [配置文件前10行] ---${RES}"
    if [ -f "$config_file" ]; then
        # 排除空行和注释，只看有效配置，且只看前10行
        grep -vE '^\s*#|^\s*$' "$config_file" | head -n 10
    else
        echo -e "${ERROR} 配置文件不存在: $config_file"
    fi
    
    echo -e "\n${PINK}--- [日志文件末尾50行] ---${RES}"
    local log_file="${GANCM_ROOT}/logs/log.log"
    if [ -f "$log_file" ]; then
        tail -n 50 "$log_file"
    else
        echo -e "${WORRY} 暂无日志文件"
    fi
    echo -e "${BLUE}======================================================${RES}\n"
}
