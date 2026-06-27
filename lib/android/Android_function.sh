garbage_collection() {
	ls -la ${HOME}/.gancm/download
	read -e -p "是否删除这些文件？[Y/n]: " delete_files
	if [[ $delete_files =~ ^[Yy]$ ]]; then
		rm -rf ${HOME}/.gancm/download/*
		echo -e "${SUSSEC}所有文件已删除。"
		log_info "所有文件已删除。"
	else
		echo -e "${INFO}文件未删除。"
		log_info "文件未删除。"
	fi

}
