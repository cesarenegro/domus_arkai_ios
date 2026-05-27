//
//  NotificationService.swift
//  Domus Arkai
//
//  Gestione unificata notifiche LOCALI + REMOTE (APNs).
//
//  Locali:  visit reminders (24h + 1h prima visita).
//  Remote: device token upsert su Supabase `device_tokens` → Edge Function `send-push`
//          chiamata da trigger backend (risposta agenzia, novità immobili, ecc.).
//

import Foundation
import UIKit
import UserNotifications
import Auth

@MainActor
@Observable
final class NotificationService: NSObject {
    static let shared = NotificationService()

    enum AuthorizationStatus: Equatable {
        case notDetermined
        case denied
        case authorized
        case provisional
    }

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var apnsDeviceToken: String?

    private var hasRequestedRegistration: Bool = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Permission

    /// Mostra all'utente la richiesta di autorizzazione notifiche (banner + sound).
    /// Se l'utente acconsente, registra il device su APNs in background.
    @discardableResult
    func requestAuthorization() async -> Bool {
        print("🟢 [Push] requestAuthorization()")
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                registerForRemoteNotifications()
            }
            print("✅ [Push] authorization granted=\(granted)")
            return granted
        } catch {
            print("🔴 [Push] requestAuthorization failed — \(error)")
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let new: AuthorizationStatus = {
            switch settings.authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .authorized: return .authorized
            case .provisional: return .provisional
            case .ephemeral: return .authorized
            @unknown default: return .notDetermined
            }
        }()
        authorizationStatus = new

        // Se già autorizzato, registra remoto (idempotente).
        if (new == .authorized || new == .provisional), !hasRequestedRegistration {
            registerForRemoteNotifications()
        }
    }

    private func registerForRemoteNotifications() {
        hasRequestedRegistration = true
        print("🟢 [Push] registering for remote notifications")
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Device token (chiamato dall'AppDelegate)

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        apnsDeviceToken = token
        print("✅ [Push] APNs device token: \(token.prefix(16))…")
        Task { await persistTokenIfNeeded() }
    }

    func handleRegistrationFailure(_ error: Error) {
        print("🔴 [Push] APNs registration failed — \(error)")
    }

    /// Persisti il token su Supabase se l'utente è loggato.
    /// Public per consentire retry esterno dopo Sign In with Apple (vedi AuthService.signInWithApple).
    func persistTokenIfNeeded() async {
        guard let token = apnsDeviceToken else {
            print("⚠️ [Push] persistTokenIfNeeded skipped — no device token yet")
            return
        }
        guard let userID = AuthService.shared.currentUser?.id else {
            print("⚠️ [Push] persistTokenIfNeeded skipped — no user logged in (sarà riprovato al sign-in)")
            return
        }
        do {
            try await DeviceTokenService.shared.upsertToken(
                userID: userID,
                apnsToken: token,
                locale: Locale.current.identifier
            )
            print("✅ [Push] device token persisted on Supabase (user=\(userID))")
        } catch {
            print("🔴 [Push] persist token failed — \(error)")
        }
    }

    // MARK: - Local notifications (visit reminders)

    /// Schedula 2 reminder locali per una visita: 24h prima e 1h prima dell'orario indicato.
    /// `propertyTitle` viene mostrato nel body della notifica.
    func scheduleVisitReminder(visitDate: Date, propertyTitle: String, visitID: UUID) async {
        let now = Date()
        let calendar = Calendar.current

        let twentyFourHoursBefore = calendar.date(byAdding: .hour, value: -24, to: visitDate)
        let oneHourBefore = calendar.date(byAdding: .hour, value: -1, to: visitDate)

        let schedules: [(Date, String, String)] = [
            (twentyFourHoursBefore ?? visitDate,
             "Visita domani",
             "Hai una visita programmata per \(propertyTitle). Ti aspettiamo."),
            (oneHourBefore ?? visitDate,
             "Visita tra un'ora",
             "Ricorda: visita di \(propertyTitle) tra un'ora.")
        ]

        for (idx, schedule) in schedules.enumerated() {
            let (when, title, body) = schedule
            guard when > now else { continue }
            await scheduleLocal(
                identifier: "visit-\(visitID.uuidString)-\(idx)",
                title: title,
                body: body,
                date: when
            )
        }
    }

    private func scheduleLocal(identifier: String, title: String, body: String, date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ [Push][Local] scheduled '\(title)' at \(date) (id=\(identifier))")
        } catch {
            print("🔴 [Push][Local] schedule failed — \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate (per gestire foreground + tap)

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Mostra la notifica anche se l'app è in foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Tap su una notifica (in background o killed state).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        print("📬 [Push] notification tapped — id=\(id)")
        // TODO: deep linking quando avremo i payload remoti (es. apri PropertyDetail con propertyID).
        completionHandler()
    }
}
