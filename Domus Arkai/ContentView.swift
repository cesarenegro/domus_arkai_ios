//
//  ContentView.swift
//  Domus Arkai
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash: Bool = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView { showSplash = false }
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LandingView()
                .tabItem { Label("Home", systemImage: "house") }

            MapSearchTabView()
                .tabItem { Label("Ricerca", systemImage: "magnifyingglass") }

            MyDossiersView()
                .tabItem { Label("Dossier", systemImage: "folder") }

            AgenciesListView()
                .tabItem { Label("Agenzie", systemImage: "building.2") }

            ProfileView()
                .tabItem { Label("Profilo", systemImage: "person") }
        }
        .tint(ADColor.primarySoft)
    }
}

#Preview {
    ContentView()
}
