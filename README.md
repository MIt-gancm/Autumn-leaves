${HOME}/.gancm/
├── gancm.sh                 # [入口] 主启动脚本
├── config/                  # [配置]
│   ├── config.sh            # 用户配置文件
│   └── version              # 版本信息文件
├── core/                    # [核心] 存放公共函数和环境检测
│   ├── utils.sh             # 颜色、日志、通用工具函数
│   └── env.sh               # 系统检测、包管理器检测
├── modules/                 # [功能] 具体功能模块
│   ├── update.sh            # 更新脚本
│   ├── android_menu.sh      # 原 Android/Android_menu
│   └── linux_menu.sh        # 原 Linux/Linux_menu
└── lib/                     # [依赖] 存放二进制或第三方库
    └── proot_proc/          # <--- 【重点】proot_proc 文件夹放这里
