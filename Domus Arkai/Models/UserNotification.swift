//
//  UserNotification.swift
//  Domus Arkai
//
//  Schema 1:1 con tabella `user_notifications` Supabase.
//  Persistita dal server quando viene invocata `send-push`, consente l'inbox in-app
//  per consultare le notifiche anche dopo che la push iOS native è sparita.
//

import Foundation

struct UserNotification: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let title: String
    let body: String
    let deepLink: String?
    let source: String?
    let sentAt: Date?
    let readAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case body
        case deepLink = "deep_link"
        case source
        case sentAt = "sent_at"
        case readAt = "read_at"
    }

    var isUnread: Bool { readAt == nil }

    /// Etichetta tempo relativa ("2 min fa", "Ieri", "12 mag", ecc.)
    var relativeTimeLabel: String {
        guard let sentAt else { return "" }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.unitsStyle = .short
        return f.localizedString(for: sentAt, relativeTo: Date())
    }

    /// Icona SF Symbol scelta in base alla source.
    var iconName: String {
        switch source {
        case "visit_confirmed": "calendar.badge.checkmark"
        case "new_property": "house.fill"
        case "agency_message": "bubble.left.fill"
        case "admin_broadcast": "megaphone.fill"
        case "system": "bell.fill"
        default: "bell"
        }
    }
}
