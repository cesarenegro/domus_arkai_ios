//
//  BuyerPassportService.swift
//  Domus Arkai
//

import Foundation
import Supabase

actor BuyerPassportService {
    static let shared = BuyerPassportService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Fetch buyer passport per utente loggato.
    func fetchPassport(userID: UUID) async throws -> BuyerPassport? {
        let rows: [BuyerPassport] = try await client
            .from("buyer_passports")
            .select()
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Upsert (insert or update) del passport dell'utente loggato.
    @discardableResult
    func upsertPassport(_ draft: BuyerPassportDraft) async throws -> BuyerPassport {
        let rows: [BuyerPassport] = try await client
            .from("buyer_passports")
            .upsert(draft, onConflict: "user_id")
            .select()
            .execute()
            .value
        guard let passport = rows.first else {
            throw NSError(domain: "BuyerPassportService", code: -1)
        }
        return passport
    }
}
