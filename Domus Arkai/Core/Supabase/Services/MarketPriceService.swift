//
//  MarketPriceService.swift
//  Domus Arkai
//
//  AVM (Automated Valuation Model) geolocalizzato.
//  RPC `find_nearest_market_price(user_lat, user_lon)` su Supabase.
//

import Foundation
import Supabase

actor MarketPriceService {
    static let shared = MarketPriceService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Trova la zona OMI più vicina alle coordinate fornite.
    /// La RPC ritorna anche i multipliers di condizione (join automatico via city).
    func findNearestZone(latitude: Double, longitude: Double) async throws -> MarketPriceZone? {
        struct Params: Encodable {
            let user_lat: Double
            let user_lon: Double
        }
        let zones: [MarketPriceZone] = try await client
            .rpc("find_nearest_market_price", params: Params(user_lat: latitude, user_lon: longitude))
            .execute()
            .value
        return zones.first
    }

    /// Calcola la valutazione completa di un immobile.
    /// Applica multiplier condizione + adjustment piano + clamping OMI.
    func valuate(property: Property) async throws -> PropertyValuation? {
        guard let lat = property.latitude, let lon = property.longitude else {
            return nil
        }
        guard let zone = try await findNearestZone(latitude: lat, longitude: lon) else {
            return nil
        }
        guard let surface = property.surfaceCommercial, surface > 0 else {
            return nil
        }

        let condition = ConditionMultiplier.from(property.conditionStatus)
        let condMultiplier = condition.multiplier(from: zone)
        let floorMultiplier = floorAdjustment(property: property)

        let basePerSqm = zone.marketAvgSqm * condMultiplier * floorMultiplier
        let clampedPerSqm = max(basePerSqm, zone.omiMinSqm)
        let totalValue = clampedPerSqm * surface

        return PropertyValuation(
            id: UUID(),
            zone: zone,
            conditionMultiplier: condMultiplier,
            floorAdjustment: floorMultiplier,
            surfaceCommercial: surface,
            estimatedValuePerSqm: clampedPerSqm,
            estimatedTotalValue: totalValue
        )
    }

    /// Micro-regolazione piano: terra -5%, attico +20%, piano alto senza ascensore -15%, altrimenti 1.0.
    private func floorAdjustment(property: Property) -> Double {
        let floor = property.floor?.lowercased() ?? ""
        if floor.contains("attico") || floor.contains("attic") || floor.contains("penth") {
            return 1.20
        }
        if floor.contains("terra") || floor == "0" || floor == "pt" {
            return 0.95
        }
        // Piano alto >= 3 senza ascensore
        if let n = Int(floor), n >= 3, property.hasElevator == false {
            return 0.85
        }
        return 1.0
    }
}
