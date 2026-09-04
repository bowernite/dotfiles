#!/usr/bin/env swift

import Cocoa
import Foundation

private let loggerTag = "com.user.watch-appearance"
private let cmuxScript = "/Users/brett/src/personal/dotfiles/macos/launch_agents/set-cmux-terminal-theme.sh"

func log(_ message: String) {
    print(message)
    fflush(stdout)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/logger")
    process.arguments = ["-t", loggerTag, message]
    try? process.run()
    process.waitUntilExit()
}

func currentAppearanceIsDark() -> Bool {
    UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
}

func reloadCmuxConfig(trigger: String) -> Int32 {
    guard FileManager.default.isExecutableFile(atPath: cmuxScript) else {
        log("cmux sync skipped: script not executable trigger=\(trigger) path=\(cmuxScript)")
        return -1
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: cmuxScript)
    var env = ProcessInfo.processInfo.environment
    env["TRIGGER"] = trigger
    process.environment = env

    do {
        try process.run()
    } catch {
        log("cmux sync failed to start trigger=\(trigger) error=\(error.localizedDescription)")
        return -1
    }

    process.waitUntilExit()
    return process.terminationStatus
}

func updateClaudeTheme(isDark: Bool, trigger: String) {
    let claudeTheme = isDark ? "dark" : "light"
    let claudeJsonPath = NSString("~/.claude.json").expandingTildeInPath
    let claudeJsonURL = URL(fileURLWithPath: claudeJsonPath)

    guard FileManager.default.fileExists(atPath: claudeJsonPath) else {
        log("claude theme skipped: ~/.claude.json missing trigger=\(trigger)")
        return
    }

    guard let data = try? Data(contentsOf: claudeJsonURL) else {
        log("claude theme failed: could not read ~/.claude.json trigger=\(trigger)")
        return
    }

    guard var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        log("claude theme failed: could not parse ~/.claude.json trigger=\(trigger)")
        return
    }

    json["theme"] = claudeTheme

    guard let updatedData = try? JSONSerialization.data(
        withJSONObject: json,
        options: [.prettyPrinted, .sortedKeys]
    ) else {
        log("claude theme failed: could not serialize ~/.claude.json trigger=\(trigger)")
        return
    }

    do {
        try updatedData.write(to: claudeJsonURL)
        log("claude theme updated trigger=\(trigger) theme=\(claudeTheme)")
    } catch {
        log("claude theme failed: could not write ~/.claude.json trigger=\(trigger) error=\(error.localizedDescription)")
    }
}

func syncAppearance(trigger: String) {
    let isDark = currentAppearanceIsDark()
    let appearance = isDark ? "dark" : "light"
    log("sync start trigger=\(trigger) appearance=\(appearance)")

    let exitCode = reloadCmuxConfig(trigger: trigger)
    if exitCode == 0 {
        log("cmux sync ok trigger=\(trigger) appearance=\(appearance)")
    } else {
        log("cmux sync failed trigger=\(trigger) appearance=\(appearance) exitCode=\(exitCode)")
    }

    updateClaudeTheme(isDark: isDark, trigger: trigger)
}

func scheduleSync(trigger: String, delaySeconds: TimeInterval) {
    log("scheduling sync trigger=\(trigger) delaySeconds=\(delaySeconds)")
    DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
        syncAppearance(trigger: trigger)
    }
}

log("started appearanceDark=\(currentAppearanceIsDark())")
syncAppearance(trigger: "launch")

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: .main
) { _ in
    syncAppearance(trigger: "theme-changed")
}

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsUnlocked"),
    object: nil,
    queue: .main
) { _ in
    scheduleSync(trigger: "unlock", delaySeconds: 1)
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: .main
) { _ in
    scheduleSync(trigger: "wake", delaySeconds: 3)
}

RunLoop.current.run()
