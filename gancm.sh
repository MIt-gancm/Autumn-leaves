if source $HOME/.gancm/function/Main_function; then
	echo -e "$SUSSEC加载主功能成功"
else
	echo -e "$WORRY加载主功能失败"
fi
case ${1} in
-h | --help)
	echo -e "
	待添加
	"
	hcjx
	;;
*)
	validity
	case $(uname -o) in
	Android)
		self_install jq pkg
		self_install wget pkg
		self_install whiptail pkg
		variable &
		source ${HOME}/.gancm/local/Android/Android_menu $1 $2 $3
		;;
	*)
		self_install jq apt
		self_install wget apt
		self_install whiptail apt
		variable &
		source ${HOME}/.gancm/local/Linux/Ubuntu/Ubuntu20.04/Ubuntu_menu $1 $2 $3
		;;

	esac

	;;
esac
