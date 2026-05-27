//
//  BuyerPassportViewModel.swift
//  Domus Arkai
//
//  Stato + sync per il Buyer Passport.
//

import Foundation
import Auth

@MainActor
@Observable
final class BuyerPassportViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case saving
        case error(String)
    }

    var passport: BuyerPassport?
    var phase: Phase = .idle

    // Form fields (editable)
    var maxBudget: String = ""
    var liquidity: String = ""
    var mortgageNeededPct: String = ""
    var minBedrooms: Int = 0
    var minBathrooms: Int = 0
    var preferredAreasInput: String = ""
    var preferredCategories: Set<String> = []

    static let availableCategories: [(key: String, label: String)] = [
        ("appartamento", "Appartamento"),
        ("attico", "Attico"),
        ("villa", "Villa"),
        ("loft", "Loft"),
        ("monolocale", "Monolocale")
    ]

    func load() async {
        let auth = AuthService.shared
        guard let uid = auth.currentUser?.id else {
            phase = .idle
            return
        }
        phase = .loading
        print("🟢 [Passport][VM] load() for user=\(uid)")
        do {
            let result = try await BuyerPassportService.shared.fetchPassport(userID: uid)
            passport = result
            hydrateForm(from: result)
            phase = .loaded
            print("✅ [Passport][VM] passport \(result == nil ? "non presente" : "caricato") · tier=\(result?.tier.label ?? "—")")
        } catch {
            print("🔴 [Passport][VM] load failed — \(error)")
            phase = .error("Impossibile caricare il Passaporto. Riprova.")
        }
    }

    func save() async {
        let auth = AuthService.shared
        guard let uid = auth.currentUser?.id else {
            phase = .error("Accedi per salvare il Passaporto.")
            return
        }
        phase = .saving
        print("🟢 [Passport][VM] save() for user=\(uid)")
        let draft = BuyerPassportDraft(
            userID: uid,
            maxBudget: parseDouble(maxBudget),
            liquidity: parseDouble(liquidity),
            mortgageNeededPct: parseDouble(mortgageNeededPct),
            preferredAreas: parseAreas(preferredAreasInput),
            preferredCategory: preferredCategories.isEmpty ? nil : Array(preferredCategories),
            minBedrooms: minBedrooms > 0 ? minBedrooms : nil,
            minBathrooms: minBathrooms > 0 ? minBathrooms : nil
        )
        do {
            let saved = try await BuyerPassportService.shared.upsertPassport(draft)
            passport = saved
            hydrateForm(from: saved)
            phase = .loaded
            print("✅ [Passport][VM] saved — score=\(saved.buyerScore), tier=\(saved.tier.label)")
        } catch {
            print("🔴 [Passport][VM] save failed — \(error)")
            phase = .error("Salvataggio non riuscito. Riprova.")
        }
    }

    // MARK: - Helpers

    private func hydrateForm(from passport: BuyerPassport?) {
        guard let p = passport else { return }
        maxBudget = p.maxBudget.map { String(Int($0)) } ?? ""
        liquidity = p.liquidity.map { String(Int($0)) } ?? ""
        mortgageNeededPct = p.mortgageNeededPct.map { String(Int($0)) } ?? ""
        minBedrooms = p.minBedrooms ?? 0
        minBathrooms = p.minBathrooms ?? 0
        preferredAreasInput = (p.preferredAreas ?? []).joined(separator: ", ")
        preferredCategories = Set(p.preferredCategory ?? [])
    }

    private func parseDouble(_ s: String) -> Double? {
        let cleaned = s.replacingOccurrences(of: " ", with: "")
                       .replacingOccurrences(of: ".", with: "")
                       .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    private func parseAreas(_ s: String) -> [String]? {
        let parts = s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                     .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts
    }
}
