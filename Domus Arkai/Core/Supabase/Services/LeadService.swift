//
//  LeadService.swift
//  Domus Arkai
//

import Foundation
import Supabase

actor LeadService {
    static let shared = LeadService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Crea un lead per l'agenzia/immobile. Ritorna l'id del lead creato.
    @discardableResult
    func createLead(
        agencyID: UUID?,
        propertyID: UUID?,
        name: String,
        email: String?,
        phone: String?,
        message: String?,
        source: Lead.Source
    ) async throws -> Lead {
        struct LeadInsert: Codable {
            let agencyID: UUID?
            let propertyID: UUID?
            let name: String
            let email: String?
            let phone: String?
            let message: String?
            let source: String

            enum CodingKeys: String, CodingKey {
                case agencyID = "agency_id"
                case propertyID = "property_id"
                case name, email, phone, message, source
            }
        }

        let payload = LeadInsert(
            agencyID: agencyID,
            propertyID: propertyID,
            name: name,
            email: email,
            phone: phone,
            message: message,
            source: source.rawValue
        )

        let inserted: [Lead] = try await client
            .from("leads")
            .insert(payload)
            .select()
            .execute()
            .value

        guard let lead = inserted.first else {
            throw NSError(domain: "LeadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Lead non creato"])
        }
        return lead
    }
}
