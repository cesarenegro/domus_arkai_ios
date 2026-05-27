//
//  PropertyScan.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — riga della tabella `property_scans` su Supabase.
//  Una scansione RoomPlan effettuata da un agente per un immobile.
//  Backend Marco elabora il payload + libreria modelli arredo → genera USDZ
//  → carica su Storage → status passa a .ready con `staging_usdz_url` valorizzato.
//
//  Schema concordato via HUB (msg b2e1fdec, 2026-05-27). In attesa
//  conferma finale di Marco sui nomi colonna precisi.
//

import Foundation

// MARK: - Status del processing pipeline

enum PropertyScanStatus: String, Codable, Sendable, CaseIterable {
    case pending     // Appena caricato, in attesa che il backend processi
    case processing  // Backend in lavorazione (generazione USDZ)
    case ready       // USDZ pronto + URL valorizzato
    case error       // Errore in pipeline (vedi `error_message`)

    var displayName: String {
        switch self {
        case .pending: "In coda"
        case .processing: "Elaborazione"
        case .ready: "Pronta"
        case .error: "Errore"
        }
    }
}

// MARK: - Geometria CapturedRoom (payload jsonb)

/// Snapshot della geometria estratta da `RoomPlan.CapturedRoom`.
/// Lo serializziamo direttamente sul DB come `scan_json` jsonb.
/// Apple `CapturedRoom` è già `Codable`: per ora salviamo il blob raw,
/// l'app non ha bisogno di interpretare la geometria — è il backend che
/// la legge per generare l'USDZ.
struct PropertyScanPayload: Codable, Sendable, Hashable {
    /// Versione dello schema (per migrazione futura)
    let version: Int
    /// Numero stanze rilevate dalla scansione
    let roomCount: Int
    /// Area totale in metri quadri
    let totalAreaM2: Double
    /// JSON encoded di `CapturedRoom` di Apple (decodable lato server)
    let capturedRoomJSON: String

    enum CodingKeys: String, CodingKey {
        case version
        case roomCount = "room_count"
        case totalAreaM2 = "total_area_m2"
        case capturedRoomJSON = "captured_room_json"
    }
}

// MARK: - Riga DB

struct PropertyScan: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let propertyID: UUID
    let scannedBy: UUID

    /// Geometria scan (jsonb su Supabase)
    let scanPayload: PropertyScanPayload?

    /// Aggregati estratti per rendering rapido in lista (denormalizzati)
    let totalAreaM2: Double?
    let roomCount: Int?

    /// Stato pipeline
    let status: PropertyScanStatus
    let errorMessage: String?

    /// URL del file USDZ generato (presente quando status == .ready)
    let stagingUSDZUrl: URL?

    /// Variante materiale del USDZ (per v2.0 sempre "minimal_premium")
    let stagingVariant: String?

    let createdAt: Date?
    let processedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case propertyID = "property_id"
        case scannedBy = "scanned_by"
        case scanPayload = "scan_payload"
        case totalAreaM2 = "total_area_m2"
        case roomCount = "room_count"
        case status
        case errorMessage = "error_message"
        case stagingUSDZUrl = "staging_usdz_url"
        case stagingVariant = "staging_variant"
        case createdAt = "created_at"
        case processedAt = "processed_at"
    }
}

// MARK: - Draft per upload (POST iniziale, status forced .pending lato server)

struct PropertyScanDraft: Encodable, Sendable {
    let propertyID: UUID
    let scannedBy: UUID
    let scanPayload: PropertyScanPayload
    let totalAreaM2: Double
    let roomCount: Int
    let stagingVariant: String

    enum CodingKeys: String, CodingKey {
        case propertyID = "property_id"
        case scannedBy = "scanned_by"
        case scanPayload = "scan_payload"
        case totalAreaM2 = "total_area_m2"
        case roomCount = "room_count"
        case stagingVariant = "staging_variant"
    }
}
