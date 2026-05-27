//
//  ConfigurationSchema.swift
//  Domus Arkai
//
//  Schema parametrico per configuratori ristrutturazione. Decodifica il jsonb
//  `configuration_schema` popolato server-side da Marco/frontend_ai.
//
//  Supporta 5 field types:
//   - `grouped_variant_picker` (es. Pavimenti → Ceramica/Lastre/Parquet/Sintetici)
//   - `variant_picker`         (es. Porte, Impianto elettrico tipo, Riscaldamento)
//   - `toggle`                 (es. Cucina isola, Elettrodomestici, Rifacimento elettrico)
//   - `number_input`           (es. Cucina mt lineari, Serramenti nr finestre, Split count)
//   - `size_picker`            (es. Serramenti dimensione finestra)
//
//  Cost calculation: NON interpretiamo `cost_formula` stringa. Le formule sono
//  hardcoded lato Swift in `RenovationViewModel` in modo specifico per item.unit.
//

import Foundation

// MARK: - Top level schema

struct ConfigurationSchema: Codable, Hashable, Sendable {
    let version: Int
    let unit: String
    let fields: [ConfigField]
    let costFormula: String?

    enum CodingKeys: String, CodingKey {
        case version, unit, fields
        case costFormula = "cost_formula"
    }
}

// MARK: - Price (3 livelli base/medium/premium)

struct ConfigPrice: Codable, Hashable, Sendable {
    let base: Double
    let medium: Double
    let premium: Double

    func value(for level: RenovationLevel) -> Double {
        switch level {
        case .essential: return base
        case .medium: return medium
        case .premium: return premium
        }
    }
}

// MARK: - Multiplier (toggle true/false → coefficiente)

struct ConfigMultiplier: Codable, Hashable, Sendable {
    let trueValue: Double
    let falseValue: Double

    enum CodingKeys: String, CodingKey {
        case trueValue = "true"
        case falseValue = "false"
    }

    func value(for flag: Bool) -> Double {
        flag ? trueValue : falseValue
    }
}

// MARK: - Field (polimorfico, discriminator `type`)

enum ConfigField: Codable, Hashable, Sendable, Identifiable {
    case groupedVariantPicker(GroupedVariantPicker)
    case variantPicker(VariantPicker)
    case toggle(ToggleField)
    case numberInput(NumberInput)
    case sizePicker(SizePicker)

    var id: String { key }

    var key: String {
        switch self {
        case .groupedVariantPicker(let f): return f.key
        case .variantPicker(let f): return f.key
        case .toggle(let f): return f.key
        case .numberInput(let f): return f.key
        case .sizePicker(let f): return f.key
        }
    }

    var label: String {
        switch self {
        case .groupedVariantPicker(let f): return f.label
        case .variantPicker(let f): return f.label
        case .toggle(let f): return f.label
        case .numberInput(let f): return f.label
        case .sizePicker(let f): return f.label
        }
    }

    private enum DiscriminatorKey: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKey.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "grouped_variant_picker":
            self = .groupedVariantPicker(try GroupedVariantPicker(from: decoder))
        case "variant_picker":
            self = .variantPicker(try VariantPicker(from: decoder))
        case "toggle":
            self = .toggle(try ToggleField(from: decoder))
        case "number_input":
            self = .numberInput(try NumberInput(from: decoder))
        case "size_picker":
            self = .sizePicker(try SizePicker(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown config field type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .groupedVariantPicker(let f): try f.encode(to: encoder)
        case .variantPicker(let f): try f.encode(to: encoder)
        case .toggle(let f): try f.encode(to: encoder)
        case .numberInput(let f): try f.encode(to: encoder)
        case .sizePicker(let f): try f.encode(to: encoder)
        }
    }
}

// MARK: - Concrete field structs

struct GroupedVariantPicker: Codable, Hashable, Sendable {
    let type: String   // "grouped_variant_picker"
    let key: String
    let label: String
    let groups: [VariantGroup]
}

struct VariantGroup: Codable, Hashable, Sendable, Identifiable {
    let key: String
    let label: String
    let options: [VariantOption]
    var id: String { key }
}

struct VariantPicker: Codable, Hashable, Sendable {
    let type: String   // "variant_picker"
    let key: String
    let label: String
    let options: [VariantOption]
}

/// Singola opzione di un variant_picker o di un VariantGroup. Polimorfica:
/// può avere `price` (Pavimenti/Porte/Riscaldamento), `price_per_sqm` (Serramenti material,
/// Impianto elettrico type), e `mode` (Riscaldamento: per_sqm vs fixed).
struct VariantOption: Codable, Hashable, Sendable, Identifiable {
    let key: String
    let label: String
    let price: ConfigPrice?
    let pricePerSqm: ConfigPrice?
    let mode: String?  // "per_sqm" | "fixed" (solo Riscaldamento)

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, label, price, mode
        case pricePerSqm = "price_per_sqm"
    }

    /// Prezzo "effettivo" per il livello — usa `price` se presente, altrimenti `price_per_sqm`.
    func effectivePrice(for level: RenovationLevel) -> Double {
        if let p = price { return p.value(for: level) }
        if let p = pricePerSqm { return p.value(for: level) }
        return 0
    }
}

struct ToggleField: Codable, Hashable, Sendable {
    let type: String   // "toggle"
    let key: String
    let label: String
    let description: String?
    let extraCost: ConfigPrice?      // Cucina toggle (isola, elettrodomestici)
    let multiplier: ConfigMultiplier? // Impianto elettrico full_rebuild

    enum CodingKeys: String, CodingKey {
        case type, key, label, description, multiplier
        case extraCost = "extra_cost"
    }
}

struct NumberInput: Codable, Hashable, Sendable {
    let type: String   // "number_input"
    let key: String
    let label: String
    let unitLabel: String?
    let min: Double
    let max: Double
    let `default`: Double
    let step: Double
    let pricePerUnit: ConfigPrice?  // Cucina mt lineari, Climatizzazione split (non Serramenti window_count)

    enum CodingKeys: String, CodingKey {
        case type, key, label, min, max, step
        case unitLabel = "unit_label"
        case `default`
        case pricePerUnit = "price_per_unit"
    }
}

struct SizePicker: Codable, Hashable, Sendable {
    let type: String   // "size_picker"
    let key: String
    let label: String
    let options: [SizeOption]
}

struct SizeOption: Codable, Hashable, Sendable, Identifiable {
    let key: String
    let label: String
    let areaSqm: Double

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, label
        case areaSqm = "area_sqm"
    }
}

// MARK: - User configuration state (lato client)

/// Valore selezionato dall'utente per un singolo field.
enum ConfigValue: Hashable, Sendable {
    case variant(groupKey: String?, optionKey: String)
    case toggle(Bool)
    case number(Double)
    case size(optionKey: String)
}

/// Riassunto leggibile della configurazione (per UI summary, PDF dossier, persistenza).
struct ConfigurationSummary: Codable, Hashable, Sendable {
    /// Coppie label → valore (es. ["Materiale": "Parquet rovere", "Metri lineari": "4.5 m"]).
    let lines: [String]
}
