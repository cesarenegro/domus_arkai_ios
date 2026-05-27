//
//  MapboxConfig.swift
//  Domus Arkai
//
//  Configurazione Mapbox per static map nel PDF Dossier.
//  Allineato col token + style ID usato dal web pannello admin (HUB confermato 23/05/2026).
//

import Foundation
import CoreGraphics

enum MapboxConfig {
    /// Token publishable lato client (allineato col frontend web, HUB 23/05/2026).
    static let accessToken = "pk.eyJ1IjoiY2VjZWhrZzIyIiwiYSI6ImNtbmIzdjFzYzBveGMycHB0Ym10OHg5OW4ifQ.ZVSZ9CDEKw5IqevXBWzjdQ"

    /// Style ID light premium off-white-sand (allineato col web).
    static let defaultStyleID = "mapbox/light-v11"

    /// Colore pin brand (sand/gold) in hex senza `#`.
    static let pinColorHex = "c5a977"

    /// Costruisce l'URL per Mapbox Static Images API con pin centrato.
    /// - Parameters:
    ///   - latitude/longitude: coordinate property
    ///   - width/height: dimensione immagine in punti (verrà richiesto @2x)
    ///   - zoom: livello zoom (default 14 ≈ 1.3 km span)
    static func staticMapURL(
        latitude: Double,
        longitude: Double,
        width: Int = 280,
        height: Int = 200,
        zoom: Double = 14,
        styleID: String = defaultStyleID
    ) -> URL? {
        // Mapbox Static API: /styles/v1/{style}/static/[pin]/[lon,lat,zoom,bearing]/[wxh]@2x
        let pinSegment = "pin-l+\(pinColorHex)(\(longitude),\(latitude))"
        let positionSegment = "\(longitude),\(latitude),\(zoom),0"
        let sizeSegment = "\(width)x\(height)@2x"
        let urlString = "https://api.mapbox.com/styles/v1/\(styleID)/static/\(pinSegment)/\(positionSegment)/\(sizeSegment)?access_token=\(accessToken)"
        return URL(string: urlString)
    }
}
