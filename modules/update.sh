#!/bin/bash
# modules/update.sh - 脚本自我更新模块

# 引入核心库
if [ -z "$GANCM_ROOT" ]; then export GANCM_ROOT="${HOME}/.gancm"; fi

# 尝试加载工具库
if [ -f "${GANCM_ROOT}/core/utils.sh" ]; then
    source "${GANCM_ROOT}/core/utils.sh"
else
    echo "错误: 无法加载核心库 ${GANCM_ROOT}/core/utils.sh"
    exit 1
fi

# 加载配置
load_config

# 定义关键路径
A_DIR="${GANCM_ROOT}"
TEMP_DIR="${HOME}/.TEMP_UPDATE_$(date +%s)"       # 下载更新的临时目录
PRESERVE_DIR="${HOME}/.TEMP_PRESERVE_$(date +%s)" # 暂存配置和日志的目录
LOCAL_VERSION_FILE="${GANCM_ROOT}/config/version"
BACKUP_DIR="${HOME}/.back"
BACKUP_FILE="" # 稍后生成

# 清理函数
cleanup() {
    rm -rf "$TEMP_DIR"
    rm -rf "$PRESERVE_DIR"
}
trap cleanup EXIT

# 检查必要依赖
for cmd in jq git tar; do
    if ! command -v $cmd &> /dev/null; then
        log_error "未找到 '$cmd' 命令，无法继续更新。请先安装它。"
        exit 1
    fi
done

# =========================================================
# 核心函数定义
# =========================================================

# 回滚函数：当更新失败时，还原备份
rollback() {
    log_error "更新过程中发生错误，正在执行回滚操作..."
    
    # 确保目录清空
    rm -rf "$A_DIR"
    mkdir -p "$A_DIR"

    if [ -f "$BACKUP_FILE" ]; then
        # 解压备份到 HOME (因为备份时包含了 .gancm 目录结构)
        tar -xzf "$BACKUP_FILE" -C "${HOME}"
        if [ $? -eq 0 ]; then
            log_warn "已成功回滚至更新前的版本。请检查网络或配置后重试。"
        else
            log_error "严重错误：回滚失败！备份文件位于: $BACKUP_FILE"
        fi
    else
        log_error "严重错误：找不到备份文件，无法回滚！"
    fi
    exit 1
}

# =========================================================
# 1. 版本检查
# =========================================================

# 获取本地版本
if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | jq -r .version 2>/dev/null)
    [ -z "$LOCAL_VERSION" ] && LOCAL_VERSION="0.0.0"
else
    LOCAL_VERSION="0.0.0"
    log_warn "本地版本文件不存在，默认为 0.0.0"
fi

# 获取远程版本配置
REMOTE_CONFIG_URL="${rawgit}config/version"
log_info "正在检查更新 (当前版本: $LOCAL_VERSION)..."

RESPONSE=$(curl --connect-timeout 10 -s "$REMOTE_CONFIG_URL")

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    log_warn "无法连接更新服务器，跳过更新检查。"
    exit 0
fi

# 解析 JSON
REMOTE_VERSION=$(echo "$RESPONSE" | jq -r .version)
GIT_CLONE_PATH=$(echo "$RESPONSE" | jq -r .git_clone)
DESCRIPTION=$(echo "$RESPONSE" | jq -r .description)

if [ "$REMOTE_VERSION" == "null" ] || [ -z "$GIT_CLONE_PATH" ]; then
    log_error "版本信息解析失败，服务器返回数据异常。"
    exit 1
fi

# =========================================================
# 2. 更新逻辑
# =========================================================

# 版本比较
LATEST_VER=$(printf '%s\n%s' "$REMOTE_VERSION" "$LOCAL_VERSION" | sort -V | tail -n1)

if [ "$LATEST_VER" != "$LOCAL_VERSION" ]; then
    echo -e "${INFO} 发现新版本: ${GREEN}$REMOTE_VERSION${RES}"
    echo -e "${INFO} 更新说明: $DESCRIPTION"

    log_info "准备开始全量更新流程..."

    # -----------------------------------------------------
    # 步骤 2.1: 下载新代码 (Git Clone)
    # -----------------------------------------------------
    GIT_FULL_URL="${git}${GIT_CLONE_PATH}"
    log_info "正在下载更新包..."
    
    if ! git clone --depth 1 "$GIT_FULL_URL" "$TEMP_DIR" &>/dev/null; then
        log_warn "下载失败，尝试增加缓存重试..."
        git config --global http.postBuffer 524288000
        if ! git clone --depth 1 "$GIT_FULL_URL" "$TEMP_DIR" &>/dev/null; then
            log_error "无法下载更新，流程终止。"
            exit 1
        fi
    fi

    # -----------------------------------------------------
    # 步骤 2.2: 创建备份 (Backup)
    # -----------------------------------------------------
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S)_v${LOCAL_VERSION}.tar.gz"
    
    log_info "正在备份当前版本至: $BACKUP_FILE"
    # 备份整个 .gancm 目录，但排除 download 目录以减小体积
    if ! tar -czf "$BACKUP_FILE" --exclude='download/*' -C "${HOME}" .gancm 2>/dev/null; then
        log_error "备份创建失败，为了安全起见，终止更新。"
        exit 1
    fi
    log_succ "备份完成"

    # -----------------------------------------------------
    # 步骤 2.3: 提取需要保留的文件 (Preserve)
    # -----------------------------------------------------
    log_info "正在暂存配置文件和日志..."
    mkdir -p "$PRESERVE_DIR"
    
    # 保留配置文件
    if [ -f "${A_DIR}/config/config.sh" ]; then
        cp "${A_DIR}/config/config.sh" "$PRESERVE_DIR/"
    fi
    
    # 保留日志目录
    if [ -d "${A_DIR}/logs" ]; then
        cp -r "${A_DIR}/logs" "$PRESERVE_DIR/"
    fi

    # -----------------------------------------------------
    # 步骤 2.4: 替换核心目录 (Delete & Replace)
    # -----------------------------------------------------
    # !!! 危险操作区域，出错需回滚 !!!
    
    log_info "正在应用更新..."
    
    # 1. 删除旧目录
    rm -rf "$A_DIR"
    
    # 2. 将临时下载的目录移动为正式目录
    # 注意：TEMP_DIR 中包含 .git 目录，如果不需要 git 信息，可以只移动内容
    # 这里直接移动整个目录
    mv "$TEMP_DIR" "$A_DIR"
    
    if [ ! -d "$A_DIR" ] || [ ! -f "${A_DIR}/gancm.sh" ]; then
        log_error "新文件部署失败，目录结构异常。"
        rollback
    fi

    # -----------------------------------------------------
    # 步骤 2.5: 还原保留文件 (Restore)
    # -----------------------------------------------------
    log_info "正在还原用户配置..."

    Modify_the_variable git "$git" "${A_DIR}/config/config.sh"
    Modify_the_variable rawgit "$rawgit" "${A_DIR}/config/config.sh"
    Modify_the_variable Fastest_download_source "$Fastest_download_source" "${A_DIR}/config/config.sh"
    Modify_the_variable last_time_aptup "$last_time_aptup" "${A_DIR}/config/config.sh"
    Modify_the_variable QQbot "$QQbot" "${A_DIR}/config/config.sh"
    Modify_the_variable auto_upgrade "$auto_upgrade" "${A_DIR}/config/config.sh"

    # 还原 Logs
    if [ -d "$PRESERVE_DIR/logs" ]; then
        mkdir -p "${A_DIR}/logs"
        cp -rf "$PRESERVE_DIR/logs/"* "${A_DIR}/logs/" 2>/dev/null
    fi

    # -----------------------------------------------------
    # 步骤 2.6: 后续处理 (Post-Update)
    # -----------------------------------------------------
    
    # 赋予执行权限
    chmod +x "${A_DIR}/gancm.sh"
    chmod +x "${A_DIR}/core/"*.sh 2>/dev/null
    chmod +x "${A_DIR}/modules/"*.sh 2>/dev/null

    log_succ "更新成功！"
    log_info "当前版本已更新为: $REMOTE_VERSION"
    echo -e "${INFO} 建议重启脚本以加载最新功能。"
    
    # 退出当前脚本，防止后续代码在旧内存环境中运行
    exit 0

else
    log_info "当前已是最新版本 ($LOCAL_VERSION)，无需更新。"
fi
