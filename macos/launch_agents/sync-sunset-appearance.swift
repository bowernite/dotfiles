#!/usr/bin/env swift

import Darwin
import Foundation

private let loggerTag = "com.user.sync-sunset-appearance"
private let sunsetAppliedKey = "com.user.sync-sunset-appearance.sunsetAppliedForCurrentNight"
private let cmuxScript = "/Users/brett/src/personal/dotfiles/macos/launch_agents/set-cmux-terminal-theme.sh"

var lastIsDaylight: Bool?

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

func reloadCmuxConfig(trigger: String) {
    guard FileManager.default.isExecutableFile(atPath: cmuxScript) else {
        log("cmux sync skipped: script not executable trigger=\(trigger) path=\(cmuxScript)")
        return
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
        return
    }

    process.waitUntilExit()
    if process.terminationStatus == 0 {
        log("cmux sync ok trigger=\(trigger) appearanceDark=\(currentAppearanceIsDark())")
    } else {
        log("cmux sync failed trigger=\(trigger) appearanceDark=\(currentAppearanceIsDark()) exitCode=\(process.terminationStatus)")
    }
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
        log("setSystemDark failed: could not load SkyLight dark=\(dark)")
        return
    }
    typealias SetTheme = @convention(c) (Bool) -> Void
    guard let symbol = dlsym(handle, "SLSSetAppearanceThemeLegacy") else {
        log("setSystemDark failed: could not find SLSSetAppearanceThemeLegacy dark=\(dark)")
        return
    }
    unsafeBitCast(symbol, to: SetTheme.self)(dark)
    log("setSystemDark ok dark=\(dark)")
    notifyAppearanceChanged()
    reloadCmuxConfig(trigger: "sunset-set-dark")
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
        log("poll skipped: could not read Night Shift solar schedule")
        return
    }

    if isDaylight {
        let wasNight = lastIsDaylight == false
        lastIsDaylight = true

        if sunsetAlreadyAppliedForCurrentNight() {
            clearSunsetAppliedForCurrentNight()
            log("sunrise: cleared sunset flag appearanceDark=\(currentAppearanceIsDark())")
        }

        if wasNight {
            log("sunrise transition: resyncing CMUX appearanceDark=\(currentAppearanceIsDark())")
            reloadCmuxConfig(trigger: "sunrise")
        }
        return
    }

    lastIsDaylight = false

    if sunsetAlreadyAppliedForCurrentNight() {
        return
    }

    log("sunset reached; switching to dark appearanceDark=\(currentAppearanceIsDark())")
    if currentAppearanceIsDark() {
        markSunsetAppliedForCurrentNight()
        log("sunset skipped: already dark")
        return
    }
    setSystemDark(true)
    markSunsetAppliedForCurrentNight()
}

guard loadCoreBrightness() else {
    log("startup failed: could not load CoreBrightness")
    exit(1)
}

if let isDaylight = nightShiftIsDaylight() {
    lastIsDaylight = isDaylight
    log("started isDaylight=\(isDaylight) appearanceDark=\(currentAppearanceIsDark()) sunsetApplied=\(sunsetAlreadyAppliedForCurrentNight())")
} else {
    log("started: could not read Night Shift solar schedule appearanceDark=\(currentAppearanceIsDark())")
}
applySunsetDarkModeIfNeeded()
RunLoop.current.add(
    Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
        applySunsetDarkModeIfNeeded()
    },
    forMode: .common
)
RunLoop.current.run()
