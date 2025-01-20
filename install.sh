#!/bin/bash
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
# 检测是否已经安装git

if ! command -v git &> /dev/null
then
    echo -e "${WORRY}Git未安装，正在尝试自动安装..."
    if [ "$(uname -o)" == "Linux" ]; then
        # Linux
        apt install -y git
    elif [ "$(uname -o)" == "Android" ]; then
        # Android
        pkg install git
    else
        echo -e "${ERROR}不支持的操作系统。"
        exit 1
    fi
    echo -e "${SUSSEC}Git已成功安装。"
fi

if [ -d ~/.gancm ]; then
    echo -e "${WORRY}目录 ~/.gancm 已存在，是否删除并重新拉取？(y/n)"
    read answer
    if [ "$answer" = "y" ]; then
        rm -rfv ~/.gancm
    else
        echo -e "${INFO}退出菜单"
        exit 0
    fi
fi

echo -e "${INFO}选择要拉取的源"
select opt in "github" "gitee" "退出" ; do
    case $opt in
        "github")
            if git clone https://github.com/MIt-gancm/Autumn-leaves ~/.gancm ; then
                echo -e "${SUSSEC}拉取成功"
                if [ "$(uname -o)" == "Linux" ]; then
                    # Linux
                    ln -s ~/.gancm/gancm.sh /usr/bin/gancm
                    chmod 777 /usr/bin/gancm
                elif [ "$(uname -o)" == "Android" ]; then
                    # Android
                    ln -s ~/.gancm/gancm.sh /data/data/com.termux/files/usr/bin/gancm
                    chmod 777 ~/data/data/com.termux/files/usr/bin/gancm   
                fi
                break
            else 
                echo -e "${ERROR}拉取失败"
                exit 1
            fi
            break
            ;;
        "gitee")
            if git clone https://gitee.com/MIt-gancm/Autumn-leaves ~/.gancm ; then
                echo -e "${SUSSEC}拉取成功"
                if [ "$(uname -o)" == "Linux" ]; then
                    # Linux
                    ln -s ~/.gancm/gancm.sh /usr/bin/gancm
                    chmod 777 /usr/bin/gancm
                elif [ "$(uname -o)" == "Android" ]; then
                    # Android
                    ln -s ~/.gancm/gancm.sh /data/data/com.termux/files/usr/bin/gancm
                    chmod 777 /data/data/com.termux/files/usr/bin/gancm
                fi
                break
            else
                echo -e "${ERROR}拉取失败"
                exit 1
            fi
            ;;
        "退出")
            echo -e "${INFO}退出菜单"
            break
            ;;
        *)
            echo -e  "{ERROR}无效选择，请重新选择"
            ;;
    esac
done