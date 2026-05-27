//
//  VisitRequestService.swift
//  Domus Arkai
//

import Foundation
import Supabase

actor VisitRequestService {
    static let shared = VisitRequestService()

    private var client: SupabaseClient { SupabaseManager.shared }

    @discardableResult
    func createVisitRequest(
        agencyID: UUID?,
        propertyID: UUID,
        leadID: UUID,
        preferredDate: Date?,
        preferredTimeSlot: VisitRequest.TimeSlot?,
        notes: String?
    ) async throws -> VisitRequest {
        struct VisitInsert: Codable {
            let agencyID: UUID?
            let propertyID: UUID
            let leadID: UUID
            let preferredDate: String?
            let preferredTimeSlot: String?
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case agencyID = "agency_id"
                case propertyID = "property_id"
                case leadID = "lead_id"
                case preferredDate = "preferred_date"
                case preferredTimeSlot = "preferred_time_slot"
                case notes
            }
        }

        let dateString: String? = preferredDate.map { date in
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(identifier: "Europe/Rome")
            return f.string(from: date)
        }

        let payload = VisitInsert(
            agencyID: agencyID,
            propertyID: propertyID,
            leadID: leadID,
            preferredDate: dateString,
            preferredTimeSlot: preferredTimeSlot?.rawValue,
            notes: notes
        )

        let inserted: [VisitRequest] = try await client
            .from("visit_requests")
            .insert(payload)
            .select()
            .execute()
            .value

        guard let visit = inserted.first else {
            throw NSError(domain: "VisitRequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Visita non creata"])
        }
        return visit
    }
}
