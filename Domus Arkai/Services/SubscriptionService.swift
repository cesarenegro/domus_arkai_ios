//
//  SubscriptionService.swift
//  Domus Arkai
//
//  L'app è GRATUITA per i clienti delle agenzie. Niente subscription, niente IAP.
//  L'unico capping è una QUOTA MENSILE per Arkai Vision Pro (Visual BOQ), che è
//  l'unica feature che chiama un servizio AI esterno a pagamento per Arkai Domus.
//
//  Modello:
//  - 5 analisi Vision al mese per utente, gratuite.
//  - Counter mensile in UserDefaults (chiave include YYYY-MM → reset automatico al cambio mese).
//  - Server-side: Edge Function `analyze-room-photos` ha rate limit (HTTP 429 se quota esaurita).
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    /// Quota Vision gratuita al mese per utente.
    static let monthlyVisionQuota = 5

    /// Numero di analisi Vision usate questo mese (refresh automatico al cambio mese).
    var visionUsedThisMonth: Int {
        UserDefaults.standard.integer(forKey: currentMonthKey)
    }

    /// Analisi Vision rimanenti questo mese.
    var visionRemainingThisMonth: Int {
        max(0, Self.monthlyVisionQuota - visionUsedThisMonth)
    }

    /// True se l'utente può ancora usare un'analisi Vision questo mese.
    var canUseVisionAnalysis: Bool {
        visionRemainingThisMonth > 0
    }

    /// Data di reset della quota (primo giorno del prossimo mese).
    var nextQuotaResetDate: Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month], from: now)
        components.month! += 1
        components.day = 1
        return calendar.date(from: components) ?? now
    }

    // MARK: - Usage tracking

    /// Da chiamare DOPO ogni analisi Vision conclusa con successo.
    func recordVisionAnalysisUsed() {
        let current = visionUsedThisMonth
        UserDefaults.standard.set(current + 1, forKey: currentMonthKey)
        print("📊 [Quota] Vision used \(current + 1)/\(Self.monthlyVisionQuota) this month")
    }

    /// Da chiamare quando il server ritorna HTTP 429 quota_exceeded.
    /// Forza il counter locale a `monthlyVisionQuota` per allinearlo con la realtà server.
    func markVisionQuotaExhausted() {
        UserDefaults.standard.set(Self.monthlyVisionQuota, forKey: currentMonthKey)
        print("📊 [Quota] Vision marked as exhausted (server-sync)")
    }

    // MARK: - Keys

    private var currentMonthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "arkai_vision_usage_\(formatter.string(from: Date()))"
    }

    // MARK: - DEBUG helpers (per testing senza aspettare il mese)

    #if DEBUG
    /// Reset locale del counter Vision (DEBUG only).
    func resetVisionQuotaForTesting() {
        UserDefaults.standard.set(0, forKey: currentMonthKey)
        print("🛠️ [Quota][DEBUG] reset Vision usage")
    }

    /// Riempi la quota fino a N (DEBUG only).
    func setVisionUsageForTesting(_ count: Int) {
        UserDefaults.standard.set(count, forKey: currentMonthKey)
        print("🛠️ [Quota][DEBUG] set Vision usage to \(count)")
    }
    #endif
}
