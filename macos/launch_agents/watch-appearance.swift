#!/usr/bin/env swift

import Cocoa
import Foundation

func updateTheme() {
    let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    let claudeTheme = isDark ? "dark" : "light"

    let logMessage = "macOS appearance changed: setting Claude Code theme to \(claudeTheme)"
    print(logMessage)

    // Log to system log
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/logger")
    process.arguments = ["-t", "com.user.appearance-watcher", logMessage]
    try? process.run()
    process.waitUntilExit()

    // Update Claude Code theme in ~/.claude.json
    let claudeJsonPath = NSString("~/.claude.json").expandingTildeInPath
    let claudeJsonURL = URL(fileURLWithPath: claudeJsonPath)

    guard FileManager.default.fileExists(atPath: claudeJsonPath),
          let data = try? Data(contentsOf: claudeJsonURL),
          var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        print("Could not read ~/.claude.json")
        return
    }

    json["theme"] = claudeTheme
    guard let updatedData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else {
        print("Could not serialize updated JSON")
        return
    }

    try? updatedData.write(to: claudeJsonURL)
    print("Updated ~/.claude.json theme to \(claudeTheme)")
}

// Set theme on launch
updateTheme()

// Watch for appearance changes
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: .main
) { _ in
    updateTheme()
}

// Run the event loop
RunLoop.current.run()
