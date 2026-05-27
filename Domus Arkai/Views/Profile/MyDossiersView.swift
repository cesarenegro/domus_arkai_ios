//
//  MyDossiersView.swift
//  Domus Arkai
//
//  Lista degli immobili per cui l'utente ha creato un Dossier (con sotto-calcoli salvati).
//

import SwiftUI
import Auth

@MainActor
@Observable
final class MyDossiersListModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    var phase: Phase = .idle
    var entries: [(dossier: PropertyDossier, property: Property)] = []

    func load() async {
        guard let uid = AuthService.shared.currentUser?.id else {
            phase = .idle
            return
        }
        phase = .loading
        do {
            let dossiers = try await DossierService.shared.listMyDossiers(userID: uid)
            let propertyIDs = Array(Set(dossiers.map { $0.propertyID }))
            let properties = try await PropertyService.shared.fetchProperties(byIDs: propertyIDs)
            let propertyByID = Dictionary(uniqueKeysWithValues: properties.map { ($0.id, $0) })

            entries = dossiers.compactMap { d in
                guard let p = propertyByID[d.propertyID] else { return nil }
                return (dossier: d, property: p)
            }
            phase = .loaded
            print("✅ [MyDossiers] loaded \(entries.count) entries")
        } catch {
            print("🔴 [MyDossiers] load failed — \(error)")
            phase = .error("Impossibile caricare i tuoi Dossier.")
        }
    }
}

struct MyDossiersView: View {
    /// Quando `true`, mostra il pulsante "Chiudi" (caso sheet). Default false (tab).
    var presentedAsSheet: Bool = false

    @State private var listModel = MyDossiersListModel()
    @State private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                if auth.isAuthenticated {
                    content
                } else {
                    notAuthenticatedView
                }
            }
            .navigationTitle("I miei Dossier")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if presentedAsSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Chiudi") { dismiss() }
                            .foregroundStyle(ADColor.primary)
                    }
                }
            }
            .task {
                if auth.isAuthenticated, case .idle = listModel.phase {
                    await listModel.load()
                }
            }
            .onChange(of: auth.isAuthenticated) { _, isAuth in
                if isAuth {
                    Task { await listModel.load() }
                } else {
                    listModel.entries = []
                    listModel.phase = .idle
                }
            }
            .refreshable {
                if auth.isAuthenticated { await listModel.load() }
            }
        }
    }

    private var notAuthenticatedView: some View {
        VStack(spacing: ADSpacing.s4) {
            Spacer()
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text("Accedi per visualizzare i tuoi Dossier")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
                .multilineTextAlignment(.center)
            Text("Vai sul tab Profilo e accedi con il tuo ID Apple per attivare i Dossier personali.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ADSpacing.s6)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch listModel.phase {
        case .idle, .loading:
            loadingView
        case .loaded:
            if listModel.entries.isEmpty {
                emptyView
            } else {
                listView
            }
        case .error(let msg):
            errorView(msg)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView().tint(ADColor.primarySoft)
            Text("Carico i tuoi Dossier…")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .padding(.top, ADSpacing.s3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: ADSpacing.s3) {
            Spacer()
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text("Nessun Dossier ancora")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text("Quando salverai una stima da un immobile (valutazione, mutuo, ristrutturazione o analisi visiva), la troverai qui.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ADSpacing.s5)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: ADSpacing.s3) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(ADColor.warning)
            Text(message)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Riprova") {
                Task { await listModel.load() }
            }
            .buttonStyle(.adSecondary(fullWidth: false))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: ADSpacing.s3) {
                ForEach(listModel.entries, id: \.dossier.id) { entry in
                    NavigationLink {
                        PropertyDetailView(property: entry.property)
                    } label: {
                        rowCard(dossier: entry.dossier, property: entry.property)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
            .padding(.top, ADSpacing.s3)
            .padding(.bottom, ADSpacing.s8)
        }
        .scrollIndicators(.hidden)
    }

    private func rowCard(dossier: PropertyDossier, property: Property) -> some View {
        HStack(spacing: ADSpacing.s3) {
            AsyncImage(url: property.coverImageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    ADColor.surfaceSoft
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))

            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(2)
                Text(property.locationLine)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
                HStack(spacing: ADSpacing.s2) {
                    if let total = dossier.totalInvestment {
                        Text(MyDossiersView.formatEuro(total))
                            .font(ADTypography.smallMedium.weight(.semibold))
                            .foregroundStyle(ADColor.primary)
                            .lineLimit(1)
                            .monospacedDigit()
                    }
                    badgesFor(dossier)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .foregroundStyle(ADColor.textLight)
                .font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.s3)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func badgesFor(_ d: PropertyDossier) -> some View {
        HStack(spacing: 3) {
            if d.avmEstimatedTotal != nil { dot(color: ADColor.primarySoft) }
            if d.mortgageMonthlyPayment != nil { dot(color: ADColor.primarySoft) }
            if d.renovationTotal != nil { dot(color: ADColor.accentWarm) }
            if d.visualBOQTotal != nil { dot(color: ADColor.accentWarm) }
        }
    }

    private func dot(color: Color) -> some View {
        Circle().fill(color).frame(width: 6, height: 6)
    }

    private static func formatEuro(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "—"
    }
}

#Preview {
    MyDossiersView()
}
