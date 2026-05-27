//
//  ActionEntryCard.swift
//  Domus Arkai
//
//  Card entry-point secondaria (Mutuo, Ristrutturazione).
//  CTA primario "Prenota visita" sta nella bottom bar, NON qui.
//

import SwiftUI

struct ActionEntryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(ADColor.primarySoft)
                    .padding(.bottom, ADSpacing.s2)

                Text(title)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ADSpacing.Card.paddingSmall)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
        .buttonStyle(.plain)
    }
}
