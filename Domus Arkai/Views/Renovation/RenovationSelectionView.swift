//
//  RenovationSelectionView.swift
//  Domus Arkai
//
//  Stima ristrutturazione — cruscotto principale.
//  Architettura: header mq + categorie navigabili (sheet dedicata per categoria con
//  varianti materiali) + difficoltà cantiere in bottom sheet + sticky footer totale.
//

import SwiftUI

struct RenovationSelectionView: View {
    @State var model: RenovationViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case category(String)
        case difficulty
        case chart
        case surfaceEdit

        var id: String {
            switch self {
            case .category(let name): return "cat:\(name)"
            case .difficulty: return "difficulty"
            case .chart: return "chart"
            case .surfaceEdit: return "surface"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        surfaceHeader
                        levelSelector
                        difficultyTrigger
                        categoriesList
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)

                stickyFooter
            }
            .navigationTitle("Stima ristrutturazione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                if model.items.isEmpty {
                    await model.load()
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .category(let name):
                    RenovationCategoryDetailView(
                        model: model,
                        categoryName: name
                    )
                case .difficulty:
                    RenovationDifficultySheet(model: model)
                case .chart:
                    RenovationChartView(model: model)
                case .surfaceEdit:
                    RenovationSurfaceEditSheet(model: model)
                }
            }
        }
    }

    // MARK: - Surface header (mq dell'appartamento, dato base)

    private var surfaceHeader: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack(spacing: ADSpacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ADColor.primaryLight)
                        .frame(width: 56, height: 56)
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(ADColor.primarySoft)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Superficie da ristrutturare")
                        .font(ADTypography.metadata.weight(.semibold))
                        .foregroundStyle(ADColor.textMuted)
                        .tracking(0.5)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(model.workingSurface))")
                            .font(ADTypography.priceMedium.monospacedDigit())
                            .foregroundStyle(ADColor.primary)
                            .lineLimit(1)
                        Text("mq")
                            .font(ADTypography.bodyMedium.weight(.semibold))
                            .foregroundStyle(ADColor.textMuted)
                    }
                    Text(model.property.title)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            Button {
                activeSheet = .surfaceEdit
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13))
                    Text("Modifica metratura")
                        .font(ADTypography.smallMedium.weight(.semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundStyle(ADColor.primary)
                .padding(.horizontal, ADSpacing.s3)
                .padding(.vertical, ADSpacing.s2)
                .frame(maxWidth: .infinity)
                .background(ADColor.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    // MARK: - Livello qualità

    private var levelSelector: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Livello di qualità")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            HStack(spacing: ADSpacing.s2) {
                ForEach(RenovationLevel.allCases, id: \.self) { level in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { model.level = level }
                    } label: {
                        Text(level.label)
                            .font(ADTypography.smallMedium.weight(.semibold))
                            .foregroundStyle(model.level == level ? ADColor.primary : ADColor.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(model.level == level ? ADColor.primaryLight : ADColor.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: ADRadius.md)
                                    .stroke(model.level == level ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(model.level.description)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Difficoltà cantiere → bottom sheet

    @ViewBuilder
    private var difficultyTrigger: some View {
        if !model.difficultyFactors.isEmpty {
            Button {
                activeSheet = .difficulty
            } label: {
                HStack(spacing: ADSpacing.s3) {
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ADColor.primarySoft)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Complessità del cantiere")
                            .font(ADTypography.bodyMedium.weight(.semibold))
                            .foregroundStyle(ADColor.primary)
                            .lineLimit(1)
                        Text(model.selectedDifficultyKeys.isEmpty
                             ? "Nessuna complessità selezionata"
                             : "\(model.selectedDifficultyKeys.count) selezionata\(model.selectedDifficultyKeys.count == 1 ? "" : "e")")
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(ADColor.textLight)
                }
                .padding(ADSpacing.Card.paddingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.card)
                        .stroke(model.selectedDifficultyKeys.isEmpty ? ADColor.border : ADColor.primarySoft, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Lista categorie navigabili

    private var categoriesList: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Categorie di intervento")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            if model.isLoading && model.items.isEmpty {
                ProgressView()
                    .tint(ADColor.primary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: ADSpacing.s2) {
                    ForEach(model.groupedItems, id: \.category) { group in
                        categoryCard(name: group.category, items: group.items)
                    }
                }
            }
        }
    }

    private func categoryCard(name: String, items: [RenovationItem]) -> some View {
        let selectedCount = items.filter { model.isSelected($0) }.count
        let categorySubtotal = items.reduce(0.0) { $0 + model.cost(of: $1) }
        let icon = items.first?.icon ?? "wrench.and.screwdriver"

        return Button {
            activeSheet = .category(name)
        } label: {
            HStack(spacing: ADSpacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedCount > 0 ? ADColor.primarySoft.opacity(0.15) : ADColor.surfaceSoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(selectedCount > 0 ? ADColor.primarySoft : ADColor.textMuted)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(1)
                    if selectedCount > 0 {
                        Text("\(selectedCount) intervent\(selectedCount == 1 ? "o" : "i") · \(categorySubtotal.formattedEuro())")
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.primarySoft)
                            .lineLimit(1)
                    } else {
                        Text("\(items.count) opzion\(items.count == 1 ? "e" : "i") disponibil\(items.count == 1 ? "e" : "i")")
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textLight)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(ADColor.textLight)
            }
            .padding(ADSpacing.Card.paddingSmall)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(selectedCount > 0 ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sticky footer

    private var stickyFooter: some View {
        HStack(spacing: ADSpacing.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Totale indicativo")
                    .font(ADTypography.metadata.weight(.medium))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
                Text(model.total.formattedEuro())
                    .font(ADTypography.priceMedium)
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: ADSpacing.s2)
            Button {
                activeSheet = .chart
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Grafico")
                        .font(ADTypography.smallMedium.weight(.semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, ADSpacing.s4)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .fill(model.selectedItems.isEmpty ? ADColor.border : ADColor.primarySoft)
                )
            }
            .buttonStyle(.plain)
            .disabled(model.selectedItems.isEmpty)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.vertical, ADSpacing.s3)
        .background(
            ADColor.surface
                .overlay(
                    Rectangle()
                        .fill(ADColor.border.opacity(0.5))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }
}

#Preview {
    RenovationSelectionView(model: RenovationViewModel(property: .preview))
}
