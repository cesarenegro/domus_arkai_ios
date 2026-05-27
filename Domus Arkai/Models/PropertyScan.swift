//
//  PropertyScan.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — riga della tabella `public.property_scans` su Supabase.
//  Schema confermato da Marco (HUB msg 64cdbf3e, 2026-05-27).
//
//  Una scansione RoomPlan effettuata da un agente per un immobile.
//  Backend Marco elabora `scan_json` + libreria modelli arredo → genera USDZ
//  → carica su Storage `property-staging` → status passa a `.ready` con
//  `staging_usdz_url` valorizzato → push notification "Scansione del locale pronta!".
//

import Foundation

// MARK: - Status del processing pipeline (CHECK constraint lato DB)

enum PropertyScanStatus: String, Codable, Sendable, CaseIterable {
    case pending     // Appena caricato, in attesa che il backend processi
    case processing  // Backend in lavorazione (generazione USDZ)
    case ready       // USDZ pronto + URL valorizzato
    case error       // Errore in pipeline

    var displayName: String {
        switch self {
        case .pending: "In coda"
        case .processing: "Elaborazione"
        case .ready: "Pronta"
        case .error: "Errore"
        }
    }
}

// MARK: - Riga DB

struct PropertyScan: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let propertyID: UUID
    /// `scanned_by` può essere `NULL` se l'utente che ha caricato viene poi
    /// eliminato (FK ON DELETE SET NULL).
    let scannedBy: UUID?

    /// Geometria scan (jsonb non-null lato DB).
    /// Lato Swift è AnyJSON-like: usiamo Data per preservare il blob raw
    /// (CapturedRoom serializzato). Sul DB Supabase decoda comunque a jsonb.
    let scanJSON: AnyCodable?

    let totalAreaM2: Double?
    let roomCount: Int?

    /// Stato pipeline (CHECK lato DB: pending/processing/ready/error)
    let status: PropertyScanStatus

    /// URL del file USDZ generato (valorizzato quando status == .ready)
    let stagingUSDZUrl: URL?

    let createdAt: Date?
    let processedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case propertyID = "property_id"
        case scannedBy = "scanned_by"
        case scanJSON = "scan_json"
        case totalAreaM2 = "total_area_m2"
        case roomCount = "room_count"
        case status
        case stagingUSDZUrl = "staging_usdz_url"
        case createdAt = "created_at"
        case processedAt = "processed_at"
    }
}

// MARK: - Draft per upload (POST iniziale)
//
// Lato server: status default = 'pending' (CHECK constraint).
// `created_at` settato dal DEFAULT now() del DDL.

struct PropertyScanDraft: Encodable, Sendable {
    let propertyID: UUID
    let scannedBy: UUID
    /// Blob serializzato del CapturedRoom Apple, va su `scan_json` jsonb.
    let scanJSON: AnyCodable
    let totalAreaM2: Double
    let roomCount: Int

    enum CodingKeys: String, CodingKey {
        case propertyID = "property_id"
        case scannedBy = "scanned_by"
        case scanJSON = "scan_json"
        case totalAreaM2 = "total_area_m2"
        case roomCount = "room_count"
    }
}

// MARK: - AnyCodable helper per blob jsonb

/// Wrapper minimale per trasportare un payload JSON arbitrario in/out di
/// Supabase. Usato per la colonna `scan_json jsonb` dove vogliamo conservare
/// la struttura nativa di `CapturedRoom` di Apple senza interpretare la
/// geometria lato Swift.
struct AnyCodable: Codable, Hashable, Sendable {
    let value: Data

    init(_ encodable: some Encodable) throws {
        let encoder = JSONEncoder()
        self.value = try encoder.encode(encodable)
    }

    init(data: Data) {
        self.value = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Il jsonb può tornare come dict/array/string/number — riserializziamo
        // tutto il sottoalbero in Data raw così l'app non deve interpretarlo.
        if let dict = try? container.decode([String: AnyCodableValue].self) {
            self.value = try JSONEncoder().encode(dict)
        } else if let arr = try? container.decode([AnyCodableValue].self) {
            self.value = try JSONEncoder().encode(arr)
        } else if let scalar = try? container.decode(AnyCodableValue.self) {
            self.value = try JSONEncoder().encode(scalar)
        } else {
            self.value = Data()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Decodifica il blob a un valore JSON nativo, poi reencode tramite il
        // container singleValue. Necessario perché Data verrebbe encodato in base64
        // di default da JSONEncoder, NON come jsonb postgres si aspetta.
        if let any = try? JSONSerialization.jsonObject(with: value, options: [.fragmentsAllowed]),
           let encoded = AnyCodableValue.bridge(from: any) {
            try container.encode(encoded)
        } else {
            try container.encodeNil()
        }
    }
}

/// Helper ricorsivo per encode/decode JSON arbitrario via Codable.
private indirect enum AnyCodableValue: Codable, Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodableValue])
    case object([String: AnyCodableValue])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([AnyCodableValue].self) { self = .array(a); return }
        if let o = try? c.decode([String: AnyCodableValue].self) { self = .object(o); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }

    static func bridge(from any: Any) -> AnyCodableValue? {
        if any is NSNull { return .null }
        if let b = any as? Bool { return .bool(b) }
        if let i = any as? Int { return .int(i) }
        if let d = any as? Double { return .double(d) }
        if let s = any as? String { return .string(s) }
        if let a = any as? [Any] {
            return .array(a.compactMap { AnyCodableValue.bridge(from: $0) })
        }
        if let o = any as? [String: Any] {
            var out: [String: AnyCodableValue] = [:]
            for (k, v) in o {
                if let mapped = AnyCodableValue.bridge(from: v) { out[k] = mapped }
            }
            return .object(out)
        }
        return nil
    }
}
