//
//  FilterPill.swift
//  Domus Arkai
//

import SwiftUI

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(ADTypography.smallMedium)
                .foregroundStyle(isSelected ? ADColor.primary : ADColor.textMuted)
                .padding(.horizontal, ADSpacing.s4)
                .padding(.vertical, ADSpacing.s2)
                .background(
                    Capsule()
                        .fill(isSelected ? ADColor.primaryLight : ADColor.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        FilterPill(label: "Milano", isSelected: true) {}
        FilterPill(label: "Vendita", isSelected: false) {}
        FilterPill(label: "€300k–€800k", isSelected: false) {}
    }
    .padding()
    .background(ADColor.background)
}
