import SwiftUI

struct UpdateSettingsView: View {
    @ObservedObject var updater: AppUpdater
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("当前版本 \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")（构建 \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—")）")
                    .font(.headline)
                if let version = updater.availableVersion {
                    Label("新版本 \(version) 可用", systemImage: "arrow.down.circle")
                }
                Button("检查更新…", action: updater.checkForUpdates)
                    .disabled(!updater.canCheckForUpdates).controlSize(.large)
                if let error = updater.startupError {
                    Text(error).foregroundStyle(.orange).textSelection(.enabled)
                } else if let date = updater.lastCheckDate {
                    Text("上次检查：\(date.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                } else {
                    Text("尚未检查更新").foregroundStyle(.secondary)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Toggle("自动检查更新", isOn: Binding(get: { updater.automaticallyChecksForUpdates },
                    set: updater.setAutomaticallyChecks)).toggleStyle(.switch)
                    .disabled(updater.startupError != nil)
                Text("每天在后台检查新版本；关闭后仍可手动检查。")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 10) {
                Toggle("自动安装更新", isOn: Binding(get: { updater.automaticallyInstallsUpdates },
                    set: updater.setAutomaticallyInstalls)).toggleStyle(.switch)
                    .disabled(!updater.allowsAutomaticUpdates || updater.startupError != nil)
                Text(updater.automaticallyChecksForUpdates
                    ? "在后台下载更新，并在退出时安装。需要授权或确认时会提示；文件夹操作期间会等待完成。"
                    : "先开启自动检查更新，才能自动下载并在退出时安装。")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Text("更新检查会连接 GitHub 获取版本信息和安装包，不上传文件、路径或系统概况。")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }.font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
    }
}
