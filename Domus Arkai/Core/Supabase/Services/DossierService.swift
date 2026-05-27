//
//  DossierService.swift
//  Domus Arkai
//
//  Servizio per "Il mio Dossier" su Supabase (`user_property_dossiers`).
//  RLS impone auth.uid() = user_id per ogni operazione.
//

import Foundation
import Supabase

actor DossierService {
    static let shared = DossierService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Recupera il Dossier per (user, property). Nil se non esiste ancora.
    func fetchDossier(userID: UUID, propertyID: UUID) async throws -> PropertyDossier? {
        print("🟢 [Dossier][Service] fetch — user=\(userID), property=\(propertyID)")
        let rows: [PropertyDossier] = try await client
            .from("user_property_dossiers")
            .select()
            .eq("user_id", value: userID.uuidString)
            .eq("property_id", value: propertyID.uuidString)
            .limit(1)
            .execute()
            .value
        print("✅ [Dossier][Service] fetch ok — exists=\(rows.first != nil)")
        return rows.first
    }

    /// Elenco di tutti i Dossier dell'utente loggato (per la sezione "I miei Dossier" in Profile).
    func listMyDossiers(userID: UUID) async throws -> [PropertyDossier] {
        print("🟢 [Dossier][Service] list — user=\(userID)")
        let rows: [PropertyDossier] = try await client
            .from("user_property_dossiers")
            .select()
            .eq("user_id", value: userID.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
        print("✅ [Dossier][Service] list ok — count=\(rows.count)")
        return rows
    }

    /// Upsert by (user_id, property_id). Sovrascrive solo i campi forniti nel draft.
    @discardableResult
    func upsertDossier(_ draft: PropertyDossierDraft) async throws -> PropertyDossier {
        print("🟢 [Dossier][Service] upsert — user=\(draft.userID), property=\(draft.propertyID)")
        let rows: [PropertyDossier] = try await client
            .from("user_property_dossiers")
            .upsert(draft, onConflict: "user_id,property_id")
            .select()
            .execute()
            .value
        guard let dossier = rows.first else {
            print("🔴 [Dossier][Service] upsert returned no rows")
            throw NSError(domain: "DossierService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Salvataggio Dossier non riuscito."])
        }
        print("✅ [Dossier][Service] upsert ok — dossierID=\(dossier.id)")
        return dossier
    }

    /// Cancella il Dossier (l'utente ha la sola facoltà sui propri tramite RLS).
    func deleteDossier(id: UUID) async throws {
        print("🟡 [Dossier][Service] delete — id=\(id)")
        try await client
            .from("user_property_dossiers")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        print("✅ [Dossier][Service] delete ok")
    }
}
