//
//  PropertyDetailViewModel.swift
//  Domus Arkai
//

import Foundation

@MainActor
@Observable
final class PropertyDetailViewModel {
    let property: Property
    var media: [PropertyMedia] = []
    var floorplan2D: PropertyFloorplan?
    var floorplan3D: PropertyFloorplan3D?
    var agency: Agency?
    var isLoadingMedia: Bool = false

    private let favoritesStore = FavoritesStore.shared

    var isFavorite: Bool {
        favoritesStore.contains(property.id)
    }

    init(property: Property) {
        self.property = property
    }

    func load() async {
        isLoadingMedia = true
        defer { isLoadingMedia = false }
        async let mediaTask = MediaService.shared.fetchMedia(propertyID: property.id)
        async let plan2DTask = MediaService.shared.fetchFloorplan2D(propertyID: property.id)
        async let plan3DTask = MediaService.shared.fetch3DAsset(propertyID: property.id)
        async let agencyTask: Agency? = {
            guard let aid = property.agencyID else { return nil }
            return try? await AgencyService.shared.fetchAgency(id: aid)
        }()
        media = (try? await mediaTask) ?? []
        floorplan2D = try? await plan2DTask
        floorplan3D = try? await plan3DTask
        agency = await agencyTask
    }

    func toggleFavorite() {
        favoritesStore.toggle(property.id)
    }
}
