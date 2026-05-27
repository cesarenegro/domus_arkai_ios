//
//  Color+Hex.swift
//  Domus Arkai
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        self = Color(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: CGFloat
        switch cleaned.count {
        case 6:
            r = CGFloat((value & 0xFF0000) >> 16) / 255
            g = CGFloat((value & 0x00FF00) >> 8) / 255
            b = CGFloat(value & 0x0000FF) / 255
            a = 1
        case 8:
            r = CGFloat((value & 0xFF000000) >> 24) / 255
            g = CGFloat((value & 0x00FF0000) >> 16) / 255
            b = CGFloat((value & 0x0000FF00) >> 8) / 255
            a = CGFloat(value & 0x000000FF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// Crea un UIColor dinamico che cambia tra light/dark automaticamente.
    static func dynamic(light: String, dark: String) -> UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark: return UIColor(hex: dark)
            default: return UIColor(hex: light)
            }
        }
    }
}

extension Color {
    /// SwiftUI Color dinamico che cambia tra light/dark automaticamente.
    static func dynamic(light: String, dark: String) -> Color {
        Color(uiColor: .dynamic(light: light, dark: dark))
    }
}
