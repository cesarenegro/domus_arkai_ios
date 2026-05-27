//
//  BuyerPassportCard.swift
//  Domus Arkai
//
//  Carta olografica del "Buyer Passport".
//  Gradient tier-specific + cronografo "parametro di eccellenza".
//  Mai chiamarlo "punteggio" in UI (regola brand-safety).
//

import SwiftUI

struct BuyerPassportCard: View {
    let passport: BuyerPassport?
    let userDisplayName: String
    let userEmail: String?

    private var tier: BuyerPassportTier { passport?.tier ?? .standardProfile }
    private var score: Int { passport?.buyerScore ?? 0 }
    private var scoreFraction: CGFloat { CGFloat(min(max(score, 0), 100)) / 100 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ADRadius.panel)
                .fill(tierGradient)

            RoundedRectangle(cornerRadius: ADRadius.panel)
                .fill(holographicShimmer)
                .blendMode(.overlay)

            RoundedRectangle(cornerRadius: ADRadius.panel)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.05), Color.white.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            VStack(alignment: .leading, spacing: ADSpacing.s3) {
                topRow
                Spacer(minLength: 0)
                Text("BUYER PASSPORT")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer(minLength: 0)
                bottomRow
            }
            .padding(ADSpacing.Card.paddingLarge)
        }
        .aspectRatio(1.586, contentMode: .fit)
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 14)
    }

    // MARK: - Sub-views

    private var topRow: some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARKAI DOMUS")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white)
                Text("Membership")
                    .font(ADTypography.metadata)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: ADSpacing.s2)
            Text(tier.label.uppercased())
                .font(ADTypography.metadata.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(.white)
                .padding(.horizontal, ADSpacing.s3)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.white.opacity(0.18))
                )
                .overlay(
                    Capsule().stroke(.white.opacity(0.45), lineWidth: 0.8)
                )
                .lineLimit(1)
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .bottom, spacing: ADSpacing.s3) {
            VStack(alignment: .leading, spacing: 4) {
                Text(userDisplayName.uppercased())
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                    .lineLimit(1)
                if let email = userEmail, !email.isEmpty {
                    Text(email)
                        .font(ADTypography.metadata)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: ADSpacing.s2)
            excellenceDial
        }
    }

    private var excellenceDial: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 3)
            Circle()
                .trim(from: 0, to: scoreFraction)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 18, weight: .semibold, design: .default).monospacedDigit())
                    .foregroundStyle(.white)
                Text("ECC.")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: 56, height: 56)
    }

    // MARK: - Visual treatments

    private var tierGradient: LinearGradient {
        let stops: [Color] = {
            switch tier {
            case .diamondElite:
                return [Color(hex: "#1B2D24"), Color(hex: "#395649"), Color(hex: "#243526")]
            case .platinumExecutive:
                return [Color(hex: "#3B3F46"), Color(hex: "#6C7480"), Color(hex: "#2E323A")]
            case .goldMember:
                return [Color(hex: "#8B6B3E"), Color(hex: "#C7A66B"), Color(hex: "#6E5325")]
            case .standardProfile:
                return [Color(hex: "#3A3A38"), Color(hex: "#5C5A52"), Color(hex: "#2A2A28")]
            }
        }()
        return LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var holographicShimmer: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                Color.white.opacity(0.0),
                Color.white.opacity(0.12),
                Color.white.opacity(0.0),
                Color.white.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack(spacing: ADSpacing.s3) {
        BuyerPassportCard(
            passport: BuyerPassport(
                id: UUID(),
                userID: UUID(),
                maxBudget: 800_000,
                liquidity: 250_000,
                mortgageNeededPct: 60,
                preferredAreas: ["Brera", "Porta Romana"],
                preferredCategory: ["attico"],
                minBedrooms: 2,
                minBathrooms: 2,
                buyerScore: 92,
                createdAt: nil,
                updatedAt: nil
            ),
            userDisplayName: "Cesare Negro",
            userEmail: "cesare@arkaidomus.com"
        )
        BuyerPassportCard(
            passport: nil,
            userDisplayName: "Ospite",
            userEmail: nil
        )
    }
    .padding(ADSpacing.s4)
    .background(ADColor.background)
}
