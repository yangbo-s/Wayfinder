Wayfinder 的首个公开测试版：把 Finder 文件剪切、在当前位置打开终端、复制真实路径放进一个原生 macOS 菜单栏 App。

### 功能

- Finder 中 ⌘X / ⌘V 剪切移动，文件操作由 Finder 完成。
- 默认 Terminal，可切换 Ghostty、iTerm2、Warp 或带自定义参数的终端。
- Finder 右键在目标位置打开终端、复制真实绝对路径；支持多选与符号链接。
- 按住 ⌘ 将 App 拖入 Finder 工具栏，可单击打开当前位置终端。
- 登录时后台启动、剪切成功提示音，均有设置开关。
- 中文原生界面；无需账号，无网络服务依赖。

### 下载与安装

选择 **Wayfinder-v0.1.0-beta.1-macOS-arm64.dmg**，打开并把 App 拖入 Applications；也提供 ZIP 和 SHA256SUMS.txt。

- 架构：Apple Silicon / arm64。
- 最低系统：macOS 13；本次构建与界面检查环境为 macOS 27.0.1。
- 首次使用请开启辅助功能（macOS 27 中名为设备控制与数据访问）和 Finder 扩展，并按系统提示允许 Finder / 终端自动化。
- 请退出 Command X 后再试，避免快捷键冲突。

### 测试版限制

此包为 **ad-hoc 本地签名，未经过 Apple Developer ID 签名或公证**。macOS 可能阻止首次打开；只有确认信任项目源码和发布来源后，才在系统设置中确认继续。无需关闭 Gatekeeper 或执行移除隔离属性的命令。

17 项核心测试通过，App / Finder 扩展构建与签名完整性检查通过，真实设置界面已检查。由于系统授权尚未开启，真实文件移动、撤销/跨卷、Finder 右键、终端工作目录、音效播放及重新登录启动尚未完成端到端验证。**这是可试用的开发测试版，不是已全面验收的稳定版。**

完整安装、构建、故障排查与验收记录请见 [README](https://github.com/yangbo-s/Wayfinder#readme) 和 [验收记录](https://github.com/yangbo-s/Wayfinder/blob/main/docs/ACCEPTANCE.md)。
