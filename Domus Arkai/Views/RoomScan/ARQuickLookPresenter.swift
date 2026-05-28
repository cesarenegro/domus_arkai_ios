//
//  ARQuickLookPresenter.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — bridge SwiftUI di `QLPreviewController` per la
//  visualizzazione di file `.usdz` in AR Quick Look.
//
//  Apple QLPreviewController riconosce nativamente i file .usdz e mostra
//  il bottone "AR" in toolbar (su device fisico con ARKit). Tap → l'utente
//  entra in modalità AR e vede l'arredo sovrapposto allo spazio reale
//  in scala 1:1.
//
//  Caching: gli URL di Supabase Storage sono signed e scadono. Per garantire
//  la visualizzazione anche in cantiere senza rete il file viene scaricato
//  preventivamente in `temporaryDirectory` e passato al QLPreviewController
//  come URL locale (file://).
//

import SwiftUI
import QuickLook

struct ARQuickLookPresenter: UIViewControllerRepresentable {
    let localFileURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: localFileURL)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // no-op: l'URL è fisso per ogni presentazione
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

// MARK: - Downloader USDZ

/// Scarica il file `.usdz` dal Supabase Storage signed URL e lo salva in
/// `temporaryDirectory`. Restituisce l'URL locale per AR Quick Look.
/// In caso di re-download, riusa il file in cache.
@MainActor
enum USDZDownloader {

    enum DownloadError: LocalizedError {
        case invalidResponse
        case http(Int)
        case write(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: "Risposta non valida dal server."
            case .http(let code): "Errore HTTP \(code) durante il download."
            case .write(let msg): "Errore salvataggio file: \(msg)"
            }
        }
    }

    /// Cerca un file USDZ demo bundlato nell'app come fallback.
    /// Per attivare: aggiungi `demo_room.usdz` al target Xcode (drag-and-drop
    /// in Project Navigator → spunta "Copy items if needed" + target membership
    /// "Domus Arkai"). File USDZ di esempio gratuiti su:
    /// https://developer.apple.com/augmented-reality/quick-look/
    static func bundledDemoURL() -> URL? {
        Bundle.main.url(forResource: "demo_room", withExtension: "usdz")
    }

    /// Scarica (o riusa cache) il file USDZ dato l'URL remoto.
    /// Nome file locale derivato dall'hash dell'URL per evitare collisioni.
    static func download(remote: URL) async throws -> URL {
        let cacheKey = remote.absoluteString.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
        let local = FileManager.default.temporaryDirectory
            .appendingPathComponent("staging_\(cacheKey).usdz")

        if FileManager.default.fileExists(atPath: local.path) {
            print("✅ [USDZDownloader] cache hit: \(local.lastPathComponent)")
            return local
        }

        print("🟢 [USDZDownloader] downloading: \(remote.absoluteString.prefix(80))…")
        let (data, response) = try await URLSession.shared.data(from: remote)
        guard let http = response as? HTTPURLResponse else {
            throw DownloadError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw DownloadError.http(http.statusCode)
        }
        do {
            try data.write(to: local, options: [.atomic])
            print("✅ [USDZDownloader] saved \(data.count) bytes → \(local.lastPathComponent)")
            return local
        } catch {
            throw DownloadError.write(error.localizedDescription)
        }
    }
}
