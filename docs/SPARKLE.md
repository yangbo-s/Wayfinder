# Sparkle 更新接入

REQ-015 / AC-015：设置新增软件更新页，提供手动检查、自动检查、自动安装；自动项默认关闭，选择由 Sparkle 自己持久化，关闭自动检查时暂停自动安装但保留原选择。更新会话中检查按钮反映 Sparkle 的可用状态。已有文件夹操作完成前推迟安装重启。

REQ-016 / AC-016：使用固定的 Sparkle 2.10.0 二进制依赖与 Package.resolved。App 内嵌 framework、安装助手和许可；可用 Developer ID 或显式选择 ad-hoc 测试签名。更新源、更新包均需 Ed25519 校验，解压前先验签。私钥仅在本机钥匙串，仓库不保存私钥。

MOD-009 / ADR-007：AppUpdater 包装 SPUStandardUpdaterController，KVO/Combine 连接真实状态，UpdateSettingsView 只负责原生控件；Sparkle 负责调度、网络、错误窗口、下载与替换 App，不另写更新安装器。UpdateRelaunchGate 在主线程等待 FolderCreation 完成再继续 Sparkle 重启。与手写下载覆盖相比，保留成熟的签名与安装流程。

IN-005 / OUT-005：SUFeedURL 为 HTTPS GitHub raw 的 `updates/appcast.xml`；SUPublicEDKey 为 32 字节 Ed25519 公钥的 base64。RSS 项目使用递增整数 CFBundleVersion、显示版本、最低系统版本、Release ZIP URL、长度和 Ed25519 签名。缺失/被篡改 feed 或 archive 均报错；手动检查的网络失败由 Sparkle 提示并允许重试，自动检查遵循其调度。自动安装是后台下载、退出时安装，并非强制立即重启。

CON-003：保留现有 Finder、音效与权限行为；不关闭系统 Gatekeeper，不上传文件路径或启用系统概况统计。开发阶段先完成代码和本地验证；用户随后授权推送源码和安装包，按下列顺序发布 beta.7。发布操作不替换现有 Applications 安装。

## 构建

```sh
# 正式签名：保留库验证，宿主及所有嵌入代码使用同一有效身份。
SIGNING_IDENTITY='Developer ID Application: …' ./scripts/build.sh

# ad-hoc 本地测试：保留 Hardened Runtime，只有此 App 关闭 Library Validation。
ALLOW_ADHOC_UPDATES=1 ./scripts/build.sh
```

ad-hoc 不需要付费证书，但不能公证，更新也不能解决 TCC 身份变化。App-AdHoc.entitlements 的例外仅在显式设置 ALLOW_ADHOC_UPDATES=1 且 SIGNING_IDENTITY 为 `-` 时使用；正式签名使用原 App.entitlements，绝不携带该例外。构建脚本默认拒绝一个无法加载 Sparkle 的 ad-hoc + 库验证组合。

## 发布密钥与更新源

密钥已通过官方 generate_keys 创建，钥匙串 account 是 `local.wayfinder.mac`。重新运行下面命令只输出公钥，不导出私钥：

```sh
.build/artifacts/sparkle/Sparkle/bin/generate_keys --account local.wayfinder.mac -p
```

其他维护者构建源码不需要私钥；发布签名必须使用同一密钥。私钥备份由发布者安全管理，不能将其写入 Git、构建日志或普通环境配置。不要重新生成并替换已发布的公钥来“修复”签名失败。

`updates/appcast.xml` 是已签名的更新源；发布时在公开安装包下载验证通过后更新。beta.6 不包含 Sparkle，需要手动安装 beta.7 一次。开发时的本地安装验证与线上下载验证分别记录在 ACCEPTANCE.md。

发布顺序：递增两个 Info.plist 的构建号 → 运行测试 → 构建签名 App → package-release.sh 生成 DMG、ZIP、音效包、已签名 appcast 与校验文件 → 将对应 tag 的 Release 上传并公开 → 验证公开 ZIP 可下载且哈希正确 → 最后将 dist/appcast.xml 原样复制到 updates/appcast.xml 并推送。不要在资产可下载前发布 appcast，也不要修改已签名的 XML 或 ZIP；新版本必须重新生成签名。

`scripts/make-appcast.py` 从最终 ZIP 读取版本与公钥，拒绝非 Wayfinder 包、版本不符、公钥与钥匙串不符或不递增的版本；验证 archive 签名后，再原子生成和校验 feed 签名。使用 `SPARKLE_ACCOUNT` 可以指定已有钥匙串 account，仍须匹配 App 内嵌公钥。

## 验收计划

TC-071：真实 Sparkle 初始化、自动项默认值、开关耦合与跨实例持久化；未启动时检查按钮不可用。TC-072：文件操作期间推迟重启且只继续一次。TC-073：签名 archive/feed 正常验证，篡改二者被拒绝；发布脚本拒绝错误 ID/版本/密钥和重复版本。TC-074：实际设置页、手动检查、无更新/网络失败和有效更新路径。TC-075：嵌入 framework、助手、rpath、签名及安装包完整性。结果与评分记入 ACCEPTANCE.md，不把模拟回调替代真实安装验证。

依据：[Sparkle 程序化接入](https://sparkle-project.org/documentation/programmatic-setup/)、[设置绑定](https://sparkle-project.org/documentation/preferences-ui/)、[签名和构建](https://sparkle-project.org/documentation/)、[发布更新](https://sparkle-project.org/documentation/publishing/)。
