//
//  LoginRequiredSheet.swift
//  Domus Arkai
//
//  Pop-up modale mostrato quando un utente non autenticato tenta un'azione che
//  richiede login (salvare nel Dossier, vedere AVM/Mutuo/Renovation/Visual BOQ).
//  Rimanda al tab Profilo per completare Sign in with Apple.
//

import SwiftUI

struct LoginRequiredSheet: View {
    let actionTitle: String        // es. "Salva nel mio Dossier"
    let reason: String             // es. "Per salvare i preventivi associati a un immobile…"
    var onGoToProfile: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ADColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: ADSpacing.s5) {
                hero
                benefitsList
                Spacer(minLength: 0)
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
            .padding(.top, ADSpacing.s5)
            .padding(.bottom, 140)

            ctaBar
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("AREA RISERVATA")
                    .font(ADTypography.metadata.weight(.semibold))
                    .tracking(1.2)
            }
            .foregroundStyle(ADColor.primaryLight)

            Text("Accedi per continuare")
                .font(ADTypography.largeTitle)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(reason)
                .font(ADTypography.body)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.panel))
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Cosa sblocchi accedendo")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            benefitRow(icon: "folder", text: "Un Dossier dedicato per ogni immobile che esplori, sincronizzato tra i tuoi dispositivi.")
            Divider().overlay(ADColor.border.opacity(0.5))
            benefitRow(icon: "creditcard", text: "Il tuo Buyer Passport — il profilo riservato che ti propone immobili coerenti con il tuo percorso.")
            Divider().overlay(ADColor.border.opacity(0.5))
            benefitRow(icon: "doc.text", text: "Scheda completa stampabile con valutazioni, mutuo e preventivi di ristrutturazione.")
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

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(ADColor.primarySoft)
                .frame(width: 28)
            Text(text)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var ctaBar: some View {
        VStack(spacing: ADSpacing.s2) {
            Button {
                onGoToProfile?()
                dismiss()
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Accedi dal Profilo")
                }
            }
            .buttonStyle(.adPrimary)

            Button("Forse più tardi") { dismiss() }
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.textMuted)
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
}

#Preview {
    Text("Host").sheet(isPresented: .constant(true)) {
        LoginRequiredSheet(
            actionTitle: "Salva nel mio Dossier",
            reason: "Per salvare le tue stime e ritrovarle ad ogni accesso, è necessario un account riservato.",
            onGoToProfile: nil
        )
    }
}
