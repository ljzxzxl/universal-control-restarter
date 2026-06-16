import Cocoa
import Darwin

struct CommandResult {
    let status: Int32
    let output: String
}

final class RestartAppDelegate: NSObject, NSApplicationDelegate {
    private let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 760, height: 440),
        styleMask: [.titled, .closable, .miniaturizable],
        backing: .buffered,
        defer: false
    )
    private let textView = NSTextView()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        configureWindow()
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.global(qos: .userInitiated).async {
            self.runRestart()
        }
    }

    private func configureWindow() {
        window.title = "UniversalControlRestart"
        window.center()
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1)

        let scrollView = NSScrollView(frame: window.contentView?.bounds ?? .zero)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1)

        textView.minSize = NSSize(width: 0, height: 0)
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
    }

    private func append(_ message: String, color: NSColor = NSColor(calibratedWhite: 0.92, alpha: 1)) {
        let timestamp = dateFormatter.string(from: Date())
        let fullMessage = "[\(timestamp)] \(message)\n"

        DispatchQueue.main.async {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: color
            ]
            self.textView.textStorage?.append(NSAttributedString(string: fullMessage, attributes: attributes))
            self.textView.scrollToEndOfDocument(nil)
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
            let message = "无法执行命令: \(error.localizedDescription)"
            append("! \(message)", color: .systemRed)
            return CommandResult(status: 127, output: message)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if showOutput, !output.isEmpty {
            for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
                append(String(line), color: NSColor(calibratedWhite: 0.82, alpha: 1))
            }
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
        append("失败: \(message)", color: .systemRed)
        append("窗口会保留，方便查看输出。", color: .systemYellow)
    }

    private func finishSuccessfully() {
        append("完成: UniversalControl 已重启。窗口即将关闭。", color: .systemGreen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            NSApp.terminate(nil)
        }
    }

    private func runRestart() {
        append("UniversalControlRestart")
        append("目标: 重启 /System/Library/CoreServices/UniversalControl.app")

        let oldPIDs = universalControlPIDs()
        if oldPIDs.isEmpty {
            append("当前未发现 UniversalControl 进程，将直接启动。", color: .systemYellow)
        } else {
            append("当前 UniversalControl PID: \(oldPIDs.map(String.init).joined(separator: ", "))")
            shell("/bin/kill -TERM \(oldPIDs.map(String.init).joined(separator: " ")) 2>/dev/null || true")
            Thread.sleep(forTimeInterval: 1.2)

            let stillAlive = oldPIDs.filter(pidExists)
            if !stillAlive.isEmpty {
                append("TERM 未结束旧进程，改用 KILL。", color: .systemYellow)
                shell("/bin/kill -KILL \(stillAlive.map(String.init).joined(separator: " ")) 2>/dev/null || true")
                Thread.sleep(forTimeInterval: 0.8)
            }
        }

        var newPIDs = waitForUniversalControl(timeout: 2.0)
        if newPIDs.isEmpty {
            shell("/usr/bin/open -g /System/Library/CoreServices/UniversalControl.app")
            newPIDs = waitForUniversalControl(timeout: 8.0)
        }

        guard let primaryPID = newPIDs.first else {
            fail("没有成功启动 UniversalControl。")
            return
        }

        append("新的 UniversalControl PID: \(newPIDs.map(String.init).joined(separator: ", "))", color: .systemGreen)

        let uid = getuid()
        shell("/bin/launchctl print gui/\(uid)/com.apple.ensemble | /usr/bin/grep -E 'pid =|runs =|last terminating signal' || true")

        let session = shell("/usr/sbin/lsof -nP -p \(primaryPID) -iTCP -a | /usr/bin/grep ESTABLISHED || true")
        if session.output.isEmpty {
            append("未检测到已建立的通用控制 TCP 会话；进程已重启，移动鼠标到屏幕边缘会触发重连。", color: .systemYellow)
        } else {
            append("已检测到已建立的通用控制/AWDL 会话。", color: .systemGreen)
        }

        let assertion = shell("/usr/bin/pmset -g assertions | /usr/bin/grep -F 'com.apple.universalcontrol.userActivity' || true")
        if assertion.output.isEmpty {
            append("未检测到 userActivity 断言；这在刚重启且尚未跨屏时是正常的。", color: .systemYellow)
        } else {
            append("已检测到 com.apple.universalcontrol.userActivity。", color: .systemGreen)
        }

        finishSuccessfully()
    }
}

let app = NSApplication.shared
let delegate = RestartAppDelegate()
app.delegate = delegate
app.run()
