//
//  LandingView.swift
//  Domus Arkai
//
//  Landing editoriale = tab Home. Vetrina premium della tecnologia
//  Arkai Vision PRO + lista immobili + stima ristrutturazione.
//
//  Interattività limitata:
//  - "Avvia analisi stanza" → VisionProInfoView (push)
//  - Card "Stima ristrutturazione" → RenovationInfoView (push)
//  - Card "Lista immobili" e search bar = vetrina statica (non tappabili)
//

import SwiftUI

struct LandingView: View {
    @State private var showMap: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ADSpacing.s3) {
                        wordmarkHeader
                        fakeSearchBar
                        visionProHeroCard
                        bottomDuo
                        Color.clear.frame(height: ADSpacing.s3)
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s2)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showMap) {
                PropertiesMapView()
            }
        }
    }

    // MARK: - Wordmark + tagline

    private var wordmarkHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARKAI")
                    .font(.system(size: 38, weight: .regular, design: .serif))
                    .tracking(6)
                    .foregroundStyle(ADColor.primary)
                HStack(spacing: ADSpacing.s2) {
                    Rectangle()
                        .fill(ADColor.accentWarm.opacity(0.6))
                        .frame(width: 16, height: 1)
                    Text("DOMUS")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .tracking(6)
                        .foregroundStyle(ADColor.accentWarm)
                    Rectangle()
                        .fill(ADColor.accentWarm.opacity(0.6))
                        .frame(width: 16, height: 1)
                }
                Text("Valuta, analizza e pianifica ogni immobile.")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .padding(.top, ADSpacing.s3)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: ADSpacing.s2)
            Image(systemName: "person.crop.circle")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(ADColor.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Search bar (statica, presentativa)

    private var fakeSearchBar: some View {
        HStack(spacing: ADSpacing.s3) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ADColor.textMuted)
                Text("Cerca indirizzo, zona, immobile o agenzia")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textLight)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 46)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                Text("Filtri")
                    .font(ADTypography.small.weight(.medium))
            }
            .foregroundStyle(ADColor.primary)
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 46)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hero card ARKAI VisionPro

    private var visionProHeroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                visionImagePlaceholder
                visionBadge
                    .padding(ADSpacing.s3)
            }

            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                Text("L'AI proprietaria che riconosce lavori e costi.")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, ADSpacing.s3)

                Text("Rileva finiture, criticità e interventi in pochi secondi, con stima professionale.")
                    .font(.system(size: 12))
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: ADSpacing.s3) {
                    NavigationLink(destination: VisionProInfoView()) {
                        avviaAnalisiPill
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: ADSpacing.s2)
                    estimateChip
                }
                .padding(.top, ADSpacing.s2)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.bottom, ADSpacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(ADColor.accentWarm.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var visionImagePlaceholder: some View {
        Image("LandingHeroRoom")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    private var visionBadge: some View {
        HStack(spacing: ADSpacing.s2) {
            Text("A")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.78, green: 0.12, blue: 0.12))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle().stroke(Color(red: 0.78, green: 0.12, blue: 0.12), lineWidth: 1.3)
                )
            Text("ARKAI VisionPro")
                .font(.system(size: 13, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, ADSpacing.s3)
        .padding(.vertical, ADSpacing.s2)
        .background(Color(red: 0.74, green: 0.91, blue: 0.20))
        .overlay(
            Capsule().stroke(Color(red: 0.87, green: 0.74, blue: 0.45), lineWidth: 1.2)
        )
        .clipShape(Capsule())
    }

    private var avviaAnalisiPill: some View {
        HStack(spacing: ADSpacing.s2) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("Avvia analisi stanza")
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
        .background(ADColor.primary)
        .clipShape(Capsule())
    }

    private var estimateChip: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Stima lavori")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(ADColor.textMuted)
            Text("€ 6.180")
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .foregroundStyle(ADColor.primary)
            HStack(spacing: ADSpacing.s1) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(ADColor.accentWarm)
                Text("Report professionale")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(ADColor.textMuted)
            }
        }
        .padding(.horizontal, ADSpacing.s3)
        .padding(.vertical, ADSpacing.s2)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Duo card sotto (stesse dimensioni via Grid)

    private var bottomDuo: some View {
        Grid(horizontalSpacing: ADSpacing.s3, verticalSpacing: 0) {
            GridRow {
                Button {
                    showMap = true
                } label: {
                    FeatureMiniCard(
                        icon: "map.fill",
                        title: "Lista immobili",
                        copy: "Consulta tutti gli immobili disponibili sulla mappa interattiva.",
                        style: .passive
                    )
                }
                .buttonStyle(.plain)
                NavigationLink(destination: RenovationInfoView()) {
                    FeatureMiniCard(
                        icon: "ruler",
                        title: "Stima ristrutturazione",
                        copy: "Calcola una stima precisa dei lavori, dei materiali e dei costi locali in base alla tua casa.",
                        style: .active(label: "Scopri di più")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Mini card riusabile

private struct FeatureMiniCard: View {
    enum Style {
        case active(label: String)
        case passive
    }

    let icon: String
    let title: String
    let copy: String
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBackground)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(ADColor.primary)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(ADColor.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(copy)
                .font(.system(size: 11))
                .foregroundStyle(ADColor.textMuted)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            footerCTA
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(ADSpacing.s4)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var footerCTA: some View {
        switch style {
        case .active(let label):
            HStack(spacing: ADSpacing.s1) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ADColor.primary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ADColor.primary)
            }
        case .passive:
            HStack(spacing: ADSpacing.s1) {
                Text("Apri mappa")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ADColor.primary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ADColor.primary)
            }
        }
    }

    private var cardBackground: Color {
        switch style {
        case .active: return ADColor.surface
        case .passive: return ADColor.primaryLight.opacity(0.55)
        }
    }

    private var borderColor: Color {
        switch style {
        case .active: return ADColor.border
        case .passive: return ADColor.primarySoft.opacity(0.35)
        }
    }

    private var iconBackground: Color {
        switch style {
        case .active: return ADColor.surfaceSoft
        case .passive: return ADColor.surface.opacity(0.7)
        }
    }
}

#Preview {
    LandingView()
}
