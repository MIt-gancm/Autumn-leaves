mkdir -p "${HOME}/.termux/gancm/MCserver"
download_JAVA() {
	echo "请选择要安装的java版本（支持多选，用空格分隔）:"
if [ ! "${package_manager}" = "apt" ]; then
    log_error "仅适用于apt安装器 当前安装器：${package_manager}"
    exit 1 
fi
	options=("quit" $(${package_manager} list openjdk-*-jdk 2>/dev/null | awk -F'/' '{print $1}' | grep '^openjdk'))
	for i in ${!options[@]}; do
		echo "$i. ${options[$i]}"
	done
	# 读取用户输入
	read -e -p "请输入您的选择：" user_input
	# 初始化选中的选项数组
	selected=()
	# 处理用户输入的选项
	for opt in $user_input; do
		if [[ " ${options[@]} " =~ " ${options[$opt]} " ]]; then
			selected+=(" ${options[$opt]}")
		else
			echo "无效的选项：$opt"
		fi
	done
	# 输出用户选择的选项
	if [ "${opt}" = "0" ]; then
		exit
	fi
	echo "您选择了：${selected[*]}"
	$package_manager install ${selected[*]} -y
	log_info "选择的Java:${selected[*]}"
}
# 定义新的 API 基础地址
API_BASE="https://mcserverapi.gancmcs.top/api"

# ==========================================
# 函数 1: 服务端核心选择菜单
# 作用: 获取列表，过滤不需要的核心，让用户选择，然后传递给安装函数
# ==========================================
install_MC_SERVER_MENU() {
    log_info "正在获取服务端核心列表..."
    
    # 1. 获取核心列表 JSON
    # 2. 使用 jq 过滤:
    #    - .data[]: 遍历数据数组
    #    - select(...): 排除名称是 Velocity 或 Waterfall 的项目
    #    - "\(.id) \(.name)": 输出格式为 "id name" (例如: paper Paper)
    # 3. 存入数组 lines 中
    mapfile -t core_list < <(curl -s "${API_BASE}/projects" | jq -r '.data[] | select(.name != "Velocity" and .name != "Waterfall") | "\(.id) \(.name)"')

    # 如果获取失败（数组为空），提示并退出
    if [ ${#core_list[@]} -eq 0 ]; then
        log_error "无法获取核心列表或列表为空，请检查网络。"
        return 1
    fi

    # 准备 whiptail 菜单所需的列表格式
    # 我们需要构建一个类似 "1 Paper 2 Fabric ..." 的字符串供菜单使用
    menu_items=()
    core_ids=()   # 另外存一个 ID 数组，方便后续根据索引取 ID
    core_names=() # 存 Name 数组，方便显示和日志

    index=1
    for line in "${core_list[@]}"; do
        # 读取每一行 "id name"，分割成变量
        read -r core_id core_name <<< "$line"
        
        # 存入菜单列表: 序号 + 显示名称
        menu_items+=("$index" "$core_name")
        
        # 存入映射数组 (索引减1对应)
        core_ids+=("$core_id")
        core_names+=("$core_name")
        
        ((index++))
    done

    # 显示菜单 (使用 whiptail)
    # 25 80 15 分别是 高度 宽度 列表高度
    user_choice=$(whiptail --title "选择服务端核心" --menu "请选择你要安装的核心类型:" 25 80 15 "${menu_items[@]}" 3>&1 1>&2 2>&3)

    # 处理用户取消 (Exit code 非 0)
    if [ $? -ne 0 ]; then
        echo "用户取消操作"
        return 0
    fi

    # 根据用户的选择 (序号) 获取对应的 ID 和 Name
    # 数组索引从 0 开始，所以 user_choice - 1
    selected_id="${core_ids[$((user_choice-1))]}"
    selected_name="${core_names[$((user_choice-1))]}"

    log_info "用户选择了: $selected_name (ID: $selected_id)"

    # 调用安装函数，传入 ID 和 Name
    install_MC_SERVER "$selected_id" "$selected_name"
}

# ==========================================
# 函数 2: 服务端版本选择与下载
# 参数 1: core_id (例如 paper)
# 参数 2: core_name (例如 Paper)
# ==========================================
install_MC_SERVER() {
    local core_id=$1
    local core_name=$2

    # --- 第一步：获取版本列表 ---
    log_info "正在获取 $core_name 的版本列表..."
    
    # 请求 /versions/:project 接口
    # API 返回的是 ["1.20.4", "1.20.2"...] 这样的纯数组
    # 我们直接通过 jq 转为行数据
    version_data=$(curl -s "${API_BASE}/versions/${core_id}")
    
    # 检查 API 是否成功 (判断 json 是否包含 success: true 稍微麻烦，这里直接判断是否有数据)
    if [ -z "$version_data" ]; then
        log_error "获取版本失败。"
        return 1
    fi

    # 提取版本号数组
    mapfile -t versions < <(echo "$version_data" | jq -r '.data[]')

    # 制作版本选择菜单
    version_menu_items=()
    v_index=1
    for v in "${versions[@]}"; do
        version_menu_items+=("$v_index" "$v")
        ((v_index++))
    done

    # 弹出版本选择框
    user_choice_ver=$(whiptail --title "选择版本" --menu "请选择 $core_name 的游戏版本:" 25 80 15 "${version_menu_items[@]}" 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        return 0
    fi

    # 获取选中的版本号 string
    selected_version="${versions[$((user_choice_ver-1))]}"
    log_info "选择的版本: $selected_version"


    # --- 第二步：获取下载链接 ---
    log_info "正在请求下载地址..."
    
    # 请求 /dl/:project/:version/latest 接口
    # 获取最新的构建版本
    dl_info_json=$(curl -s "${API_BASE}/dl/${core_id}/${selected_version}/latest")
    
    # 解析下载链接和文件名
    download_url=$(echo "$dl_info_json" | jq -r '.data.download_url')
    file_name=$(echo "$dl_info_json" | jq -r '.data.file_name')
    
    # 简单的空值检查
    if [ "$download_url" == "null" ] || [ -z "$download_url" ]; then
        log_error "获取下载链接失败，该版本可能不存在或 API 报错。"
        return 1
    fi

    log_info "获取成功，文件名: $file_name"
    log_info "下载源: $download_url"


    # --- 第三步：准备目录与下载 ---
    # 定义安装路径: ~/.termux/gancm/MCserver/核心名/版本号
    # 注意：这里使用 core_name (Paper) 还是 core_id (paper) 取决于你的个人习惯，
    # 原脚本使用的是菜单显示的名字，为了兼容性，这里建议保持一致性，或者统一下转小写。
    # 这里我们使用传入的 Core Name (如 Paper) 以保持目录美观。
    
    INSTALL_DIR="${HOME}/.termux/gancm/MCserver/${core_name}/${selected_version}"
    
    # 确保目录存在
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    # 定义最终文件路径
    # 注意：原脚本重命名为 核心_版本_server.jar，如果你想保持这个习惯：
    SAVE_FILE="${INSTALL_DIR}/${core_name}_${selected_version}_server.jar"
    
    # 如果你想保留官方原名(比如 paper-1.20.4-496.jar)，就用下面的:
    # SAVE_FILE="${INSTALL_DIR}/${file_name}"

    log_info "开始下载到: $SAVE_FILE"
    
    # 使用 wget 下载
    if wget -q --show-progress "$download_url" -O "$SAVE_FILE"; then
        log_succ "下载完成！"
        
        # --- 第四步：启动 ---
        # 调用原来的启动脚本
        # 参数 1: 核心名 (用于识别目录)
        # 参数 2: 版本号
        source "${HOME}/.gancm/lib/Start_Java_MC_SERVER.sh" "$core_name" "$selected_version"
    else
        log_error "下载失败！"
        # 下载失败删除空目录和残留文件
        rm -f "$SAVE_FILE"
        rmdir --ignore-fail-on-non-empty -p "$INSTALL_DIR" 2>/dev/null
    fi
}
start_MC_SERVER() {
	log_info "准备启动mcserver"
	if [ ! -f "$(command -v java)" ]; then
		echo -e "${RED}目前并没有任何安装 java ${RES}"
		echo -e "没有安装java"
		download_JAVA
	fi

	list_dir ${HOME}/.termux/gancm/MCserver/
	case $user_choice in
	0|"")
		echo -e "${RED}返回上级${RES}"
		return
		;;
	*)
		start_MC_SERVER_class=${menu_items[$((user_choice - 1))]}
		log_info "选择核心类型:${start_MC_SERVER_class}"
		;;
	esac

	list_dir ${HOME}/.termux/gancm/MCserver/${start_MC_SERVER_class}
	case $user_choice in
	0|"")
		echo -e "${RED}返回上级${RES}"
		return
		;;
	*)
		if [ ! -f ${HOME}/.termux/gancm/MCserver/${start_MC_SERVER_class}/${menu_items[$((user_choice - 1))]}/start.sh ]; then
			log_error "未寻找到启动脚本启动配置程序"
			source ${HOME}/.gancm/lib/Start_Java_MC_SERVER.sh ${start_MC_SERVER_class} ${menu_items[$((user_choice - 1))]}
		fi
		log_info "启动mcserver"
		bash ${HOME}/.termux/gancm/MCserver/${start_MC_SERVER_class}/${menu_items[$((user_choice - 1))]}/start.sh
		;;
	esac
}
rm_MC_SERVER() {
	log_info "准备删除mcserver"
	list_dir ${HOME}/.termux/gancm/MCserver/
	case $user_choice in
	0|"")
		echo -e "${RED}返回上级${RES}"
		return
		;;
	*)
		rm_MC_SERVER_class=${menu_items[$((user_choice - 1))]}
		;;
	esac
	list_dir ${HOME}/.termux/gancm/MCserver/${rm_MC_SERVER_class}
	case $user_choice in
	0|"")
		echo -e "${RED}返回上级${RES}"
		return
		;;
	*)
		num1=$((RANDOM % 100))
		num2=$((RANDOM % 100))
		read -e -p "${num1}+${num2}=?" user_sum
		correct_sum=$(($num1 + $num2))
		if [ $user_sum -eq $correct_sum ]; then
			echo -e "删除开始正确！你输入的和是正确的。"
			rm -rfv "${HOME}/.termux/gancm/MCserver/${rm_MC_SERVER_class}/${menu_items[$((user_choice - 1))]}"
			log_succ "删除完成"
		else
			echo -e "错误！你输入的和不正确。删除程序将不执行。"
			log_info "取消失败"
		fi
		;;
	esac

}
Import_zip_MC_SERVER() {
	log_info "准备导入zip格式的mcserver"
	self_install zip 
	self_install unzip
	if [ ! -d ${HOME}/.termux/gancm/MCserver/导入的MCserver/ ]; then
		mkdir -p ${HOME}/.termux/gancm/MCserver/导入的MCserver/
	fi
	log_info "请选择要导入的zip文件"
	zip_file=$(whiptail --title "选择zip文件以当前系统目录为准" --inputbox "请输入zip文件路径解压后直接为服务器根目录的zip" 10 60 3>&1 1>&2 2>&3)
	log_info "选择的zip文件:${zip_file}"		
	nowtime=$(date +%y-%m-%d-%H:%M:%S)
	if [ ! -d ${HOME}/.termux/gancm/MCserver/导入的MCserver/${nowtime}解压后目录/ ]; then
		mkdir -p ${HOME}/.termux/gancm/MCserver/导入的MCserver/${nowtime}解压后目录/
	fi
	unzip "${zip_file}" -d "${HOME}/.termux/gancm/MCserver/导入的MCserver/${nowtime}解压后目录/"
	if [ ! $? = 0 ]; then
	log_error "导入失败"
		exit
	fi
	log_succ "导入完成"
} 
Export_zip_MC_SERVER() {
	mkdir -p ${HOME}/.termux/gancm/back
	log_info "准备导出zip格式的mcserver"
	if [ ! -f "$(command -v zip)" ]; then
		echo -e "${RED}目前并没有任何安装 zip ${RES}"
		echo -e "没有安装zip"
		self_install zip
	fi
	list_dir ${HOME}/.termux/gancm/MCserver/
	case $user_choice in
	0|"")
		echo -e "${RED}返回上级${RES}"
		return
		;;
	*)
		export_MC_SERVER_class=${menu_items[$((user_choice - 1))]}
		log_info "选择核心类型:${export_MC_SERVER_class}"
		;;
	esac

	list_dir ${HOME}/.termux/gancm/MCserver/${export_MC_SERVER_class}
	case $user_choice in
	0|"")
		echo -e "${RED}返回上级${RES}"
		return
		;;
	*)
		export_MC_SERVER_class_bb=${menu_items[$((user_choice - 1))]}
		log_info "选择服务器版本类型:${export_MC_SERVER_class_bb}"
		;;
	esac

	log_info "请输入导出zip文件名"
	read -e -p "请输入导出zip文件名:" export_zip_name
	if [ -z "${export_zip_name}" ]; then
		export_zip_name="${export_MC_SERVER_class_bb}_$(date +%Y%m%d_%H%M%S).zip"
	fi

	if [ ! -d ${HOME}/.termux/gancm/MCserver/${export_MC_SERVER_class}/${export_MC_SERVER_class_bb} ]; then
		log_error "未找到服务器:${export_MC_SERVER_class_bb}"
		exit
	fi

	cd ${HOME}/.termux/gancm/MCserver/${export_MC_SERVER_class}/${export_MC_SERVER_class_bb}
	if zip -r "${HOME}/.termux/gancm/back/${export_zip_name}" .; then
		log_succ "导出完成:${HOME}/.termux/gancm/back/${export_zip_name}"
	else
		log_error "导出失败"
	fi

}
startMCSManager() {
	log_info "启动mcsmanager"
	if [ -d /opt/mcsmanager/ ]; then
		log_info "mcsmanager已安装"
		# mcsmanager
		if [ "${system_os_type}" = proot ]; then
			log_info "系统为proot容器"
			rm -rf /run/screen/S-root
			start_mcsmanager
		else
			log_info "系统为非proot容器"
			systemctl start mcsm-daemon.service
			systemctl start mcsm-web.service
		fi
	else
		log_info "mcsmanager未安装"
		log_info "安装mcsmanager"
		installMCSManager
	fi
}
stopMCSManager() {
	log_info "启动mcsmanager"
	if [ -d /opt/mcsmanager/ ]; then
		log_info "mcsmanager已安装"
		# mcsmanager
		if [ "${system_os_type}" = proot ]; then
			log_info "系统为proot容器"
			rm -rf /run/screen/S-root
			stop_mcsmanager
		else
			log_info "系统为非proot容器"
			systemctl stop mcsm-web.service
			systemctl stop mcsm-daemon.service
		fi
	else
		log_info "mcsmanager未安装"
		echo -e "${WARNING}没安装点到天荒地老也没用${RES}"
	fi
}
installMCSManager() {
		if [ "${system_os_type}" = proot ]; then
			log_info "系统为proot容器"
			if bash <(curl -sL https://gitee.com/moze_sz/MCSMFP/raw/master/setup_cn.sh); then
				log_succ "安装成功"
			else
				log_error "安装失败"
			fi
		else
			log_info "系统为非proot容器"
			if wget -qO- https://script.mcsmanager.com/setup_cn.sh | bash; then
				log_succ "安装成功"
			else
				log_error "安装失败"
			fi
		fi
}
# curl -s https://download.fastmirror.net/api/v3 | jq -r '.data[].tag' | grep -n "pure" | cut -d: -f1
# 纯净服务端
# curl -s https://download.fastmirror.net/api/v3 | jq -r '.data[].tag' | grep -n "mod" | cut -d: -f1
# mod服务端
# curl -s https://download.fastmirror.net/api/v3 | jq -r '.data[].tag' | grep -n "bedrock" | cut -d: -f1
# pe服务端
# curl -s https://download.fastmirror.net/api/v3 | jq -r '.data[].tag' | grep -n "vanilla" | cut -d: -f1
# 原版服务端
# pure_tag=(echo "${}" | jq '.data[].tag' | grep -n "pure" | cut -d: -f1))
# 行数
# curl -s https://download.fastmirror.net/api/v3 | jq .data.[$((${pure_tag[1]}-1))].name
# 行数对应名字
# for i in ${tag[@]} ; do
# 	curl -s https://download.fastmirror.net/api/v3 | jq .data.[$((${i}-1))].name
# done
