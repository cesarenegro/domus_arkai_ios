//
//  ADEmptyState.swift
//  Domus Arkai
//

import SwiftUI

struct ADEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(ADColor.textLight)

            Text(title)
                .font(ADTypography.cardTitle)
                .foregroundStyle(ADColor.primary)

            Text(message)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ADSpacing.s5)
        .padding(.vertical, ADSpacing.s6)
    }
}

struct ADErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(ADColor.warning)

            Text("Qualcosa è andato storto")
                .font(ADTypography.cardTitle)
                .foregroundStyle(ADColor.primary)

            Text(message)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ADSpacing.s4)

            Button("Riprova", action: onRetry)
                .buttonStyle(.adSecondary(fullWidth: false))
                .padding(.top, ADSpacing.s2)
        }
        .frame(maxWidth: .infinity)
        .padding(ADSpacing.s6)
    }
}
