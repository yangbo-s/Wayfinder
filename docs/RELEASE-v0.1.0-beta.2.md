# Wayfinder v0.1.0-beta.2

修复 Finder 操作无响应与启动行为，并统一 App 内品牌图标。macOS 13+，本次提供 Apple Silicon（arm64）安装包。

- 普通打开或再次打开 App 显示设置；仅明确的 Finder / 菜单终端操作打开终端。
- Finder 菜单在点击时读取当前位置，修复终端和路径复制静默失效。工具栏扩展按钮现在单击打开终端，复制路径保留在文件及空白处右键菜单。
- 设置页使用和 App 外部相同的图标；菜单栏 / Finder 工具栏换成清晰的单色“文件夹＋转向箭头”图标。
- 系统授权与快捷键监听分别显示，增加重新检查、重试监听和重启入口，避免监听失败被误报为未授权。
- 已有终端选择与设置保留；新安装默认系统 Terminal。

25 项核心测试通过，宿主和 Finder 扩展 release 构建与严格签名校验通过。Finder 中的文件、符号链接和空白处路径复制实测通过；工具栏到 Ghostty 脚本请求成功。完整终端 cwd、文件剪切和登录 E2E 仍未全部验证。

安装：退出旧版，将 DMG / ZIP 内 Wayfinder.app 替换到 Applications，再打开。添加工具栏按钮请使用 Finder 的“自定工具栏”中的 Wayfinder 扩展按钮。

仍为 ad-hoc 签名测试版，尚未 Developer ID 签名或公证。更新会改变代码身份，系统可能要求重新授权当前 App；开关已开但 App 仍显示未生效时，请移除系统权限列表的旧 Wayfinder，再添加 /Applications/Wayfinder.app 并开启。不需要关闭系统安全保护。
