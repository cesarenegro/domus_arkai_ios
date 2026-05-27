//
//  BuyerPassport.swift
//  Domus Arkai
//
//  Profilo di pre-qualificazione B2C: budget, liquidità, preferenze, "parametro di eccellenza".
//  Schema 1:1 con tabella `buyer_passports`.
//

import Foundation

struct BuyerPassport: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let maxBudget: Double?
    let liquidity: Double?
    let mortgageNeededPct: Double?
    let preferredAreas: [String]?
    let preferredCategory: [String]?
    let minBedrooms: Int?
    let minBathrooms: Int?
    /// "Parametro di eccellenza" (mai chiamarlo "punteggio" / "algoritmo" in UI).
    let buyerScore: Int
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case maxBudget = "max_budget"
        case liquidity
        case mortgageNeededPct = "mortgage_needed_pct"
        case preferredAreas = "preferred_areas"
        case preferredCategory = "preferred_category"
        case minBedrooms = "min_bedrooms"
        case minBathrooms = "min_bathrooms"
        case buyerScore = "buyer_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Rank Tier (derivato lato client da buyer_score)
// Le soglie possono essere allineate con il backend in futuro.

enum BuyerPassportTier: String, CaseIterable, Hashable, Sendable {
    case diamondElite
    case platinumExecutive
    case goldMember
    case standardProfile

    static func from(score: Int) -> BuyerPassportTier {
        switch score {
        case 90...: .diamondElite
        case 70..<90: .platinumExecutive
        case 50..<70: .goldMember
        default: .standardProfile
        }
    }

    var label: String {
        switch self {
        case .diamondElite: "Diamond Elite"
        case .platinumExecutive: "Platinum Executive"
        case .goldMember: "Gold Member"
        case .standardProfile: "Standard Profile"
        }
    }
}

extension BuyerPassport {
    var tier: BuyerPassportTier { BuyerPassportTier.from(score: buyerScore) }
}

/// Payload per upsert/update di un BuyerPassport.
struct BuyerPassportDraft: Codable, Hashable, Sendable {
    let userID: UUID
    var maxBudget: Double?
    var liquidity: Double?
    var mortgageNeededPct: Double?
    var preferredAreas: [String]?
    var preferredCategory: [String]?
    var minBedrooms: Int?
    var minBathrooms: Int?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case maxBudget = "max_budget"
        case liquidity
        case mortgageNeededPct = "mortgage_needed_pct"
        case preferredAreas = "preferred_areas"
        case preferredCategory = "preferred_category"
        case minBedrooms = "min_bedrooms"
        case minBathrooms = "min_bathrooms"
    }
}
