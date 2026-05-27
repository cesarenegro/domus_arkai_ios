//
//  PropertyFloorplan2DView.swift
//  Domus Arkai
//
//  Spec: `06_ios_2d_floorplan.json`. Distribution card rimossa (scope lock).
//  Resta: planimetria zoomabile + quick specs grid 2x2.
//

import SwiftUI

struct PropertyFloorplan2DView: View {
    let property: Property
    let floorplan: PropertyFloorplan

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: ADSpacing.s5) {
                        floorplanCard
                        quickSpecsGrid
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
            }
            .navigationTitle("Planimetria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    private var floorplanCard: some View {
        AsyncImage(url: floorplan.url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 360)
            case .empty:
                ADColor.surfaceSoft
                    .frame(minHeight: 360)
                    .overlay(ProgressView().tint(ADColor.primarySoft))
            default:
                ADColor.surfaceSoft
                    .frame(minHeight: 360)
            }
        }
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var quickSpecsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ADSpacing.s3) {
            if let sqm = property.surfaceCommercial {
                miniCard(value: "\(Int(sqm)) mq", label: "Superficie")
            }
            if let r = property.rooms {
                miniCard(value: "\(r)", label: r == 1 ? "Locale" : "Locali")
            }
            if let b = property.bathrooms {
                miniCard(value: "\(b)", label: b == 1 ? "Bagno" : "Bagni")
            }
            if property.hasTerrace {
                miniCard(value: "Sì", label: "Terrazza")
            } else if property.hasBalcony {
                miniCard(value: "Sì", label: "Balcone")
            } else if let e = property.energyClass {
                miniCard(value: e.rawValue, label: "Classe energ.")
            }
        }
    }

    private func miniCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s1) {
            Text(value)
                .font(ADTypography.cardTitle.weight(.semibold))
                .foregroundStyle(ADColor.primary)
            Text(label)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingSmall)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }
}
