import Foundation
import SwiftUI

/// Small global settings that don't warrant SwiftData persistence — mirrors the
/// Settings sheet in the design: rest timer on/off + duration, and the accent swap.
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    var restTimerEnabled: Bool {
        didSet { UserDefaults.standard.set(restTimerEnabled, forKey: Keys.restOn) }
    }

    /// Seconds. Steps by 10, clamped 10...300.
    var restDuration: Int {
        didSet { UserDefaults.standard.set(restDuration, forKey: Keys.restLen) }
    }

    var accent: AccentChoice {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: Keys.accent) }
    }

    private enum Keys {
        static let restOn = "settings.restOn"
        static let restLen = "settings.restLen"
        static let accent = "settings.accent"
    }

    private init() {
        let d = UserDefaults.standard
        self.restTimerEnabled = d.object(forKey: Keys.restOn) as? Bool ?? true
        self.restDuration = d.object(forKey: Keys.restLen) as? Int ?? 90
        self.accent = AccentChoice(rawValue: d.string(forKey: Keys.accent) ?? "") ?? .lime
    }
}

enum AccentChoice: String, CaseIterable {
    case lime, amber

    var color: Color {
        switch self {
        case .lime: return Color(hex: 0xC6FF3E)
        case .amber: return Color(hex: 0xFFB020)
        }
    }
}
