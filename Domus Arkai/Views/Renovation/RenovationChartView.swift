//
//  RenovationChartView.swift
//  Domus Arkai
//
//  Spec: `11_ios_renovation_cost_chart.json`. Horizontal bar chart sage-only.
//

import SwiftUI

struct RenovationChartView: View {
    let model: RenovationViewModel

    @State private var dossierVM: PropertyDossierViewModel
    @State private var auth = AuthService.shared
    @State private var showLoginRequired: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveResult: SaveResult?

    @Environment(\.dismiss) private var dismiss

    enum SaveResult: Equatable {
        case success
        case failure(String)
    }

    init(model: RenovationViewModel) {
        self.model = model
        _dossierVM = State(initialValue: PropertyDossierViewModel(property: model.property))
    }

    private var sortedItems: [RenovationItem] {
        model.selectedItems.sorted { model.cost(of: $0) > model.cost(of: $1) }
    }

    private var maxCost: Double {
        sortedItems.map { model.cost(of: $0) }.max() ?? 1
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        header
                        barChart
                        rangesGrid
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s5)
                    .padding(.bottom, 130)
                }

                saveBar
            }
            .navigationTitle("Costi per categoria")
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
                    reason: "Per conservare i preventivi e ritrovarli su ogni dispositivo, accedi al tuo profilo riservato.",
                    onGoToProfile: nil
                )
            }
            .alert("Salvataggio non riuscito", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { saveResult = nil }
            } message: {
                Text(currentErrorMessage)
            }
        }
    }

    // MARK: - Save bar

    private var saveBar: some View {
        VStack(spacing: ADSpacing.s2) {
            Button {
                Task { await handleSave() }
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else if case .success = saveResult {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .semibold))
                    } else {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(saveButtonLabel)
                }
            }
            .buttonStyle(.adPrimary)
            .disabled(isSaving || model.selectedItems.isEmpty)
            .opacity((isSaving || model.selectedItems.isEmpty) ? 0.55 : 1.0)

            Text(model.selectedItems.isEmpty
                 ? "Seleziona almeno un intervento per salvare."
                 : "La stima verrà associata al tuo Dossier per questo immobile.")
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

    private var saveButtonLabel: String {
        if isSaving { return "Salvataggio…" }
        if case .success = saveResult { return "Salvato nel Dossier" }
        return "Salva nel mio Dossier"
    }

    private func handleSave() async {
        guard !model.selectedItems.isEmpty else { return }
        guard auth.isAuthenticated else {
            print("🟡 [Renovation][Save] gate auth — user not authenticated, showing LoginRequiredSheet")
            showLoginRequired = true
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await dossierVM.saveRenovation(
                total: model.total,
                lines: model.dossierLines,
                difficultyFactors: model.selectedDifficultyKeysList
            )
            saveResult = .success
        } catch {
            saveResult = .failure(error.localizedDescription)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failure = saveResult { return true }
                return false
            },
            set: { if !$0 { saveResult = nil } }
        )
    }

    private var currentErrorMessage: String {
        if case .failure(let msg) = saveResult { return msg }
        return ""
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Totale indicativo")
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
            Text(model.total.formattedEuro())
                .font(ADTypography.priceLarge)
                .foregroundStyle(ADColor.primary)
            Text("Livello selezionato: \(model.level.label)")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var barChart: some View {
        VStack(spacing: ADSpacing.s3) {
            ForEach(sortedItems) { item in
                let cost = model.cost(of: item)
                let percentage = model.total > 0 ? cost / model.total : 0
                VStack(alignment: .leading, spacing: ADSpacing.s1) {
                    HStack(spacing: ADSpacing.s2) {
                        Text(item.name)
                            .font(ADTypography.smallMedium)
                            .foregroundStyle(ADColor.text)
                            .lineLimit(1)
                        Spacer(minLength: ADSpacing.s2)
                        Text(cost.formattedEuro())
                            .font(ADTypography.smallMedium.weight(.semibold))
                            .foregroundStyle(ADColor.primary)
                            .lineLimit(1)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ADColor.primaryLight)
                                .frame(height: 8)
                            Capsule()
                                .fill(ADColor.primarySoft)
                                .frame(width: geo.size.width * CGFloat(cost / maxCost), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text(String(format: "%.0f%% del totale", percentage * 100))
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                }
            }
        }
    }

    private var rangesGrid: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Range qualità sui lavori selezionati")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            HStack(spacing: ADSpacing.s3) {
                rangeCard(label: "Essenziale", value: model.totalForLevel.essential, isCurrent: model.level == .essential)
                rangeCard(label: "Medio", value: model.totalForLevel.medium, isCurrent: model.level == .medium)
                rangeCard(label: "Premium", value: model.totalForLevel.premium, isCurrent: model.level == .premium)
            }
        }
    }

    private func rangeCard(label: String, value: Double, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(label)
                .font(ADTypography.metadata.weight(.medium))
                .foregroundStyle(isCurrent ? ADColor.primary : ADColor.textMuted)
                .tracking(0.5)
            Text(value.formattedEuro())
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(isCurrent ? ADColor.primary : ADColor.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingSmall)
        .background(isCurrent ? ADColor.primaryLight : ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(isCurrent ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }
}
