#!/bin/bash

# 定义全局根目录变量
export GANCM_ROOT="${HOME}/.gancm"


#debug开启状态
export DEBUG_MODE=false

# 加载核心库
if [ -f "${GANCM_ROOT}/core/utils.sh" ]; then
    source "${GANCM_ROOT}/core/utils.sh"
else
    echo "错误: 核心库文件丢失 (${GANCM_ROOT}/core/utils.sh)"
    exit 1
fi

if [ -f "${GANCM_ROOT}/core/env.sh" ]; then
    source "${GANCM_ROOT}/core/env.sh"
else
    log_error "环境库文件丢失"
    exit 1
fi

# 解析命令行参数以启用调试模式
for arg in "$@"; do
    if [[ "$arg" == "--debug" || "$arg" == "-D" ]]; then
        DEBUG_MODE=true
        break
    fi
done

# 初始化检查 (文件夹、默认配置)
validity_check

# 加载用户配置
load_config

# 自动更新检查 (调用 env.sh 中的函数)
check_auto_update

# 主参数处理
case ${1} in
-h | --help)
    show_help
    ;;
-s | --start)
    case $2 in
    Android | A)
        log_info "指定加载安卓功能"
        source "${GANCM_ROOT}/modules/android_menu.sh" $3 $4 $5
        ;;
    Linux | L)
        log_info "指定加载Linux功能"
        source "${GANCM_ROOT}/modules/linux_menu.sh" $3 $4 $5
        ;;
    esac
    ;;
*)
    log_info "初始化完成"
    # 根据系统类型加载菜单
    SYSTEM_TYPE=$(get_system_type)
    
    if [ "$SYSTEM_TYPE" == "Android" ]; then
        log_info "加载安卓功能"
        # 检查并安装必要依赖
        check_dependencies "jq" "git" "wget" "whiptail" "tmux" "bc"
        # 检查脚本更新
        bash "${GANCM_ROOT}/modules/update.sh"
        source "${GANCM_ROOT}/modules/android_menu.sh" $1 $2 $3 $4 $5
    else
        log_info "加载Linux功能"
        check_dependencies "jq" "git" "wget" "whiptail" "tmux" "bc"
        bash "${GANCM_ROOT}/modules/update.sh"
        source "${GANCM_ROOT}/modules/linux_menu.sh" $1 $2 $3 $4 $5
    fi
    ;;
esac
