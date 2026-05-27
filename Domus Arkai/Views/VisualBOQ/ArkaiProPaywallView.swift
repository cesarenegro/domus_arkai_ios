//
//  ArkaiProPaywallView.swift
//  Domus Arkai
//
//  Sheet informativo Arkai Vision Pro — NIENTE pagamento.
//  L'app è gratuita per i clienti delle agenzie. La feature ha solo una quota mensile
//  (5 analisi/mese) che vale per tutti gli utenti loggati.
//
//  Mostrato in due casi:
//   1. Utente FREE non loggato → invita a loggarsi (gli utenti loggati hanno accesso).
//   2. Utente loggato con quota esaurita → info "torna il giorno X del prossimo mese".
//

import SwiftUI

struct ArkaiProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscription = SubscriptionService.shared
    @State private var auth = AuthService.shared

    /// Callback invocato quando l'utente può continuare (per il flow esterno).
    var onActivated: (() -> Void)?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "d MMMM"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        hero
                        statusCard
                        howItWorksCard
                        complianceNote
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 140)
                }
                .scrollIndicators(.hidden)

                ctaBar
            }
            .navigationTitle("Arkai Vision Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("ARKAI VISION PRO")
                    .font(ADTypography.metadata.weight(.semibold))
                    .tracking(1.2)
            }
            .foregroundStyle(ADColor.primaryLight)

            Text("L'analisi visiva degli ambienti, gratuita.")
                .font(ADTypography.largeTitle)
                .foregroundStyle(.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Arkai Domus offre l'analisi visiva delle stanze direttamente dalle foto, come servizio incluso dalle agenzie immobiliari per i propri clienti.")
                .font(ADTypography.body)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.panel))
    }

    @ViewBuilder
    private var statusCard: some View {
        if !auth.isAuthenticated {
            statusCardContent(
                tone: .neutral,
                title: "Accedi per usare Arkai Vision Pro",
                body: "Per garantire un uso responsabile della tecnologia di analisi visiva, è necessario accedere con il tuo ID Apple."
            )
        } else if !subscription.canUseVisionAnalysis {
            statusCardContent(
                tone: .warning,
                title: "Quota mensile esaurita",
                body: "Hai utilizzato le \(SubscriptionService.monthlyVisionQuota) analisi gratuite di questo mese. Il contatore si azzererà il \(Self.dateFormatter.string(from: subscription.nextQuotaResetDate))."
            )
        } else {
            statusCardContent(
                tone: .neutral,
                title: "Hai \(subscription.visionRemainingThisMonth) analisi gratuite disponibili questo mese",
                body: "Ogni mese ricevi \(SubscriptionService.monthlyVisionQuota) analisi visive gratuite, incluse nel servizio offerto dall'agenzia. Reset il \(Self.dateFormatter.string(from: subscription.nextQuotaResetDate))."
            )
        }
    }

    enum StatusTone { case neutral, warning }

    private func statusCardContent(tone: StatusTone, title: String, body: String) -> some View {
        let accent: Color = tone == .warning ? ADColor.warning : ADColor.primarySoft
        return VStack(alignment: .leading, spacing: ADSpacing.s2) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: tone == .warning ? "hourglass" : "checkmark.seal")
                    .foregroundStyle(accent)
                    .font(.system(size: 16))
                Text(title)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(body)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(accent.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            Text("Come funziona")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            step(
                number: "1",
                title: "Carica fino a 3 foto",
                subtitle: "Scatta o seleziona le immagini di una stanza che vuoi valutare."
            )
            Divider().overlay(ADColor.border.opacity(0.5))
            step(
                number: "2",
                title: "Lascia che Arkai Vision Pro analizzi",
                subtitle: "Identifichiamo gli interventi necessari e calcoliamo i costi con i parametri di mercato della tua zona."
            )
            Divider().overlay(ADColor.border.opacity(0.5))
            step(
                number: "3",
                title: "Salva nel tuo Dossier",
                subtitle: "La stima viene aggiunta al Dossier dell'immobile e inclusa nella tua Scheda Completa."
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func step(number: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            Text(number)
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(ADColor.primary))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                Text(subtitle)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var complianceNote: some View {
        Text("Le stime fornite hanno valore puramente indicativo e non sostituiscono il giudizio di un tecnico abilitato. Le immagini caricate vengono inviate in forma riservata ai sistemi di analisi Arkai Vision Pro ed elaborate esclusivamente per generare la tua stima.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ADSpacing.s2)
    }

    // MARK: - Sticky CTA

    private var ctaBar: some View {
        VStack(spacing: ADSpacing.s2) {
            Button {
                handleContinue()
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: ctaIcon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(ctaLabel)
                }
            }
            .buttonStyle(.adPrimary)
            .disabled(!isCTAEnabled)
            .opacity(isCTAEnabled ? 1.0 : 0.55)

            Text(ctaFooter)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.top, ADSpacing.s3)
        .padding(.bottom, ADSpacing.s5)
        .background(
            ADColor.surface
                .overlay(
                    Rectangle()
                        .fill(ADColor.border.opacity(0.4))
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var ctaIcon: String {
        if !auth.isAuthenticated { return "applelogo" }
        return "sparkles"
    }

    private var ctaLabel: String {
        if !auth.isAuthenticated { return "Accedi dal Profilo" }
        if subscription.canUseVisionAnalysis { return "Inizia l'analisi" }
        return "Quota esaurita"
    }

    private var ctaFooter: String {
        if !auth.isAuthenticated {
            return "Tutti i servizi sono gratuiti, inclusi nel pacchetto offerto dall'agenzia."
        }
        if subscription.canUseVisionAnalysis {
            return "Servizio gratuito · \(subscription.visionRemainingThisMonth) di \(SubscriptionService.monthlyVisionQuota) analisi residue questo mese."
        }
        return "Disponibile di nuovo dal \(Self.dateFormatter.string(from: subscription.nextQuotaResetDate))."
    }

    private var isCTAEnabled: Bool {
        !auth.isAuthenticated || subscription.canUseVisionAnalysis
    }

    private func handleContinue() {
        if !auth.isAuthenticated {
            // L'utente deve andare al tab Profilo per loggarsi.
            print("🟡 [Vision][Info] not authenticated — dismissing to guide to Profile tab")
            dismiss()
            return
        }
        if subscription.canUseVisionAnalysis {
            print("🟢 [Vision][Info] user has quota — proceeding to capture")
            onActivated?()
            dismiss()
        }
    }
}

#Preview {
    ArkaiProPaywallView()
}
