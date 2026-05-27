//
//  SpecCard.swift
//  Domus Arkai
//

import SwiftUI

struct SpecCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(ADColor.primarySoft)
            Text(value)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, ADSpacing.s3)
        .padding(.vertical, ADSpacing.s3)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.input)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.input))
    }
}
