//
//  PropertyService.swift
//  Domus Arkai
//
//  Wrapper Supabase per la tabella `properties` + join `property_media` per cover image.
//

import Foundation
import Supabase

actor PropertyService {
    static let shared = PropertyService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Fetch properties pubblicate (published_status = 'online').
    /// Enriches con cover image URL da property_media (is_cover=true).
    func fetchPublishedProperties(featured: Bool? = nil) async throws -> [Property] {
        var query = client
            .from("properties")
            .select()
            .eq("published_status", value: "online")

        if let featured = featured {
            query = query.eq("is_featured", value: featured)
        }

        let properties: [Property] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value

        return await enrichWithCovers(properties)
    }

    func fetchProperty(byID id: UUID) async throws -> Property? {
        let properties: [Property] = try await client
            .from("properties")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        guard let property = properties.first else { return nil }
        let enriched = await enrichWithCovers([property])
        return enriched.first
    }

    /// Fetch batch di properties per ID (utile per "I miei Dossier" → un fetch invece di N).
    func fetchProperties(byIDs ids: [UUID]) async throws -> [Property] {
        guard !ids.isEmpty else { return [] }
        let properties: [Property] = try await client
            .from("properties")
            .select()
            .in("id", values: ids.map { $0.uuidString })
            .execute()
            .value
        return await enrichWithCovers(properties)
    }

    /// Enriches property list aggiungendo coverImageURL dalla tabella property_media.
    private func enrichWithCovers(_ properties: [Property]) async -> [Property] {
        guard !properties.isEmpty else { return properties }
        let propertyIDs = properties.map { $0.id.uuidString }

        struct CoverRow: Codable {
            let propertyID: UUID
            let fileURL: String?

            enum CodingKeys: String, CodingKey {
                case propertyID = "property_id"
                case fileURL = "file_url"
            }
        }

        do {
            let rows: [CoverRow] = try await client
                .from("property_media")
                .select("property_id, file_url")
                .in("property_id", values: propertyIDs)
                .eq("is_cover", value: true)
                .execute()
                .value

            var coverByID: [UUID: URL] = [:]
            for row in rows {
                if let urlStr = row.fileURL, let url = URL(string: urlStr) {
                    coverByID[row.propertyID] = url
                }
            }

            return properties.map { $0.withCover(coverByID[$0.id]) }
        } catch {
            return properties
        }
    }
}
