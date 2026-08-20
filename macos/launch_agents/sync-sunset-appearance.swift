#!/usr/bin/env swift

import Darwin
import Foundation

private let loggerTag = "com.user.sync-sunset-appearance"

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
    UserDefaults.standard.set(true, forKey: "AppleInterfaceStyleSwitchesAutomatically")
}

func syncAppearanceToNightShift() {
    guard let isDaylight = nightShiftIsDaylight() else {
        log("Could not read Night Shift solar schedule")
        return
    }
    let wantDark = !isDaylight
    if wantDark == currentAppearanceIsDark() {
        return
    }
    log(wantDark
        ? "Night Shift sunset reached; switching to dark"
        : "Night Shift sunrise reached; switching to light")
    setSystemDark(wantDark)
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
syncAppearanceToNightShift()
RunLoop.current.add(
    Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
        syncAppearanceToNightShift()
    },
    forMode: .common
)
RunLoop.current.run()
