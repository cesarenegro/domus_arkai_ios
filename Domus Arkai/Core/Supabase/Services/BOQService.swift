//
//  BOQService.swift
//  Domus Arkai
//
//  Wrapper Supabase per BOQ regional + difficulty + base_prices + renovation_items.
//  Cache in-memory dei coefficienti (cambiano raramente).
//

import Foundation
import Supabase

actor BOQService {
    static let shared = BOQService()

    private var client: SupabaseClient { SupabaseManager.shared }

    // Cache lazy (resta valida per la vita dell'app session)
    private var cachedDifficultyFactors: [BOQDifficultyFactor]?
    private var cachedRegionalByCity: [String: BOQRegionalCoefficient] = [:]
    private var cachedBasePrices: [BOQBasePrice]?

    /// Fattori di difficoltà cantiere (label brand-safe, multiplier mai esposto in UI).
    func fetchDifficultyFactors() async throws -> [BOQDifficultyFactor] {
        if let cached = cachedDifficultyFactors { return cached }
        let factors: [BOQDifficultyFactor] = try await client
            .from("boq_difficulty_factors")
            .select()
            .order("key", ascending: true)
            .execute()
            .value
        cachedDifficultyFactors = factors
        return factors
    }

    /// Coefficiente regionale per città (k_final + labor_cost). Cache per call.
    func fetchRegionalCoefficient(city: String) async throws -> BOQRegionalCoefficient? {
        if let cached = cachedRegionalByCity[city] { return cached }
        let rows: [BOQRegionalCoefficient] = try await client
            .from("boq_regional_coefficients")
            .select()
            .eq("city", value: city)
            .limit(1)
            .execute()
            .value
        if let coef = rows.first {
            cachedRegionalByCity[city] = coef
            return coef
        }
        // Fallback: cerca riga 'default'
        let fallback: [BOQRegionalCoefficient] = try await client
            .from("boq_regional_coefficients")
            .select()
            .eq("city", value: "default")
            .limit(1)
            .execute()
            .value
        return fallback.first
    }

    /// Prezzi base per work_code (codici Edge Function: demolition_floor, hydraulic_points, ecc.)
    func fetchBasePrices() async throws -> [BOQBasePrice] {
        if let cached = cachedBasePrices { return cached }
        let rows: [BOQBasePrice] = try await client
            .from("boq_base_prices")
            .select()
            .order("work_code", ascending: true)
            .execute()
            .value
        cachedBasePrices = rows
        return rows
    }

    /// Renovation categories attive dell'agenzia (per raggruppamento UI).
    func fetchRenovationCategories(agencyID: UUID? = nil) async throws -> [RenovationCategory] {
        var query = client.from("renovation_categories").select().eq("is_active", value: true)
        if let agencyID = agencyID {
            query = query.eq("agency_id", value: agencyID.uuidString)
        }
        let rows: [RenovationCategory] = try await query
            .order("order_index", ascending: true)
            .execute()
            .value
        return rows
    }

    /// Renovation items configurati dall'agenzia (tinteggiature, bagno, ecc.) per il calcolatore parametrico.
    func fetchRenovationItems(agencyID: UUID? = nil) async throws -> [RenovationItem] {
        var query = client.from("renovation_items").select().eq("is_active", value: true)
        if let agencyID = agencyID {
            query = query.eq("agency_id", value: agencyID.uuidString)
        }
        let rows: [RenovationItem] = try await query
            .order("order_index", ascending: true)
            .execute()
            .value
        return rows
    }

    // MARK: - Calcolo

    /// Calcola moltiplicatore difficoltà come prodotto dei multiplier dei factor selezionati.
    /// MAI esporre il valore in UI — solo per calcolo interno.
    func computeDifficultyMultiplier(selectedKeys: Set<String>, allFactors: [BOQDifficultyFactor]) -> Double {
        guard !selectedKeys.isEmpty else { return 1.0 }
        return allFactors
            .filter { selectedKeys.contains($0.key) }
            .reduce(1.0) { $0 * $1.multiplier }
    }
}
