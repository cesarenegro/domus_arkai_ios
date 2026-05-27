//
//  PlaceholderHomeView.swift
//  Domus Arkai
//
//  Schermata temporanea brandizzata mostrata finché l'MVP iOS
//  non è ancora implementato.
//

import SwiftUI

struct PlaceholderHomeView: View {
    var body: some View {
        ZStack {
            ADColor.background
                .ignoresSafeArea()

            VStack(spacing: ADSpacing.s5) {
                Spacer()

                VStack(spacing: ADSpacing.s3) {
                    Text("Arkai Domus")
                        .font(ADTypography.display)
                        .foregroundStyle(ADColor.primary)

                    Rectangle()
                        .fill(ADColor.primarySoft)
                        .frame(width: 36, height: 1)

                    Text("La nuova esperienza\nimmobiliare intelligente")
                        .font(ADTypography.body)
                        .foregroundStyle(ADColor.textMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                statusCard

                Spacer()
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack(spacing: ADSpacing.s2) {
                Circle()
                    .fill(ADColor.primarySoft)
                    .frame(width: 6, height: 6)
                Text("MVP IN COSTRUZIONE")
                    .font(ADTypography.metadata.weight(.medium))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(1.2)
            }

            Text("In attesa delle specifiche UI dal coordinamento backend.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        .shadow(
            color: ADColor.primary.opacity(ADShadow.softOpacity),
            radius: ADShadow.softRadius,
            x: ADShadow.softOffset.width,
            y: ADShadow.softOffset.height
        )
    }
}

#Preview {
    PlaceholderHomeView()
}
