//
//  ADTypography.swift
//  Domus Arkai
//
//  iOS type scale. Editorial titles use system serif (.serif design)
//  finché non aggiungiamo Cormorant Garamond come custom font.
//  UI body usa system rounded sans (Inter sostituibile più avanti).
//

import SwiftUI

enum ADTypography {
    // Editorial (serif) — solo per titoli grandi e marketing
    static let display = Font.system(size: 40, weight: .regular, design: .serif)
    static let largeTitle = Font.system(size: 34, weight: .regular, design: .serif)

    // UI titles (sans)
    static let pageTitle = Font.system(size: 28, weight: .semibold, design: .default)
    static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .default)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .default)

    // Body / data
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let small = Font.system(size: 14, weight: .regular, design: .default)
    static let smallMedium = Font.system(size: 14, weight: .medium, design: .default)
    static let metadata = Font.system(size: 12, weight: .regular, design: .default)

    // Numbers (prezzi, KPI)
    static let priceLarge = Font.system(size: 28, weight: .semibold, design: .default).monospacedDigit()
    static let priceMedium = Font.system(size: 20, weight: .semibold, design: .default).monospacedDigit()
    static let kpiNumber = Font.system(size: 32, weight: .medium, design: .default).monospacedDigit()
}
