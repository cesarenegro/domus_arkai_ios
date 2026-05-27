//
//  VisualBOQResultView.swift
//  Domus Arkai
//
//  Risultato analisi Arkai Vision Pro: lista interventi stimati + costo totale.
//  Linguaggio istituzionale, mai citare fornitori o formule interne.
//

import SwiftUI

struct VisualBOQResultView: View {
    @Bindable var model: VisualBOQViewModel
    @State private var dossierVM: PropertyDossierViewModel?
    @State private var auth = AuthService.shared
    @State private var saveState: DossierSaveBar.State = .idle
    @State private var showLoginRequired: Bool = false

    @Environment(\.dismiss) private var dismiss

    init(model: VisualBOQViewModel) {
        self.model = model
        if let property = model.property {
            _dossierVM = State(initialValue: PropertyDossierViewModel(property: property))
        } else {
            _dossierVM = State(initialValue: nil)
        }
    }

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    private static let quantityFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        if let result = model.result {
                            summaryCard(for: result)
                            detectedConditionsCard(for: result)
                            worksSection(for: result)
                            disclaimer
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 130)
                }
                .scrollIndicators(.hidden)

                stickyBar
            }
            .navigationTitle("Stima ambiente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                if let vm = dossierVM, auth.isAuthenticated, vm.dossier == nil {
                    await vm.load()
                }
            }
            .sheet(isPresented: $showLoginRequired) {
                LoginRequiredSheet(
                    actionTitle: "Salva nel mio Dossier",
                    reason: "Per conservare le analisi degli ambienti insieme agli altri preventivi, accedi al tuo profilo riservato.",
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
        guard let result = model.result, let dossierVM else { return }
        guard auth.isAuthenticated else {
            print("🟡 [VisionPRO][Save] gate auth — showing LoginRequiredSheet")
            showLoginRequired = true
            return
        }
        saveState = .saving
        do {
            _ = try await dossierVM.appendVisualBOQ(
                estimateID: result.estimateID,
                cost: result.totalEstimatedCost
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

    private func summaryCard(for result: VisualBOQResponse) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("ARKAI VISION PRO")
                    .font(ADTypography.metadata.weight(.semibold))
                    .tracking(1.2)
            }
            .foregroundStyle(ADColor.primaryLight)

            Text("Costo indicativo stimato")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .tracking(0.5)

            Text(formatCurrency(result.totalEstimatedCost))
                .font(ADTypography.priceLarge)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(roomLine(for: result))
                .font(ADTypography.small)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    @ViewBuilder
    private func detectedConditionsCard(for result: VisualBOQResponse) -> some View {
        if !result.detectedConditions.isEmpty {
            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                Text("Condizioni rilevate")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
                ForEach(result.detectedConditions, id: \.self) { condition in
                    HStack(alignment: .top, spacing: ADSpacing.s2) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(ADColor.primarySoft)
                            .padding(.top, 2)
                        Text(condition.capitalizedFirst)
                            .font(ADTypography.body)
                            .foregroundStyle(ADColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
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
    }

    private func worksSection(for result: VisualBOQResponse) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Interventi previsti")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            if result.estimatedWorks.isEmpty {
                Text("Nessun intervento rilevante segnalato per questo ambiente.")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(result.estimatedWorks.enumerated()), id: \.element.id) { idx, work in
                        workRow(work)
                        if idx < result.estimatedWorks.count - 1 {
                            Divider().overlay(ADColor.border.opacity(0.5))
                        }
                    }
                }
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.card)
                        .stroke(ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            }
        }
    }

    private func workRow(_ work: VisualBOQWork) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            HStack(alignment: .firstTextBaseline, spacing: ADSpacing.s3) {
                Text(work.description)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: ADSpacing.s2)
                Text(formatCurrency(work.totalCost))
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.text)
                    .lineLimit(1)
                    .monospacedDigit()
            }
            HStack(spacing: ADSpacing.s3) {
                Text(quantityLine(quantity: work.quantity, unit: work.unit))
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                Spacer(minLength: ADSpacing.s2)
                Text(unitCostLine(unitCost: work.unitCost, unit: work.unit))
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
    }

    private var disclaimer: some View {
        Text("La stima è elaborata sulla base delle informazioni visive fornite e dei parametri di mercato di Arkai Domus. I valori indicati hanno carattere puramente orientativo: il computo definitivo richiede un sopralluogo tecnico e l'analisi di un professionista abilitato.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ADSpacing.s2)
    }

    private var emptyState: some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text("Nessuna stima disponibile")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text("Riprova ad analizzare la stanza con foto più nitide.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ADSpacing.s8)
    }

    // MARK: - Sticky bar

    private var stickyBar: some View {
        Group {
            if dossierVM != nil {
                VStack(spacing: ADSpacing.s3) {
                    retakeButton
                    saveDossierButton
                }
            } else {
                HStack(spacing: ADSpacing.s3) {
                    retakeButton
                    Button { dismiss() } label: { Text("Chiudi") }
                        .buttonStyle(.adPrimary)
                }
            }
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

    private var retakeButton: some View {
        Button {
            model.resetToCapture()
            dismiss()
        } label: {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                Text("Nuova analisi")
            }
        }
        .buttonStyle(.adSecondary)
    }

    @ViewBuilder
    private var saveDossierButton: some View {
        Button {
            Task { await handleSave() }
        } label: {
            HStack(spacing: ADSpacing.s2) {
                switch saveState {
                case .saving:
                    ProgressView().tint(.white)
                    Text("Salvataggio…")
                case .success:
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Salvato nel Dossier")
                case .idle, .failure:
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Salva nel mio Dossier")
                }
            }
        }
        .buttonStyle(.adPrimary)
        .disabled(saveState == .saving)
    }

    // MARK: - Helpers

    private func roomLine(for result: VisualBOQResponse) -> String {
        let room = result.detectedRoomType.capitalizedFirst
        let city = model.city.isEmpty ? "—" : model.city
        return "\(room) · \(city)"
    }

    private func formatCurrency(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
    }

    private func quantityLine(quantity: Double, unit: String) -> String {
        let q = Self.quantityFormatter.string(from: NSNumber(value: quantity)) ?? "\(quantity)"
        return "Quantità · \(q) \(unit)"
    }

    private func unitCostLine(unitCost: Double, unit: String) -> String {
        "\(formatCurrency(unitCost)) / \(unit)"
    }
}

private extension String {
    var capitalizedFirst: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

#Preview {
    let model = VisualBOQViewModel(property: nil)
    model.result = VisualBOQResponse(
        estimateID: UUID(),
        detectedRoomType: "bagno",
        detectedConditions: ["Rivestimenti datati", "Sanitari da sostituire"],
        estimatedWorks: [
            VisualBOQWork(
                workCode: "demolition_floor",
                description: "Demolizione pavimenti e rivestimenti",
                quantity: 9.0,
                unit: "mq",
                unitCost: 35,
                totalCost: 315
            ),
            VisualBOQWork(
                workCode: "hydraulic_points",
                description: "Rifacimento impianto idraulico",
                quantity: 4,
                unit: "punti",
                unitCost: 280,
                totalCost: 1120
            )
        ],
        totalEstimatedCost: 1435
    )
    return VisualBOQResultView(model: model)
}
