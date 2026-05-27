//
//  AgencyDetailView.swift
//  Domus Arkai
//
//  Pagina dettaglio di una singola agenzia partner:
//  cover image, info, contatti, lista immobili dell'agenzia, CTA "Apri sito agenzia".
//

import SwiftUI

@MainActor
@Observable
final class AgencyDetailViewModel {
    enum Phase: Equatable {
        case idle, loading, loaded, error(String)
    }

    let agency: Agency
    var properties: [Property] = []
    var phase: Phase = .idle

    private let favoritesStore = FavoritesStore.shared

    init(agency: Agency) {
        self.agency = agency
    }

    func load() async {
        phase = .loading
        do {
            // Fetch tutti gli immobili dell'agenzia
            let all = try await PropertyService.shared.fetchPublishedProperties()
            properties = all.filter { $0.agencyID == agency.id }
            phase = .loaded
            print("📦 [AgencyDetail] '\(agency.name)' properties=\(properties.count)")
        } catch {
            phase = .error(error.localizedDescription)
            print("🔴 [AgencyDetail] load failed — \(error)")
        }
    }

    func toggleFavorite(_ property: Property) {
        favoritesStore.toggle(property.id)
    }

    func isFavorite(_ property: Property) -> Bool {
        favoritesStore.contains(property.id)
    }
}

struct AgencyDetailView: View {
    let agency: Agency
    @State private var model: AgencyDetailViewModel

    init(agency: Agency) {
        self.agency = agency
        _model = State(initialValue: AgencyDetailViewModel(agency: agency))
    }

    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                    coverSection
                    headerSection
                    if let desc = agency.description, !desc.isEmpty {
                        descriptionSection(desc)
                    }
                    contactsSection
                    propertiesSection
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.top, ADSpacing.s3)
                .padding(.bottom, ADSpacing.s8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(agency.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .idle = model.phase {
                await model.load()
            }
        }
    }

    // MARK: - Cover

    @ViewBuilder
    private var coverSection: some View {
        if let coverURL = agency.coverImageURL {
            ADColor.surfaceSoft
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                .overlay {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ProgressView().tint(ADColor.primarySoft)
                        default:
                            Image(systemName: "building.2")
                                .font(.system(size: 36))
                                .foregroundStyle(ADColor.textLight)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.card)
                        .stroke(ADColor.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Header (logo + name + city)

    private var headerSection: some View {
        HStack(spacing: ADSpacing.s3) {
            if let logoURL = agency.logoURL {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: ADColor.surfaceSoft
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .stroke(ADColor.border, lineWidth: 1)
                )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .fill(ADColor.primaryLight)
                        .frame(width: 64, height: 64)
                    Image(systemName: "building.2")
                        .font(.system(size: 26))
                        .foregroundStyle(ADColor.primary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(agency.name)
                    .font(ADTypography.sectionTitle.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(2)
                if let city = agency.city {
                    Text(city)
                        .font(ADTypography.small)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Description

    private func descriptionSection(_ desc: String) -> some View {
        Text(desc)
            .font(ADTypography.body)
            .foregroundStyle(ADColor.text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Contatti (Chiama / WhatsApp / Email / Sito)

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Contatti")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            VStack(spacing: ADSpacing.s2) {
                if let phone = agency.phone, !phone.isEmpty {
                    contactRow(icon: "phone.fill", label: "Chiama", value: phone) {
                        openURL("tel://\(phone.replacingOccurrences(of: " ", with: ""))")
                    }
                }
                if let wa = agency.whatsapp, !wa.isEmpty {
                    contactRow(icon: "message.fill", label: "WhatsApp", value: wa) {
                        let cleaned = wa.replacingOccurrences(of: " ", with: "")
                                        .replacingOccurrences(of: "+", with: "")
                        openURL("https://wa.me/\(cleaned)")
                    }
                }
                if let email = agency.email, !email.isEmpty {
                    contactRow(icon: "envelope.fill", label: "Email", value: email) {
                        openURL("mailto:\(email)")
                    }
                }
                if let address = agency.address, !address.isEmpty {
                    contactRow(icon: "mappin.and.ellipse", label: "Indirizzo", value: address) {
                        let q = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        openURL("https://maps.apple.com/?q=\(q)")
                    }
                }
                if let pwa = agency.pwaURL {
                    openSiteCTA(url: pwa, title: "Apri sito agenzia")
                } else if let web = agency.website {
                    openSiteCTA(url: web, title: "Apri sito web")
                }
            }
        }
    }

    private func contactRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ADColor.primarySoft)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(ADTypography.metadata.weight(.medium))
                        .foregroundStyle(ADColor.textMuted)
                    Text(value)
                        .font(ADTypography.smallMedium)
                        .foregroundStyle(ADColor.text)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ADColor.textLight)
            }
            .padding(.horizontal, ADSpacing.s3)
            .padding(.vertical, ADSpacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func openSiteCTA(url: URL, title: String) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(ADTypography.smallMedium.weight(.semibold))
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, ADSpacing.s4)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .fill(ADColor.primary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Properties dell'agenzia

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack {
                Text("Immobili di questa agenzia")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
                Spacer()
                if case .loaded = model.phase {
                    Text("\(model.properties.count)")
                        .font(ADTypography.metadata.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                }
            }

            switch model.phase {
            case .idle, .loading:
                VStack(spacing: ADSpacing.s3) {
                    ForEach(0..<2, id: \.self) { _ in PropertyCardSkeleton() }
                }
            case .loaded:
                if model.properties.isEmpty {
                    ADEmptyState(
                        icon: "house",
                        title: "Nessun immobile pubblicato",
                        message: "Questa agenzia non ha ancora immobili attivi sulla piattaforma."
                    )
                } else {
                    VStack(spacing: ADSpacing.s4) {
                        ForEach(model.properties) { property in
                            NavigationLink(value: property) {
                                PropertyCard(
                                    property: property,
                                    isFavorite: model.isFavorite(property),
                                    onTapFavorite: { model.toggleFavorite(property) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            case .error(let msg):
                ADErrorState(message: msg) {
                    Task { await model.load() }
                }
            }
        }
    }

    private func openURL(_ string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
}
