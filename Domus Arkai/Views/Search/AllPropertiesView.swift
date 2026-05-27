//
//  AllPropertiesView.swift
//  Domus Arkai
//
//  Lista completa di tutti gli immobili. Vista raggiungibile dal tab Ricerca
//  tramite il bottone "Vedi tutti gli immobili". Supporta due modalità:
//  - .full → PropertyCard editorial (card grande, immagine cover, badge, prezzo)
//  - .compact → riga compatta stile "I miei Dossier" (thumbnail 84pt + info + chevron)
//

import SwiftUI

struct AllPropertiesView: View {
    enum ViewMode { case full, compact }

    @State private var model = HomeViewModel()
    @State private var searchText: String = ""
    @State private var viewMode: ViewMode = .full
    @State private var visibleCardIndex: Int = 0

    private var filtered: [Property] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return model.properties }
        return model.properties.filter { property in
            property.title.localizedCaseInsensitiveContains(trimmed)
            || property.locationLine.localizedCaseInsensitiveContains(trimmed)
            || (property.address?.localizedCaseInsensitiveContains(trimmed) ?? false)
            || (property.city?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: ADSpacing.s3) {
                    headerControls
                    contentSection
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.top, ADSpacing.s3)
                .padding(.bottom, ADSpacing.s8)
            }
            .scrollIndicators(.hidden)
            .refreshable { await model.load() }
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1.0), trigger: visibleCardIndex)
        }
        .navigationTitle("Immobili")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model.loadState == .idle {
                await model.load()
            }
        }
    }

    // MARK: - Header (search + count + toggle vista)

    private var headerControls: some View {
        VStack(spacing: ADSpacing.s3) {
            searchBar
            HStack {
                Text("\(filtered.count) \(filtered.count == 1 ? "immobile" : "immobili")")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
                Spacer()
                viewToggle
            }
        }
        .padding(.bottom, ADSpacing.s2)
    }

    private var searchBar: some View {
        HStack(spacing: ADSpacing.s2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ADColor.textMuted)
            TextField("Cerca per zona, indirizzo, tipologia…", text: $searchText)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ADColor.textLight)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ADSpacing.s4)
        .frame(height: 46)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var viewToggle: some View {
        HStack(spacing: 2) {
            toggleButton(mode: .full, icon: "square.grid.2x2.fill", label: "Card")
            toggleButton(mode: .compact, icon: "list.bullet", label: "Lista")
        }
        .padding(3)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func toggleButton(mode: ViewMode, icon: String, label: String) -> some View {
        let isActive = viewMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewMode = mode }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11, weight: .medium))
                Text(label).font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, ADSpacing.s3)
            .padding(.vertical, 6)
            .foregroundStyle(isActive ? ADColor.background : ADColor.primary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? ADColor.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content (full / compact / states)

    @ViewBuilder
    private var contentSection: some View {
        switch model.loadState {
        case .idle, .loading:
            VStack(spacing: ADSpacing.s4) {
                ForEach(0..<3, id: \.self) { _ in PropertyCardSkeleton() }
            }

        case .loaded, .empty:
            if filtered.isEmpty {
                ADEmptyState(
                    icon: searchText.isEmpty ? "house.slash" : "magnifyingglass",
                    title: searchText.isEmpty ? "Nessun immobile" : "Nessun risultato",
                    message: searchText.isEmpty
                        ? "Al momento non ci sono immobili pubblicati."
                        : "Prova a modificare la ricerca."
                )
            } else {
                if viewMode == .full {
                    fullList
                } else {
                    compactList
                }
            }

        case .error(let msg):
            ADErrorState(message: msg) { Task { await model.load() } }
        }
    }

    private var fullList: some View {
        VStack(spacing: ADSpacing.s2) {
            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, property in
                NavigationLink(value: property) {
                    PropertyCard(
                        property: property,
                        isFavorite: model.isFavorite(property),
                        onTapFavorite: { model.toggleFavorite(property) },
                        agencyName: model.agencyName(for: property)
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    if visibleCardIndex != index { visibleCardIndex = index }
                }
            }
        }
    }

    private var compactList: some View {
        VStack(spacing: ADSpacing.s1) {
            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, property in
                NavigationLink(value: property) {
                    compactRow(property)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if visibleCardIndex != index { visibleCardIndex = index }
                }
            }
        }
    }

    private func compactRow(_ property: Property) -> some View {
        HStack(spacing: ADSpacing.s3) {
            AsyncImage(url: property.coverImageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    ADColor.surfaceSoft
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))

            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(2)
                Text(property.locationLine)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
                Text(property.formattedPrice)
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(ADColor.textLight)
                .font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.s3)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }
}

#Preview {
    NavigationStack {
        AllPropertiesView()
    }
}
