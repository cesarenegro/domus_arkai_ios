//
//  RoomScanOnboardingView.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — onboarding 3-slide mostrato la prima volta
//  che un agente apre `RoomScanFlowView`. Spiega in modo editoriale
//  come ottenere una scansione di qualità.
//
//  Flag persistente: `@AppStorage("hasSeenRoomScanOnboarding")`.
//

import SwiftUI

struct RoomScanOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenRoomScanOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var page: Int = 0

    private let slides: [Slide] = [
        Slide(
            number: "I",
            icon: "iphone.gen3.radiowaves.left.and.right",
            title: "Prepara la stanza",
            body: "Accendi tutte le luci. Apri le tende. Rimuovi tappeti, sedie e oggetti sul pavimento per agevolare il riconoscimento delle pareti."
        ),
        Slide(
            number: "II",
            icon: "figure.walk.motion",
            title: "Muoviti lentamente",
            body: "Avvia la scansione partendo da un angolo. Cammina lungo le pareti tenendo l'iPhone all'altezza del torace, inquadrando dove pavimento e parete si incontrano."
        ),
        Slide(
            number: "III",
            icon: "checkmark.seal.fill",
            title: "Verifica e carica",
            body: "Quando l'app conferma il completamento, controlla che il modello 3D rispecchi la stanza. Poi tocca \"Carica su immobile\" e attendi la notifica push: la pipeline genera l'arredo USDZ in pochi minuti."
        )
    ]

    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                        slideView(slide)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
                    .padding(.bottom, ADSpacing.s4)

                ctaButton
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.bottom, ADSpacing.s5)
            }
        }
    }

    // MARK: - Subviews

    private func slideView(_ slide: Slide) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s5) {
            HStack(spacing: ADSpacing.s3) {
                Text(slide.number)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(ADColor.accentWarm)
                Text("COME SCANSIONARE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(ADColor.accentWarm)
                Spacer(minLength: 0)
            }

            ZStack {
                Circle()
                    .fill(ADColor.surfaceSoft)
                    .frame(width: 140, height: 140)
                Image(systemName: slide.icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(ADColor.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, ADSpacing.s4)

            VStack(alignment: .leading, spacing: ADSpacing.s3) {
                Text(slide.title)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(ADColor.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(slide.body)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.top, ADSpacing.s8)
    }

    private var pageIndicator: some View {
        HStack(spacing: ADSpacing.s2) {
            ForEach(0..<slides.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? ADColor.primary : ADColor.border)
                    .frame(width: i == page ? 22 : 8, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }

    @ViewBuilder
    private var ctaButton: some View {
        if page < slides.count - 1 {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    page += 1
                }
            } label: {
                ctaLabel("Avanti")
            }
            .buttonStyle(.plain)
        } else {
            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                ctaLabel("Inizia la scansione")
            }
            .buttonStyle(.plain)
        }
    }

    private func ctaLabel(_ text: String) -> some View {
        HStack(spacing: ADSpacing.s2) {
            Text(text)
                .font(ADTypography.bodyMedium)
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(ADColor.primary)
        .foregroundStyle(ADColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct Slide {
    let number: String
    let icon: String
    let title: String
    let body: String
}

#Preview {
    RoomScanOnboardingView()
}
