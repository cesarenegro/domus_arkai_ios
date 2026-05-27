//
//  SearchFilters.swift
//  Domus Arkai
//

import Foundation

struct SearchFilters: Hashable, Sendable {
    var query: String = ""
    var contractType: ContractType?
    var propertyTypes: Set<PropertyType> = []
    var priceMin: Double?
    var priceMax: Double?
    var surfaceMin: Double?
    var surfaceMax: Double?
    var minRooms: Int?
    var features: Set<Feature> = []
    /// Filtro per agenzia (multi-select). Vuoto = tutte le agenzie.
    var agencyIDs: Set<UUID> = []

    enum Feature: String, Hashable, Sendable, CaseIterable {
        case terrazza, giardino, box, ascensore, ristrutturato

        var displayName: String {
            switch self {
            case .terrazza: "Terrazza"
            case .giardino: "Giardino"
            case .box: "Box"
            case .ascensore: "Ascensore"
            case .ristrutturato: "Ristrutturato"
            }
        }
    }

    var isEmpty: Bool {
        query.isEmpty
            && contractType == nil
            && propertyTypes.isEmpty
            && priceMin == nil && priceMax == nil
            && surfaceMin == nil && surfaceMax == nil
            && minRooms == nil
            && features.isEmpty
            && agencyIDs.isEmpty
    }
}
