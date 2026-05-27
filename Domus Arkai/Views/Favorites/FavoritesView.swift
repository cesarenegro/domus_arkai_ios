//
//  FavoritesView.swift
//  Domus Arkai
//
//  Spec: `14_ios_favorites.json`. Filtri estesi a tutti i property_type del DB.
//

import SwiftUI

struct FavoritesView: View {
    @State private var model = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: ADSpacing.s4) {
                        if !model.properties.isEmpty {
                            filterPillsRow
                        }
                        content
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
                .refreshable {
                    await model.load()
                }
            }
            .navigationTitle("Preferiti")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Property.self) { property in
                PropertyDetailView(property: property)
            }
            .task {
                await model.load()
            }
        }
    }

    private var filterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ADSpacing.s2) {
                FilterPill(label: "Tutti", isSelected: model.filter == nil) {
                    model.filter = nil
                }
                ForEach(model.availableTypes, id: \.self) { type in
                    FilterPill(label: type.displayName, isSelected: model.filter == type) {
                        model.filter = (model.filter == type) ? nil : type
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            VStack(spacing: ADSpacing.s4) {
                ForEach(0..<2, id: \.self) { _ in
                    PropertyCardSkeleton()
                }
            }
        } else if model.properties.isEmpty {
            ADEmptyState(
                icon: "heart",
                title: "Nessun preferito",
                message: "Tocca il cuore sugli immobili che ti piacciono per ritrovarli qui."
            )
            .padding(.top, ADSpacing.s7)
        } else if model.filteredProperties.isEmpty {
            ADEmptyState(
                icon: "line.3.horizontal.decrease.circle",
                title: "Nessun risultato",
                message: "Nessun preferito di questa tipologia. Cambia il filtro."
            )
        } else {
            ForEach(model.filteredProperties) { property in
                NavigationLink(value: property) {
                    PropertyCard(
                        property: property,
                        isFavorite: true,
                        onTapFavorite: { model.remove(property) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    FavoritesView()
}
