//
//  PropertyValuationView.swift
//  Domus Arkai
//
//  AVM premium view — sheet aperto da PropertyDetailView.
//  Linguaggio istituzionale (mai "algoritmo proprietario"), zero formule esposte.
//

import SwiftUI

struct PropertyValuationView: View {
    @State var model: PropertyValuationViewModel
    @State private var dossierVM: PropertyDossierViewModel
    @State private var auth = AuthService.shared
    @State private var saveState: DossierSaveBar.State = .idle
    @State private var showLoginRequired: Bool = false

    @Environment(\.dismiss) private var dismiss

    init(model: PropertyValuationViewModel) {
        _model = State(initialValue: model)
        _dossierVM = State(initialValue: PropertyDossierViewModel(property: model.property))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        headerCard
                        contentBlock
                        disclaimerNote
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 130)
                }
                .scrollIndicators(.hidden)

                if model.valuation != nil {
                    DossierSaveBar(
                        state: saveState,
                        isEnabled: true,
                        caption: "La valutazione di zona verrà associata al tuo Dossier per questo immobile."
                    ) {
                        Task { await handleSave() }
                    }
                }
            }
            .navigationTitle("Valutazione immobile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                if model.valuation == nil {
                    await model.compute()
                }
                if auth.isAuthenticated, dossierVM.dossier == nil {
                    await dossierVM.load()
                }
            }
            .sheet(isPresented: $showLoginRequired) {
                LoginRequiredSheet(
                    actionTitle: "Salva nel mio Dossier",
                    reason: "Per conservare la valutazione di zona insieme agli altri preventivi, accedi al tuo profilo riservato.",
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

    // MARK: - Save

    private func handleSave() async {
        guard let valuation = model.valuation else { return }
        guard auth.isAuthenticated else {
            print("🟡 [AVM][Save] gate auth — showing LoginRequiredSheet")
            showLoginRequired = true
            return
        }
        saveState = .saving
        do {
            _ = try await dossierVM.saveAVM(
                zoneID: valuation.zone.id,
                estimatedPerSqm: valuation.estimatedValuePerSqm,
                estimatedTotal: valuation.estimatedTotalValue
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

    // MARK: - Sections

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: "location.viewfinder")
                    .foregroundStyle(ADColor.primarySoft)
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.property.title)
                        .font(ADTypography.cardTitle)
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(2)
                    Text(model.property.locationLine)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: ADSpacing.s2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    @ViewBuilder
    private var contentBlock: some View {
        switch model.state {
        case .idle, .loading:
            loadingBlock
        case .loaded:
            if model.valuation != nil { resultBlock } else { loadingBlock }
        case .unavailable(let msg):
            unavailableBlock(message: msg)
        case .error(let msg):
            errorBlock(message: msg)
        }
    }

    private var loadingBlock: some View {
        VStack(spacing: ADSpacing.s3) {
            ProgressView().tint(ADColor.primarySoft)
            Text("Recupero parametri di riferimento per la zona…")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ADSpacing.s8)
    }

    private func unavailableBlock(message: String) -> some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text("Stima non disponibile")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text(message)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ADSpacing.s8)
    }

    private func errorBlock(message: String) -> some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(ADColor.warning)
            Text(message)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Riprova") {
                Task { await model.compute() }
            }
            .buttonStyle(.adSecondary(fullWidth: false))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ADSpacing.s6)
    }

    @ViewBuilder
    private var resultBlock: some View {
        valuationCard
        zoneCard
        comparisonCard
        marketRangeCard
    }

    private var valuationCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Valore di riferimento")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.primaryLight.opacity(0.95))
                .tracking(0.5)

            Text(model.formattedTotal)
                .font(ADTypography.priceLarge)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(model.formattedPerSqm)
                .font(ADTypography.smallMedium)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var zoneCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(ADColor.primarySoft)
                    .font(.system(size: 16))
                Text("Zona analizzata")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
            }
            Text(model.zoneLabel)
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
                .lineLimit(2)
            if let dist = model.distanceLabel {
                Text(dist)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
            }
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

    @ViewBuilder
    private var comparisonCard: some View {
        if let comp = model.priceComparison {
            HStack(alignment: .top, spacing: ADSpacing.s3) {
                Image(systemName: comp.isAlignment ? "checkmark.seal" : "info.circle")
                    .foregroundStyle(comp.isAlignment ? ADColor.primarySoft : ADColor.accentWarm)
                    .font(.system(size: 20))
                Text(comp.label)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(ADSpacing.Card.paddingLarge)
            .background(comp.isAlignment ? ADColor.primaryLight.opacity(0.4) : ADColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
    }

    private var marketRangeCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Riferimenti di mercato")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
            Text(model.marketRangeLabel)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
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

    private var disclaimerNote: some View {
        Text("Questo report è stato redatto sulla base dei parametri di riferimento di Arkai Domus per il mercato residenziale di pregio. L'analisi considera le caratteristiche essenziali dell'immobile come ubicazione, superficie, stato conservativo e pertinenze, in linea con gli standard professionali del settore.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ADSpacing.s2)
    }
}
