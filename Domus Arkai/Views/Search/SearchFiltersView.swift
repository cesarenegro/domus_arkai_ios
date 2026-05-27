//
//  SearchFiltersView.swift
//  Domus Arkai
//
//  Spec: `03_ios_search_filters.json`. Sheet modale fullscreen, controls grandi.
//

import SwiftUI

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    var onApply: () -> Void

    @State private var draft: SearchFilters
    @State private var availableAgencies: [Agency] = []
    @Environment(\.dismiss) private var dismiss

    init(filters: Binding<SearchFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._draft = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        sectionContractType
                        sectionPropertyTypes
                        sectionPriceRange
                        sectionSurfaceRange
                        sectionRooms
                        sectionFeatures
                        sectionAgencies
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s9)
                }

                VStack {
                    Spacer()
                    bottomActions
                }
            }
            .navigationTitle("Filtri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancella tutto") { draft = SearchFilters() }
                        .foregroundStyle(ADColor.textMuted)
                }
            }
            .task {
                if availableAgencies.isEmpty {
                    availableAgencies = (try? await AgencyService.shared.fetchAllAgencies()) ?? []
                }
            }
        }
    }

    @ViewBuilder
    private var sectionAgencies: some View {
        if !availableAgencies.isEmpty {
            sectionBox(title: "Agenzia") {
                FlowLayout(spacing: ADSpacing.s2) {
                    ForEach(availableAgencies) { agency in
                        FilterPill(
                            label: agency.name,
                            isSelected: draft.agencyIDs.contains(agency.id)
                        ) {
                            if draft.agencyIDs.contains(agency.id) {
                                draft.agencyIDs.remove(agency.id)
                            } else {
                                draft.agencyIDs.insert(agency.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var sectionContractType: some View {
        sectionBox(title: "Contratto") {
            HStack(spacing: ADSpacing.s2) {
                segmentChip(label: "Vendita", isSelected: draft.contractType == .vendita) {
                    draft.contractType = draft.contractType == .vendita ? nil : .vendita
                }
                segmentChip(label: "Affitto", isSelected: draft.contractType == .affitto) {
                    draft.contractType = draft.contractType == .affitto ? nil : .affitto
                }
            }
        }
    }

    private var sectionPropertyTypes: some View {
        sectionBox(title: "Tipologia") {
            FlowLayout(spacing: ADSpacing.s2) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    FilterPill(
                        label: type.displayName,
                        isSelected: draft.propertyTypes.contains(type)
                    ) {
                        if draft.propertyTypes.contains(type) {
                            draft.propertyTypes.remove(type)
                        } else {
                            draft.propertyTypes.insert(type)
                        }
                    }
                }
            }
        }
    }

    private var sectionPriceRange: some View {
        sectionBox(title: "Prezzo (€)") {
            HStack(spacing: ADSpacing.s2) {
                rangeField(value: bindingPrice(\.priceMin), placeholder: "Da")
                rangeField(value: bindingPrice(\.priceMax), placeholder: "A")
            }
        }
    }

    private var sectionSurfaceRange: some View {
        sectionBox(title: "Superficie (mq)") {
            HStack(spacing: ADSpacing.s2) {
                rangeField(value: bindingPrice(\.surfaceMin), placeholder: "Da")
                rangeField(value: bindingPrice(\.surfaceMax), placeholder: "A")
            }
        }
    }

    private var sectionRooms: some View {
        sectionBox(title: "Locali (minimo)") {
            HStack(spacing: ADSpacing.s2) {
                ForEach([1, 2, 3, 4], id: \.self) { value in
                    segmentChip(
                        label: value == 4 ? "4+" : "\(value)",
                        isSelected: draft.minRooms == value
                    ) {
                        draft.minRooms = draft.minRooms == value ? nil : value
                    }
                }
            }
        }
    }

    private var sectionFeatures: some View {
        sectionBox(title: "Extra") {
            FlowLayout(spacing: ADSpacing.s2) {
                ForEach(SearchFilters.Feature.allCases, id: \.self) { feature in
                    FilterPill(
                        label: feature.displayName,
                        isSelected: draft.features.contains(feature)
                    ) {
                        if draft.features.contains(feature) {
                            draft.features.remove(feature)
                        } else {
                            draft.features.insert(feature)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func sectionBox<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text(title)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
            content()
        }
    }

    private func segmentChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(ADTypography.smallMedium)
                .foregroundStyle(isSelected ? ADColor.primary : ADColor.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? ADColor.primaryLight : ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .stroke(isSelected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func rangeField(value: Binding<Double?>, placeholder: String) -> some View {
        TextField(placeholder, value: value, format: .number)
            .keyboardType(.numberPad)
            .font(ADTypography.body)
            .foregroundStyle(ADColor.text)
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 50)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
    }

    private var bottomActions: some View {
        HStack(spacing: ADSpacing.s3) {
            Button("Reset") {
                draft = SearchFilters()
            }
            .buttonStyle(.adSecondary(fullWidth: false))

            Button("Applica filtri") {
                filters = draft
                onApply()
                dismiss()
            }
            .buttonStyle(.adPrimary)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.vertical, ADSpacing.s3)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Bindings helpers

    private func bindingPrice(_ keyPath: WritableKeyPath<SearchFilters, Double?>) -> Binding<Double?> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { draft[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - FlowLayout (wraps pills su più righe)

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let totalHeight = rows.reduce(0) { partial, row in
            partial + row.maxHeight + (partial == 0 ? 0 : spacing)
        }
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = item.sizeThatFits(.unspecified)
                item.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.maxHeight + spacing
        }
    }

    private struct Row {
        var items: [LayoutSubview] = []
        var maxHeight: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        var currentX: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
                currentX = 0
            }
            rows[rows.count - 1].items.append(sub)
            rows[rows.count - 1].maxHeight = max(rows[rows.count - 1].maxHeight, size.height)
            currentX += size.width + spacing
        }
        return rows
    }
}
