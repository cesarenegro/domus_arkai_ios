//
//  PropertyMedia.swift
//  Domus Arkai
//

import Foundation

struct PropertyMedia: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let propertyID: UUID
    let url: URL
    let mediaType: MediaType
    let orderIndex: Int
    let isCover: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case propertyID = "property_id"
        case url = "file_url"
        case mediaType = "media_type"
        case orderIndex = "order_index"
        case isCover = "is_cover"
    }
}

enum MediaType: String, Codable, Hashable, Sendable, CaseIterable {
    case cover
    case gallery
    case photo
}

struct PropertyFloorplan: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let propertyID: UUID
    let url: URL
    let kind: Kind

    enum Kind: String, Codable, Hashable, Sendable {
        case plan2D = "2d_plan"
        case optimized = "optimized_plan"
        case pdf = "pdf_plan"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case propertyID = "property_id"
        case url = "file_url"
        case kind = "type"
    }
}

struct PropertyFloorplan3D: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let propertyID: UUID
    let previewImageURL: URL?
    let assetURL: URL?
    let assetType: AssetType

    enum AssetType: String, Codable, Hashable, Sendable {
        case staticImage = "static_image"
        case usdz
        case glb
    }

    enum CodingKeys: String, CodingKey {
        case id
        case propertyID = "property_id"
        case previewImageURL = "preview_image_url"
        case assetURL = "asset_url"
        case assetType = "asset_type"
    }
}
