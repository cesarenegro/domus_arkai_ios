//
//  AgencyService.swift
//  Domus Arkai
//
//  Wrapper Supabase per la tabella `agencies` (multi-tenant marketplace).
//

import Foundation
import Supabase

actor AgencyService {
    static let shared = AgencyService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Legacy: usata in UI single-agency. Mantenuta per retrocompatibilità.
    /// Equivalente a `fetchAllAgencies().first`.
    func fetchPrimaryAgency() async throws -> Agency? {
        let agencies = try await fetchAllAgencies(activeOnly: true)
        return agencies.first
    }

    /// Tutte le agenzie partner pubbliche.
    /// NOTA: il filtro server-side per `is_active = true` è disabilitato finché Marco
    /// non aggiunge la colonna alla tabella `agencies`. Una volta presente, il filtro
    /// si applica client-side via `Agency.isActive ?? true` (default true se nil).
    func fetchAllAgencies(activeOnly: Bool = true) async throws -> [Agency] {
        let rows: [Agency] = try await client
            .from("agencies")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        if activeOnly {
            return rows.filter { ($0.isActive ?? true) }
        }
        return rows
    }

    /// Singola agenzia by ID.
    func fetchAgency(id: UUID) async throws -> Agency? {
        let rows: [Agency] = try await client
            .from("agencies")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Singola agenzia by slug (utile per deep linking futuro).
    func fetchAgency(slug: String) async throws -> Agency? {
        let rows: [Agency] = try await client
            .from("agencies")
            .select()
            .eq("slug", value: slug)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}
