//
//  MockDataService.swift
//  Domus Arkai
//
//  Dati finti per sviluppare la UI prima che arrivi lo schema/seed reale da Supabase.
//  Sostituire con PropertyService reale quando avremo i Models definitivi.
//

import Foundation

actor MockDataService {
    static let shared = MockDataService()

    private let demoAgency = Agency(
        id: UUID(),
        name: "Studio Casa Milano",
        slug: "studio-casa-milano",
        logoURL: nil,
        phone: "+39 02 1234567",
        email: "info@studiocasamilano.it",
        whatsapp: "+39 333 1234567",
        address: "Via Brera 10, Milano",
        city: "Milano",
        website: URL(string: "https://studiocasamilano.it")
    )

    func currentAgency() async -> Agency {
        demoAgency
    }

    func fetchProperties(filters: SearchFilters = SearchFilters()) async throws -> [Property] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return mockProperties.filter { matches(property: $0, filters: filters) }
    }

    func fetchMedia(for propertyID: UUID) async -> [PropertyMedia] {
        let urls: [URL] = mockGalleryURLs.compactMap { URL(string: $0) }
        return urls.enumerated().map { idx, url in
            PropertyMedia(
                id: UUID(),
                propertyID: propertyID,
                url: url,
                mediaType: idx == 0 ? .cover : .gallery,
                orderIndex: idx,
                isCover: idx == 0
            )
        }
    }

    func fetchFloorplan2D(for propertyID: UUID) async -> PropertyFloorplan? {
        guard let url = URL(string: mockFloorplan2DURL) else { return nil }
        return PropertyFloorplan(id: UUID(), propertyID: propertyID, url: url, kind: .plan2D)
    }

    func fetchFloorplan3D(for propertyID: UUID) async -> PropertyFloorplan3D? {
        guard let url = URL(string: mockFloorplan3DURL) else { return nil }
        return PropertyFloorplan3D(
            id: UUID(),
            propertyID: propertyID,
            previewImageURL: url,
            assetURL: nil,
            assetType: .staticImage
        )
    }

    // fetchRenovationItems rimosso — ora usiamo BOQService.shared.fetchRenovationItems() dal backend reale.

    func fetchProperty(byID id: UUID) async -> Property? {
        mockProperties.first { $0.id == id }
    }

    func submitVisitRequest(
        propertyID: UUID,
        name: String,
        email: String,
        phone: String,
        preferredDate: Date,
        timeSlot: VisitRequest.TimeSlot,
        notes: String?
    ) async throws -> VisitRequest {
        try await Task.sleep(nanoseconds: 600_000_000)
        let lead = Lead(
            id: UUID(),
            agencyID: demoAgency.id,
            propertyID: propertyID,
            name: name,
            email: email,
            phone: phone,
            message: notes,
            source: .visitRequest,
            status: .new,
            createdAt: Date()
        )
        return VisitRequest(
            id: UUID(),
            agencyID: demoAgency.id,
            propertyID: propertyID,
            leadID: lead.id,
            preferredDate: preferredDate,
            preferredTimeSlot: timeSlot,
            notes: notes,
            status: .new,
            createdAt: Date()
        )
    }

private let mockGalleryURLs: [String] = [
        "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1400&q=80",
        "https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1400&q=80",
        "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1400&q=80",
        "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=1400&q=80",
        "https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=1400&q=80",
        "https://images.unsplash.com/photo-1502672023488-70e25813eb80?w=1400&q=80",
        "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=1400&q=80"
    ]

    private let mockFloorplan2DURL = "https://images.unsplash.com/photo-1503174971373-b1f69850bded?w=1200&q=80"
    private let mockFloorplan3DURL = "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80"

    private func matches(property: Property, filters: SearchFilters) -> Bool {
        if !filters.query.isEmpty {
            let q = filters.query.lowercased()
            let haystack = "\(property.title) \(property.locationLine)".lowercased()
            if !haystack.contains(q) { return false }
        }
        if let contract = filters.contractType, property.contractType != contract { return false }
        if !filters.propertyTypes.isEmpty {
            guard let type = property.propertyType, filters.propertyTypes.contains(type) else { return false }
        }
        if let pmin = filters.priceMin, (property.price ?? 0) < pmin { return false }
        if let pmax = filters.priceMax, (property.price ?? .infinity) > pmax { return false }
        if let smin = filters.surfaceMin, (property.surfaceCommercial ?? 0) < smin { return false }
        if let smax = filters.surfaceMax, (property.surfaceCommercial ?? 0) > smax { return false }
        if let minR = filters.minRooms, (property.rooms ?? 0) < minR { return false }
        for feature in filters.features {
            switch feature {
            case .terrazza: if !property.hasTerrace { return false }
            case .giardino: if !property.hasGarden { return false }
            case .box: if !property.hasGarage { return false }
            case .ascensore: if !property.hasElevator { return false }
            case .ristrutturato:
                if property.conditionStatus?.lowercased().contains("ristruttur") != true { return false }
            }
        }
        return true
    }

    // MARK: - Sample data

    private lazy var mockProperties: [Property] = [
        Property(
            id: UUID(),
            agencyID: demoAgency.id,
            title: "Attico in Brera",
            descriptionShort: "Attico panoramico con terrazza vista Duomo, finiture sartoriali e luce naturale tutto il giorno.",
            descriptionLong: nil,
            propertyType: .attico,
            contractType: .vendita,
            price: 780_000,
            city: "Milano",
            area: "Brera",
            addressPublic: "Via Brera",
            latitude: 45.4716,
            longitude: 9.1879,
            surfaceCommercial: 120,
            surfaceInternal: 110,
            rooms: 3,
            bedrooms: 2,
            bathrooms: 2,
            floor: "5",
            totalFloors: 6,
            hasElevator: true,
            hasBalcony: false,
            hasTerrace: true,
            hasGarden: false,
            hasGarage: false,
            hasParking: false,
            hasCellar: true,
            conditionStatus: "Ristrutturato",
            energyClass: .a2,
            publishedStatus: .online,
            isFeatured: true,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80")
        ),
        Property(
            id: UUID(),
            agencyID: demoAgency.id,
            title: "Trilocale ristrutturato",
            descriptionShort: "Trilocale completamente ristrutturato in palazzina liberty, finiture moderne.",
            descriptionLong: nil,
            propertyType: .appartamento,
            contractType: .vendita,
            price: 650_000,
            city: "Milano",
            area: "Porta Venezia",
            addressPublic: "Corso Buenos Aires",
            latitude: 45.4744,
            longitude: 9.2024,
            surfaceCommercial: 95,
            surfaceInternal: 88,
            rooms: 3,
            bedrooms: 2,
            bathrooms: 2,
            floor: "3",
            totalFloors: 5,
            hasElevator: true,
            hasBalcony: true,
            hasTerrace: false,
            hasGarden: false,
            hasGarage: false,
            hasParking: false,
            hasCellar: false,
            conditionStatus: "Ristrutturato",
            energyClass: .b,
            publishedStatus: .online,
            isFeatured: false,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80")
        ),
        Property(
            id: UUID(),
            agencyID: demoAgency.id,
            title: "Villa con giardino",
            descriptionShort: "Villa singola con giardino privato e box doppio, zona residenziale tranquilla.",
            descriptionLong: nil,
            propertyType: .villa,
            contractType: .vendita,
            price: 1_350_000,
            city: "Milano",
            area: "San Siro",
            addressPublic: "Via Novara",
            latitude: 45.4781,
            longitude: 9.1232,
            surfaceCommercial: 230,
            surfaceInternal: 210,
            rooms: 5,
            bedrooms: 4,
            bathrooms: 3,
            floor: "T",
            totalFloors: 2,
            hasElevator: false,
            hasBalcony: false,
            hasTerrace: true,
            hasGarden: true,
            hasGarage: true,
            hasParking: true,
            hasCellar: true,
            conditionStatus: "Ottimo",
            energyClass: .a1,
            publishedStatus: .online,
            isFeatured: true,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80")
        ),
        Property(
            id: UUID(),
            agencyID: demoAgency.id,
            title: "Loft Navigli",
            descriptionShort: "Loft di design fronte Naviglio Grande, ex laboratorio artigianale convertito.",
            descriptionLong: nil,
            propertyType: .loft,
            contractType: .affitto,
            price: 2_400,
            city: "Milano",
            area: "Navigli",
            addressPublic: "Alzaia Naviglio Grande",
            latitude: 45.4519,
            longitude: 9.1681,
            surfaceCommercial: 85,
            surfaceInternal: 80,
            rooms: 2,
            bedrooms: 1,
            bathrooms: 1,
            floor: "T",
            totalFloors: 3,
            hasElevator: false,
            hasBalcony: true,
            hasTerrace: false,
            hasGarden: false,
            hasGarage: false,
            hasParking: false,
            hasCellar: false,
            conditionStatus: "Ristrutturato",
            energyClass: .c,
            publishedStatus: .online,
            isFeatured: false,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80")
        ),
        Property(
            id: UUID(),
            agencyID: demoAgency.id,
            title: "Bilocale luminoso Isola",
            descriptionShort: "Bilocale con vista grattacieli e ampia terrazza, palazzina di nuova costruzione.",
            descriptionLong: nil,
            propertyType: .appartamento,
            contractType: .vendita,
            price: 420_000,
            city: "Milano",
            area: "Isola",
            addressPublic: "Via Confalonieri",
            latitude: 45.4858,
            longitude: 9.1908,
            surfaceCommercial: 65,
            surfaceInternal: 60,
            rooms: 2,
            bedrooms: 1,
            bathrooms: 1,
            floor: "8",
            totalFloors: 12,
            hasElevator: true,
            hasBalcony: false,
            hasTerrace: true,
            hasGarden: false,
            hasGarage: false,
            hasParking: true,
            hasCellar: true,
            conditionStatus: "Nuovo",
            energyClass: .a3,
            publishedStatus: .online,
            isFeatured: false,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80")
        )
    ]
}
