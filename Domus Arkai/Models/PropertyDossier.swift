//
//  PropertyDossier.swift
//  Domus Arkai
//
//  "Il mio Dossier": raccoglie tutti i sotto-calcoli di un utente per un singolo immobile
//  (AVM + Mutuo + Ristrutturazione parametrica + Visual BOQ AI + snapshot prezzo).
//  Schema 1:1 con tabella `user_property_dossiers`.
//

import Foundation

// MARK: - Singolo item di ristrutturazione persistito nel Dossier

struct DossierRenovationLine: Codable, Hashable, Sendable, Identifiable {
    var id: String { itemID.uuidString }
    let itemID: UUID
    let categoryID: UUID?
    let name: String
    let level: String      // "base" | "medium" | "premium"
    let quantity: Double
    let unitPrice: Double
    let lineTotal: Double
    let variantKey: String?
    let variantLabel: String?

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case categoryID = "category_id"
        case name
        case level
        case quantity
        case unitPrice = "unit_price"
        case lineTotal = "line_total"
        case variantKey = "variant_key"
        case variantLabel = "variant_label"
    }
}

// MARK: - Dossier principale

struct PropertyDossier: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let propertyID: UUID

    // Snapshot prezzo al momento di creazione
    let askingPriceSnapshot: Double?

    // AVM
    let avmZoneID: String?
    let avmEstimatedPerSqm: Double?
    let avmEstimatedTotal: Double?

    // Mutuo
    let mortgageEstimateID: UUID?
    let mortgageMonthlyPayment: Double?

    // Ristrutturazione parametrica
    let renovationTotal: Double?
    let renovationItems: [DossierRenovationLine]?
    let renovationDifficultyFactors: [String]?

    // Visual BOQ
    let visualBOQEstimateIDs: [UUID]?
    let visualBOQTotal: Double?

    // Note libere utente
    let userNotes: String?

    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case propertyID = "property_id"
        case askingPriceSnapshot = "asking_price_snapshot"
        case avmZoneID = "avm_zone_id"
        case avmEstimatedPerSqm = "avm_estimated_per_sqm"
        case avmEstimatedTotal = "avm_estimated_total"
        case mortgageEstimateID = "mortgage_estimate_id"
        case mortgageMonthlyPayment = "mortgage_monthly_payment"
        case renovationTotal = "renovation_total"
        case renovationItems = "renovation_items"
        case renovationDifficultyFactors = "renovation_difficulty_factors"
        case visualBOQEstimateIDs = "visual_boq_estimate_ids"
        case visualBOQTotal = "visual_boq_total"
        case userNotes = "user_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Investimento totale stimato (prezzo richiesto + ristrutturazione + visual BOQ).
    /// Calcolato solo se almeno il prezzo c'è.
    var totalInvestment: Double? {
        guard let price = askingPriceSnapshot else { return nil }
        return price + (renovationTotal ?? 0) + (visualBOQTotal ?? 0)
    }
}

// MARK: - Draft per upsert

/// Payload UPSERT del Dossier. user_id e property_id chiave logica.
/// I campi opzionali vengono inviati nulli per non-impostati (Supabase mantiene il valore esistente solo se omessi via JSON encoding standard — di solito conviene leggere il dossier corrente e fare merge lato client prima di upsert).
struct PropertyDossierDraft: Codable, Hashable, Sendable {
    let userID: UUID
    let propertyID: UUID

    var askingPriceSnapshot: Double?

    var avmZoneID: String?
    var avmEstimatedPerSqm: Double?
    var avmEstimatedTotal: Double?

    var mortgageEstimateID: UUID?
    var mortgageMonthlyPayment: Double?

    var renovationTotal: Double?
    var renovationItems: [DossierRenovationLine]?
    var renovationDifficultyFactors: [String]?

    var visualBOQEstimateIDs: [UUID]?
    var visualBOQTotal: Double?

    var userNotes: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case propertyID = "property_id"
        case askingPriceSnapshot = "asking_price_snapshot"
        case avmZoneID = "avm_zone_id"
        case avmEstimatedPerSqm = "avm_estimated_per_sqm"
        case avmEstimatedTotal = "avm_estimated_total"
        case mortgageEstimateID = "mortgage_estimate_id"
        case mortgageMonthlyPayment = "mortgage_monthly_payment"
        case renovationTotal = "renovation_total"
        case renovationItems = "renovation_items"
        case renovationDifficultyFactors = "renovation_difficulty_factors"
        case visualBOQEstimateIDs = "visual_boq_estimate_ids"
        case visualBOQTotal = "visual_boq_total"
        case userNotes = "user_notes"
    }
}
