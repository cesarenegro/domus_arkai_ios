//
//  PropertiesMapView.swift
//  Domus Arkai
//
//  Mappa full-screen con tutte le proprietà del portale geolocalizzate.
//  Pin sand `#A48768` per coerenza brand (stesso colore del PDF Dossier).
//  Tap su pin → callout con preview + CTA "Vai al dettaglio".
//

import SwiftUI
import MapKit

@MainActor
@Observable
final class PropertiesMapViewModel {
    enum Phase: Equatable {
        case idle, loading, loaded, error(String)
    }

    var properties: [Property] = []
    var phase: Phase = .idle

    /// Solo le properties con coordinate valide (mappa non può renderizzare le altre).
    var geolocated: [Property] {
        properties.filter { $0.latitude != nil && $0.longitude != nil }
    }

    func load() async {
        phase = .loading
        do {
            let all = try await PropertyService.shared.fetchPublishedProperties()
            properties = all
            phase = .loaded
            print("📦 [PropertiesMap] loaded \(properties.count) properties (\(geolocated.count) geolocated)")
        } catch {
            phase = .error(error.localizedDescription)
            print("🔴 [PropertiesMap] load failed — \(error)")
        }
    }

    /// Region calcolata sui bounds delle properties geolocalizzate. Fallback: Milano centro.
    var initialPosition: MapCameraPosition {
        let coords = geolocated.compactMap { p -> CLLocationCoordinate2D? in
            guard let lat = p.latitude, let lon = p.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !coords.isEmpty else {
            // Fallback Milano centro
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.4716, longitude: 9.1879),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            ))
        }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = max(0.02, (maxLat - minLat) * 1.4)
        let lonDelta = max(0.02, (maxLon - minLon) * 1.4)
        return .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }
}

struct PropertiesMapView: View {
    @State private var model = PropertiesMapViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedProperty: Property?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                    .ignoresSafeArea(edges: .bottom)

                if model.phase == .loading {
                    overlayLoading
                }
                if case .loaded = model.phase, model.geolocated.isEmpty {
                    overlayEmpty
                }
                if let p = selectedProperty {
                    detailPreview(p)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, ADSpacing.s4)
                }
            }
            .navigationTitle("Mappa immobili")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if case .loaded = model.phase {
                        Text("\(model.geolocated.count) di \(model.properties.count)")
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

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition, selection: $selectedProperty) {
            ForEach(model.geolocated) { property in
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

                VStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ADColor.primarySoft)
                }
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
            Image(systemName: "mappin.slash")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text("Nessun immobile geolocalizzato")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
            Text("Le coordinate degli immobili non sono ancora disponibili.")
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
