//
//  RenovationViewModel.swift
//  Domus Arkai
//
//  Calcolatore ristrutturazione parametrico + BOQ regional (k_final città) + Difficoltà cantiere.
//  Formula interna (MAI esposta in UI): total = quantity × unit_price × k_final × K_difficolta.
//

import Foundation

@MainActor
@Observable
final class RenovationViewModel {
    let property: Property
    var items: [RenovationItem] = []
    var categories: [RenovationCategory] = []
    var difficultyFactors: [BOQDifficultyFactor] = []
    var selectedDifficultyKeys: Set<String> = []
    var regionalCoef: BOQRegionalCoefficient?

    var selectedQuantities: [UUID: Double] = [:]
    /// Variante materiale selezionata per item (key di `MaterialVariant`). Nil = default item price.
    var selectedVariants: [UUID: String] = [:]
    /// Configurazioni parametriche per item (chiave field → valore). Solo per items con `configurationSchema`.
    var selectedConfigurations: [UUID: [String: ConfigValue]] = [:]
    var level: RenovationLevel = .medium
    var isLoading: Bool = false
    /// Override metratura editabile dall'utente. Nil = usa `propertySurface`.
    var surfaceOverride: Double?

    /// v2.1 — Se la property ha una scansione 3D RoomPlan disponibile, l'area
    /// effettiva (m² dei floors) viene popolata qui e usata come override di
    /// default. L'utente può comunque modificarla.
    var scanArea: Double?

    init(property: Property) {
        self.property = property
    }

    var propertySurface: Double {
        property.surfaceCommercial ?? 80
    }

    /// Metratura usata per i calcoli (override utente o `propertySurface`).
    var workingSurface: Double {
        surfaceOverride ?? propertySurface
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        async let itemsResult = fetchItemsLogged()
        async let categoriesResult = fetchCategoriesLogged()
        async let factorsResult = fetchFactorsLogged()
        async let regionalTask = (try? BOQService.shared.fetchRegionalCoefficient(city: property.city ?? "Milano"))
        // v2.1 — pre-fetch ultima scansione per auto-popolare l'area
        async let scanTask: PropertyScan? = (try? await PropertyScanService.shared.latestScan(forPropertyID: property.id))

        let rawItems = await itemsResult
        let cats = await categoriesResult
        difficultyFactors = await factorsResult
        regionalCoef = await regionalTask
        if let scan = await scanTask, let area = scan.totalAreaM2, area > 0 {
            scanArea = area
            // Auto-imposta override SOLO se l'utente non ha già toccato il campo
            if surfaceOverride == nil {
                surfaceOverride = area
                print("✅ [Renovation][VM] auto-filled surfaceOverride = \(area) m² da scansione 3D")
            }
        }

        let catByID = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
        items = rawItems.map { item in
            var copy = item
            copy.categoryName = item.categoryID.flatMap { catByID[$0] }
            return copy
        }
        categories = cats
        print("📦 [Renovation] loaded items=\(items.count) categories=\(categories.count) factors=\(difficultyFactors.count)")
    }

    private func fetchItemsLogged() async -> [RenovationItem] {
        do {
            return try await BOQService.shared.fetchRenovationItems(agencyID: property.agencyID)
        } catch {
            print("🔴 [Renovation] fetchRenovationItems failed — \(error)")
            return []
        }
    }

    private func fetchCategoriesLogged() async -> [RenovationCategory] {
        do {
            return try await BOQService.shared.fetchRenovationCategories(agencyID: property.agencyID)
        } catch {
            print("🔴 [Renovation] fetchRenovationCategories failed — \(error)")
            return []
        }
    }

    private func fetchFactorsLogged() async -> [BOQDifficultyFactor] {
        do {
            return try await BOQService.shared.fetchDifficultyFactors()
        } catch {
            print("🔴 [Renovation] fetchDifficultyFactors failed — \(error)")
            return []
        }
    }

    // MARK: - Quantity management

    func defaultQuantity(for item: RenovationItem) -> Double {
        switch item.unitType {
        case .sqm:
            return min(item.maxQuantity, max(item.minQuantity, workingSurface))
        case .unit, .other:
            return item.defaultQuantity
        }
    }

    func quantity(for item: RenovationItem) -> Double {
        selectedQuantities[item.id] ?? 0
    }

    func isSelected(_ item: RenovationItem) -> Bool {
        selectedQuantities[item.id] != nil
    }

    func toggle(_ item: RenovationItem) {
        if isSelected(item) {
            selectedQuantities.removeValue(forKey: item.id)
            selectedVariants.removeValue(forKey: item.id)
            selectedConfigurations.removeValue(forKey: item.id)
        } else {
            selectedQuantities[item.id] = defaultQuantity(for: item)
            if let firstVariant = item.materialVariants?.first {
                selectedVariants[item.id] = firstVariant.key
            }
            // Inizializza configurazione parametrica con default
            if let schema = item.configurationSchema {
                selectedConfigurations[item.id] = defaultConfiguration(for: schema)
            }
        }
    }

    /// Inizializza la configurazione con i valori di default per ciascun field dello schema.
    private func defaultConfiguration(for schema: ConfigurationSchema) -> [String: ConfigValue] {
        var values: [String: ConfigValue] = [:]
        for field in schema.fields {
            switch field {
            case .groupedVariantPicker(let f):
                if let firstGroup = f.groups.first, let firstOpt = firstGroup.options.first {
                    values[f.key] = .variant(groupKey: firstGroup.key, optionKey: firstOpt.key)
                }
            case .variantPicker(let f):
                if let firstOpt = f.options.first {
                    values[f.key] = .variant(groupKey: nil, optionKey: firstOpt.key)
                }
            case .toggle(let f):
                values[f.key] = .toggle(false)
            case .numberInput(let f):
                values[f.key] = .number(f.default)
            case .sizePicker(let f):
                if let firstOpt = f.options.first {
                    values[f.key] = .size(optionKey: firstOpt.key)
                }
            }
        }
        return values
    }

    // MARK: - Configuration access (parametric items)

    func configValue(for item: RenovationItem, fieldKey: String) -> ConfigValue? {
        selectedConfigurations[item.id]?[fieldKey]
    }

    func setConfigValue(_ value: ConfigValue, for item: RenovationItem, fieldKey: String) {
        if !isSelected(item) {
            toggle(item)
        }
        var current = selectedConfigurations[item.id] ?? [:]
        current[fieldKey] = value
        selectedConfigurations[item.id] = current
    }

    func boolConfig(for item: RenovationItem, key: String) -> Bool {
        if case .toggle(let v) = configValue(for: item, fieldKey: key) { return v }
        return false
    }

    func numberConfig(for item: RenovationItem, key: String) -> Double {
        if case .number(let v) = configValue(for: item, fieldKey: key) { return v }
        return 0
    }

    func variantOptionKey(for item: RenovationItem, fieldKey: String) -> String? {
        if case .variant(_, let optKey) = configValue(for: item, fieldKey: fieldKey) { return optKey }
        return nil
    }

    func sizeOptionKey(for item: RenovationItem, fieldKey: String) -> String? {
        if case .size(let optKey) = configValue(for: item, fieldKey: fieldKey) { return optKey }
        return nil
    }

    func updateQuantity(_ item: RenovationItem, to value: Double) {
        let clamped = max(item.minQuantity, min(value, item.maxQuantity))
        selectedQuantities[item.id] = clamped
    }

    // MARK: - Material variants

    /// Variante materiale selezionata per un item (nil se assente o non-applicabile).
    func selectedVariant(for item: RenovationItem) -> MaterialVariant? {
        guard let key = selectedVariants[item.id] else { return nil }
        return item.materialVariants?.first(where: { $0.key == key })
    }

    /// Imposta la variante selezionata per un item. Se l'item non è ancora selezionato, lo seleziona.
    func selectVariant(_ variant: MaterialVariant, for item: RenovationItem) {
        if !isSelected(item) {
            selectedQuantities[item.id] = defaultQuantity(for: item)
        }
        selectedVariants[item.id] = variant.key
    }

    /// Prezzo unitario corrente (con eventuale variante).
    func currentUnitPrice(for item: RenovationItem) -> Double {
        item.unitPrice(for: level, variant: selectedVariant(for: item))
    }

    // MARK: - Difficulty

    func toggleDifficulty(_ factor: BOQDifficultyFactor) {
        if selectedDifficultyKeys.contains(factor.key) {
            selectedDifficultyKeys.remove(factor.key)
        } else {
            selectedDifficultyKeys.insert(factor.key)
        }
    }

    func isDifficultySelected(_ factor: BOQDifficultyFactor) -> Bool {
        selectedDifficultyKeys.contains(factor.key)
    }

    // MARK: - Cost calculation (INTERNAL — multiplier MAI esposti in UI)

    /// Moltiplicatore regionale (1.0 fallback se non disponibile).
    private var kFinal: Double {
        regionalCoef?.kFinal ?? 1.0
    }

    /// Moltiplicatore difficoltà cantiere (1.0 se nessun factor selezionato).
    private var kDifficulty: Double {
        difficultyFactors
            .filter { selectedDifficultyKeys.contains($0.key) }
            .reduce(1.0) { $0 * $1.multiplier }
    }

    /// Costo intervento singolo. Usa il cost engine parametrico se presente schema,
    /// altrimenti il calcolo legacy (livello × variante × quantità).
    func cost(of item: RenovationItem) -> Double {
        guard isSelected(item) else { return 0 }
        let base: Double
        if let schema = item.configurationSchema {
            base = parametricBaseCost(item: item, schema: schema)
        } else {
            base = item.baseCost(level: level, quantity: quantity(for: item), variant: selectedVariant(for: item))
        }
        return base * kFinal * kDifficulty
    }

    /// Cost engine per items con `configurationSchema`. Hardcoded per item.unit (mappa formule
    /// note dichiarate da Marco lato server). NON interpreta `cost_formula` stringa.
    private func parametricBaseCost(item: RenovationItem, schema: ConfigurationSchema) -> Double {
        parametricBaseCost(item: item, schema: schema, level: level)
    }

    private func parametricBaseCost(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        switch schema.unit {
        case "sqm":
            return costSqmUnit(item: item, schema: schema, level: level)
        case "porta":
            return costPortaUnit(item: item, schema: schema, level: level)
        case "cucina":
            return costCucinaUnit(item: item, schema: schema, level: level)
        case "serramento":
            return costSerramentoUnit(item: item, schema: schema, level: level)
        case "split":
            return costNumberInputUnit(item: item, schema: schema, level: level)
        case "impianto":
            return costImpiantoUnit(item: item, schema: schema, level: level)
        default:
            return 0
        }
    }

    private func costSqmUnit(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        let qty = quantity(for: item)
        var unitPrice: Double = 0
        var multiplier: Double = 1.0
        for field in schema.fields {
            switch field {
            case .groupedVariantPicker(let f):
                if let optKey = variantOptionKey(for: item, fieldKey: f.key),
                   let opt = f.groups.flatMap(\.options).first(where: { $0.key == optKey }) {
                    unitPrice += opt.effectivePrice(for: level)
                }
            case .variantPicker(let f):
                if let optKey = variantOptionKey(for: item, fieldKey: f.key),
                   let opt = f.options.first(where: { $0.key == optKey }) {
                    unitPrice += opt.effectivePrice(for: level)
                }
            case .toggle(let f):
                let on = boolConfig(for: item, key: f.key)
                if let m = f.multiplier { multiplier *= m.value(for: on) }
                if let extra = f.extraCost { unitPrice += on ? extra.value(for: level) : 0 }
            default: break
            }
        }
        return qty * unitPrice * multiplier
    }

    private func costPortaUnit(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        let qty = quantity(for: item)
        var unitPrice: Double = 0
        for field in schema.fields {
            if case .variantPicker(let f) = field,
               let optKey = variantOptionKey(for: item, fieldKey: f.key),
               let opt = f.options.first(where: { $0.key == optKey }) {
                unitPrice += opt.effectivePrice(for: level)
            }
        }
        return qty * unitPrice
    }

    private func costCucinaUnit(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        var total: Double = 0
        for field in schema.fields {
            switch field {
            case .numberInput(let f):
                let qty = numberConfig(for: item, key: f.key)
                if let p = f.pricePerUnit {
                    total += qty * p.value(for: level)
                }
            case .toggle(let f):
                let on = boolConfig(for: item, key: f.key)
                if on, let extra = f.extraCost {
                    total += extra.value(for: level)
                }
            default: break
            }
        }
        return total
    }

    private func costSerramentoUnit(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        var count: Double = 0
        var sizeSqm: Double = 0
        var pricePerSqm: Double = 0
        for field in schema.fields {
            switch field {
            case .numberInput(let f):
                count = numberConfig(for: item, key: f.key)
            case .sizePicker(let f):
                if let optKey = sizeOptionKey(for: item, fieldKey: f.key),
                   let opt = f.options.first(where: { $0.key == optKey }) {
                    sizeSqm = opt.areaSqm
                }
            case .variantPicker(let f):
                if let optKey = variantOptionKey(for: item, fieldKey: f.key),
                   let opt = f.options.first(where: { $0.key == optKey }) {
                    pricePerSqm = opt.effectivePrice(for: level)
                }
            default: break
            }
        }
        return count * sizeSqm * pricePerSqm
    }

    private func costNumberInputUnit(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        var total: Double = 0
        for field in schema.fields {
            if case .numberInput(let f) = field {
                let qty = numberConfig(for: item, key: f.key)
                if let p = f.pricePerUnit {
                    total += qty * p.value(for: level)
                }
            }
        }
        return total
    }

    private func costImpiantoUnit(item: RenovationItem, schema: ConfigurationSchema, level: RenovationLevel) -> Double {
        for field in schema.fields {
            if case .variantPicker(let f) = field,
               let optKey = variantOptionKey(for: item, fieldKey: f.key),
               let opt = f.options.first(where: { $0.key == optKey }) {
                let mode = opt.mode ?? "per_sqm"
                let price = opt.effectivePrice(for: level)
                if mode == "fixed" {
                    return price
                } else {
                    return workingSurface * price
                }
            }
        }
        return 0
    }

    var selectedItems: [RenovationItem] {
        items.filter { isSelected($0) }
    }

    var total: Double {
        selectedItems.reduce(0) { $0 + cost(of: $1) }
    }

    var totalForLevel: (essential: Double, medium: Double, premium: Double) {
        func tot(_ level: RenovationLevel) -> Double {
            selectedItems.reduce(0) { partial, item in
                let base: Double
                if let schema = item.configurationSchema {
                    base = parametricBaseCost(item: item, schema: schema, level: level)
                } else {
                    let variant = selectedVariant(for: item)
                    base = item.baseCost(level: level, quantity: quantity(for: item), variant: variant)
                }
                return partial + base * kFinal * kDifficulty
            }
        }
        return (tot(.essential), tot(.medium), tot(.premium))
    }

    var groupedItems: [(category: String, items: [RenovationItem])] {
        // Raggruppa per categoryName (fallback "Altro" se assente).
        let groups = Dictionary(grouping: items, by: { $0.categoryName ?? "Altro" })
        // Mantieni l'ordine di renovation_categories.order_index quando possibile
        let orderedNames = categories.map(\.name)
        let known = orderedNames.compactMap { name -> (category: String, items: [RenovationItem])? in
            guard let items = groups[name] else { return nil }
            return (category: name, items: items)
        }
        let extras = groups
            .filter { !orderedNames.contains($0.key) }
            .map { (category: $0.key, items: $0.value) }
        return known + extras
    }

    // MARK: - Brand-safe display

    /// Messaggio istituzionale da mostrare se ci sono difficoltà selezionate (mai i multiplier).
    var difficultyIntegrationMessage: String? {
        guard !selectedDifficultyKeys.isEmpty else { return nil }
        return "Le complessità logistiche selezionate sono state integrate nella pianificazione dei costi di cantiere."
    }

    // MARK: - Dossier integration

    /// Lista interventi serializzabile per "Il mio Dossier".
    /// Per items con `configurationSchema`: nome arricchito col riepilogo config (es. "Cucina · 4.5m + isola").
    /// Per items legacy: nome arricchito con variante (es. "Pavimenti — Parquet rovere").
    var dossierLines: [DossierRenovationLine] {
        selectedItems.map { item in
            let qty = quantity(for: item)
            let finalTotal = cost(of: item)
            if item.configurationSchema != nil {
                let summary = configurationSummary(for: item)
                let summaryStr = summary.map { "\($0.value)" }.joined(separator: " · ")
                let displayName = summaryStr.isEmpty ? item.name : "\(item.name) · \(summaryStr)"
                return DossierRenovationLine(
                    itemID: item.id,
                    categoryID: item.categoryID,
                    name: displayName,
                    level: level.rawValue,
                    quantity: qty,
                    unitPrice: 0,
                    lineTotal: finalTotal,
                    variantKey: nil,
                    variantLabel: summaryStr.isEmpty ? nil : summaryStr
                )
            } else {
                let variant = selectedVariant(for: item)
                let displayName = variant.map { "\(item.name) — \($0.label)" } ?? item.name
                return DossierRenovationLine(
                    itemID: item.id,
                    categoryID: item.categoryID,
                    name: displayName,
                    level: level.rawValue,
                    quantity: qty,
                    unitPrice: item.unitPrice(for: level, variant: variant),
                    lineTotal: finalTotal,
                    variantKey: variant?.key,
                    variantLabel: variant?.label
                )
            }
        }
    }

    var selectedDifficultyKeysList: [String] {
        Array(selectedDifficultyKeys).sorted()
    }

    // MARK: - Configuration summary (UI/dossier)

    /// Riassunto human-readable della configurazione scelta per un item parametrico
    /// (es. ["Materiale": "Parquet rovere", "Metri lineari": "4.5 m", "Con isola": "sì"]).
    func configurationSummary(for item: RenovationItem) -> [(label: String, value: String)] {
        guard let schema = item.configurationSchema else { return [] }
        var lines: [(label: String, value: String)] = []
        for field in schema.fields {
            switch field {
            case .groupedVariantPicker(let f):
                if let optKey = variantOptionKey(for: item, fieldKey: f.key),
                   let opt = f.groups.flatMap(\.options).first(where: { $0.key == optKey }) {
                    lines.append((f.label, opt.label))
                }
            case .variantPicker(let f):
                if let optKey = variantOptionKey(for: item, fieldKey: f.key),
                   let opt = f.options.first(where: { $0.key == optKey }) {
                    lines.append((f.label, opt.label))
                }
            case .toggle(let f):
                let on = boolConfig(for: item, key: f.key)
                lines.append((f.label, on ? "Sì" : "No"))
            case .numberInput(let f):
                let qty = numberConfig(for: item, key: f.key)
                let formatted = qty.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(qty)) \(f.unitLabel ?? "")"
                    : String(format: "%.1f %@", qty, f.unitLabel ?? "")
                lines.append((f.label, formatted.trimmingCharacters(in: .whitespaces)))
            case .sizePicker(let f):
                if let optKey = sizeOptionKey(for: item, fieldKey: f.key),
                   let opt = f.options.first(where: { $0.key == optKey }) {
                    lines.append((f.label, opt.label))
                }
            }
        }
        return lines
    }
}
