#!/bin/bash
# modules/android_menu.sh - 安卓功能模块
for script in $HOME/.gancm/lib/android/* ; do
	source "$script" 
	log_info "加载:$script"
done
case $1 in
install)
	case $2 in
	proot)
		log_info "安装proot容器"
		install_proot
		;;
	*)
		echo -e "\n$WORRY请输入完整命令\ninstall proot"
		;;
	esac

	;;
start)
	case $2 in
	proot)
		log_info "启动proot容器"
		start_proot
		;;
	*)
		echo -e "\n$WORRY请输入完整命令\nstart proot"
		;;
	esac

	;;
*)
	while true; do
		Android_menu=$(
			whiptail --title "选择功能" --menu "termux按自己需求来" 15 60 8 \
				"1" "管理proot容器" \
				"2" "垃圾清理" \
				"3" "待添加" \
				"0" "退出" \
				"D" "debuger"  3>&1 1>&2 2>&3
		)
		case $Android_menu in
		1)
			log_info "管理proot容器"
			while true; do
				open_proot=$(
					whiptail --title "选择功能" --menu "termux按自己需求来" 15 60 4 \
						"1" "安装proot容器" \
						"2" "启动proot容器" \
						"3" "删除proot容器" \
						"0" "返回上级" 3>&1 1>&2 2>&3
				)
				case $open_proot in
				1)
					log_info "安装proot容器"
					install_proot
					hcjx
					;;
				2)
					log_info "启动proot容器"
					start_proot
					hcjx
					;;
				3)
					log_info "删除proot容器"
					rm_proot
					hcjx
					;;
				*)
					break
					;;
				esac
			done
			;;
		2)
			log_info "垃圾清理"
			garbage_collection
			hcjx
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