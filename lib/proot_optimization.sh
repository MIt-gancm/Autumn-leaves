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


Modify_the_variable() {
	sed -i "s/^${1}=.*/${1}=${2}/" ${3}
	#使用格式
	#Modify_the_variable 变量名 变量值 变量存储位置
	#Modify_the_variable git github.com ${HOME}/.gancm/config/config.sh
	#更改变量
}

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
 
# 检测包管理器的函数
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

detect_package_manager() {
    local distro=$(get_linux_distro)
    case "$distro" in
        "ubuntu"|"debian"|"linuxmint"|"pop"|"kali")
            echo "apt"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            echo "yum"
            ;;
        "fedora")
            echo "dnf"
            ;;
        "arch"|"manjaro"|"endeavouros")
            echo "pacman"
            ;;
        "opensuse"|"suse")
            echo "zypper"
            ;;
        *)
            # 3. 如果发行版未知，再检查命令是否存在
            if command -v apt >/dev/null 2>&1; then
                echo "apt"
            elif command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            elif command -v yum >/dev/null 2>&1; then
                echo "yum"
            elif command -v pacman >/dev/null 2>&1; then
                echo "pacman"
            elif command -v zypper >/dev/null 2>&1; then
                echo "zypper"
            elif [ -d "/data/data/com.termux/files/usr" ]; then
                echo "pkg"
                return
            else
                echo "unknown"
                return 1
            fi
            ;;
    esac
}

package_manager=$(detect_package_manager)

self_install() {
	if ! command -v "$1" &>/dev/null; then
		echo -e "${RED}未安装 $1，正在安装...${RES}"
		$package_manager install -y "$1"
	fi
}

hcjx() {
	echo -e "${GREEN}请按回车键继续下一条指令...${RES}"
	read -r
}

echo "127.0.0.1 localhost" >/etc/hosts
mkdir -p /run/systemd/resolve
echo -e "${GREEN}尝试修复dns${RES}"

echo -e "nameserver 8.8.8.8
nameserver 114.114.114.114" >/run/systemd/resolve/stub-resolv.conf

echo -e "nameserver 8.8.8.8
nameserver 114.114.114.114" >/etc/resolv.conf
echo -e "${GREEN}尝试禁用无用检测${RES}"
ln -s ~/.gancm/gancm.sh /usr/bin/gancm
chmod 777 /usr/bin/gancm
touch ~/.hushlogin
$package_manager update -y &
$package_manager upgrade -y
Modify_the_variable last_time_aptup $(date +%s) ${HOME}/.gancm/config/config.sh
self_install language-pack-zh-hans $package_manager
self_install fonts-wqy-microhei $package_manager
self_install fonts-wqy-zenhei $package_manager
self_install glibc-langpack-zh $package_manager
self_install xfonts-wqy $package_manager
self_install ttf-wqy-zenhei $package_manager
self_install wget $package_manager
self_install git $package_manager
self_install jq $package_manager
self_install curl $package_manager
self_install bc $package_manager
echo -e "${GREEN}自己选择语言${RES}"
hcjx
rm -rf $0
dpkg-reconfigure locales
exit
