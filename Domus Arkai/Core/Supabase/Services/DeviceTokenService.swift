//
//  DeviceTokenService.swift
//  Domus Arkai
//
//  Upsert del device token APNs dell'utente loggato sulla tabella `device_tokens`.
//  Schema reale (confermato da frontend_ai HUB 23/05/2026):
//   device_tokens(user_id uuid REF auth.users, token text, device_type text, created_at)
//

import Foundation
import Supabase

actor DeviceTokenService {
    static let shared = DeviceTokenService()

    private var client: SupabaseClient { SupabaseManager.shared }

    struct DeviceTokenInsert: Encodable {
        let user_id: UUID
        let token: String
        let device_type: String
    }

    /// Upsert (idempotente): elimina riga esistente per stesso user+token, poi inserisce nuova.
    /// Il parametro `locale` è kept per backwards compat ma ignorato (lo schema server non ha la colonna).
    func upsertToken(userID: UUID, apnsToken: String, locale: String) async throws {
        let payload = DeviceTokenInsert(
            user_id: userID,
            token: apnsToken,
            device_type: "ios"
        )
        print("🟢 [DeviceToken] upsert — user=\(userID), token=\(apnsToken.prefix(16))…")

        // Cancella prima eventuale duplicato (idempotenza senza dipendere da UNIQUE constraint server)
        try await client
            .from("device_tokens")
            .delete()
            .eq("user_id", value: userID.uuidString)
            .eq("token", value: apnsToken)
            .execute()

        try await client
            .from("device_tokens")
            .insert(payload)
            .execute()
        print("✅ [DeviceToken] insert ok")
    }
}
