//
//  BOQ.swift
//  Domus Arkai
//
//  Models per Computo Metrico (BOQ) regionalizzato + Visual BOQ AI.
//  Schema 1:1 con tabelle `boq_regional_coefficients`, `boq_difficulty_factors`,
//  `boq_base_prices`, `visual_boq_estimates`.
//

import Foundation

// MARK: - BOQ regional / difficulty

struct BOQRegionalCoefficient: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let city: String
    let region: String
    let laborCostEurH: Double
    let kFinal: Double
    let laborSource: String?
    let confidenceLabel: String?

    enum CodingKeys: String, CodingKey {
        case id, city, region
        case laborCostEurH = "labor_cost_eur_h"
        case kFinal = "k_final"
        case laborSource = "labor_source"
        case confidenceLabel = "confidence_label"
    }
}

struct BOQDifficultyFactor: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let key: String          // centro_storico, ztl_access, ...
    let label: String        // "Centro Storico", "ZTL", ... (già brand-safe lato backend)
    let multiplier: Double   // ⚠️ MAI mostrare in UI — solo per calcolo interno
    let description: String
}

struct BOQBasePrice: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let workCode: String                  // demolition_floor, hydraulic_points, ...
    let description: String
    let unit: String                      // mq, punti, cad
    let basePricePerUnit: Double

    enum CodingKeys: String, CodingKey {
        case id
        case workCode = "work_code"
        case description, unit
        case basePricePerUnit = "base_price_per_unit"
    }
}

// MARK: - Visual BOQ (Arkai Vision Pro)

/// Singolo intervento rilevato/calcolato dall'analisi visiva.
struct VisualBOQWork: Codable, Hashable, Sendable, Identifiable {
    var id: String { workCode }
    let workCode: String
    let description: String
    let quantity: Double
    let unit: String
    let unitCost: Double
    let totalCost: Double

    enum CodingKeys: String, CodingKey {
        case workCode = "work_code"
        case description, quantity, unit
        case unitCost = "unit_cost"
        case totalCost = "total_cost"
    }
}

/// Response Edge Function `analyze-room-photos`.
struct VisualBOQResponse: Codable, Hashable, Sendable {
    let estimateID: UUID
    let detectedRoomType: String
    let detectedConditions: [String]
    let estimatedWorks: [VisualBOQWork]
    let totalEstimatedCost: Double

    enum CodingKeys: String, CodingKey {
        case estimateID = "estimate_id"
        case detectedRoomType = "detected_room_type"
        case detectedConditions = "detected_conditions"
        case estimatedWorks = "estimated_works"
        case totalEstimatedCost = "total_estimated_cost"
        // NOTA: `breakdown` (k_final, k_difficolta) NON viene esposto al client per regola di oscuramento formule.
    }
}

/// Riga persistita su `visual_boq_estimates`.
struct VisualBOQEstimateRecord: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let userID: UUID?
    let propertyID: UUID?
    let photoURLs: [String]?
    let detectedRoomType: String?
    let detectedConditions: [String]?
    let city: String
    let difficultyFactors: [String]?
    let totalEstimatedCost: Double?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case propertyID = "property_id"
        case photoURLs = "photo_urls"
        case detectedRoomType = "detected_room_type"
        case detectedConditions = "detected_conditions"
        case city
        case difficultyFactors = "difficulty_factors"
        case totalEstimatedCost = "total_estimated_cost"
        case createdAt = "created_at"
    }
}
