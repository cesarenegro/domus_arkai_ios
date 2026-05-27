//
//  VisualBOQService.swift
//  Domus Arkai
//
//  "Arkai Vision Pro" — chiamata Edge Function `analyze-room-photos`.
//  L'iOS NON chiama mai direttamente Google AI: tutto passa via Edge Function
//  con Sandbox Demo Mode fallback se GEMINI_API_KEY non è configurata server-side.
//

import Foundation
import UIKit
import Supabase

actor VisualBOQService {
    static let shared = VisualBOQService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// Tipologia ambiente (italiano, va a Edge Function).
    enum RoomType: String, CaseIterable, Sendable {
        case bagno
        case cucina
        case camera
        case soggiorno

        var displayName: String {
            switch self {
            case .bagno: "Bagno"
            case .cucina: "Cucina"
            case .camera: "Camera"
            case .soggiorno: "Soggiorno"
            }
        }
    }

    struct AnalyzePayload: Encodable {
        let photos: [String]                  // data:image/jpeg;base64,...
        let room_type: String
        let city: String
        let difficulty_factors: [String]
        let property_id: String?
    }

    /// Errore semantico: server ha negato per quota mensile esaurita (HTTP 429).
    /// Generato quando il messaggio dell'errore contiene segnali di quota_exceeded.
    enum VisualBOQError: LocalizedError {
        case quotaExceeded
        case underlying(String)

        var errorDescription: String? {
            switch self {
            case .quotaExceeded:
                return "Hai esaurito le 5 analisi gratuite di questo mese. Riprova il primo del prossimo mese."
            case .underlying(let msg):
                return msg
            }
        }
    }

    /// Pipeline completa: comprimi foto, base64 encode, invia Edge Function, parse response.
    func analyze(
        images: [UIImage],
        roomType: RoomType,
        city: String,
        difficultyFactors: [String],
        propertyID: UUID?
    ) async throws -> VisualBOQResponse {
        let start = Date()
        print("🟢 [VisionPRO][Service] analyze() start — images=\(images.count), room=\(roomType.rawValue), city=\(city), factors=\(difficultyFactors), propertyID=\(propertyID?.uuidString ?? "nil")")

        // Riduci dimensione + JPEG compression per evitare payload eccessivo
        let base64Photos = images.prefix(3).compactMap { Self.encode(image: $0) }
        let totalBytes = base64Photos.reduce(0) { $0 + $1.utf8.count }
        print("📸 [VisionPRO][Service] encoded \(base64Photos.count) photos · payload size = \(totalBytes / 1024) KB")

        guard !base64Photos.isEmpty else {
            print("🔴 [VisionPRO][Service] no valid images after encoding — abort")
            throw NSError(
                domain: "VisualBOQService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Nessuna immagine valida da analizzare."]
            )
        }

        let payload = AnalyzePayload(
            photos: base64Photos,
            room_type: roomType.rawValue,
            city: city,
            difficulty_factors: difficultyFactors,
            property_id: propertyID?.uuidString
        )

        print("📡 [VisionPRO][Service] invoking Edge Function 'analyze-room-photos'…")
        do {
            let response: VisualBOQResponse = try await client.functions
                .invoke("analyze-room-photos", options: .init(body: payload))
            let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))
            print("✅ [VisionPRO][Service] response OK in \(elapsed)s — works=\(response.estimatedWorks.count), total=\(Int(response.totalEstimatedCost))€, room=\(response.detectedRoomType), conditions=\(response.detectedConditions)")
            return response
        } catch {
            let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))
            print("🔴 [VisionPRO][Service] Edge Function FAILED in \(elapsed)s — \(error)")

            // Estrai body errore dall'Edge Function quando disponibile (FunctionsError.httpError(code, data))
            var serverBody: String?
            let mirror = Mirror(reflecting: error)
            for child in mirror.children {
                if let data = child.value as? Data {
                    serverBody = String(data: data, encoding: .utf8)
                } else {
                    let inner = Mirror(reflecting: child.value)
                    for sub in inner.children {
                        if let data = sub.value as? Data {
                            serverBody = String(data: data, encoding: .utf8)
                        }
                    }
                }
            }
            if let body = serverBody, !body.isEmpty {
                print("🔴 [VisionPRO][Service] server body: \(body)")
            }

            let desc = error.localizedDescription.lowercased()
            let combined = (desc + " " + (serverBody?.lowercased() ?? ""))
            // Detect HTTP 429 / quota_exceeded dal messaggio del FunctionsError di supabase-swift
            if combined.contains("429") || combined.contains("quota_exceeded") || combined.contains("quota exceeded") {
                print("🟡 [VisionPRO][Service] quota mensile esaurita lato server")
                throw VisualBOQError.quotaExceeded
            }
            throw VisualBOQError.underlying(serverBody ?? error.localizedDescription)
        }
    }

    /// Resize a max 1280 lato lungo + JPEG quality 0.6 + base64 data URI.
    private nonisolated static func encode(image: UIImage) -> String? {
        let maxSide: CGFloat = 1280
        let size = image.size
        let scale = min(maxSide / max(size.width, size.height), 1.0)
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.6) else { return nil }
        let base64 = jpeg.base64EncodedString()
        return "data:image/jpeg;base64,\(base64)"
    }
}
