//
//  MapSearchTabView.swift
//  Domus Arkai
//
//  Tab "Ricerca": barra di ricerca + mappa grande con tutti gli immobili
//  pubblicati geolocalizzati. Pin tappabili → preview card + push al detail.
//

import SwiftUI
import MapKit

struct MapSearchTabView: View {
    @State private var model = PropertiesMapViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedProperty: Property?
    @State private var searchText: String = ""
    private let lightBlue = Color(red: 0.82, green: 0.89, blue: 0.94)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                    .ignoresSafeArea(edges: .bottom)

                VStack(spacing: ADSpacing.s2) {
                    searchBar
                    seeAllPropertiesButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.top, ADSpacing.s2)

                if model.phase == .loading {
                    overlayLoading
                }
                if case .loaded = model.phase, filteredGeolocated.isEmpty {
                    overlayEmpty
                }
                if let p = selectedProperty {
                    detailPreview(p)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, ADSpacing.s4)
                }
            }
            .navigationTitle("Ricerca")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if case .loaded = model.phase {
                        Text("\(filteredGeolocated.count) di \(model.properties.count)")
                            .font(ADTypography.metadata.weight(.semibold))
                            .foregroundStyle(ADColor.textMuted)
                    }
                }
            }
            .navigationDestination(for: Property.self) { property in
                PropertyDetailView(property: property)
            }
            .task {
                if case .idle = model.phase {
                    await model.load()
                    cameraPosition = model.initialPosition
                }
            }
        }
    }

    // MARK: - See all properties button

    private var seeAllPropertiesButton: some View {
        NavigationLink {
            AllPropertiesView()
        } label: {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "rectangle.grid.1x2.fill")
                    .font(.system(size: 14, weight: .medium))
                Text("Vedi tutti gli immobili")
                    .font(ADTypography.body.weight(.medium))
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(ADColor.primary)
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .background(lightBlue)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lightBlue.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtering

    private var filteredGeolocated: [Property] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return model.geolocated }
        return model.geolocated.filter { property in
            property.title.localizedCaseInsensitiveContains(trimmed)
            || property.locationLine.localizedCaseInsensitiveContains(trimmed)
            || (property.address?.localizedCaseInsensitiveContains(trimmed) ?? false)
            || (property.city?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: ADSpacing.s2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ADColor.textMuted)
            TextField("Cerca indirizzo, zona, immobile…", text: $searchText)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ADColor.textLight)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ADSpacing.s4)
        .frame(height: 46)
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition, selection: $selectedProperty) {
            ForEach(filteredGeolocated) { property in
                if let lat = property.latitude, let lon = property.longitude {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        pin(for: property)
                    }
                    .tag(property)
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    private func pin(for property: Property) -> some View {
        let isSelected = selectedProperty?.id == property.id
        return ZStack {
            Circle()
                .fill(ADColor.accentWarm)
                .frame(width: isSelected ? 38 : 28, height: isSelected ? 38 : 28)
                .shadow(color: ADColor.primary.opacity(0.4), radius: 4, x: 0, y: 2)
            Image(systemName: "house.fill")
                .font(.system(size: isSelected ? 16 : 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .onTapGesture {
            withAnimation(.spring(duration: 0.25)) {
                selectedProperty = property
            }
        }
    }

    // MARK: - Bottom preview card

    @ViewBuilder
    private func detailPreview(_ property: Property) -> some View {
        NavigationLink(value: property) {
            HStack(spacing: ADSpacing.s3) {
                AsyncImage(url: property.coverImageURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: ADColor.surfaceSoft
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(property.formattedPrice)
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(1)
                    Text(property.title)
                        .font(ADTypography.small)
                        .foregroundStyle(ADColor.text)
                        .lineLimit(1)
                    Text(property.locationLine)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: ADSpacing.s2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ADColor.primarySoft)
            }
            .padding(ADSpacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 0.5)
            )
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Overlays

    private var overlayLoading: some View {
        VStack(spacing: ADSpacing.s2) {
            ProgressView().tint(ADColor.primary)
            Text("Carico mappa immobili…")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
        }
        .padding(ADSpacing.s4)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        .padding(.bottom, ADSpacing.s8)
    }

    private var overlayEmpty: some View {
        VStack(spacing: ADSpacing.s2) {
            Image(systemName: searchText.isEmpty ? "mappin.slash" : "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text(searchText.isEmpty ? "Nessun immobile geolocalizzato" : "Nessun risultato")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
            Text(searchText.isEmpty
                 ? "Le coordinate degli immobili non sono ancora disponibili."
                 : "Prova con un'altra zona o indirizzo.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(ADSpacing.s4)
        .frame(maxWidth: 280)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        .padding(.bottom, ADSpacing.s8)
    }
}

#Preview {
    MapSearchTabView()
}
