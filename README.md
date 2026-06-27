# Autumn-leaves - GNU/Linux & Android 综合管理脚本

一个基于 Bash 的多功能管理脚本，支持在 **Android (Termux)** 和 **Linux** 环境下运行，提供容器管理、Minecraft 服务器管理、QQ 机器人部署等功能。

## 功能特性

### Android (Termux)
- **Proot 容器管理** — 安装/启动/删除 Proot 容器（支持 Ubuntu、RockyLinux、CentOS）
- **垃圾清理** — 清理下载缓存文件

### Linux
- **Java 环境管理** — 一键安装 OpenJDK
- **Minecraft 服务器管理**
  - 多核心支持（Paper、Fabric、Purpur 等）
  - 版本选择（支持全版本）
  - 服务器启动/停止/删除
  - Zip 导入/导出/备份
- **MCSManager 面板** — 安装/启动/停止我的世界面板
- **NapCatQQ 机器人** — 安装/启动（支持后台运行）

### 通用
- 自动更新检查
- 包管理器自动更新
- 系统调试信息输出 (`-D` / `--debug`)

## 安装

```bash
git clone https://github.com/MIt-gancm/Autumn-leaves.git ~/.gancm
chmod +x ~/.gancm/gancm.sh
~/.gancm/gancm.sh
```

## 使用

### 交互模式
直接运行脚本进入菜单界面：
```bash
~/.gancm/gancm.sh
```

### 命令行模式

```bash
# 显示帮助
~/.gancm/gancm.sh -h

# 指定平台启动
~/.gancm/gancm.sh -s Android
~/.gancm/gancm.sh -s Linux

# 带子命令
~/.gancm/gancm.sh -s Android install proot
~/.gancm/gancm.sh -s Linux install_MC_SERVER

# 调试模式
~/.gancm/gancm.sh -D
```

## 目录结构

```
~/.gancm/
├── gancm.sh                 # [入口] 主启动脚本
├── config/                  # [配置]
│   ├── config.sh            # 用户配置文件 (Git源、自动更新、QQ号等)
│   └── version              # 版本信息文件 (JSON)
├── core/                    # [核心] 公共函数和环境检测
│   ├── utils.sh             # 颜色、日志、通用工具函数
│   └── env.sh               # 系统检测、包管理器检测
├── modules/                 # [功能] 具体功能模块
│   ├── update.sh            # 脚本自我更新模块
│   ├── android_menu.sh      # Android 功能菜单
│   └── linux_menu.sh        # Linux 功能菜单
└── lib/                     # [依赖] 平台功能库
    ├── android/
    │   ├── Android_function.sh   # Android 工具函数
    │   └── Android_proot.sh      # Proot 容器管理
    ├── linux/
    │   ├── Linux_mcserver.sh     # MC 服务器管理
    │   └── Linux_qqbot.sh        # QQ 机器人管理
    ├── Start_Java_MC_SERVER.sh   # Java 服务端启动配置
    ├── proot_optimization.sh     # Proot 容器优化脚本
    └── proot_proc/               # Proot 容器 proc 模拟文件
```

## 注意事项

- **Linux 系统建议使用 apt 包管理器**（Debian/Ubuntu 系），其他包管理器可能存在兼容问题
- Proot 容器功能仅在 Termux (Android) 环境下可用
- MC 服务器下载依赖 API 服务 `mcserverapi.gancmcs.top`
- 首次运行会自动创建目录结构和初始化配置