//
//  DossierPDFRenderer.swift
//  Domus Arkai
//
//  Renderer multipagina del Dossier in formato A4 portrait.
//  Async loading di tutti gli asset visivi (hero, mappa, planimetria, gallery)
//  PRIMA del rendering CGContext.
//

import SwiftUI
import CoreGraphics
import UIKit
import MapKit

// MARK: - Bundle di asset precaricati per il PDF

struct DossierPDFAssets: Sendable {
    var heroImage: UIImage?
    var floorplanImage: UIImage?
    var mapSnapshot: UIImage?
    var galleryImages: [UIImage] = []
}

@MainActor
enum DossierPDFRenderer {

    /// Render multipagina async: precarica tutti gli asset visivi e poi compone il PDF.
    static func render(
        property: Property,
        dossier: PropertyDossier,
        userDisplayName: String,
        generatedAt: Date = Date()
    ) async -> Data? {
        print("🟢 [PDF][Renderer] start — property=\(property.id), dossierLines=\(dossier.renovationItems?.count ?? 0)")

        let assets = await loadAssets(property: property)
        print("📦 [PDF][Renderer] assets ready — hero=\(assets.heroImage != nil), map=\(assets.mapSnapshot != nil), floorplan=\(assets.floorplanImage != nil), gallery=\(assets.galleryImages.count)")

        // Suddividi le righe di ristrutturazione in pagine (12 per pagina)
        let allLines = dossier.renovationItems ?? []
        let itemsPerPage = DossierPDFRenovationPage.maxItemsPerPage
        let renovationChunks: [[DossierRenovationLine]] = stride(from: 0, to: max(allLines.count, 0), by: itemsPerPage)
            .map { Array(allLines[$0..<min($0 + itemsPerPage, allLines.count)]) }

        let hasRenovation = !renovationChunks.isEmpty
        let hasDetails = dossier.avmEstimatedTotal != nil
            || dossier.mortgageMonthlyPayment != nil
            || (dossier.visualBOQTotal ?? 0) > 0

        var totalPages = 2  // cover + summary
        if hasRenovation { totalPages += renovationChunks.count }
        if hasDetails { totalPages += 1 }

        var pageViews: [AnyView] = []
        // 1. Cover
        pageViews.append(AnyView(
            DossierPDFCoverPage(
                property: property,
                dossier: dossier,
                userDisplayName: userDisplayName,
                generatedAt: generatedAt,
                heroImage: assets.heroImage
            )
        ))
        // 2. Summary (con mappa + floorplan nel right column)
        pageViews.append(AnyView(
            DossierPDFSummaryPage(
                property: property,
                dossier: dossier,
                pageNumber: 2,
                totalPages: totalPages,
                mapSnapshot: assets.mapSnapshot,
                floorplanImage: assets.floorplanImage
            )
        ))
        // 3..N. Renovation pages (l'ultima ha la galleria foto)
        if hasRenovation {
            for (idx, chunk) in renovationChunks.enumerated() {
                let pageNumber = 3 + idx
                let isLast = idx == renovationChunks.count - 1
                pageViews.append(AnyView(
                    DossierPDFRenovationPage(
                        dossier: dossier,
                        pageNumber: pageNumber,
                        totalPages: totalPages,
                        items: chunk,
                        pageIndex: idx,
                        totalItemPages: renovationChunks.count,
                        galleryImages: isLast ? assets.galleryImages : []
                    )
                ))
            }
        }
        // N+1. Details
        if hasDetails {
            pageViews.append(AnyView(
                DossierPDFDetailsPage(
                    property: property,
                    dossier: dossier,
                    pageNumber: totalPages,
                    totalPages: totalPages
                )
            ))
        }

        return composePDF(pages: pageViews)
    }

    // MARK: - Asset loading (parallelo)

    private static func loadAssets(property: Property) async -> DossierPDFAssets {
        // Hero pre-cropato al ratio esatto del frame Cover (595/522 ≈ 1.14)
        let heroRatio = DossierPDFFormat.pageSize.width / (DossierPDFFormat.pageSize.height * 0.62)
        async let hero = loadImage(url: property.coverImageURL, targetAspectRatio: heroRatio)
        async let floorplan = loadFloorplan(propertyID: property.id)
        async let map = renderMapSnapshot(property: property)
        async let gallery = loadGallery(propertyID: property.id)

        let assets = DossierPDFAssets(
            heroImage: await hero,
            floorplanImage: await floorplan,
            mapSnapshot: await map,
            galleryImages: await gallery
        )
        return assets
    }

    // MARK: - Image fetch (HTTPS)

    /// Carica + (opzionale) center-crop al ratio target + downscale + CGImage-backed UIImage.
    private static func loadImage(
        url: URL?,
        maxSide: CGFloat = 800,
        targetAspectRatio: CGFloat? = nil
    ) async -> UIImage? {
        guard let url else {
            print("⚠️ [PDF][Renderer] no URL")
            return nil
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("📥 [PDF][Renderer] downloaded \(data.count / 1024) KB from \(url.lastPathComponent) (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))")
            guard let raw = UIImage(data: data) else {
                print("🔴 [PDF][Renderer] UIImage init nil")
                return nil
            }
            let cropped: UIImage = {
                guard let ratio = targetAspectRatio else { return raw }
                return centerCrop(raw, toAspectRatio: ratio) ?? raw
            }()
            return downscaleAndNormalize(cropped, maxSide: maxSide)
        } catch {
            print("🔴 [PDF][Renderer] image load failed — \(error)")
            return nil
        }
    }

    /// Center-crop di un'UIImage al ratio target (es. 595/522 per hero della cover).
    private static func centerCrop(_ image: UIImage, toAspectRatio ratio: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let srcW = CGFloat(cg.width)
        let srcH = CGFloat(cg.height)
        let srcRatio = srcW / srcH

        var cropRect: CGRect
        if srcRatio > ratio {
            // sorgente più larga del target → cropa orizzontalmente
            let newW = srcH * ratio
            let xOffset = (srcW - newW) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newW, height: srcH)
        } else {
            // sorgente più alta del target → cropa verticalmente
            let newH = srcW / ratio
            let yOffset = (srcH - newH) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: srcW, height: newH)
        }
        guard let cropped = cg.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped, scale: 1.0, orientation: .up)
    }

    /// Ridimensiona a max `maxSide` (lato lungo) e ritorna una UIImage backed da CGImage diretto in sRGB.
    /// Riempie bianco lo sfondo prima del draw per evitare pixel undefined.
    /// Garantisce `cgImage != nil` per renderizzazione affidabile in ImageRenderer.
    private static func downscaleAndNormalize(_ image: UIImage, maxSide: CGFloat) -> UIImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else {
            print("🔴 [PDF][Renderer] image has zero size")
            return nil
        }
        let longest = max(size.width, size.height)
        let scale = longest > maxSide ? maxSide / longest : 1.0
        let target = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false // RGBA buffer
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let normalized = renderer.image { ctx in
            // Riempi bianco esplicito (evita pixel undefined nei bordi sub-pixel)
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: target))
            image.draw(in: CGRect(origin: .zero, size: target))
        }

        // Force CGImage-backed UIImage (ImageRenderer renderizza solo CGImage-backed in modo affidabile)
        guard let cg = normalized.cgImage else {
            print("⚠️ [PDF][Renderer] no cgImage after normalize, fallback to original")
            return image
        }
        let final = UIImage(cgImage: cg, scale: 1.0, orientation: .up)
        print("🖼️ [PDF][Renderer] image normalized — \(Int(size.width))x\(Int(size.height)) → \(Int(target.width))x\(Int(target.height)) (cgImage=\(cg.width)x\(cg.height))")
        return final
    }

    private static func loadFloorplan(propertyID: UUID) async -> UIImage? {
        do {
            guard let floorplan = try await MediaService.shared.fetchFloorplan2D(propertyID: propertyID) else {
                print("⚠️ [PDF][Renderer] no floorplan for \(propertyID)")
                return nil
            }
            return await loadImage(url: floorplan.url)
        } catch {
            print("🔴 [PDF][Renderer] floorplan fetch failed — \(error)")
            return nil
        }
    }

    private static func loadGallery(propertyID: UUID) async -> [UIImage] {
        do {
            let media = try await MediaService.shared.fetchMedia(propertyID: propertyID)
            let urls = media.filter { !$0.isCover }.prefix(6).map(\.url)
            var imgs: [UIImage] = []
            for url in urls {
                if let img = await loadImage(url: url) {
                    imgs.append(img)
                }
            }
            return imgs
        } catch {
            print("🔴 [PDF][Renderer] gallery fetch failed — \(error)")
            return []
        }
    }

    // MARK: - Map snapshot (Mapbox Static API con fallback MKMapSnapshotter)

    private static func renderMapSnapshot(property: Property) async -> UIImage? {
        guard let lat = property.latitude, let lon = property.longitude else {
            print("⚠️ [PDF][Renderer] no coordinates for map snapshot")
            return nil
        }

        // 1. Tentativo Mapbox Static API (style + pin allineati al web)
        if let mapboxURL = MapboxConfig.staticMapURL(latitude: lat, longitude: lon) {
            if let img = await downloadMapboxStaticMap(url: mapboxURL) {
                print("🗺️ [PDF][Renderer] Mapbox static map ok")
                return img
            }
            print("⚠️ [PDF][Renderer] Mapbox failed, falling back to MKMapSnapshotter")
        }

        // 2. Fallback MKMapSnapshotter (Apple Maps)
        return await renderAppleMapSnapshot(latitude: lat, longitude: lon)
    }

    private static func downloadMapboxStaticMap(url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📥 [PDF][Renderer] downloaded \(data.count / 1024) KB from Mapbox (HTTP \(status))")
            guard status == 200, let raw = UIImage(data: data) else {
                if status != 200, let body = String(data: data, encoding: .utf8) {
                    print("🔴 [PDF][Renderer] Mapbox HTTP \(status) body=\(body.prefix(200))")
                }
                return nil
            }
            return downscaleAndNormalize(raw, maxSide: 800)
        } catch {
            print("🔴 [PDF][Renderer] Mapbox download error — \(error)")
            return nil
        }
    }

    private static func renderAppleMapSnapshot(latitude: Double, longitude: Double) async -> UIImage? {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
        options.size = CGSize(width: 280, height: 200)
        options.scale = 2.0
        options.mapType = .standard

        return await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start { snapshot, error in
                if let error {
                    print("🔴 [PDF][Renderer] Apple map fallback failed — \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let snapshot else {
                    continuation.resume(returning: nil)
                    return
                }
                let image = snapshot.image
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                image.draw(at: .zero)
                let point = snapshot.point(for: coord)
                let pinSize = CGSize(width: 16, height: 16)
                let pinRect = CGRect(
                    x: point.x - pinSize.width / 2,
                    y: point.y - pinSize.height / 2,
                    width: pinSize.width, height: pinSize.height
                )
                UIColor(red: 0.77, green: 0.66, blue: 0.47, alpha: 1.0).setFill() // brand sand #c5a977
                let path = UIBezierPath(ovalIn: pinRect)
                path.fill()
                UIColor.white.setStroke()
                path.lineWidth = 2
                path.stroke()
                let composed = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                continuation.resume(returning: composed?.preparingForDisplay() ?? composed)
            }
        }
    }

    // MARK: - PDF composition

    private static func composePDF(pages: [AnyView]) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData) else {
            print("🔴 [PDF][Renderer] CGDataConsumer init failed")
            return nil
        }
        var mediaBox = CGRect(origin: .zero, size: DossierPDFFormat.pageSize)
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            print("🔴 [PDF][Renderer] CGContext PDF init failed")
            return nil
        }

        // FIX iOS 26: il path `ImageRenderer.render(closure)` con CGContext PDF
        // NON rasterizza correttamente `Image(uiImage:)` (zone nere). Usiamo
        // invece `ImageRenderer.uiImage` (rasterizzazione bitmap completa) e poi
        // disegniamo il CGImage risultante nel PDF context. Tutte le immagini
        // verranno renderizzate fedelmente.
        let pageRect = CGRect(origin: .zero, size: DossierPDFFormat.pageSize)
        for (index, page) in pages.enumerated() {
            let renderer = ImageRenderer(content: page)
            renderer.proposedSize = ProposedViewSize(DossierPDFFormat.pageSize)
            renderer.scale = 1.0
            guard let pageImage = renderer.uiImage,
                  let cg = pageImage.cgImage else {
                print("🔴 [PDF][Renderer] page \(index + 1) rasterization failed")
                continue
            }
            pdfContext.beginPDFPage(nil)
            pdfContext.draw(cg, in: pageRect)
            pdfContext.endPDFPage()
            print("📄 [PDF][Renderer] page \(index + 1)/\(pages.count) rendered (bitmap \(cg.width)x\(cg.height))")
        }
        pdfContext.closePDF()

        print("✅ [PDF][Renderer] complete — pages=\(pages.count), bytes=\(pdfData.length)")
        return pdfData as Data
    }

    // MARK: - File output

    static func writeToTemporaryFile(data: Data, suggestedName: String) -> URL? {
        let safeName = suggestedName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).pdf")
        do {
            try data.write(to: url, options: .atomic)
            print("✅ [PDF][Renderer] written to \(url.lastPathComponent)")
            return url
        } catch {
            print("🔴 [PDF][Renderer] write failed — \(error)")
            return nil
        }
    }
}
