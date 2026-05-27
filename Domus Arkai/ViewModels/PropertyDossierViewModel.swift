//
//  PropertyDossierViewModel.swift
//  Domus Arkai
//
//  Stato + sync per "Il mio Dossier" di un singolo immobile.
//  Operazioni di merge: mai sovrascrive porzioni del Dossier non interessate dall'azione corrente.
//

import Foundation
import Auth

@MainActor
@Observable
final class PropertyDossierViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case saving
        case error(String)
    }

    let property: Property
    var dossier: PropertyDossier?
    var phase: Phase = .idle

    init(property: Property) {
        self.property = property
    }

    /// Carica il Dossier dell'utente loggato per l'immobile corrente.
    func load() async {
        guard let uid = AuthService.shared.currentUser?.id else {
            print("⚠️ [Dossier][VM] load skipped — no user")
            phase = .idle
            return
        }
        phase = .loading
        do {
            dossier = try await DossierService.shared.fetchDossier(userID: uid, propertyID: property.id)
            phase = .loaded
        } catch {
            print("🔴 [Dossier][VM] load failed — \(error)")
            phase = .error("Impossibile caricare il Dossier.")
        }
    }

    // MARK: - Save helpers (merge baseline + sovrascrive solo i campi del singolo calcolo)

    /// Costruisce un draft baseline con i valori correnti del dossier. Il chiamante sovrascrive ciò che gli serve.
    private func baselineDraft(userID: UUID) -> PropertyDossierDraft {
        let current = dossier
        return PropertyDossierDraft(
            userID: userID,
            propertyID: property.id,
            askingPriceSnapshot: current?.askingPriceSnapshot ?? property.price,
            avmZoneID: current?.avmZoneID,
            avmEstimatedPerSqm: current?.avmEstimatedPerSqm,
            avmEstimatedTotal: current?.avmEstimatedTotal,
            mortgageEstimateID: current?.mortgageEstimateID,
            mortgageMonthlyPayment: current?.mortgageMonthlyPayment,
            renovationTotal: current?.renovationTotal,
            renovationItems: current?.renovationItems,
            renovationDifficultyFactors: current?.renovationDifficultyFactors,
            visualBOQEstimateIDs: current?.visualBOQEstimateIDs,
            visualBOQTotal: current?.visualBOQTotal,
            userNotes: current?.userNotes
        )
    }

    private func currentUserID() throws -> UUID {
        guard let uid = AuthService.shared.currentUser?.id else {
            throw DossierError.notAuthenticated
        }
        return uid
    }

    @discardableResult
    private func performSave(_ draft: PropertyDossierDraft, kind: String) async throws -> PropertyDossier {
        phase = .saving
        do {
            let saved = try await DossierService.shared.upsertDossier(draft)
            dossier = saved
            phase = .loaded
            print("✅ [Dossier][VM] saved \(kind) — dossierID=\(saved.id)")
            return saved
        } catch {
            print("🔴 [Dossier][VM] save \(kind) failed — \(error)")
            phase = .error("Salvataggio non riuscito. Riprova.")
            throw error
        }
    }

    // MARK: - Quick add (solo snapshot prezzo, nessun sotto-calcolo)

    /// Crea un Dossier minimo per l'immobile corrente, salvando solo lo snapshot del prezzo.
    /// Usato dalla CTA "Aggiungi al mio Dossier" su PropertyDetail come gesto rapido.
    /// Se esiste già un Dossier, è un no-op (ritorna quello esistente).
    @discardableResult
    func quickSave() async throws -> PropertyDossier {
        let uid = try currentUserID()
        if let existing = dossier {
            print("⚠️ [Dossier][VM] quickSave skipped — dossier already exists for property=\(property.id)")
            return existing
        }
        var draft = baselineDraft(userID: uid)
        // baselineDraft popola già asking_price_snapshot con property.price
        draft.askingPriceSnapshot = property.price
        return try await performSave(draft, kind: "quickAdd (price=\(Int(property.price ?? 0))€)")
    }

    // MARK: - Renovation (Fase 1)

    @discardableResult
    func saveRenovation(
        total: Double,
        lines: [DossierRenovationLine],
        difficultyFactors: [String]
    ) async throws -> PropertyDossier {
        let uid = try currentUserID()
        var draft = baselineDraft(userID: uid)
        draft.renovationTotal = total
        draft.renovationItems = lines
        draft.renovationDifficultyFactors = difficultyFactors
        return try await performSave(draft, kind: "renovation (\(lines.count) lines, total \(Int(total))€)")
    }

    // MARK: - AVM

    @discardableResult
    func saveAVM(
        zoneID: String?,
        estimatedPerSqm: Double,
        estimatedTotal: Double
    ) async throws -> PropertyDossier {
        let uid = try currentUserID()
        var draft = baselineDraft(userID: uid)
        draft.avmZoneID = zoneID
        draft.avmEstimatedPerSqm = estimatedPerSqm
        draft.avmEstimatedTotal = estimatedTotal
        return try await performSave(draft, kind: "AVM (\(Int(estimatedTotal))€)")
    }

    // MARK: - Mortgage

    @discardableResult
    func saveMortgage(
        estimateID: UUID?,
        monthlyPayment: Double
    ) async throws -> PropertyDossier {
        let uid = try currentUserID()
        var draft = baselineDraft(userID: uid)
        draft.mortgageEstimateID = estimateID
        draft.mortgageMonthlyPayment = monthlyPayment
        return try await performSave(draft, kind: "mortgage (\(Int(monthlyPayment))€/mese)")
    }

    // MARK: - Visual BOQ (può accumulare più analisi stanze)

    @discardableResult
    func appendVisualBOQ(
        estimateID: UUID,
        cost: Double
    ) async throws -> PropertyDossier {
        let uid = try currentUserID()
        var draft = baselineDraft(userID: uid)
        var ids = draft.visualBOQEstimateIDs ?? []
        if !ids.contains(estimateID) { ids.append(estimateID) }
        draft.visualBOQEstimateIDs = ids
        draft.visualBOQTotal = (draft.visualBOQTotal ?? 0) + cost
        return try await performSave(draft, kind: "visualBOQ (+\(Int(cost))€, total=\(Int(draft.visualBOQTotal ?? 0))€)")
    }
}

enum DossierError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Accedi con Apple per salvare nel tuo Dossier."
        }
    }
}
