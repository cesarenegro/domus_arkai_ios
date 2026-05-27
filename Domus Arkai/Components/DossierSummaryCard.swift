//
//  DossierSummaryCard.swift
//  Domus Arkai
//
//  Card riepilogo del Dossier per un immobile: mostra i 4 sotto-calcoli salvati
//  + investimento totale stimato. Brand-safe.
//

import SwiftUI

struct DossierSummaryCard: View {
    let dossier: PropertyDossier
    var onTapPrint: (() -> Void)?

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    private static func formatEuro(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return Self.currencyFormatter.string(from: NSNumber(value: v)) ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            header
            divider
            rows
            divider
            totalSection
            if onTapPrint != nil {
                printButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.panel)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.panel))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("IL MIO DOSSIER")
                        .font(ADTypography.metadata.weight(.semibold))
                        .tracking(1.2)
                }
                .foregroundStyle(ADColor.primarySoft)

                Text("Stime salvate per questo immobile")
                    .font(ADTypography.sectionTitle)
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }

    private var divider: some View {
        Divider().overlay(ADColor.border.opacity(0.5))
    }

    private var rows: some View {
        VStack(spacing: ADSpacing.s3) {
            row(
                icon: "house",
                label: "Prezzo richiesto",
                value: Self.formatEuro(dossier.askingPriceSnapshot),
                tone: .neutral
            )
            row(
                icon: "location.viewfinder",
                label: "Valutazione di zona",
                value: Self.formatEuro(dossier.avmEstimatedTotal),
                tone: .neutral
            )
            row(
                icon: "function",
                label: "Mutuo stimato (rata)",
                value: dossier.mortgageMonthlyPayment.map { "\(Self.formatEuro($0))/mese" } ?? "—",
                tone: .neutral
            )
            row(
                icon: "hammer",
                label: "Ristrutturazione",
                value: Self.formatEuro(dossier.renovationTotal),
                tone: .accent
            )
            row(
                icon: "camera.viewfinder",
                label: "Arkai Vision Pro",
                value: Self.formatEuro(dossier.visualBOQTotal),
                tone: .accent
            )
        }
    }

    enum RowTone { case neutral, accent }

    private func row(icon: String, label: String, value: String, tone: RowTone) -> some View {
        HStack(spacing: ADSpacing.s3) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(tone == .accent ? ADColor.accentWarm : ADColor.primarySoft)
                .frame(width: 22)
            Text(label)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
            Spacer(minLength: ADSpacing.s2)
            Text(value)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
                .lineLimit(1)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var totalSection: some View {
        if let total = dossier.totalInvestment {
            VStack(alignment: .leading, spacing: 4) {
                Text("INVESTIMENTO TOTALE STIMATO")
                    .font(ADTypography.metadata.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(ADColor.textMuted)
                Text(Self.formatEuro(total))
                    .font(ADTypography.priceLarge)
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Prezzo richiesto + ristrutturazione + analisi visive.")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var printButton: some View {
        if let onTapPrint {
            Button(action: onTapPrint) {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "printer")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Stampa scheda completa")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ADRadius.md).fill(ADColor.actionAccent)
                )
                .foregroundStyle(.white)
                .font(ADTypography.bodyMedium.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    DossierSummaryCard(
        dossier: PropertyDossier(
            id: UUID(),
            userID: UUID(),
            propertyID: UUID(),
            askingPriceSnapshot: 780_000,
            avmZoneID: "PMP-120",
            avmEstimatedPerSqm: 9_500,
            avmEstimatedTotal: 745_000,
            mortgageEstimateID: nil,
            mortgageMonthlyPayment: 1_950,
            renovationTotal: 38_500,
            renovationItems: nil,
            renovationDifficultyFactors: ["centro_storico"],
            visualBOQEstimateIDs: nil,
            visualBOQTotal: 12_300,
            userNotes: nil,
            createdAt: nil,
            updatedAt: nil
        ),
        onTapPrint: {}
    )
    .padding()
    .background(ADColor.background)
}
