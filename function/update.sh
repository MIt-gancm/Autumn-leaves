# 设置变量
A_DIR="${HOME}/.gancm"                   # A分区路径
B_DIR="${HOME}/.back"                   # B分区路径
TEMP_DIR="${HOME}/.TEMP"        # 临时目录
REMOTE_URL="${rawgit}config/version"
LOCAL_VERSION_FILE="${HOME}/.gancm/config/version"

# 获取本地版本
if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | jq -r .version)
else
    echo "本地版本文件不存在，无法进行版本比较！"
    exit 1
fi

# 获取最新的云端版本信息
echo "正在获取最新版本信息..."
RESPONSE=$(curl -s $REMOTE_URL)
log "更新源信息:$RESPONSE"

# 检查curl命令是否成功
if [ $? -ne 0 ]; then
    echo "无法获取版本信息，请检查网络连接！"
    exit 1
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

    # 进行git克隆
    echo "正在下载更新..."
    git clone ${git}$GIT_CLONE $TEMP_DIR

    # 检查克隆是否成功
    if [ $? -ne 0 ]; then
        echo "更新失败，无法克隆仓库！"
        exit 1
    fi

    # 备份当前A分区
    echo "备份当前A分区..."
    cp -r $A_DIR/* $B_DIR/

    # 更新A分区
    echo "更新A分区..."
    rm -rf $A_DIR/*
    cp -r $TEMP_DIR/* $A_DIR/

    # 清理临时目录
    rm -rf $TEMP_DIR
    if [ "${git}" = "http://gitee.com/" ]; then
        Modify_the_variable git "http:\/\/gitee.com\/" ${HOME}/.gancm/config/config.sh
	    Modify_the_variable rawgit "https:\/\/raw.giteeusercontent.com\/MIt-gancm\/Autumn-leaves\/raw/main\/" ${HOME}/.gancm/config/config.sh

    elif [ "${git}" = "http://github.com/" ]; then
        Modify_the_variable git "http:\/\/github.com\/" ${HOME}/.gancm/config/config.sh
		Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/MIt-gancm\/Autumn-leaves\/refs\/heads\/main\/" ${HOME}/.gancm/config/config.sh
    fi
    
    echo "更新完成！当前版本: $REMOTE_VERSION"
    log 更新成功
else
    echo "本地版本是最新版本，无需更新。"
    log 已是最新版本
fi