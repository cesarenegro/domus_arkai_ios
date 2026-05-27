//
//  ADButtonStyles.swift
//  Domus Arkai
//

import SwiftUI

struct ADPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ADTypography.bodyMedium.weight(.semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 50)
            .padding(.horizontal, fullWidth ? 0 : ADSpacing.s5)
            .background(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .fill(configuration.isPressed ? ADColor.primary : ADColor.primarySoft)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ADSecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ADTypography.bodyMedium)
            .foregroundStyle(ADColor.primary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 48)
            .padding(.horizontal, fullWidth ? 0 : ADSpacing.s5)
            .background(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .fill(configuration.isPressed ? ADColor.surfaceSoft : ADColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(configuration.isPressed ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ADPrimaryButtonStyle {
    static var adPrimary: ADPrimaryButtonStyle { ADPrimaryButtonStyle() }
    static func adPrimary(fullWidth: Bool) -> ADPrimaryButtonStyle { ADPrimaryButtonStyle(fullWidth: fullWidth) }
}

extension ButtonStyle where Self == ADSecondaryButtonStyle {
    static var adSecondary: ADSecondaryButtonStyle { ADSecondaryButtonStyle() }
    static func adSecondary(fullWidth: Bool) -> ADSecondaryButtonStyle { ADSecondaryButtonStyle(fullWidth: fullWidth) }
}
