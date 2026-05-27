//
//  MarketPrice.swift
//  Domus Arkai
//
//  Models per AVM (Automated Valuation Model) geolocalizzato.
//  Schema 1:1 con tabelle `property_market_prices` + `market_adjustment_factors`.
//

import Foundation

/// Riga zona OMI/Portali per AVM, con join multipliers condizione (dalla RPC).
struct MarketPriceZone: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let city: String
    let zoneName: String
    let latitude: Double
    let longitude: Double
    let precisionLevel: String?
    let marketAvgSqm: Double
    let omiMinSqm: Double
    let omiMaxSqm: Double
    let omiAvgSqm: Double
    let distanceKm: Double?
    let multiplierNormal: Double?
    let multiplierToRenovate: Double?
    let multiplierNewExcellent: Double?
    /// Tenuto come String per evitare crash decoding (il backend usa formato "yyyy-MM-dd",
    /// non ISO8601 completo, che il decoder di default di Supabase Swift non accetta).
    let lastUpdatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, city
        case zoneName = "zone_name"
        case latitude, longitude
        case precisionLevel = "precision_level"
        case marketAvgSqm = "market_avg_sqm"
        case omiMinSqm = "omi_min_sqm"
        case omiMaxSqm = "omi_max_sqm"
        case omiAvgSqm = "omi_avg_sqm"
        case distanceKm = "distance_km"
        case multiplierNormal = "multiplier_normal"
        case multiplierToRenovate = "multiplier_to_renovate"
        case multiplierNewExcellent = "multiplier_new_excellent"
        case lastUpdatedAt = "last_updated_at"
    }
}

/// Stato di conservazione → multiplier corrispondente.
enum ConditionMultiplier {
    case toRenovate
    case normal
    case newOrExcellent

    static func from(_ status: String?) -> ConditionMultiplier {
        let s = status?.lowercased() ?? "normal"
        if s.contains("ristruttur") || s.contains("renov") { return .toRenovate }
        if s.contains("nuovo") || s.contains("ottim") || s.contains("excellent") || s.contains("new") { return .newOrExcellent }
        return .normal
    }

    func multiplier(from zone: MarketPriceZone) -> Double {
        switch self {
        case .toRenovate: return zone.multiplierToRenovate ?? 0.65
        case .normal: return zone.multiplierNormal ?? 0.80
        case .newOrExcellent: return zone.multiplierNewExcellent ?? 1.0
        }
    }
}

/// Risultato finale stima AVM.
struct PropertyValuation: Identifiable, Hashable, Sendable {
    let id: UUID
    let zone: MarketPriceZone
    let conditionMultiplier: Double
    let floorAdjustment: Double          // -5% piano terra, +20% attico, ecc.
    let surfaceCommercial: Double
    let estimatedValuePerSqm: Double     // OMI clamped
    let estimatedTotalValue: Double      // valuePerSqm × surface
}
