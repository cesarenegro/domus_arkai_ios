//
//  VisualBOQViewModel.swift
//  Domus Arkai
//
//  Stato per la pipeline "Arkai Vision Pro" — foto stanza → analisi → BOQ stimato.
//

import Foundation
import UIKit

@MainActor
@Observable
final class VisualBOQViewModel {
    enum Phase: Equatable {
        case capture                 // utente sta scegliendo foto + parametri
        case analyzing               // chiamata in corso
        case result                  // analisi completata
        case error(String)
    }

    let property: Property?
    var phase: Phase = .capture
    var selectedImages: [UIImage] = []
    var roomType: VisualBOQService.RoomType = .bagno
    var city: String
    var availableDifficultyFactors: [BOQDifficultyFactor] = []
    var selectedDifficultyKeys: Set<String> = []
    var result: VisualBOQResponse?

    init(property: Property?) {
        self.property = property
        self.city = property?.city ?? "Milano"
        print("🟢 [VisionPRO][VM] init — propertyID=\(property?.id.uuidString ?? "nil"), city=\(self.city)")
    }

    func loadDifficultyFactors() async {
        print("🔍 [VisionPRO][VM] loadDifficultyFactors() start")
        do {
            let factors = try await BOQService.shared.fetchDifficultyFactors()
            availableDifficultyFactors = factors
            print("✅ [VisionPRO][VM] loaded \(factors.count) difficulty factors")
        } catch {
            print("🔴 [VisionPRO][VM] failed to load difficulty factors — \(error)")
            availableDifficultyFactors = []
        }
    }

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

    var canAnalyze: Bool {
        !selectedImages.isEmpty
            && !city.isEmpty
            && phase != .analyzing
            && SubscriptionService.shared.canUseVisionAnalysis
    }

    func analyze() async {
        guard canAnalyze else {
            print("⚠️ [VisionPRO][VM] analyze() blocked — canAnalyze=false (images=\(selectedImages.count), city='\(city)', phase=\(phase))")
            return
        }
        print("🟢 [VisionPRO][VM] analyze() begin — images=\(selectedImages.count), room=\(roomType.rawValue), city=\(city), factors=\(Array(selectedDifficultyKeys))")
        phase = .analyzing
        do {
            let response = try await VisualBOQService.shared.analyze(
                images: selectedImages,
                roomType: roomType,
                city: city,
                difficultyFactors: Array(selectedDifficultyKeys),
                propertyID: property?.id
            )
            result = response
            phase = .result
            // Registra l'uso della quota mensile (1 analisi consumata)
            SubscriptionService.shared.recordVisionAnalysisUsed()
            print("✅ [VisionPRO][VM] phase -> .result (estimateID=\(response.estimateID), works=\(response.estimatedWorks.count), total=\(Int(response.totalEstimatedCost))€)")
        } catch VisualBOQService.VisualBOQError.quotaExceeded {
            print("🟡 [VisionPRO][VM] quota exceeded from server")
            // Sincronizza il counter locale con la realtà server
            SubscriptionService.shared.markVisionQuotaExhausted()
            phase = .error("Hai esaurito le 5 analisi gratuite di questo mese. Riprova il primo del prossimo mese.")
        } catch {
            print("🔴 [VisionPRO][VM] analyze() failed — \(error)")
            phase = .error("Analisi non riuscita. Riprova tra qualche istante.")
        }
    }

    func resetToCapture() {
        print("🔄 [VisionPRO][VM] resetToCapture()")
        result = nil
        phase = .capture
    }
}
