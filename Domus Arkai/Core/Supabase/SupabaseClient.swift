//
//  SupabaseClient.swift
//  Domus Arkai
//
//  Singleton client Supabase per tutto l'app.
//  Usa l'SDK ufficiale `supabase-swift` aggiunto via SPM.
//
//  Include un custom User-Agent deterministico (es. "ArkaiDomus/1.0 (122) iOS/26.5 iPhone")
//  per consentire al backend (trigger access_logs) di identificare client_type='ios_app'
//  senza ambiguità verso Safari iOS o webview.
//

import Foundation
import UIKit
import Supabase

enum SupabaseManager {
    /// Singleton globale del client Supabase.
    /// Configurato con URL + anon key da `SupabaseConfig` + custom User-Agent.
    static let shared: SupabaseClient = SupabaseClient(
        supabaseURL: SupabaseConfig.baseURL,
        supabaseKey: SupabaseConfig.anonKey,
        options: SupabaseClientOptions(
            global: .init(
                headers: ["User-Agent": Self.userAgent]
            )
        )
    )

    /// User-Agent inviato su ogni request Supabase. Forma:
    /// `ArkaiDomus/<short> (<build>) iOS/<sysVersion> <deviceModel>`
    private static let userAgent: String = {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        let device = UIDevice.current
        return "ArkaiDomus/\(short) (\(build)) iOS/\(device.systemVersion) \(device.model)"
    }()
}
