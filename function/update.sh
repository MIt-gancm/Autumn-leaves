# 设置变量
source ${HOME}/.gancm/config/config.sh
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

#函数
A_DIR="${HOME}/.gancm"   # A分区路径
B_DIR="${HOME}/.back"    # B分区路径
TEMP_DIR="${HOME}/.TEMP" # 临时目录
REMOTE_URL="${rawgit}config/version"
LOCAL_VERSION_FILE="${HOME}/.gancm/config/version"
log 清理临时目录
rm -rf $TEMP_DIR
# 获取本地版本
if [ -f "$LOCAL_VERSION_FILE" ]; then
	LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | jq -r .version)
else
	echo "本地版本文件不存在，无法进行版本比较！"
fi

# 获取最新的云端版本信息
echo -e "${INFO} 正在获取最新版本信息..."
log "更新源信息:$RESPONSE"
log "更新地址: $REMOTE_URL"
RESPONSE=$(curl -s $REMOTE_URL)

# 检查curl命令是否成功
if [ $? -ne 0 ]; then
	echo -e "${WORRY} 无法获取版本信息，请检查网络连接！"
fi

# 使用jq解析JSON信息
REMOTE_VERSION=$(echo $RESPONSE | jq -r .version)
GIT_CLONE=$(echo $RESPONSE | jq -r .git_clone)
DESCRIPTION=$(echo $RESPONSE | jq -r .description)
RELEASE_DATE=$(echo $RESPONSE | jq -r .release_date)

log "本地版本: $LOCAL_VERSION"
log "云端版本: $REMOTE_VERSION"
log "公告: $DESCRIPTION"
log "发布日期: $RELEASE_DATE"

# 比较版本
if [ "$(printf '%s\n' "$REMOTE_VERSION" "$LOCAL_VERSION" | sort -V | tail -n1)" != "$LOCAL_VERSION" ]; then
	# 输出获取的信息
	echo "本地版本: $LOCAL_VERSION"
	echo "云端版本: $REMOTE_VERSION"
	echo "公告: $DESCRIPTION"
	echo "发布日期: $RELEASE_DATE"

	echo "发现新版本，准备更新..."

	log 进行git克隆
	echo -e "${INFO}正在下载更新..."
	if git clone --depth 1 ${git}$GIT_CLONE $TEMP_DIR ; then
	    log 仓库拉取成功
	else
	    git config --global http.postBuffer 524288000  # 设置缓冲区为 500MB  
	    git config --global http.maxRequestBuffer 100M
		log 设置缓冲区
		log 重新拉取
		git clone --depth 1 ${git}$GIT_CLONE $TEMP_DIR
	fi



	if [ $? -ne 0 ]; then
		echo -e "${ERROR}更新失败，无法克隆仓库！"
		log 拉取失败
		exit 1
	fi

	# 备份当前A分区
	echo -e "${INFO}备份当前A分区..."
	log 创建备份的 tar.gz 压缩包
	log "BACKUP_FILE=".back/backup_$(date +%Y%m%d_%H%M%S)_${LOCAL_VERSION}_to_${REMOTE_VERSION}.tar.gz""
	BACKUP_FILE=".back/backup_$(date +%Y%m%d_%H%M%S)_${LOCAL_VERSION}_to_${REMOTE_VERSION}.tar.gz"
	log "正在创建备份的压缩文件: $BACKUP_FILE"
	if ! tar -czf "$BACKUP_FILE" -C "$HOME" .gancm; then

		echo -e "${ERROR}备份失败！"
	fi

	log 更新A分区
	echo -e "${INFO}更新A分区..."
	rm -rf $A_DIR/*
	cp -r $TEMP_DIR/* $A_DIR/

	log 清理临时目录
	rm -rf $TEMP_DIR
	if [ "${git}" = "http://gitee.com/" ]; then
		Modify_the_variable git "http:\/\/gitee.com\/" ${HOME}/.gancm/config/config.sh
		Modify_the_variable rawgit "https:\/\/raw.giteeusercontent.com\/MIt-gancm\/Autumn-leaves\/raw\/main\/" ${HOME}/.gancm/config/config.sh
	elif [ "${git}" = "http://github.com/" ]; then
		Modify_the_variable git "http:\/\/github.com\/" ${HOME}/.gancm/config/config.sh
		Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/MIt-gancm\/Autumn-leaves\/refs\/heads\/main\/" ${HOME}/.gancm/config/config.sh
	fi
	if [ "${qqBot}" != "" ]; then
		Modify_the_variable qqBot ${qqBot} ${HOME}/.gancm/config/config.sh
	fi
	
	echo "更新完成！当前版本: $REMOTE_VERSION"
	log 更新成功
else
	echo "本地版本是最新版本，无需更新。"
	log 已是最新版本
fi
