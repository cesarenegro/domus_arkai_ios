//
//  Domus_ArkaiApp.swift
//  Domus Arkai
//
//  Created by Cesare on 22/05/26.
//

import SwiftUI
import UIKit

@main
struct Domus_ArkaiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var themeService = ThemeService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeService.colorScheme)
                .environment(themeService)
        }
    }
}

/// AppDelegate minimale per gestire i callback APNs (device token + remote payload).
/// SwiftUI App lifecycle non espone direttamente questi callback, da qui l'@UIApplicationDelegateAdaptor.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // NotificationService inizializzato lazy via .shared al primo accesso.
        // Qui controlliamo subito lo status di autorizzazione e se già concesso registriamo APNs.
        Task { @MainActor in
            await NotificationService.shared.refreshAuthorizationStatus()
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationService.shared.handleDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            NotificationService.shared.handleRegistrationFailure(error)
        }
    }
}
