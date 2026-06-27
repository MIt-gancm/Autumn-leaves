#!/bin/bash
# modules/linux_menu.sh - Linux功能模块
for script in $HOME/.gancm/lib/linux/*; do
	source "$script"
	log_info "加载:$script"
done
case $1 in
download_JAVA | dj)
	download_JAVA
	;;
install_MC_SERVER | imcs)
	install_MC_SERVER_MENU
	;;
start_MC_SERVER | smcs)
	start_MC_SERVER
	;;
rm_MC_SERVER | rmcs)
	rm_MC_SERVER
	;;
installMCSManager | imcsm)
	installMCSManager
	;;
startMCSManager | startcsm)
	startMCSManager
	;;
stopMCSManager | stopcsm)
	stopMCSManager
	;;
installNapCatQQ | inQQ)
	installNapCatQQ
	;;
startNapCatQQ | startnQQ)
	startNapCatQQ
	;;
startNapCatQQB | startnQQB)
	startNapCatQQ -B
	;;
*)
	if [ "${system_os_type}" = "" ]; then
		echo -e "${INFO}完整linux环境或非本脚本安装的proot${RES}"
	fi

	while true; do
		Linux_menu=$(
			whiptail --title "Linux_menu" --menu "按自己需求来" 15 60 4 \
				"1" "管理mc Server" \
				"2" "QQ机器人" \
				"3" "咕咕咕" \
				"0" "退出" \
				"D" "debuger" 3>&1 1>&2 2>&3
		)
		if [ ! "${package_manager}" = "apt" ]; then
			echo -e "${RED}请使用apt包管理器${RES}"
			exit 1
		fi
		case $Linux_menu in
		1)
			while true; do
				MC_Server=$(
					whiptail --title "选择功能" --menu "我的世界服务器按自己需求来" 20 60 10 \
						"1" "安装MC SERVER" \
						"2" "启动MC SERVER" \
						"3" "删除MC SERVER" \
						"4" "导入我的世界zip服务器" \
						"5" "打包/备份我的世界zip服务器" \
						"6" "启动我的世界面板" \
						"7" "停止我的世界面板" \
						"8" "安装我的世界面板" \
						"9" "安装java" \
						"0" "返回上级" 3>&1 1>&2 2>&3
				)
				case $MC_Server in
				1)
					log_info "安装MC SERVER"
					install_MC_SERVER_MENU
					hcjx
					;;
				2)
					log_info "启动MC SERVER"
					start_MC_SERVER
					hcjx
					;;
				3)
					log_info "删除MC SERVER"
					rm_MC_SERVER
					hcjx
					;;
				4)
					log_info "导入我的世界服务器"
					Import_zip_MC_SERVER
					hcjx
					;;
				5)
					log_info "导出我的世界服务器"
					Export_zip_MC_SERVER
					hcjx
					;;
				6)
					log_info "启动我的世界面板"
					startMCSManager
					hcjx
					;;
				7)
					log_info "停止我的世界面板"
					stopMCSManager
					hcjx
					;;
				8)
					log_info "安装我的世界面板"
					installMCSManager
					hcjx
					;;
				9)
					log_info "安装java"
					download_JAVA
					hcjx
					;;
				*)
					break
					;;
				esac
			done
			;;
		2)
			while true; do
				QQBot_menu=$(
					whiptail --title "选择功能" --menu "QQ机器人按自己需求来" 15 60 8 \
						"1" "管理NapCatQQ" \
						"2" "管理机器人" \
						"0" "返回上级" 3>&1 1>&2 2>&3
				)
				case $QQBot_menu in
				1)
					log_info "管理NapCatQQ"
					while true; do
						QQBotTX_menu=$(
							whiptail --title "选择功能" --menu "QQ机器容器支持deb12和非容器Ubuntu 20+/Debian 10+/Centos9" 15 60 8 \
								"1" "安装NapCatQQ" \
								"2" "启动NapCatQQ" \
								"3" "后台启动NapCatQQ" \
								"4" "WebUI地址" \
								"0" "返回上级" 3>&1 1>&2 2>&3
						)
						case $QQBotTX_menu in
						1)
							log_info "安装NapCatQQ"
							installNapCatQQ
							hcjx
							;;
						2)
							log_info "启动NapCatQQ"
							startNapCatQQ
							hcjx
							;;
						3)
							log_info "后台启动NapCatQQ"
							startNapCatQQ -B
							hcjx
							;;
						4)
							log_info "WebUI地址"
							QQbottk=$(jq -r '.token' /opt/QQ/resources/app/app_launcher/napcat/config/webui.json 2>/dev/null)
							echo -e "机器人后台地址: http://127.0.0.1:6099/webui?token=${QQbottk} "
							hcjx
							;;
						*)
							break
							;;
						esac
					done
					;;
				2)
					log_info "管理机器人"
					echo "咕咕咕"
					hcjx
					;;
				*)
					break
					;;
				esac
			done
			;;

		D)
			debuger
			hcjx
			;;
		*)
			break
			;;
		esac
	done
	;;
esac