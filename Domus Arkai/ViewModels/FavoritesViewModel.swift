//
//  FavoritesViewModel.swift
//  Domus Arkai
//

import Foundation

@MainActor
@Observable
final class FavoritesViewModel {
    var properties: [Property] = []
    var filter: PropertyType?
    var isLoading: Bool = false

    private let store = FavoritesStore.shared

    var availableTypes: [PropertyType] {
        Array(Set(properties.compactMap { $0.propertyType })).sorted { $0.displayName < $1.displayName }
    }

    var filteredProperties: [Property] {
        guard let filter else { return properties }
        return properties.filter { $0.propertyType == filter }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        let ids = Array(store.ids)
        guard !ids.isEmpty else {
            properties = []
            return
        }
        do {
            // Batch fetch invece di N round-trip
            let fetched = try await PropertyService.shared.fetchProperties(byIDs: ids)
            // Mantieni l'ordine dello store (più recente in cima)
            let byID = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            properties = ids.compactMap { byID[$0] }
        } catch {
            print("🔴 [Favorites][VM] load failed — \(error)")
            properties = []
        }
    }

    func remove(_ property: Property) {
        store.remove(property.id)
        properties.removeAll { $0.id == property.id }
    }
}
