//
//  HomeViewModel.swift
//  Domus Arkai
//

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    var properties: [Property] = []
    /// Legacy: la "primary agency" per backwards compat (alcune view la usano ancora).
    var agency: Agency?
    /// Mappa agency_id → Agency per resolve veloce nel rendering (PropertyCard, PropertyDetail).
    var agencyByID: [UUID: Agency] = [:]
    var filters: SearchFilters = SearchFilters()
    var loadState: LoadState = .idle

    private let favoritesStore = FavoritesStore.shared

    /// Restituisce il nome dell'agenzia per una property (nil se non risolto).
    func agencyName(for property: Property) -> String? {
        guard let aid = property.agencyID else { return nil }
        return agencyByID[aid]?.name
    }

    /// Properties in vetrina (is_featured = true) per hero carousel.
    var featuredProperties: [Property] {
        properties.filter { $0.isFeatured }
    }

    /// Properties non in vetrina, ordinate per più recenti — "Nuovi Arrivi".
    var newArrivals: [Property] {
        properties.filter { !$0.isFeatured }
    }

    /// True se ci sono filtri attivi (in tal caso saltiamo la sezione featured/new arrivals
    /// e mostriamo i risultati come lista piatta tipica della search).
    var hasActiveFilters: Bool {
        !filters.isEmpty
    }

    func load() async {
        loadState = .loading
        async let agenciesTask: [Agency] = (try? await AgencyService.shared.fetchAllAgencies()) ?? []
        do {
            let fetched = try await PropertyService.shared.fetchPublishedProperties()
            let allAgencies = await agenciesTask
            agencyByID = Dictionary(uniqueKeysWithValues: allAgencies.map { ($0.id, $0) })
            agency = allAgencies.first  // legacy retrocompat
            let filtered = applyLocalFilters(to: fetched)
            properties = filtered
            loadState = filtered.isEmpty ? .empty : .loaded
            print("📦 [Home] loaded properties=\(filtered.count) agencies=\(allAgencies.count)")
        } catch {
            loadState = .error(error.localizedDescription)
            print("🔴 [Home] load failed — \(error)")
        }
    }

    /// Filtri client-side temporanei finché non muoveremo i predicati su Supabase.
    /// Tutti i 7 filtri SearchFilters: query, contractType, propertyTypes, priceMin/Max,
    /// surfaceMin/Max, minRooms, features (terrazza/giardino/box/ascensore/ristrutturato).
    private func applyLocalFilters(to source: [Property]) -> [Property] {
        source.filter { property in
            if !filters.query.isEmpty {
                let haystack = "\(property.title) \(property.locationLine)".lowercased()
                if !haystack.contains(filters.query.lowercased()) { return false }
            }
            if let contract = filters.contractType, property.contractType != contract { return false }
            if !filters.propertyTypes.isEmpty {
                guard let type = property.propertyType, filters.propertyTypes.contains(type) else { return false }
            }
            if let pmin = filters.priceMin, (property.price ?? 0) < pmin { return false }
            if let pmax = filters.priceMax, (property.price ?? .infinity) > pmax { return false }
            if let smin = filters.surfaceMin, (property.surfaceCommercial ?? 0) < smin { return false }
            if let smax = filters.surfaceMax, (property.surfaceCommercial ?? .infinity) > smax { return false }
            if let minRooms = filters.minRooms, (property.rooms ?? 0) < minRooms { return false }
            if !filters.agencyIDs.isEmpty {
                guard let aid = property.agencyID, filters.agencyIDs.contains(aid) else { return false }
            }
            for feature in filters.features {
                switch feature {
                case .terrazza:      if !property.hasTerrace { return false }
                case .giardino:      if !property.hasGarden { return false }
                case .box:           if !(property.hasGarage || property.hasParking) { return false }
                case .ascensore:     if !property.hasElevator { return false }
                case .ristrutturato:
                    let cond = (property.conditionStatus ?? "").lowercased()
                    if !(cond.contains("ristruttur") || cond.contains("nuovo")) { return false }
                }
            }
            return true
        }
    }

    func toggleFavorite(_ property: Property) {
        favoritesStore.toggle(property.id)
    }

    func isFavorite(_ property: Property) -> Bool {
        favoritesStore.contains(property.id)
    }

    func updateFilter(query: String) {
        filters.query = query
    }
}
