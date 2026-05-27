//
//  RenovationItem.swift
//  Domus Arkai
//
//  Schema 1:1 con tabella `renovation_items` Supabase.
//  Computed helper lato Swift per icon/unitLabel/quantity bounds (config UI).
//

import Foundation

struct RenovationItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let agencyID: UUID?
    let categoryID: UUID?
    let name: String
    let description: String?
    let unitType: UnitType
    let basePrice: Double
    let mediumPrice: Double
    let premiumPrice: Double
    let defaultQuantity: Double
    let isActive: Bool
    let orderIndex: Int?
    let createdAt: Date?
    let updatedAt: Date?
    /// Varianti materiali (es. parquet vs marmo). Null = usa i prezzi base/medium/premium dell'item.
    let materialVariants: [MaterialVariant]?
    /// Schema parametrico per configuratori avanzati (Pavimenti gerarchico, Cucina, Serramenti…).
    /// Quando presente, sostituisce sia il livello globale sia le `materialVariants`.
    let configurationSchema: ConfigurationSchema?

    /// Popolato lato client dopo enrich con `renovation_categories`. Non-codable.
    var categoryName: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case agencyID = "agency_id"
        case categoryID = "category_id"
        case name, description
        case unitType = "unit_type"
        case basePrice = "base_price"
        case mediumPrice = "medium_price"
        case premiumPrice = "premium_price"
        case defaultQuantity = "default_quantity"
        case isActive = "is_active"
        case orderIndex = "order_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case materialVariants = "material_variants"
        case configurationSchema = "configuration_schema"
    }

    var hasVariants: Bool { (materialVariants?.isEmpty == false) }
    var hasConfigurationSchema: Bool { configurationSchema != nil }

    /// Decoder resiliente: se `material_variants` o `configuration_schema` hanno una struttura inattesa
    /// (campo nuovo aggiunto server-side non ancora supportato lato client), NON facciamo fallire l'intero
    /// item — manteniamo nil e logghiamo. Tutti gli altri campi seguono il default Codable.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.agencyID = try c.decodeIfPresent(UUID.self, forKey: .agencyID)
        self.categoryID = try c.decodeIfPresent(UUID.self, forKey: .categoryID)
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try c.decodeIfPresent(String.self, forKey: .description)
        self.unitType = try c.decode(UnitType.self, forKey: .unitType)
        self.basePrice = try c.decode(Double.self, forKey: .basePrice)
        self.mediumPrice = try c.decode(Double.self, forKey: .mediumPrice)
        self.premiumPrice = try c.decode(Double.self, forKey: .premiumPrice)
        self.defaultQuantity = try c.decode(Double.self, forKey: .defaultQuantity)
        self.isActive = try c.decode(Bool.self, forKey: .isActive)
        self.orderIndex = try c.decodeIfPresent(Int.self, forKey: .orderIndex)
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Best-effort sui campi opzionali "evoluti"
        do {
            self.materialVariants = try c.decodeIfPresent([MaterialVariant].self, forKey: .materialVariants)
        } catch {
            print("⚠️ [RenovationItem] material_variants decode failed for '\(self.name)' — \(error)")
            self.materialVariants = nil
        }
        do {
            self.configurationSchema = try c.decodeIfPresent(ConfigurationSchema.self, forKey: .configurationSchema)
        } catch {
            print("⚠️ [RenovationItem] configuration_schema decode failed for '\(self.name)' — \(error)")
            self.configurationSchema = nil
        }
    }

    /// Unit type dell'item. `sqm`/`unit` sono i tipi base. Altri valori (es. "impianto",
    /// "cucina", "split", "serramento", "porta" usati lato Marco per items parametrici)
    /// vengono mappati su `.other` per non far fallire il decoding. Il calcolo per questi
    /// items deriva da `configurationSchema` non dall'`unit_type` colonna.
    enum UnitType: String, Codable, Hashable, Sendable {
        case sqm
        case unit
        case other

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = UnitType(rawValue: raw) ?? .other
        }
    }

    // MARK: - Display helpers (computed lato client, brand-safe)

    /// Icona SF Symbol derivata dal nome dell'intervento.
    var icon: String {
        let n = name.lowercased()
        if n.contains("tintegg") || n.contains("pittur") { return "paintbrush" }
        if n.contains("pavime") { return "square.grid.3x3" }
        if n.contains("bagno") { return "shower" }
        if n.contains("cucina") { return "fork.knife" }
        if n.contains("serramen") || n.contains("finestr") { return "rectangle.split.3x1" }
        if n.contains("porte") { return "door.left.hand.closed" }
        if n.contains("elettr") { return "bolt" }
        if n.contains("idraul") { return "drop" }
        if n.contains("climat") || n.contains("split") { return "snowflake" }
        if n.contains("demoli") { return "hammer" }
        return "wrench.and.screwdriver"
    }

    /// Etichetta unità singolare (UI: "mq", "finestra", "porta", "bagno", "cucina", "split").
    var unitLabel: String {
        switch unitType {
        case .sqm: return "mq"
        case .unit, .other:
            let n = name.lowercased()
            if n.contains("bagno") { return "bagno" }
            if n.contains("cucina") { return "cucina" }
            if n.contains("serramen") || n.contains("finestr") { return "finestra" }
            if n.contains("porte") { return "porta" }
            if n.contains("climat") || n.contains("split") { return "split" }
            if n.contains("riscalda") || n.contains("impianto") { return "impianto" }
            return "unità"
        }
    }

    var minQuantity: Double {
        switch unitType {
        case .sqm: return 10
        case .unit, .other: return 1
        }
    }

    var maxQuantity: Double {
        switch unitType {
        case .sqm: return 500
        case .unit, .other:
            let n = name.lowercased()
            if n.contains("bagno") { return 5 }
            if n.contains("cucina") { return 3 }
            if n.contains("serramen") || n.contains("finestr") { return 30 }
            if n.contains("porte") { return 20 }
            if n.contains("climat") || n.contains("split") { return 10 }
            return 20
        }
    }

    var quantityStep: Double {
        switch unitType {
        case .sqm: return 5
        case .unit, .other: return 1
        }
    }

    /// Prezzo unitario per livello dell'item (fallback quando non c'è variante).
    func unitPrice(for level: RenovationLevel) -> Double {
        switch level {
        case .essential: return basePrice
        case .medium: return mediumPrice
        case .premium: return premiumPrice
        }
    }

    /// Prezzo unitario per livello, considerando una variante materiale opzionale.
    /// Se la variante è nil → usa i prezzi dell'item; altrimenti i prezzi della variante.
    func unitPrice(for level: RenovationLevel, variant: MaterialVariant?) -> Double {
        guard let variant else { return unitPrice(for: level) }
        return variant.unitPrice(for: level)
    }

    /// Costo base livello × quantità con variante opzionale (PRIMA dei multiplier regional/difficulty).
    func baseCost(level: RenovationLevel, quantity: Double, variant: MaterialVariant? = nil) -> Double {
        return quantity * unitPrice(for: level, variant: variant)
    }

    /// Etichetta umana per quantità con plurale ("4 finestre", "1 bagno", "120 mq").
    func quantityLabel(for value: Double) -> String {
        let qty = Int(value)
        switch unitType {
        case .sqm: return "\(qty) mq"
        case .unit, .other:
            let label = unitLabel
            if qty == 1 { return "1 \(label)" }
            // Italianissimo: pluralizzazione
            let plural: String
            switch label {
            case "finestra": plural = "finestre"
            case "porta": plural = "porte"
            case "bagno": plural = "bagni"
            case "cucina": plural = "cucine"
            case "split": plural = "split"
            case "impianto": plural = "impianti"
            default: plural = label + "i"
            }
            return "\(qty) \(plural)"
        }
    }
}

enum RenovationLevel: String, Codable, Hashable, Sendable, CaseIterable {
    case essential
    case medium
    case premium

    var label: String {
        switch self {
        case .essential: "Essenziale"
        case .medium: "Medio"
        case .premium: "Premium"
        }
    }

    var description: String {
        switch self {
        case .essential: "Soluzioni standard, prezzi contenuti."
        case .medium: "Buon equilibrio qualità-prezzo."
        case .premium: "Materiali e finiture di pregio."
        }
    }
}

// MARK: - Material Variant

/// Variante materiale per un `RenovationItem` (es. "parquet rovere" vs "marmo Carrara").
/// Schema embedded in `renovation_items.material_variants jsonb`.
struct MaterialVariant: Codable, Hashable, Sendable, Identifiable {
    let key: String
    let label: String
    let description: String?
    let basePrice: Double
    let mediumPrice: Double
    let premiumPrice: Double
    let orderIndex: Int?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, label, description
        case basePrice = "base_price"
        case mediumPrice = "medium_price"
        case premiumPrice = "premium_price"
        case orderIndex = "order_index"
    }

    func unitPrice(for level: RenovationLevel) -> Double {
        switch level {
        case .essential: return basePrice
        case .medium: return mediumPrice
        case .premium: return premiumPrice
        }
    }
}

/// Schema 1:1 con `renovation_categories`.
struct RenovationCategory: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let agencyID: UUID?
    let name: String
    let description: String?
    let orderIndex: Int?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case agencyID = "agency_id"
        case name, description
        case orderIndex = "order_index"
        case isActive = "is_active"
    }
}
