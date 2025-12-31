#!/bin/bash
# modules/update.sh - 脚本自我更新模块

# 引入核心库
if [ -z "$GANCM_ROOT" ]; then export GANCM_ROOT="${HOME}/.gancm"; fi

# 尝试加载工具库，如果加载失败则无法记录日志，需报错退出
if [ -f "${GANCM_ROOT}/core/utils.sh" ]; then
    source "${GANCM_ROOT}/core/utils.sh"
else
    echo "错误: 无法加载核心库 ${GANCM_ROOT}/core/utils.sh"
    exit 1
fi

# 加载配置
load_config

# 定义变量
A_DIR="${GANCM_ROOT}"
TEMP_DIR="${HOME}/.TEMP_UPDATE_$(date +%s)" # 使用时间戳防止目录冲突
LOCAL_VERSION_FILE="${GANCM_ROOT}/config/version"
BACKUP_DIR="${HOME}/.back"

# 注册退出时的清理工作 (无论成功失败都会执行)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 检查必要依赖
if ! command -v jq &> /dev/null; then
    log_error "未找到 'jq' 命令，无法解析版本信息。请先安装 jq。"
    exit 1
fi

if ! command -v git &> /dev/null; then
    log_error "未找到 'git' 命令，无法拉取更新。请先安装 git。"
    exit 1
fi

# =========================================================
# 2. 版本检查
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
log_info "请求地址: $REMOTE_CONFIG_URL"

RESPONSE=$(curl --connect-timeout 10 -s "$REMOTE_CONFIG_URL")

# 检查 curl 返回值及内容有效性
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
    log_error "返回内容: $RESPONSE"
    exit 1
fi

# =========================================================
# 3. 更新逻辑
# =========================================================

# 版本比较逻辑 (使用 sort -V 进行版本号排序)
LATEST_VER=$(printf '%s\n%s' "$REMOTE_VERSION" "$LOCAL_VERSION" | sort -V | tail -n1)
    
if [ "$LATEST_VER" != "$LOCAL_VERSION" ]; then
    echo -e "${INFO} 发现新版本: ${GREEN}$REMOTE_VERSION${RES}"
    echo -e "${INFO} 更新说明: $DESCRIPTION"
    log_info "开始执行更新流程: $LOCAL_VERSION -> $REMOTE_VERSION"
    
    # 3.1 下载代码
    GIT_FULL_URL="${git}${GIT_CLONE_PATH}"
    log_info "正在从 $GIT_FULL_URL 拉取代码..."
    
    # 尝试第一次克隆
    if git clone --depth 1 "$GIT_FULL_URL" "$TEMP_DIR" &>/dev/null; then
        log_succ "更新包下载成功"
    else
        log_warn "下载失败，尝试调整 Git 缓存重试..."
        git config --global http.postBuffer 524288000
        if git clone --depth 1 "$GIT_FULL_URL" "$TEMP_DIR" &>/dev/null; then
            log_succ "重试下载成功"
        else
            log_error "更新失败: 无法克隆 Git 仓库，请检查网络连通性。"
            exit 1
        fi
    fi

    # 3.2 执行备份
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S)_v${LOCAL_VERSION}.tar.gz"
    
    log_info "正在备份当前版本至: $BACKUP_FILE"
    # 排除 logs
    if tar -czf "$BACKUP_FILE" -C "${HOME}" .gancm --exclude='logs/*.log' 2>/dev/null; then
        log_succ "备份完成"
    else
        log_error "备份失败，终止更新以保护数据。"
        exit 1
    fi

    # 3.3 覆盖文件
    log_info "正在安装新文件..."
    
    # 复制文件
    cp -rf "${TEMP_DIR}/"* "${A_DIR}/"

    if [ $? -eq 0 ]; then
        log_succ "文件覆盖完成"
    else
        log_error "文件覆盖失败，请手动检查 ${A_DIR} 目录权限"
        exit 1
    fi

    # 3.4 权限修正
    chmod +x "${GANCM_ROOT}/gancm.sh"
    
    # 3.5 配置恢复/迁移
    # 如果更新包覆盖了 config.sh，这里尝试恢复关键变量 qqBot
    CONFIG_FILE="${GANCM_ROOT}/config/config.sh"
    if [ -n "$qqBot" ] && [ -f "$CONFIG_FILE" ]; then
        log_info "正在恢复用户配置 (qqBot)..."
        # 假设 Modify_the_variable 是 utils.sh 中的函数
        Modify_the_variable "git" "$git" "$CONFIG_FILE"
        Modify_the_variable "rawgit" "$rawgit" "$CONFIG_FILE"
        Modify_the_variable "Fastest_download_source" "$Fastest_download_source" "$CONFIG_FILE"
        Modify_the_variable "qqBot" "$qqBot" "$CONFIG_FILE"
        Modify_the_variable "last_time_aptup" "$last_time_aptup" "$CONFIG_FILE"
        Modify_the_variable "auto_upgrade" "$auto_upgrade" "$CONFIG_FILE"
    fi

    log_succ "更新流程结束！当前版本: $REMOTE_VERSION"
    
    # 可选：提示用户重启
    echo -e "${INFO} 请重新运行脚本以应用更改。"
    
else
    log_info "远程版本: $REMOTE_VERSION"
    log_info "更新说明: $DESCRIPTION"
    log_info "检查完毕，当前已是最新版本 ($LOCAL_VERSION)。"
fi
