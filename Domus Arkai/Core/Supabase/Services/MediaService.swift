//
//  MediaService.swift
//  Domus Arkai
//

import Foundation
import Supabase

actor MediaService {
    static let shared = MediaService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Tutti i media (gallery) per un immobile, ordinati per `order_index`.
    func fetchMedia(propertyID: UUID) async throws -> [PropertyMedia] {
        let rows: [PropertyMedia] = try await client
            .from("property_media")
            .select()
            .eq("property_id", value: propertyID.uuidString)
            .order("order_index", ascending: true)
            .execute()
            .value
        return rows
    }

    /// Planimetria 2D per immobile (primo match).
    func fetchFloorplan2D(propertyID: UUID) async throws -> PropertyFloorplan? {
        let rows: [PropertyFloorplan] = try await client
            .from("property_floorplans")
            .select()
            .eq("property_id", value: propertyID.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Asset 3D (immagine statica) per immobile.
    func fetch3DAsset(propertyID: UUID) async throws -> PropertyFloorplan3D? {
        let rows: [PropertyFloorplan3D] = try await client
            .from("property_3d_assets")
            .select()
            .eq("property_id", value: propertyID.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}
