//
//  Agency.swift
//  Domus Arkai
//
//  Schema 1:1 con tabella `agencies` Supabase.
//  Multi-tenant: ogni agenzia partner ha i propri immobili + branding.
//

import Foundation

struct Agency: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let slug: String?
    let logoURL: URL?
    let coverImageURL: URL?
    let description: String?
    let phone: String?
    let email: String?
    let whatsapp: String?
    let address: String?
    let city: String?
    let website: URL?
    let pwaURL: URL?
    let isFeatured: Bool?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, slug
        case logoURL = "logo_url"
        case coverImageURL = "cover_image_url"
        case description
        case phone, email, whatsapp, address, city, website
        case pwaURL = "pwa_url"
        case isFeatured = "is_featured"
        case isActive = "is_active"
    }

    /// Memberwise init esplicito (Swift lo rimuove quando definisco init custom Decodable).
    init(
        id: UUID,
        name: String,
        slug: String? = nil,
        logoURL: URL? = nil,
        coverImageURL: URL? = nil,
        description: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        whatsapp: String? = nil,
        address: String? = nil,
        city: String? = nil,
        website: URL? = nil,
        pwaURL: URL? = nil,
        isFeatured: Bool? = nil,
        isActive: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.logoURL = logoURL
        self.coverImageURL = coverImageURL
        self.description = description
        self.phone = phone
        self.email = email
        self.whatsapp = whatsapp
        self.address = address
        self.city = city
        self.website = website
        self.pwaURL = pwaURL
        self.isFeatured = isFeatured
        self.isActive = isActive
    }

    /// Decoder resiliente: i campi nuovi (cover_image_url, description, is_featured, pwa_url, is_active)
    /// possono mancare se il DB non è ancora migrato. In quel caso restano nil/default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.slug = try c.decodeIfPresent(String.self, forKey: .slug)
        self.logoURL = try c.decodeIfPresent(URL.self, forKey: .logoURL)
        self.coverImageURL = try? c.decodeIfPresent(URL.self, forKey: .coverImageURL)
        self.description = try? c.decodeIfPresent(String.self, forKey: .description)
        self.phone = try c.decodeIfPresent(String.self, forKey: .phone)
        self.email = try c.decodeIfPresent(String.self, forKey: .email)
        self.whatsapp = try c.decodeIfPresent(String.self, forKey: .whatsapp)
        self.address = try c.decodeIfPresent(String.self, forKey: .address)
        self.city = try c.decodeIfPresent(String.self, forKey: .city)
        self.website = try c.decodeIfPresent(URL.self, forKey: .website)
        self.pwaURL = try? c.decodeIfPresent(URL.self, forKey: .pwaURL)
        self.isFeatured = try? c.decodeIfPresent(Bool.self, forKey: .isFeatured)
        self.isActive = try? c.decodeIfPresent(Bool.self, forKey: .isActive)
    }
}
