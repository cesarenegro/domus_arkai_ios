//
//  FavoritesStore.swift
//  Domus Arkai
//
//  Persistenza locale dei preferiti (MVP: UserDefaults).
//  Fase 2: sync su Supabase se aggiungeremo auth utente.
//

import Foundation
import Observation

@MainActor
@Observable
final class FavoritesStore {
    static let shared = FavoritesStore()

    private(set) var ids: Set<UUID> = []

    private let storageKey = "favorites_property_ids"
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func contains(_ id: UUID) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: UUID) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        save()
    }

    func remove(_ id: UUID) {
        ids.remove(id)
        save()
    }

    private func save() {
        let strings = ids.map { $0.uuidString }
        defaults.set(strings, forKey: storageKey)
    }

    private func load() {
        guard let strings = defaults.array(forKey: storageKey) as? [String] else { return }
        ids = Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
