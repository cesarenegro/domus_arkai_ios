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

    /// v2.0 Spatial Staging — ultima scansione di QUALSIASI status (pending/processing/ready).
    /// Durante v2.0 dev se la pipeline server non ha ancora prodotto staging_usdz_url
    /// la card fa fallback su un USDZ demo locale (vedi SpatialStagingCard).
    var latestScan: PropertyScan?

    private let favoritesStore = FavoritesStore.shared

    var isFavorite: Bool {
        favoritesStore.contains(property.id)
    }

    /// Ultima scansione disponibile per questa property (per la card "Spatial Staging").
    var primaryStagingScan: PropertyScan? {
        latestScan
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
        async let scanTask: PropertyScan? = {
            (try? await PropertyScanService.shared.latestScan(forPropertyID: property.id))
        }()
        media = (try? await mediaTask) ?? []
        floorplan2D = try? await plan2DTask
        floorplan3D = try? await plan3DTask
        agency = await agencyTask
        latestScan = await scanTask
    }

    func toggleFavorite() {
        favoritesStore.toggle(property.id)
    }
}
