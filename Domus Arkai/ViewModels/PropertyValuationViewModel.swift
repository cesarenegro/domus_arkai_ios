//
//  PropertyValuationViewModel.swift
//  Domus Arkai
//
//  AVM: stima del valore immobile basata su OMI + portali + condizione + piano.
//

import Foundation

@MainActor
@Observable
final class PropertyValuationViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case unavailable(String)
        case error(String)
    }

    let property: Property
    var state: LoadState = .idle
    var valuation: PropertyValuation?

    init(property: Property) {
        self.property = property
    }

    func compute() async {
        state = .loading
        do {
            if let result = try await MarketPriceService.shared.valuate(property: property) {
                valuation = result
                state = .loaded
            } else {
                state = .unavailable("Stima non disponibile per questo immobile.")
            }
        } catch {
            state = .error("Errore nel recupero dei parametri di riferimento. Riprova.")
        }
    }

    // MARK: - Display helpers (brand-safe, no formule esposte)

    var formattedTotal: String {
        guard let v = valuation else { return "—" }
        return v.estimatedTotalValue.formattedEuro()
    }

    var formattedPerSqm: String {
        guard let v = valuation else { return "—" }
        return "\(v.estimatedValuePerSqm.formattedEuro()) / mq"
    }

    var zoneLabel: String {
        guard let z = valuation?.zone else { return "—" }
        let city = z.city
        let zone = z.zoneName
        return "\(zone) · \(city)"
    }

    var distanceLabel: String? {
        guard let d = valuation?.zone.distanceKm else { return nil }
        if d < 1.0 { return "Zona di riferimento entro 1 km" }
        return String(format: "Zona di riferimento a %.1f km", d)
    }

    var marketRangeLabel: String {
        guard let z = valuation?.zone else { return "" }
        return "Range di mercato della zona: da \(z.omiMinSqm.formattedEuro()) a \(z.omiMaxSqm.formattedEuro()) al mq."
    }

    /// Confronto col prezzo richiesto.
    var priceComparison: (label: String, isAlignment: Bool)? {
        guard let asking = property.price, let valuated = valuation?.estimatedTotalValue else { return nil }
        let delta = asking - valuated
        let pct = abs(delta) / valuated * 100
        if pct < 5 {
            return ("Il prezzo richiesto è in linea con la valutazione di zona.", true)
        } else if delta > 0 {
            return ("Il prezzo richiesto è superiore alla valutazione di zona di circa \(Int(pct))%.", false)
        } else {
            return ("Il prezzo richiesto è inferiore alla valutazione di zona di circa \(Int(pct))%.", true)
        }
    }
}
