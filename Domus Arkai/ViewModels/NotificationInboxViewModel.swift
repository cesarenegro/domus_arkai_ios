//
//  NotificationInboxViewModel.swift
//  Domus Arkai
//
//  Stato + fetch della inbox notifiche utente. Espone `unreadCount` come @Observable
//  per il badge della campanella in HomeView.
//

import Foundation
import Auth

@MainActor
@Observable
final class NotificationInboxViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    var notifications: [UserNotification] = []
    var phase: Phase = .idle

    var unreadCount: Int {
        notifications.lazy.filter { $0.isUnread }.count
    }

    func load() async {
        guard let userID = AuthService.shared.currentUser?.id else {
            phase = .idle
            notifications = []
            return
        }
        phase = .loading
        do {
            notifications = try await UserNotificationsService.shared.fetchInbox(userID: userID)
            phase = .loaded
        } catch {
            print("🔴 [Inbox][VM] load failed — \(error)")
            phase = .error("Impossibile caricare le notifiche.")
        }
    }

    func markAsRead(_ notification: UserNotification) async {
        guard notification.isUnread else { return }
        do {
            try await UserNotificationsService.shared.markAsRead(id: notification.id)
            // Ottimistic update locale
            if let idx = notifications.firstIndex(of: notification) {
                let updated = UserNotification(
                    id: notification.id,
                    userID: notification.userID,
                    title: notification.title,
                    body: notification.body,
                    deepLink: notification.deepLink,
                    source: notification.source,
                    sentAt: notification.sentAt,
                    readAt: Date()
                )
                notifications[idx] = updated
            }
        } catch {
            print("🔴 [Inbox][VM] markAsRead failed — \(error)")
        }
    }

    func markAllAsRead() async {
        guard let userID = AuthService.shared.currentUser?.id else { return }
        do {
            try await UserNotificationsService.shared.markAllAsRead(userID: userID)
            await load()
        } catch {
            print("🔴 [Inbox][VM] markAllAsRead failed — \(error)")
        }
    }

    func delete(_ notification: UserNotification) async {
        do {
            try await UserNotificationsService.shared.delete(id: notification.id)
            notifications.removeAll { $0.id == notification.id }
        } catch {
            print("🔴 [Inbox][VM] delete failed — \(error)")
        }
    }
}
