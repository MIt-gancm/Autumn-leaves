installNapCatQQ() {
	if [ ${system_os_type} = proot ]; then
		log_info "系统为proot容器"
		log_info "安装NapCatQQ"
		if [ "${system_os_type2}" = Bookworm_Debian_12 ]; then
			log_info "容器为Bookworm_Debian_12下载并安装官方脚本"
			curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh && sudo bash napcat.sh
		else
			echo -e "${WORRY}容器状态该功能只支持Bookworm_Debian_12"
			log_info "容器非目前该功能只支持Debian 12"
		fi
	else
		log_info "系统为非proot容器"
		curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh && sudo bash napcat.sh
	fi
}
startNapCatQQ() {
	if [ ${system_os_type} = proot ]; then
		log_info "系统为proot容器"
		log_info "启动NapCatQQ"
		if [ "${system_os_type2}" == Bookworm_Debian_12 ]; then
			log_info "启动NapCatQQ"
			if [ ${QQbot} = "" ]; then
				read -e -p "请输入您的选择：" QQbot
				log_error "QQbot为空"
				Modify_the_variable QQbot ${QQbot} ${HOME}/.gancm/config/config.sh
			fi
			case ${1} in
			--Background | -B)
				log_info "后台启动NapCatQQ"
				screen -dmS napcat bash -c \"xvfb-run -a qq --no-sandbox -q ${QQbot}
				;;
			*)
				log_info "启动NapCatQQ"
				xvfb-run -a qq --no-sandbox -q ${QQbot}
				;;
			esac

		else
			echo -e "${WORRY}容器状态该功能只支持Bookworm_Debian_12"
			log_error "容器非目前该功能只支持Debian 12"
		fi
	else
		log_info "系统为非proot容器"
		curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh && sudo bash napcat.sh
	fi
}
