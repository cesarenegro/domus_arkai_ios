//
//  UserNotificationsService.swift
//  Domus Arkai
//
//  Inbox notifiche utente: fetch + mark-as-read + delete.
//  Le righe vengono create server-side dalla Edge Function `send-push`.
//

import Foundation
import Supabase

actor UserNotificationsService {
    static let shared = UserNotificationsService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Lista delle notifiche dell'utente loggato, più recenti prima.
    func fetchInbox(userID: UUID, limit: Int = 100) async throws -> [UserNotification] {
        let rows: [UserNotification] = try await client
            .from("user_notifications")
            .select()
            .eq("user_id", value: userID.uuidString)
            .order("sent_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        print("✅ [Inbox] fetched \(rows.count) notifications")
        return rows
    }

    /// Marca una singola notifica come letta (set read_at = now).
    func markAsRead(id: UUID) async throws {
        struct ReadUpdate: Encodable { let read_at: String }
        let payload = ReadUpdate(read_at: ISO8601DateFormatter().string(from: Date()))
        try await client
            .from("user_notifications")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
        print("✅ [Inbox] marked as read — id=\(id)")
    }

    /// Marca TUTTE le notifiche dell'utente come lette.
    func markAllAsRead(userID: UUID) async throws {
        struct ReadUpdate: Encodable { let read_at: String }
        let payload = ReadUpdate(read_at: ISO8601DateFormatter().string(from: Date()))
        try await client
            .from("user_notifications")
            .update(payload)
            .eq("user_id", value: userID.uuidString)
            .is("read_at", value: nil)
            .execute()
        print("✅ [Inbox] marked all as read")
    }

    /// Cancella una notifica dall'inbox.
    func delete(id: UUID) async throws {
        try await client
            .from("user_notifications")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        print("✅ [Inbox] deleted — id=\(id)")
    }
}
