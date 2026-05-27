//
//  ADColor.swift
//  Domus Arkai
//
//  Brand palette — fonte autorevole:
//  ARKAI_DOMUS_BRAND_IDENTITY_UI_COLOR_SYSTEM.md
//
//  Supporta light/dark mode via dynamic UIColor. La modalità è guidata
//  da ThemeService.preferredColorScheme + system default.
//

import SwiftUI

enum ADColor {
    // Backgrounds & surfaces
    static let background  = Color.dynamic(light: "#F7F4ED", dark: "#0F0E0C")
    static let surface     = Color.dynamic(light: "#FFFFFF", dark: "#1B1A17")
    static let surfaceSoft = Color.dynamic(light: "#F1EDE4", dark: "#23211D")

    // Primary brand (deep green) + interactive (sage)
    static let primary      = Color.dynamic(light: "#243526", dark: "#D8E1CC")
    static let primarySoft  = Color.dynamic(light: "#556B45", dark: "#8FA277")
    static let primaryLight = Color.dynamic(light: "#DDE5D3", dark: "#3A4530")

    // Borders & dividers
    static let border   = Color.dynamic(light: "#D8D2C4", dark: "#3D372D")
    static let gridLine = Color.dynamic(light: "#E6E1D7", dark: "#2E2A24")

    // Text
    static let text      = Color.dynamic(light: "#1E1E1E", dark: "#F0EBE0")
    static let textMuted = Color.dynamic(light: "#6E6A61", dark: "#A39E92")
    static let textLight = Color.dynamic(light: "#8C867A", dark: "#7A746A")

    // Accents & feedback
    static let accentWarm   = Color.dynamic(light: "#A48768", dark: "#C5A977")
    static let actionAccent = Color.dynamic(light: "#64c4ff", dark: "#64c4ff") // azzurro CTA stampa
    static let warning      = Color.dynamic(light: "#B8795D", dark: "#D4926F")
    static let success      = Color.dynamic(light: "#556B45", dark: "#8FA277")

    // Icon roles
    enum Icon {
        static let `default` = ADColor.primarySoft
        static let muted = ADColor.textLight
        static let active = ADColor.primary
    }
}
