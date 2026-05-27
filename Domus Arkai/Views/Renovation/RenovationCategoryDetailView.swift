//
//  RenovationCategoryDetailView.swift
//  Domus Arkai
//
//  Sheet dettagliata per una singola categoria. Renderer DUE modalità:
//   1. Items con `configurationSchema` → form renderer dinamico (5 field types).
//   2. Items legacy con `materialVariants` → picker varianti flat + stepper quantità.
//

import SwiftUI

struct RenovationCategoryDetailView: View {
    @Bindable var model: RenovationViewModel
    let categoryName: String

    @Environment(\.dismiss) private var dismiss

    private var items: [RenovationItem] {
        model.groupedItems.first(where: { $0.category == categoryName })?.items ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s4) {
                        ForEach(items) { item in
                            itemCard(item)
                        }
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)

                stickyTotal
            }
            .navigationTitle(categoryName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fatto") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                        .font(ADTypography.smallMedium.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Item card (dispatcher)

    @ViewBuilder
    private func itemCard(_ item: RenovationItem) -> some View {
        let selected = model.isSelected(item)

        VStack(alignment: .leading, spacing: 0) {
            itemHeader(item: item, selected: selected)

            if selected {
                Divider().overlay(ADColor.border.opacity(0.6))
                if item.configurationSchema != nil {
                    parametricFormContent(item: item)
                } else {
                    legacyVariantContent(item: item)
                }
            }
        }
        .background(selected ? ADColor.primaryLight.opacity(0.35) : ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(selected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func itemHeader(item: RenovationItem, selected: Bool) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { model.toggle(item) }
        } label: {
            HStack(spacing: ADSpacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? ADColor.primarySoft.opacity(0.15) : ADColor.surfaceSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: item.icon)
                        .font(.system(size: 17))
                        .foregroundStyle(selected ? ADColor.primarySoft : ADColor.textMuted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(2)
                    if let desc = item.description {
                        Text(desc)
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textMuted)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: ADSpacing.s2)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? ADColor.primarySoft : ADColor.border)
            }
            .padding(ADSpacing.s4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Parametric form (configurationSchema)

    @ViewBuilder
    private func parametricFormContent(item: RenovationItem) -> some View {
        if let schema = item.configurationSchema {
            VStack(alignment: .leading, spacing: ADSpacing.s4) {
                ForEach(schema.fields) { field in
                    renderField(field, item: item)
                }

                Divider().overlay(ADColor.border.opacity(0.4))

                HStack {
                    Text("Subtotale")
                        .font(ADTypography.smallMedium.weight(.semibold))
                        .foregroundStyle(ADColor.text)
                    Spacer(minLength: ADSpacing.s2)
                    Text(model.cost(of: item).formattedEuro())
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(1)
                }
            }
            .padding(ADSpacing.s4)
        }
    }

    @ViewBuilder
    private func renderField(_ field: ConfigField, item: RenovationItem) -> some View {
        switch field {
        case .groupedVariantPicker(let f):
            groupedVariantPickerView(field: f, item: item)
        case .variantPicker(let f):
            variantPickerView(field: f, item: item)
        case .toggle(let f):
            toggleView(field: f, item: item)
        case .numberInput(let f):
            numberInputView(field: f, item: item)
        case .sizePicker(let f):
            sizePickerView(field: f, item: item)
        }
    }

    // MARK: - Field views

    private func fieldHeader(_ label: String, description: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
            if let description {
                Text(description)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func groupedVariantPickerView(field: GroupedVariantPicker, item: RenovationItem) -> some View {
        let currentKey = model.variantOptionKey(for: item, fieldKey: field.key)
        return VStack(alignment: .leading, spacing: ADSpacing.s3) {
            fieldHeader(field.label)
            VStack(alignment: .leading, spacing: ADSpacing.s3) {
                ForEach(field.groups) { group in
                    VStack(alignment: .leading, spacing: ADSpacing.s2) {
                        Text(group.label)
                            .font(ADTypography.metadata.weight(.semibold))
                            .foregroundStyle(ADColor.primarySoft)
                            .tracking(0.3)
                        VStack(spacing: ADSpacing.s2) {
                            ForEach(group.options) { opt in
                                optionRow(
                                    label: opt.label,
                                    priceLabel: opt.effectivePrice(for: model.level).formattedEuro() + " / mq",
                                    isSelected: currentKey == opt.key
                                ) {
                                    model.setConfigValue(.variant(groupKey: group.key, optionKey: opt.key), for: item, fieldKey: field.key)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func variantPickerView(field: VariantPicker, item: RenovationItem) -> some View {
        let currentKey = model.variantOptionKey(for: item, fieldKey: field.key)
        return VStack(alignment: .leading, spacing: ADSpacing.s2) {
            fieldHeader(field.label)
            VStack(spacing: ADSpacing.s2) {
                ForEach(field.options) { opt in
                    optionRow(
                        label: opt.label,
                        priceLabel: priceLabelFor(option: opt),
                        isSelected: currentKey == opt.key
                    ) {
                        model.setConfigValue(.variant(groupKey: nil, optionKey: opt.key), for: item, fieldKey: field.key)
                    }
                }
            }
        }
    }

    private func priceLabelFor(option opt: VariantOption) -> String {
        let p = opt.effectivePrice(for: model.level)
        guard p > 0 else { return "" }
        if opt.pricePerSqm != nil { return p.formattedEuro() + " / mq" }
        if opt.mode == "fixed" { return p.formattedEuro() }
        return p.formattedEuro()
    }

    private func toggleView(field: ToggleField, item: RenovationItem) -> some View {
        let isOn = model.boolConfig(for: item, key: field.key)
        let extraLabel: String? = {
            if let extra = field.extraCost {
                return "+ " + extra.value(for: model.level).formattedEuro()
            }
            return nil
        }()
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                model.setConfigValue(.toggle(!isOn), for: item, fieldKey: field.key)
            }
        } label: {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(isOn ? ADColor.primarySoft : ADColor.border)
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.label)
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.text)
                        .lineLimit(2)
                    if let desc = field.description {
                        Text(desc)
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textMuted)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: ADSpacing.s2)
                if let extraLabel {
                    Text(extraLabel)
                        .font(ADTypography.metadata.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isOn ? ADColor.primary : ADColor.textLight)
                        .lineLimit(1)
                }
            }
            .padding(ADSpacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? ADColor.primaryLight.opacity(0.5) : ADColor.surfaceSoft)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(isOn ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func numberInputView(field: NumberInput, item: RenovationItem) -> some View {
        let value = model.numberConfig(for: item, key: field.key)
        let priceLabel: String? = {
            if let p = field.pricePerUnit {
                return p.value(for: model.level).formattedEuro() + " / " + (field.unitLabel ?? "u")
            }
            return nil
        }()
        return VStack(alignment: .leading, spacing: ADSpacing.s2) {
            fieldHeader(field.label)
            HStack(spacing: ADSpacing.s3) {
                stepBtn(icon: "minus", enabled: value > field.min) {
                    let next = max(field.min, value - field.step)
                    model.setConfigValue(.number(next), for: item, fieldKey: field.key)
                }
                Text(formatNumber(value, unitLabel: field.unitLabel))
                    .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                stepBtn(icon: "plus", enabled: value < field.max) {
                    let next = min(field.max, value + field.step)
                    model.setConfigValue(.number(next), for: item, fieldKey: field.key)
                }
            }
            .padding(.horizontal, ADSpacing.s3)
            .padding(.vertical, ADSpacing.s2)
            .background(ADColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))

            if let priceLabel {
                HStack {
                    Text("Prezzo unitario")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                    Spacer()
                    Text(priceLabel)
                        .font(ADTypography.metadata.weight(.medium))
                        .foregroundStyle(ADColor.textMuted)
                }
            }
        }
    }

    private func sizePickerView(field: SizePicker, item: RenovationItem) -> some View {
        let currentKey = model.sizeOptionKey(for: item, fieldKey: field.key)
        return VStack(alignment: .leading, spacing: ADSpacing.s2) {
            fieldHeader(field.label)
            VStack(spacing: ADSpacing.s2) {
                ForEach(field.options) { opt in
                    optionRow(
                        label: opt.label,
                        priceLabel: String(format: "%.2f mq", opt.areaSqm),
                        isSelected: currentKey == opt.key
                    ) {
                        model.setConfigValue(.size(optionKey: opt.key), for: item, fieldKey: field.key)
                    }
                }
            }
        }
    }

    // MARK: - Generic reusable row

    private func optionRow(label: String, priceLabel: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? ADColor.primarySoft : ADColor.border)
                Text(label)
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: ADSpacing.s2)
                if !priceLabel.isEmpty {
                    Text(priceLabel)
                        .font(ADTypography.metadata.weight(.medium).monospacedDigit())
                        .foregroundStyle(isSelected ? ADColor.primary : ADColor.textMuted)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, ADSpacing.s3)
            .padding(.vertical, ADSpacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? ADColor.primaryLight.opacity(0.5) : ADColor.surfaceSoft)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(isSelected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func stepBtn(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(enabled ? ADColor.primary : ADColor.textLight)
                .frame(width: 36, height: 36)
                .background(ADColor.surface)
                .overlay(
                    Circle().stroke(enabled ? ADColor.border : ADColor.border.opacity(0.5), lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func formatNumber(_ value: Double, unitLabel: String?) -> String {
        let isInt = value.truncatingRemainder(dividingBy: 1) == 0
        let numStr = isInt ? String(Int(value)) : String(format: "%.1f", value)
        return [numStr, unitLabel ?? ""].joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Legacy variant content (materialVariants flat OR no varianti)

    @ViewBuilder
    private func legacyVariantContent(item: RenovationItem) -> some View {
        let variant = model.selectedVariant(for: item)
        let unitPrice = model.currentUnitPrice(for: item)

        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            if item.hasVariants, let variants = item.materialVariants {
                VStack(alignment: .leading, spacing: ADSpacing.s2) {
                    fieldHeader("Materiale")
                    VStack(spacing: ADSpacing.s2) {
                        ForEach(variants) { v in
                            optionRow(
                                label: v.label,
                                priceLabel: v.unitPrice(for: model.level).formattedEuro() + " / " + item.unitLabel,
                                isSelected: variant?.key == v.key
                            ) {
                                model.selectVariant(v, for: item)
                            }
                        }
                    }
                }
            }

            quantityRow(for: item)

            HStack {
                Text("Prezzo unitario")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
                Spacer(minLength: ADSpacing.s2)
                Text("\(unitPrice.formattedEuro()) / \(item.unitLabel)")
                    .font(ADTypography.metadata.weight(.medium))
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
            }

            Divider().overlay(ADColor.border.opacity(0.4))

            HStack {
                Text("Subtotale")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.text)
                Spacer(minLength: ADSpacing.s2)
                Text(model.cost(of: item).formattedEuro())
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
            }
        }
        .padding(ADSpacing.s4)
    }

    private func quantityRow(for item: RenovationItem) -> some View {
        let qty = model.quantity(for: item)
        return HStack(spacing: ADSpacing.s3) {
            Text("Quantità")
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.textMuted)
            Spacer(minLength: ADSpacing.s2)
            HStack(spacing: ADSpacing.s2) {
                stepBtn(icon: "minus", enabled: qty > item.minQuantity) {
                    withAnimation(.easeOut(duration: 0.12)) {
                        model.updateQuantity(item, to: qty - item.quantityStep)
                    }
                }
                Text(item.quantityLabel(for: qty))
                    .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
                    .frame(minWidth: 88)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                stepBtn(icon: "plus", enabled: qty < item.maxQuantity) {
                    withAnimation(.easeOut(duration: 0.12)) {
                        model.updateQuantity(item, to: qty + item.quantityStep)
                    }
                }
            }
        }
    }

    // MARK: - Sticky total (categoria)

    private var stickyTotal: some View {
        let categorySubtotal = items.reduce(0.0) { $0 + model.cost(of: $1) }
        let selectedCount = items.filter { model.isSelected($0) }.count
        return HStack(spacing: ADSpacing.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Subtotale categoria")
                    .font(ADTypography.metadata.weight(.medium))
                    .foregroundStyle(ADColor.textMuted)
                    .tracking(0.5)
                Text(categorySubtotal.formattedEuro())
                    .font(ADTypography.priceMedium)
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: ADSpacing.s2)
            VStack(alignment: .trailing, spacing: 2) {
                Text("Interventi")
                    .font(ADTypography.metadata.weight(.medium))
                    .foregroundStyle(ADColor.textMuted)
                Text("\(selectedCount) di \(items.count)")
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
            }
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
