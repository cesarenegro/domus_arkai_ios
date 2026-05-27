//
//  PropertyFloorplan3DView.swift
//  Domus Arkai
//
//  Spec: `07_ios_3d_floorplan.json`. CTA "Esplora spazi" rimossa (scope lock):
//  MVP è immagine statica.
//

import SwiftUI

struct PropertyFloorplan3DView: View {
    let property: Property
    let floorplan: PropertyFloorplan3D

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        previewCard
                        quickSpecsList
                        legalNote
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
            }
            .navigationTitle("Vista 3D")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    private var previewCard: some View {
        AsyncImage(url: floorplan.previewImageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 320)
            case .empty:
                ADColor.surfaceSoft
                    .frame(height: 320)
                    .overlay(ProgressView().tint(ADColor.primarySoft))
            default:
                ADColor.surfaceSoft
                    .frame(height: 320)
            }
        }
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var quickSpecsList: some View {
        VStack(spacing: 0) {
            if let sqm = property.surfaceCommercial {
                specRow(label: "Superficie", value: "\(Int(sqm)) mq")
            }
            if let r = property.rooms {
                specRow(label: "Locali", value: "\(r)")
            }
            if let b = property.bathrooms {
                specRow(label: "Bagni", value: "\(b)")
            }
            if let e = property.energyClass {
                specRow(label: "Classe energetica", value: e.rawValue, isLast: true)
            }
        }
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func specRow(label: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: ADSpacing.s3) {
                Text(label)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
                Spacer(minLength: ADSpacing.s2)
                Text(value)
                    .font(ADTypography.smallMedium)
                    .foregroundStyle(ADColor.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
            if !isLast {
                Divider().overlay(ADColor.border.opacity(0.6))
            }
        }
    }

    private var legalNote: some View {
        Text("Rendering architettonico indicativo. Le proporzioni e gli arredi possono differire dallo stato reale dell'immobile.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, ADSpacing.s2)
    }
}
