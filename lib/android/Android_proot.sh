self_install proot 
mkdir -p ${HOME}/.termux/共享文件夹
open_os_list() {
	# 这段代码多亏了ai我才看懂((((((

    # 1. 获取传入的发行版名称 (例如 ubuntu, debian, kali)
    local target_distro="$1"
    
    # 检查是否传入了参数
    if [ -z "${target_distro}" ]; then
        whiptail --title "错误" --msgbox "未指定发行版名称！" 10 60
        return 1

    fi

    # 2. 从网络获取该发行版的所有版本列表 (Releases)
    # URL 结构假设为: ${Proot_os_download_source}/${target_distro}/
    # grep 提取链接文本，sed 去除末尾斜杠，grep -v 过滤掉 "Parent Directory" 或非版本号的干扰项
    local release_list
    release_list=$(curl -s "${Proot_os_download_source}/${target_distro}/" | \
                   grep -oP '<a href="[^"]*">\K[^/<]*' | \
                   sed 's|/$||' | \
                   grep -vE "^(\.|default|images|alt|cloud|daily)" | sort -r)

    # 如果获取失败或列表为空
    if [ -z "${release_list}" ]; then
        whiptail --title "错误" --msgbox "无法获取 ${target_distro} 的版本列表，请检查网络或源地址。" 10 60
        return 1
    fi

    # 3. 构建 Whiptail 菜单数组
    # 格式: ID "版本名称" ID "版本名称" ...
    local menu_ops=()
    local i=1
    local releases_array=() # 用于后续通过 ID 映射回名称

    # 这里使用 while read 循环处理换行符分隔的列表
    while IFS= read -r release; do
        menu_ops+=("$i" "${release}")
        releases_array[i]="${release}" # 存储映射关系: 1=bookworm
        ((i++))
    done <<< "$release_list"
    
    # 添加退出选项
    menu_ops+=("0" "退出")

    # 4. 显示菜单并获取用户选择
    local choice
    choice=$(whiptail --title "选择版本" --menu "请选择 ${target_distro} 的版本" 20 60 10 \
        "${menu_ops[@]}" 3>&1 1>&2 2>&3)

    # 处理退出逻辑
    if [ "$choice" == "0" ] || [ -z "$choice" ]; then
        return 1
    fi

    # 5. 获取选中的版本名称
    local selected_release="${releases_array[$choice]}"
    
    # 设置 os_name (例如: bookworm_debian)
    os_name="${selected_release}_${target_distro}"

    # 6. 获取具体的 Build ID (时间戳目录)
    # 逻辑沿用原代码：进入 default 目录，取第二个链接 (通常第一个是 ../，第二个是最新版本)
    # URL 结构: .../distro/release/arch/default/
    local base_path="${Proot_os_download_source}/${target_distro}/${selected_release}/${archurl}/default"
    
    local download_proot_name
    download_proot_name=$(curl -s "${base_path}/" | \
                          grep -oP '<a href="[^"]*">\K[^<]*' | \
                          sed -n '2s|/$||p')

    # 检查是否成功获取到具体版本目录
    if [ -z "${download_proot_name}" ]; then
        whiptail --title "错误" --msgbox "无法解析 ${selected_release} 的具体下载路径 (arch: ${archurl})。" 10 60
        return 1
    fi

    # 7. 最终生成下载链接
    Download_proot_url="${base_path}/${download_proot_name}/rootfs.tar.xz"
    
}

install_proot() {
	case "$(uname -m)" in
	aarch64)
		archurl="arm64"
		;;
	armv7l)
		archurl="armhf"
		;;
	x86_64)
		archurl="amd64"
		;;
	*)
		echo -e "${ERROR}未知框架"
		exit
		;;
	esac
	mkdir -p "${HOME}/.termux/gancm/proot"
	Proot_os_download_source="https://sgp1lxdmirror01.do.letsbuildthe.cloud/images"
	open_proot_os_list=$(
		whiptail --title "选择功能" --menu "proot容器按自己需求来" 15 60 7 \
			"1" "ubuntu" \
			"2" "rockylinux" \
			"3" "centos" \
			"0" "退出" 3>&1 1>&2 2>&3
	)
	case ${open_proot_os_list} in
	1)
		open_os_list ubuntu
		log_info "安装ubuntu系列"
		;;
	2)
		open_os_list rockylinux
		log_info "安装rockylinux系列"
		;;
	3)
		open_os_list centos
		log_info "安装centos系列"
		;;
	*)
		log_info "未选择退出"
		exit 1
		;;
	esac
	log_info "os_name: ${os_name}"
	log_info "Download_proot_NAME: ${Download_proot_NAME}"
	log_info "Download_proot_url: ${Download_proot_url}"

	wget_proot_url(){
		while [ $counter -lt $Maximum_number_of_attempts ]; do
			log_info "最大循环Maximum_number_of_attempts: $Maximum_number_of_attempts"
			log_info "当前循环counter= $counter"
			if wget -q --show-progress "${Download_proot_url}" -O "$download_file"; then
				echo -e "${INFO}文件存储在${RED}$download_file${RES}"
				log_info "下载成功：$download_file"
				break
			else
				echo -e "${WORRY}请检查网络访问问题${RES}"
				log_error "下载失败：$download_file"
				if [ $counter -eq 0 ]; then
					Download_proot_url="https://dl.gancmcs.top/${Download_proot_url}"
					log_info "尝试使用备用 URL 下载，更新 Download_proot_url 为 \"$Download_proot_url\""
				fi
				if [ $counter -eq $((Maximum_number_of_attempts - 1)) ]; then
					echo -e "${ERROR}多次下载失败，退出程序"
					exit 1
				fi
			fi

			((counter++))
		done
	}

	download_file="${HOME}/.gancm/download/${os_name}.tar.xz"
	# 检查文件是否存在并且文件大小是否小于40MB
	if [ -f "$download_file" ] && [ $(du -b "$download_file" | cut -f1) -lt 41943040 ]; then
		echo -e "${WORRY}${RED}${download_file}${RES}可能已经损坏"
		log_info "\"${HOME}/.gancm/download/${os_name}.tar.xz\"文件损坏，重新下载"
		log_info "下载url:\"${Download_proot_url}\" 保存到 \"$download_file\""
		counter=0
		Maximum_number_of_attempts=2  # 定义最大重试次数
		wget_proot_url
	elif [ -f "$download_file" ]; then
		log_info "\"${HOME}/.gancm/download/${os_name}.tar.xz\"存在且大于40MBB"
	else
		log_info "\"${HOME}/.gancm/download/${os_name}.tar.xz\"不存在"
		log_info "下载url:\"${Download_proot_url}\" 保存到 \"$download_file\""
		counter=0
		Maximum_number_of_attempts=2  # 
		wget_proot_url
	fi

	# 提示清理空间
	echo -e "${INFO}您可以使用${RED}rm -rfv $download_file${RES}来节省存储空间"

	unset LD_PRELOAD
	mkdir -p ${HOME}/.termux/gancm/proot/${os_name}
	log_info "解压\"${HOME}/.gancm/download/${os_name}.tar.xz\""
	proot --link2symlink tar --overwrite -xJf ${HOME}/.gancm/download/${os_name}.tar.xz -C ${HOME}/.termux/gancm/proot/${os_name}/ --exclude='dev' || :
	chmod 777 "${HOME}/.termux/gancm/proot/${os_name}/root/"
	chmod 777 "${HOME}/.termux/gancm/proot/${os_name}/proc/"
	echo -e "${GREEN}复制脚本到容器${RES}"
	log_info "复制脚本到容器"
	mkdir -p ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm
	mkdir -p ${HOME}/.termux/gancm/.重要文件夹/sys/.empty
	mkdir -p ${HOME}/.termux/gancm/.重要文件夹/dev/shm

	echo -e "${GREEN}复制gancm脚本到容器${RES}"
	cp -r ${HOME}/.gancm/config ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm
	cp -r ${HOME}/.gancm/core ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm
	cp -r ${HOME}/.gancm/lib ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm
	cp -r ${HOME}/.gancm/modules ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm
	cp ${HOME}/.gancm/gancm.sh ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm
	cp ${HOME}/.gancm/README.md ${HOME}/.termux/gancm/proot/${os_name}/root/.gancm

	echo -e "${GREEN}复制优化脚本到容器${RES}"
	cp ${HOME}/.gancm/lib/proot_proc/.* ${HOME}/.termux/gancm/proot/${os_name}/proc/
	cp ${HOME}/.gancm/lib/proot_optimization.sh ${HOME}/.termux/gancm/proot/${os_name}/root/优化.sh
	proot \
		--link2symlink -0 \
		--rootfs=${HOME}/.termux/gancm/proot/${os_name}/ \
		--bind=/dev \
		--bind=/sys \
		--bind=/proc \
		--bind="${HOME}/.termux/gancm/proot/${os_name}/proc/.loadavg:/proc/loadavg" \
		--bind="${HOME}/.termux/gancm/proot/${os_name}/proc/.version:/proc/version" \
		--bind="${HOME}/.termux/gancm/proot/${os_name}/proc/.uptime:/proc/uptime" \
		--bind="${HOME}/.termux/gancm/proot/${os_name}/proc/.stat:/proc/stat" \
		--bind="${HOME}/.termux/gancm/proot/${os_name}/proc/.vmstat:/proc/vmstat" \
		--bind="${HOME}/.termux/gancm/proot/${os_name}/proc/.sysctl_entry_cap_last_cap:/proc/sysctl_entry_cap_last_cap" \
		--kernel-release="5.15.0" \
		-w /root /usr/bin/env \
		-i HOME=/root \
		PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games \
		TERM=xterm-256color \
		LANG=zh_CN.UTF-8 \
		LC_CTYPE="zh_CN.UTF-8" \
		LC_NUMERIC="zh_CN.UTF-8" \
		LC_TIME="zh_CN.UTF-8" \
		LC_COLLATE="zh_CN.UTF-8" \
		LC_MONETARY="zh_CN.UTF-8" \
		LC_MESSAGES="zh_CN.UTF-8" \
		LC_PAPER="zh_CN.UTF-8" \
		LC_NAME="zh_CN.UTF-8" \
		LC_ADDRESS="zh_CN.UTF-8" \
		LC_TELEPHONE="zh_CN.UTF-8" \
		LC_MEASUREMENT="zh_CN.UTF-8" \
		LC_IDENTIFICATION="zh_CN.UTF-8" \
		/bin/bash 优化.sh
	log_info "优化脚本执行成功"
	log_info "退出容器"

}
start_proot() {
	list_dir ${HOME}/.termux/gancm/proot
	case $user_choice in
	0)
		echo -e "${RED}quit${RES}"
		log_info "退出"
		;;
	*)
		if [ ! $? = 0 ]; then
			exit
		fi
		os_name=${list_items[$((user_choice - 1))]}
		log_info "进入容器${os_name}"
		unset LD_PRELOAD
		proot \
			--bind=/vendor \
			--bind=/system \
			--bind=/system/product \
			--bind=/odm \
			--bind=/apex \
			--bind=/data/data/com.termux/cache \
			--bind=/data/dalvik-cache \
			--bind=/data/app \
			--bind=/proc:/proc \
			--bind=/data/data/com.termux/files/home/.termux/共享文件夹:/termux共享文件夹 \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.sysctl_inotify_max_user_watches:/proc/sys/fs/inotify/max_user_watches \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.sysctl_entry_cap_last_cap:/proc/sys/kernel/cap_last_cap \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.vmstat:/proc/vmstat \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.version:/proc/version \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.uptime:/proc/uptime \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.stat:/proc/stat \
			--bind=${HOME}/.termux/gancm/proot/${os_name}/proc/.loadavg:/proc/loadavg \
			--bind=${HOME}/.termux/gancm/.重要文件夹/sys/.empty:/sys/fs/selinux \
			--bind=${HOME}/.termux/gancm/.重要文件夹/dev/shm:/dev/shm \
			--bind=/sys \
			--bind=/proc/self/fd/2:/dev/stderr \
			--bind=/proc/self/fd/1:/dev/stdout \
			--bind=/proc/self/fd/0:/dev/stdin \
			--bind=/proc/self/fd:/dev/fd \
			--bind=/proc \
			--bind=/dev/urandom:/dev/random \
			--bind=/dev \
			-L \
			--kernel-release=6.2.1-PRoot-Distro \
			--sysvipc \
			--link2symlink \
			--kill-on-exit \
			--cwd=/root \
			--change-id=0:0 \
			--rootfs=${HOME}/.termux/gancm/proot/${os_name}/ \
			/usr/bin/env -i \
			PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games \
			TERM=xterm-256color \
			system_os_type=proot \
			system_os_type2=${os_name} \
			LANG=zh_CN.UTF-8 \
			LC_CTYPE="zh_CN.UTF-8" \
			LC_NUMERIC="zh_CN.UTF-8" \
			LC_TIME="zh_CN.UTF-8" \
			LC_COLLATE="zh_CN.UTF-8" \
			LC_MONETARY="zh_CN.UTF-8" \
			LC_MESSAGES="zh_CN.UTF-8" \
			LC_PAPER="zh_CN.UTF-8" \
			LC_NAME="zh_CN.UTF-8" \
			LC_ADDRESS="zh_CN.UTF-8" \
			LC_TELEPHONE="zh_CN.UTF-8" \
			LC_MEASUREMENT="zh_CN.UTF-8" \
			LC_IDENTIFICATION="zh_CN.UTF-8" \
			ANDROID_DATA=/data \
			ANDROID_ROOT=/system \
			ANDROID_RUNTIME_ROOT=/apex/com.android.runtime \
			ANDROID_TZDATA_ROOT=/apex/com.android.tzdata \
			BOOTCLASSPATH=/apex/com.android.runtime/javalib/core-oj.jar:/apex/com.android.runtime/javalib/core-libart.jar:/apex/com.android.runtime/javalib/okhttp.jar:/apex/com.android.runtime/javalib/bouncycastle.jar:/apex/com.android.runtime/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/android.test.base.jar:/system/framework/tcmiface.jar:/system/framework/qcom.fmradio.jar:/system/framework/QPerformance.jar:/system/framework/UxPerformance.jar:/system/framework/WfdCommon.jar:/system/framework/vivo-framework.jar:/system/framework/vivo-media.jar:/system/framework/framework-adapter.jar:/system/framework/soc-framework.jar:/system/framework/vendor.factory.hardware.vivoem-V1.0-java.jar:/system/framework/vivo-vgcclient.jar:/system/framework/telephony-ext.jar:/system/framework/com.qti.location.sdk.jar:/apex/com.android.conscrypt/javalib/conscrypt.jar:/apex/com.android.media/javalib/updatable-media.jar \
			DEX2OATBOOTCLASSPATH=/apex/com.android.runtime/javalib/core-oj.jar:/apex/com.android.runtime/javalib/core-libart.jar:/apex/com.android.runtime/javalib/okhttp.jar:/apex/com.android.runtime/javalib/bouncycastle.jar:/apex/com.android.runtime/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/android.test.base.jar:/system/framework/tcmiface.jar:/system/framework/qcom.fmradio.jar:/system/framework/QPerformance.jar:/system/framework/UxPerformance.jar:/system/framework/WfdCommon.jar:/system/framework/vivo-framework.jar:/system/framework/vivo-media.jar:/system/framework/framework-adapter.jar:/system/framework/soc-framework.jar:/system/framework/vendor.factory.hardware.vivoem-V1.0-java.jar:/system/framework/vivo-vgcclient.jar:/system/framework/telephony-ext.jar:/system/framework/com.qti.location.sdk.jar \
			COLORTERM=truecolor \
			LANG=en_US.UTF-8 \
			MOZ_FAKE_NO_SANDBOX=1 \
			PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games:/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin \
			PULSE_SERVER=127.0.0.1 \
			TERM=xterm-256color \
			TMPDIR=/tmp \
			ANDROID_DATA=/data \
			ANDROID_ROOT=/system \
			ANDROID_RUNTIME_ROOT=/apex/com.android.runtime \
			ANDROID_TZDATA_ROOT=/apex/com.android.tzdata \
			BOOTCLASSPATH=/apex/com.android.runtime/javalib/core-oj.jar:/apex/com.android.runtime/javalib/core-libart.jar:/apex/com.android.runtime/javalib/okhttp.jar:/apex/com.android.runtime/javalib/bouncycastle.jar:/apex/com.android.runtime/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/android.test.base.jar:/system/framework/tcmiface.jar:/system/framework/qcom.fmradio.jar:/system/framework/QPerformance.jar:/system/framework/UxPerformance.jar:/system/framework/WfdCommon.jar:/system/framework/vivo-framework.jar:/system/framework/vivo-media.jar:/system/framework/framework-adapter.jar:/system/framework/soc-framework.jar:/system/framework/vendor.factory.hardware.vivoem-V1.0-java.jar:/system/framework/vivo-vgcclient.jar:/system/framework/telephony-ext.jar:/system/framework/com.qti.location.sdk.jar:/apex/com.android.conscrypt/javalib/conscrypt.jar:/apex/com.android.media/javalib/updatable-media.jar \
			DEX2OATBOOTCLASSPATH=/apex/com.android.runtime/javalib/core-oj.jar:/apex/com.android.runtime/javalib/core-libart.jar:/apex/com.android.runtime/javalib/okhttp.jar:/apex/com.android.runtime/javalib/bouncycastle.jar:/apex/com.android.runtime/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/android.test.base.jar:/system/framework/tcmiface.jar:/system/framework/qcom.fmradio.jar:/system/framework/QPerformance.jar:/system/framework/UxPerformance.jar:/system/framework/WfdCommon.jar:/system/framework/vivo-framework.jar:/system/framework/vivo-media.jar:/system/framework/framework-adapter.jar:/system/framework/soc-framework.jar:/system/framework/vendor.factory.hardware.vivoem-V1.0-java.jar:/system/framework/vivo-vgcclient.jar:/system/framework/telephony-ext.jar:/system/framework/com.qti.location.sdk.jar \
			COLORTERM=truecolor \
			HOME=/root \
			USER=root \
			TERM=xterm-256color \
			/bin/bash --login
		log_info "退出${os_name}"
		;;
	esac
}
rm_proot() {
	list_dir ${HOME}/.termux/gancm/proot
	case $user_choice in
	0)
		echo -e "${RED}quit${RES}"
		log_info "退出"
		;;
	*)
		if [ ! $? = 0 ]; then
			exit
		fi
		os_name=${list_items[$((user_choice - 1))]}
		num1=$((RANDOM % 100))
		num2=$((RANDOM % 100))
		log_info "num1=$num1 num2=$num2"
		# 读取用户输入
		read -e -p "${num1}+${num2}=?" user_sum
		log_info "user_sum=$user_sum"
		# 计算正确的和
		correct_sum=$(($num1 + $num2))
		# 检查用户输入是否正确
		if [ $user_sum -eq $correct_sum ]; then
			echo -e "删除开始正确！你输入的和是正确的。"
			chmod 777 -R "${HOME}/.termux/gancm/proot/${os_name}/"
			rm -rfv "${HOME}/.termux/gancm/proot/${os_name}/"
			# 在这里添加你想要执行的命令
		else
			echo -e "错误！你输入的和不正确。删除程序将不执行。"
		fi
		;;
	esac
}
