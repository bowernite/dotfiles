#!/usr/bin/env swift

import Darwin
import Foundation

private let loggerTag = "com.user.sync-sunset-appearance"
private let sunsetAppliedKey = "com.user.sync-sunset-appearance.sunsetAppliedForCurrentNight"

func log(_ message: String) {
    print(message)
    fflush(stdout)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/logger")
    process.arguments = ["-t", loggerTag, message]
    try? process.run()
    process.waitUntilExit()
}

func loadCoreBrightness() -> Bool {
    Bundle(path: "/System/Library/PrivateFrameworks/CoreBrightness.framework")?.load() ?? false
}

func nightShiftIsDaylight() -> Bool? {
    guard let cls = NSClassFromString("BrightnessSystemClient") as? NSObject.Type else {
        return nil
    }
    let client = cls.init()
    let sel = NSSelectorFromString("copyPropertyForKey:")
    guard client.responds(to: sel) else { return nil }
    let unmanaged = client.perform(sel, with: "BlueLightSunSchedule")
    guard let dict = unmanaged?.takeUnretainedValue() as? [String: Any] else {
        return nil
    }
    if let isDaylight = dict["isDaylight"] as? Bool {
        return isDaylight
    }
    if let isDaylight = dict["isDaylight"] as? NSNumber {
        return isDaylight.boolValue
    }
    return nil
}

func currentAppearanceIsDark() -> Bool {
    UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
}

func reloadCmuxConfig() {
    let script = "/Users/brett/src/personal/dotfiles/macos/launch_agents/set-cmux-terminal-theme.sh"
    guard FileManager.default.isExecutableFile(atPath: script) else { return }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: script)
    try? process.run()
    process.waitUntilExit()
}

func notifyAppearanceChanged() {
    DistributedNotificationCenter.default().post(
        name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
        object: nil
    )
}

func setSystemDark(_ dark: Bool) {
    guard let handle = dlopen(
        "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
        RTLD_NOW
    ) else {
        log("Could not load SkyLight")
        return
    }
    typealias SetTheme = @convention(c) (Bool) -> Void
    guard let symbol = dlsym(handle, "SLSSetAppearanceThemeLegacy") else {
        log("Could not find SLSSetAppearanceThemeLegacy")
        return
    }
    unsafeBitCast(symbol, to: SetTheme.self)(dark)
    notifyAppearanceChanged()
    reloadCmuxConfig()
}

func sunsetAlreadyAppliedForCurrentNight() -> Bool {
    UserDefaults.standard.bool(forKey: sunsetAppliedKey)
}

func markSunsetAppliedForCurrentNight() {
    UserDefaults.standard.set(true, forKey: sunsetAppliedKey)
}

func clearSunsetAppliedForCurrentNight() {
    UserDefaults.standard.removeObject(forKey: sunsetAppliedKey)
}

func applySunsetDarkModeIfNeeded() {
    guard let isDaylight = nightShiftIsDaylight() else {
        log("Could not read Night Shift solar schedule")
        return
    }

    if isDaylight {
        if sunsetAlreadyAppliedForCurrentNight() {
            clearSunsetAppliedForCurrentNight()
        }
        return
    }

    if sunsetAlreadyAppliedForCurrentNight() {
        return
    }

    log("Sunset reached; switching to dark")
    if currentAppearanceIsDark() {
        markSunsetAppliedForCurrentNight()
        return
    }
    setSystemDark(true)
    markSunsetAppliedForCurrentNight()
}

guard loadCoreBrightness() else {
    log("Could not load CoreBrightness")
    exit(1)
}

if let isDaylight = nightShiftIsDaylight() {
    log("started; Night Shift isDaylight=\(isDaylight) appearanceDark=\(currentAppearanceIsDark())")
} else {
    log("started; could not read Night Shift solar schedule")
}
applySunsetDarkModeIfNeeded()
RunLoop.current.add(
    Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
        applySunsetDarkModeIfNeeded()
    },
    forMode: .common
)
RunLoop.current.run()
