//
//  SupabaseConfig.swift
//  Domus Arkai
//

import Foundation

enum SupabaseConfig {
    static let baseURL = URL(string: "https://fviomnrtswsuoqfxcbki.supabase.co")!
    static let anonKey = "sb_publishable_zhcObBd9xMAzo-nTzoXhlw_LHlId9xh"
    static let restURL = baseURL.appendingPathComponent("rest/v1")
}

enum HubConfig {
    static let coordinationTable = "ai_coordination_messages"
    static let selfSender = "ios_ai"
    static let peerSender = "frontend_ai"
}
