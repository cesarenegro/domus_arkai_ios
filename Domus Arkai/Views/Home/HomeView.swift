//
//  HomeView.swift
//  Domus Arkai
//
//  Spec: `02_ios_home_property_feed.json`. Token design system rigorosamente AD*.
//

import SwiftUI

struct HomeView: View {
    enum ActiveSheet: Identifiable {
        case filters, inbox, map
        var id: Self { self }
    }

    @State private var model = HomeViewModel()
    @State private var inboxModel = NotificationInboxViewModel()
    @State private var searchText: String = ""
    @State private var activeSheet: ActiveSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: ADSpacing.s5) {
                        searchBar
                        quickFiltersRow
                        contentSection
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await model.load()
                }
            }
            .navigationTitle("Arkai Domus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeSheet = .map
                    } label: {
                        Image(systemName: "map")
                            .foregroundStyle(ADColor.primary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .inbox
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: inboxModel.unreadCount > 0 ? "bell.fill" : "bell")
                                .foregroundStyle(ADColor.primary)
                                .frame(width: 28, height: 28)

                            if inboxModel.unreadCount > 0 {
                                Text(inboxModel.unreadCount > 9 ? "9+" : "\(inboxModel.unreadCount)")
                                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 6, y: -6)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(for: Property.self) { property in
                PropertyDetailView(property: property)
            }
            .navigationDestination(for: Agency.self) { agency in
                AgencyDetailView(agency: agency)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .filters:
                    SearchFiltersView(filters: $model.filters) {
                        Task { await model.load() }
                    }
                case .inbox:
                    NotificationInboxView(model: inboxModel)
                case .map:
                    PropertiesMapView()
                }
            }
            .task {
                if model.loadState == .idle {
                    await model.load()
                }
                await inboxModel.load()
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: ADSpacing.s2) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ADColor.textMuted)
                TextField("Cerca per zona, indirizzo, tipologia…", text: $searchText)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            model.updateFilter(query: searchText)
                            await model.load()
                        }
                    }
            }
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 46)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.input)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.input))

            Button {
                activeSheet = .filters
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ADColor.primary)
                    .frame(width: 46, height: 46)
                    .background(ADColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ADRadius.input)
                            .stroke(ADColor.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ADRadius.input))
            }
            .buttonStyle(.plain)
        }
    }

    private var quickFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ADSpacing.s2) {
                FilterPill(label: "Milano", isSelected: true) {}
                FilterPill(label: "Vendita", isSelected: model.filters.contractType == .vendita) {
                    Task {
                        model.filters.contractType = model.filters.contractType == .vendita ? nil : .vendita
                        await model.load()
                    }
                }
                FilterPill(label: "€300k–€800k", isSelected: false) {}
                FilterPill(label: "80–150 mq", isSelected: false) {}
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch model.loadState {
        case .idle, .loading:
            VStack(spacing: ADSpacing.s4) {
                ForEach(0..<3, id: \.self) { _ in
                    PropertyCardSkeleton()
                }
            }

        case .loaded:
            if model.hasActiveFilters {
                filteredResults
            } else {
                editorialFeed
            }

        case .empty:
            ADEmptyState(
                icon: "house",
                title: "Nessun immobile trovato",
                message: "Prova a modificare la ricerca o i filtri per vedere altre proposte."
            )

        case .error(let msg):
            ADErrorState(message: msg) {
                Task { await model.load() }
            }
        }
    }

    // MARK: - Editorial feed (no filtri attivi)

    private var editorialFeed: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s6) {
            if !model.featuredProperties.isEmpty {
                heroCarousel
            }
            if !model.newArrivals.isEmpty {
                newArrivalsSection
            }
        }
    }

    private var heroCarousel: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("In Vetrina")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            TabView {
                ForEach(model.featuredProperties) { property in
                    NavigationLink(value: property) {
                        heroCard(property)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 2)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .frame(height: 320)
        }
    }

    private func heroCard(_ property: Property) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: property.coverImageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .empty:
                    ADColor.surfaceSoft.overlay(ProgressView().tint(ADColor.primarySoft))
                default:
                    ADColor.surfaceSoft
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 290)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                startPoint: .center, endPoint: .bottom
            )
            .frame(height: 290)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                HStack {
                    Text("IN VETRINA")
                        .font(ADTypography.metadata.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, ADSpacing.s3)
                        .padding(.vertical, 5)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                    Spacer()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.title)
                        .font(ADTypography.sectionTitle.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: ADSpacing.s2) {
                        Text(property.city ?? "—")
                            .font(ADTypography.small)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer(minLength: ADSpacing.s2)
                        Text(property.formattedPrice)
                            .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            }
            .padding(ADSpacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 290)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 0.5)
        )
    }

    private var newArrivalsSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Nuovi Arrivi")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            VStack(spacing: ADSpacing.s4) {
                ForEach(model.newArrivals) { property in
                    NavigationLink(value: property) {
                        PropertyCard(
                            property: property,
                            isFavorite: model.isFavorite(property),
                            onTapFavorite: { model.toggleFavorite(property) },
                            agencyName: model.agencyName(for: property)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Filtered results (lista piatta quando ci sono filtri attivi)

    private var filteredResults: some View {
        VStack(spacing: ADSpacing.s4) {
            ForEach(model.properties) { property in
                NavigationLink(value: property) {
                    PropertyCard(
                        property: property,
                        isFavorite: model.isFavorite(property),
                        onTapFavorite: { model.toggleFavorite(property) },
                        agencyName: model.agencyName(for: property)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    HomeView()
}
