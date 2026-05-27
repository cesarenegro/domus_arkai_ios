//
//  Property.swift
//  Domus Arkai
//

import Foundation

struct Property: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let agencyID: UUID?
    let title: String
    let slug: String?
    let descriptionShort: String?
    let descriptionLong: String?
    let propertyType: PropertyType?
    let contractType: ContractType?
    let price: Double?
    let city: String?
    let area: String?
    let address: String?
    let addressPublic: String?
    let latitude: Double?
    let longitude: Double?
    let surfaceCommercial: Double?
    let surfaceInternal: Double?
    let rooms: Int?
    let bedrooms: Int?
    let bathrooms: Int?
    let floor: String?
    let totalFloors: Int?
    let hasElevator: Bool
    let hasBalcony: Bool
    let hasTerrace: Bool
    let hasGarden: Bool
    let hasGarage: Bool
    let hasParking: Bool
    let hasCellar: Bool
    let conditionStatus: String?
    let energyClass: EnergyClass?
    let publishedStatus: PublishedStatus?
    let isFeatured: Bool
    let createdAt: Date?
    let updatedAt: Date?

    /// Cover image URL — NOT decoded da Supabase. Popolato dopo il fetch via
    /// `PropertyMedia` (riga con `is_cover=true`). Default nil.
    var coverImageURL: URL? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case agencyID = "agency_id"
        case title, slug
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case propertyType = "property_type"
        case contractType = "contract_type"
        case price
        case city, area, address
        case addressPublic = "address_public"
        case latitude, longitude
        case surfaceCommercial = "surface_commercial"
        case surfaceInternal = "surface_internal"
        case rooms, bedrooms, bathrooms, floor
        case totalFloors = "total_floors"
        case hasElevator = "has_elevator"
        case hasBalcony = "has_balcony"
        case hasTerrace = "has_terrace"
        case hasGarden = "has_garden"
        case hasGarage = "has_garage"
        case hasParking = "has_parking"
        case hasCellar = "has_cellar"
        case conditionStatus = "condition_status"
        case energyClass = "energy_class"
        case publishedStatus = "published_status"
        case isFeatured = "is_featured"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // NIENTE coverImageURL — è non-Codable, default nil
    }

    init(
        id: UUID,
        agencyID: UUID? = nil,
        title: String,
        slug: String? = nil,
        descriptionShort: String? = nil,
        descriptionLong: String? = nil,
        propertyType: PropertyType? = nil,
        contractType: ContractType? = nil,
        price: Double? = nil,
        city: String? = nil,
        area: String? = nil,
        address: String? = nil,
        addressPublic: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        surfaceCommercial: Double? = nil,
        surfaceInternal: Double? = nil,
        rooms: Int? = nil,
        bedrooms: Int? = nil,
        bathrooms: Int? = nil,
        floor: String? = nil,
        totalFloors: Int? = nil,
        hasElevator: Bool = false,
        hasBalcony: Bool = false,
        hasTerrace: Bool = false,
        hasGarden: Bool = false,
        hasGarage: Bool = false,
        hasParking: Bool = false,
        hasCellar: Bool = false,
        conditionStatus: String? = nil,
        energyClass: EnergyClass? = nil,
        publishedStatus: PublishedStatus? = nil,
        isFeatured: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        coverImageURL: URL? = nil
    ) {
        self.id = id
        self.agencyID = agencyID
        self.title = title
        self.slug = slug
        self.descriptionShort = descriptionShort
        self.descriptionLong = descriptionLong
        self.propertyType = propertyType
        self.contractType = contractType
        self.price = price
        self.city = city
        self.area = area
        self.address = address
        self.addressPublic = addressPublic
        self.latitude = latitude
        self.longitude = longitude
        self.surfaceCommercial = surfaceCommercial
        self.surfaceInternal = surfaceInternal
        self.rooms = rooms
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.floor = floor
        self.totalFloors = totalFloors
        self.hasElevator = hasElevator
        self.hasBalcony = hasBalcony
        self.hasTerrace = hasTerrace
        self.hasGarden = hasGarden
        self.hasGarage = hasGarage
        self.hasParking = hasParking
        self.hasCellar = hasCellar
        self.conditionStatus = conditionStatus
        self.energyClass = energyClass
        self.publishedStatus = publishedStatus
        self.isFeatured = isFeatured
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.coverImageURL = coverImageURL
    }

    /// Ritorna una copia con coverImageURL settato (utile dopo fetch property_media).
    func withCover(_ url: URL?) -> Property {
        var copy = self
        copy.coverImageURL = url
        return copy
    }
}

// MARK: - Display helpers

extension Property {
    var formattedPrice: String {
        guard let price = price else { return "Prezzo su richiesta" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: price)) ?? "€\(Int(price))"
    }

    var locationLine: String {
        [area, city].compactMap { $0 }.joined(separator: ", ")
    }

    var metadataLine: String {
        var parts: [String] = []
        if let sqm = surfaceCommercial { parts.append("\(Int(sqm)) mq") }
        if let r = rooms { parts.append("\(r) \(r == 1 ? "locale" : "locali")") }
        if let b = bathrooms { parts.append("\(b) \(b == 1 ? "bagno" : "bagni")") }
        if hasTerrace { parts.append("Terrazza") }
        else if hasGarden { parts.append("Giardino") }
        else if hasBalcony { parts.append("Balcone") }
        return parts.prefix(4).joined(separator: " · ")
    }
}

// MARK: - Enums (best-guess in attesa schema reale)

enum PropertyType: String, Codable, Hashable, Sendable, CaseIterable {
    case appartamento
    case villa
    case attico
    case loft
    case ufficio
    case terreno
    case localeCommerciale = "locale_commerciale"

    var displayName: String {
        switch self {
        case .appartamento: "Appartamento"
        case .villa: "Villa"
        case .attico: "Attico"
        case .loft: "Loft"
        case .ufficio: "Ufficio"
        case .terreno: "Terreno"
        case .localeCommerciale: "Locale commerciale"
        }
    }
}

enum ContractType: String, Codable, Hashable, Sendable, CaseIterable {
    case vendita
    case affitto

    var displayName: String {
        switch self {
        case .vendita: "Vendita"
        case .affitto: "Affitto"
        }
    }
}

enum EnergyClass: String, Codable, Hashable, Sendable, CaseIterable {
    case a4 = "A4", a3 = "A3", a2 = "A2", a1 = "A1"
    case b = "B", c = "C", d = "D", e = "E", f = "F", g = "G"
}

enum PublishedStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case draft, ready, online, reserved, sold, rented, archived
}
