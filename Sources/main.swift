import Cocoa
import Darwin

struct CommandResult {
    let status: Int32
    let output: String
}

final class RestartAppDelegate: NSObject, NSApplicationDelegate {
    private let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 780, height: 500),
        styleMask: [.titled, .closable, .miniaturizable],
        backing: .buffered,
        defer: false
    )
    private let scrollView = NSScrollView()
    private let textView = NSTextView()
    private let confirmationDefaultsKey = "HasConfirmedUniversalControlRestart"
    private let usesChinese = Locale.preferredLanguages.first?
        .lowercased()
        .hasPrefix("zh") ?? false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if shouldAskForConfirmation() {
            guard confirmRestart() else {
                NSApp.terminate(nil)
                return
            }
            UserDefaults.standard.set(true, forKey: confirmationDefaultsKey)
        }

        configureWindow()
        append(t(
            "正在准备执行，请稍候...",
            "Preparing to run. Please wait..."
        ), color: .systemGreen)

        DispatchQueue.global(qos: .userInitiated).async {
            self.runRestart()
        }
    }

    private func t(_ zh: String, _ en: String) -> String {
        usesChinese ? zh : en
    }

    private func shouldAskForConfirmation() -> Bool {
        !UserDefaults.standard.bool(forKey: confirmationDefaultsKey)
    }

    private func confirmRestart() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSApp.applicationIconImage
        alert.messageText = t(
            "即将重启“通用控制”",
            "Restart Universal Control?"
        )
        alert.informativeText = t(
            "此操作会结束并重新打开 macOS 的 UniversalControl 相关进程，用于恢复通用控制连接。操作不需要管理员权限，也不会修改系统设置。\n\n是否继续？",
            "This will quit and reopen the macOS UniversalControl process to help restore Universal Control connections. It does not require administrator privileges and will not change system settings.\n\nDo you want to continue?"
        )
        alert.addButton(withTitle: t("确认重启", "Restart"))
        alert.addButton(withTitle: t("取消", "Cancel"))

        return alert.runModal() == .alertFirstButtonReturn
    }

    private func configureWindow() {
        window.title = "UniversalControlRestart"
        window.center()
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1)

        scrollView.frame = window.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 780, height: 500)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1)

        textView.frame = NSRect(origin: .zero, size: scrollView.contentSize)
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1)
        textView.textColor = NSColor(calibratedWhite: 0.92, alpha: 1)
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 14, height: 14)

        scrollView.documentView = textView
        window.contentView = scrollView
        window.makeKeyAndOrderFront(nil)
        window.displayIfNeeded()
    }

    private func resizeTextViewForContent() {
        guard let textContainer = textView.textContainer, let layoutManager = textView.layoutManager else {
            return
        }

        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        let targetHeight = max(
            scrollView.contentSize.height,
            ceil(usedRect.height + textView.textContainerInset.height * 2 + 24)
        )
        textView.setFrameSize(NSSize(width: scrollView.contentSize.width, height: targetHeight))
    }

    private func appendNow(_ fullMessage: String, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: color
        ]
        textView.textStorage?.append(NSAttributedString(string: fullMessage, attributes: attributes))
        resizeTextViewForContent()
        textView.scrollToEndOfDocument(nil)
        textView.needsDisplay = true
        scrollView.needsDisplay = true
        window.contentView?.layoutSubtreeIfNeeded()
        window.contentView?.displayIfNeeded()
    }

    private func append(_ message: String, color: NSColor = NSColor(calibratedWhite: 0.92, alpha: 1)) {
        let timestamp = dateFormatter.string(from: Date())
        let lines = message.isEmpty ? [""] : message.components(separatedBy: .newlines)
        let fullMessage = lines
            .map { "[\(timestamp)] \($0)" }
            .joined(separator: "\n") + "\n"

        if Thread.isMainThread {
            appendNow(fullMessage, color: color)
        } else {
            DispatchQueue.main.sync {
                self.appendNow(fullMessage, color: color)
            }
        }
    }

    @discardableResult
    private func shell(_ command: String, showCommand: Bool = true, showOutput: Bool = true) -> CommandResult {
        if showCommand {
            append("$ \(command)", color: NSColor(calibratedRed: 0.48, green: 0.78, blue: 1.0, alpha: 1))
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            let message = t(
                "无法执行命令: \(error.localizedDescription)",
                "Could not run command: \(error.localizedDescription)"
            )
            append("! \(message)", color: .systemRed)
            return CommandResult(status: 127, output: message)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if showOutput {
            if output.isEmpty {
                append(t("（无输出）", "(no output)"), color: NSColor(calibratedWhite: 0.55, alpha: 1))
            } else {
                for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
                    append(String(line), color: NSColor(calibratedWhite: 0.82, alpha: 1))
                }
            }
        }

        if showCommand {
            let statusMessage = process.terminationStatus == 0
                ? t("命令完成，退出码 0", "Command finished with exit code 0")
                : t("命令结束，退出码 \(process.terminationStatus)", "Command finished with exit code \(process.terminationStatus)")
            append(statusMessage, color: process.terminationStatus == 0 ? .systemGreen : .systemYellow)
        }

        return CommandResult(status: process.terminationStatus, output: output)
    }

    private func universalControlPIDs() -> [Int32] {
        let result = shell("/usr/bin/pgrep -x UniversalControl", showCommand: false, showOutput: false)
        return result.output
            .split(whereSeparator: \.isNewline)
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private func pidExists(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }

    private func waitForUniversalControl(timeout: TimeInterval) -> [Int32] {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let pids = universalControlPIDs()
            if !pids.isEmpty {
                return pids
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return universalControlPIDs()
    }

    private func fail(_ message: String) {
        append(t("失败: \(message)", "Failed: \(message)"), color: .systemRed)
        append(t("窗口会保留，方便查看输出。", "This window will stay open so you can review the output."), color: .systemYellow)
    }

    private func finishSuccessfully() {
        append(t("完成: UniversalControl 已重启。", "Done: UniversalControl has been restarted."), color: .systemGreen)
        append(t("窗口将在 2 秒后自动关闭。", "This window will close automatically in 2 seconds."), color: .systemGreen)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSApp.terminate(nil)
        }
    }

    private func runRestart() {
        append("UniversalControlRestart")
        append(t(
            "已确认操作，开始重启“通用控制”相关服务。",
            "Confirmed. Starting Universal Control service restart."
        ), color: .systemGreen)
        append(t(
            "目标: /System/Library/CoreServices/UniversalControl.app",
            "Target: /System/Library/CoreServices/UniversalControl.app"
        ))
        append("")

        append(t("步骤 1/5: 查找当前 UniversalControl 进程。", "Step 1/5: Looking for the current UniversalControl process."))
        let oldPIDs = universalControlPIDs()
        if oldPIDs.isEmpty {
            append(t(
                "当前未发现 UniversalControl 进程，将直接启动。",
                "No running UniversalControl process was found. The app will be started directly."
            ), color: .systemYellow)
        } else {
            append(t(
                "当前 UniversalControl PID: \(oldPIDs.map(String.init).joined(separator: ", "))",
                "Current UniversalControl PID: \(oldPIDs.map(String.init).joined(separator: ", "))"
            ))

            append(t("步骤 2/5: 尝试正常结束旧进程。", "Step 2/5: Asking the old process to quit normally."))
            shell("/bin/kill -TERM \(oldPIDs.map(String.init).joined(separator: " ")) 2>/dev/null || true")
            append(t("等待旧进程退出。", "Waiting for the old process to exit."))
            Thread.sleep(forTimeInterval: 1.2)

            let stillAlive = oldPIDs.filter(pidExists)
            if !stillAlive.isEmpty {
                append(t(
                    "TERM 未结束旧进程，改用 KILL: \(stillAlive.map(String.init).joined(separator: ", "))",
                    "TERM did not stop the old process, using KILL: \(stillAlive.map(String.init).joined(separator: ", "))"
                ), color: .systemYellow)
                shell("/bin/kill -KILL \(stillAlive.map(String.init).joined(separator: " ")) 2>/dev/null || true")
                append(t("等待系统重新拉起 UniversalControl。", "Waiting for macOS to relaunch UniversalControl."))
                Thread.sleep(forTimeInterval: 0.8)
            } else {
                append(t("旧进程已响应 TERM。", "The old process responded to TERM."), color: .systemGreen)
            }
        }

        append(t("步骤 3/5: 确认 UniversalControl 已启动。", "Step 3/5: Confirming that UniversalControl is running."))
        var newPIDs = waitForUniversalControl(timeout: 2.0)
        if newPIDs.isEmpty {
            append(t(
                "系统尚未自动启动 UniversalControl，手动打开目标 App。",
                "macOS has not relaunched UniversalControl yet. Opening the target app manually."
            ), color: .systemYellow)
            shell("/usr/bin/open -g /System/Library/CoreServices/UniversalControl.app")
            newPIDs = waitForUniversalControl(timeout: 8.0)
        }

        guard let primaryPID = newPIDs.first else {
            fail(t("没有成功启动 UniversalControl。", "UniversalControl did not start successfully."))
            return
        }

        append(t(
            "新的 UniversalControl PID: \(newPIDs.map(String.init).joined(separator: ", "))",
            "New UniversalControl PID: \(newPIDs.map(String.init).joined(separator: ", "))"
        ), color: .systemGreen)

        append(t("步骤 4/5: 检查 launchd 状态。", "Step 4/5: Checking launchd state."))
        let uid = getuid()
        shell("/bin/launchctl print gui/\(uid)/com.apple.ensemble | /usr/bin/grep -E 'pid =|runs =|last terminating signal' || true")

        append(t("步骤 5/5: 检查通用控制连接状态。", "Step 5/5: Checking Universal Control connection state."))
        let session = shell("/usr/sbin/lsof -nP -p \(primaryPID) -iTCP -a | /usr/bin/grep ESTABLISHED || true")
        if session.output.isEmpty {
            append(t(
                "未检测到已建立的通用控制 TCP 会话；进程已重启，移动鼠标到屏幕边缘会触发重连。",
                "No established Universal Control TCP session was detected. The process has restarted; moving the pointer to the screen edge should trigger reconnection."
            ), color: .systemYellow)
        } else {
            append(t(
                "已检测到已建立的通用控制/AWDL 会话。",
                "An established Universal Control/AWDL session was detected."
            ), color: .systemGreen)
        }

        let assertion = shell("/usr/bin/pmset -g assertions | /usr/bin/grep -F 'com.apple.universalcontrol.userActivity' || true")
        if assertion.output.isEmpty {
            append(t(
                "未检测到 userActivity 断言；这在刚重启且尚未跨屏时是正常的。",
                "No userActivity assertion was detected. This is normal right after restart if you have not moved across displays yet."
            ), color: .systemYellow)
        } else {
            append(t(
                "已检测到 com.apple.universalcontrol.userActivity。",
                "Detected com.apple.universalcontrol.userActivity."
            ), color: .systemGreen)
        }

        finishSuccessfully()
    }
}

let app = NSApplication.shared
let delegate = RestartAppDelegate()
app.delegate = delegate
app.run()
