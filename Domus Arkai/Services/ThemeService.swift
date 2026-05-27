//
//  ThemeService.swift
//  Domus Arkai
//
//  Gestione preferenza tema (Sistema / Chiaro / Scuro) persistita in AppStorage.
//  Applicata al root via `.preferredColorScheme(themeService.colorScheme)`.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Sistema"
        case .light: "Chiaro"
        case .dark: "Scuro"
        }
    }

    var iconName: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
@Observable
final class ThemeService {
    static let shared = ThemeService()

    private let storageKey = "preferred_app_theme"

    var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: storageKey)
        }
    }

    var colorScheme: ColorScheme? { theme.colorScheme }

    private init() {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? AppTheme.system.rawValue
        self.theme = AppTheme(rawValue: raw) ?? .system
    }
}
