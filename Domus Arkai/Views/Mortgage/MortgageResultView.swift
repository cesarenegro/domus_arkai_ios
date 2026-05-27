//
//  MortgageResultView.swift
//  Domus Arkai
//
//  Spec: `09_ios_mortgage_result.json`.
//

import SwiftUI

struct MortgageResultView: View {
    let estimate: MortgageEstimate
    let property: Property

    @State private var dossierVM: PropertyDossierViewModel
    @State private var auth = AuthService.shared
    @State private var saveState: DossierSaveBar.State = .idle
    @State private var showLoginRequired: Bool = false

    @Environment(\.dismiss) private var dismiss

    init(estimate: MortgageEstimate, property: Property) {
        self.estimate = estimate
        self.property = property
        _dossierVM = State(initialValue: PropertyDossierViewModel(property: property))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        mainResultCard
                        sustainabilityBar
                        summaryCard
                        disclaimer
                        consultationButton
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s5)
                    .padding(.bottom, 130)
                }

                DossierSaveBar(
                    state: saveState,
                    isEnabled: true,
                    caption: "La stima del mutuo verrà associata al tuo Dossier per questo immobile."
                ) {
                    Task { await handleSave() }
                }
            }
            .navigationTitle("Risultato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                if auth.isAuthenticated, dossierVM.dossier == nil {
                    await dossierVM.load()
                }
            }
            .sheet(isPresented: $showLoginRequired) {
                LoginRequiredSheet(
                    actionTitle: "Salva nel mio Dossier",
                    reason: "Per conservare la stima del mutuo insieme agli altri preventivi, accedi al tuo profilo riservato.",
                    onGoToProfile: nil
                )
            }
            .alert("Salvataggio non riuscito", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { saveState = .idle }
            } message: {
                Text(currentErrorMessage)
            }
        }
    }

    private func handleSave() async {
        guard auth.isAuthenticated else {
            print("🟡 [Mortgage][Save] gate auth — showing LoginRequiredSheet")
            showLoginRequired = true
            return
        }
        saveState = .saving
        do {
            _ = try await dossierVM.saveMortgage(
                estimateID: nil,
                monthlyPayment: estimate.estimatedMonthlyPayment
            )
            saveState = .success
        } catch {
            saveState = .failure(error.localizedDescription)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failure = saveState { return true }
                return false
            },
            set: { if !$0 { saveState = .idle } }
        )
    }

    private var currentErrorMessage: String {
        if case .failure(let msg) = saveState { return msg }
        return ""
    }

    private var mainResultCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Rata mensile stimata")
                .font(ADTypography.smallMedium)
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: ADSpacing.s2) {
                Text(estimate.estimatedMonthlyPayment.formattedEuro())
                    .font(.system(size: 40, weight: .semibold, design: .default).monospacedDigit())
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("/ mese")
                    .font(ADTypography.body)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.panel))
    }

    private var sustainabilityBar: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack {
                Text("Sostenibilità")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
                Spacer()
                Text(estimate.sustainabilityStatus.label)
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ADColor.primaryLight)
                    Capsule()
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(estimate.incomeRatio / 0.5, 1))
                }
            }
            .frame(height: 10)

            HStack {
                Text("Buona")
                Spacer()
                Text("Da verificare")
                Spacer()
                Text("Critica")
            }
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
        }
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var statusColor: Color {
        switch estimate.sustainabilityStatus {
        case .good: ADColor.primarySoft
        case .warning: ADColor.accentWarm
        case .critical: ADColor.warning
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 0) {
            row("Importo mutuo indicativo", estimate.estimatedLoanAmount.formattedEuro())
            row("Anticipo", estimate.availableDeposit.formattedEuro())
            row("Durata", "\(estimate.mortgageYears) anni")
            row("Tasso applicato", String(format: "%.2f%%", estimate.interestRate * 100))
            row("Incidenza sul reddito", String(format: "%.0f%%", estimate.incomeRatio * 100), isLast: true)
        }
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func row(_ label: String, _ value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: ADSpacing.s3) {
                Text(label)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
                Spacer(minLength: ADSpacing.s2)
                Text(value)
                    .font(ADTypography.smallMedium)
                    .foregroundStyle(ADColor.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
            if !isLast {
                Divider().overlay(ADColor.border.opacity(0.6))
            }
        }
    }

    private var disclaimer: some View {
        Text("Questa valutazione è indicativa e non costituisce approvazione formale da parte di istituti bancari.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textMuted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(ADSpacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var consultationButton: some View {
        Button("Richiedi consulenza") {
            // placeholder → genera lead source=mortgage_calculator
        }
        .buttonStyle(.adSecondary)
    }
}
