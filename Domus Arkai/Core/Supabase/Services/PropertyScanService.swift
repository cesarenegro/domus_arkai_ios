//
//  PropertyScanService.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — CRUD su tabella `property_scans` di Supabase.
//  RLS prevista: l'agente può vedere/modificare solo le proprie scansioni;
//  admin tutto. Backend Marco elabora le righe `pending` e aggiorna lo
//  `status` con l'URL del USDZ generato.
//
//  Schema concordato via HUB (msg b2e1fdec, 2026-05-27).
//  In attesa conferma finale dei nomi colonna esatti.
//

import Foundation
import Supabase

actor PropertyScanService {
    static let shared = PropertyScanService()

    private var client: SupabaseClient { SupabaseManager.shared }

    private static let table = "property_scans"

    // MARK: - Read

    /// Tutte le scansioni di un agente, dalla più recente alla più vecchia.
    func listMyScans(userID: UUID) async throws -> [PropertyScan] {
        print("🟢 [PropertyScan][Service] list — user=\(userID)")
        let rows: [PropertyScan] = try await client
            .from(Self.table)
            .select()
            .eq("scanned_by", value: userID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        print("✅ [PropertyScan][Service] list ok — count=\(rows.count)")
        return rows
    }

    /// Ultima scansione (qualsiasi status) per la property. Utile durante
    /// la fase v2.0 di sviluppo quando la pipeline server non sempre produce
    /// `staging_usdz_url` — il client può fallback su un USDZ demo locale.
    func latestScan(forPropertyID propertyID: UUID) async throws -> PropertyScan? {
        print("🟢 [PropertyScan][Service] latestScan — property=\(propertyID)")
        let rows: [PropertyScan] = try await client
            .from(Self.table)
            .select()
            .eq("property_id", value: propertyID.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        print("✅ [PropertyScan][Service] latestScan — found=\(rows.first != nil) status=\(rows.first?.status.rawValue ?? "nil")")
        return rows.first
    }

    /// Scansioni associate a un singolo immobile (visibili lato cliente
    /// per capire se mostrare la card "Spatial Staging").
    /// Filtrate solo status `.ready`.
    func listReady(forPropertyID propertyID: UUID) async throws -> [PropertyScan] {
        print("🟢 [PropertyScan][Service] listReady — property=\(propertyID)")
        let rows: [PropertyScan] = try await client
            .from(Self.table)
            .select()
            .eq("property_id", value: propertyID.uuidString)
            .eq("status", value: PropertyScanStatus.ready.rawValue)
            .order("processed_at", ascending: false)
            .execute()
            .value
        print("✅ [PropertyScan][Service] listReady ok — count=\(rows.count)")
        return rows
    }

    /// Dettaglio singola scan (per polling status).
    func fetchScan(id: UUID) async throws -> PropertyScan? {
        print("🟢 [PropertyScan][Service] fetch — id=\(id)")
        let rows: [PropertyScan] = try await client
            .from(Self.table)
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        print("✅ [PropertyScan][Service] fetch ok — found=\(rows.first != nil)")
        return rows.first
    }

    // MARK: - Write

    /// Upload di una nuova scansione. Il server forza `status = .pending`
    /// e fa partire la pipeline di elaborazione USDZ.
    @discardableResult
    func createScan(_ draft: PropertyScanDraft) async throws -> PropertyScan {
        print("🟢 [PropertyScan][Service] create — property=\(draft.propertyID), area=\(draft.totalAreaM2)m², rooms=\(draft.roomCount)")
        let rows: [PropertyScan] = try await client
            .from(Self.table)
            .insert(draft)
            .select()
            .execute()
            .value
        guard let created = rows.first else {
            print("🔴 [PropertyScan][Service] create returned no rows")
            throw NSError(
                domain: "PropertyScanService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Caricamento scansione non riuscito."]
            )
        }
        print("✅ [PropertyScan][Service] create ok — scanID=\(created.id) status=\(created.status.rawValue)")
        return created
    }

    /// Cancellazione lato agente (RLS deve consentire solo al proprietario).
    func deleteScan(id: UUID) async throws {
        print("🟡 [PropertyScan][Service] delete — id=\(id)")
        try await client
            .from(Self.table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        print("✅ [PropertyScan][Service] delete ok")
    }
}
