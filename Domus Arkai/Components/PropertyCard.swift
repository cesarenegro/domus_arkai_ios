//
//  PropertyCard.swift
//  Domus Arkai
//

import SwiftUI

struct PropertyCard: View {
    let property: Property
    let isFavorite: Bool
    let onTapFavorite: () -> Void
    /// Nome agenzia (mostrato come "Pubblicato da X" in fondo alla card). Nil = non mostrato.
    var agencyName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            infoSection
        }
        .background(ADColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border.opacity(0.6), lineWidth: 1)
        )
        .shadow(
            color: ADColor.primary.opacity(ADShadow.softOpacity),
            radius: ADShadow.softRadius,
            x: ADShadow.softOffset.width,
            y: ADShadow.softOffset.height
        )
    }

    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                AsyncImage(url: property.coverImageURL) { phase in
                    switch phase {
                    case .empty:
                        ADColor.surfaceSoft
                            .overlay(ProgressView().tint(ADColor.primarySoft))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ADColor.surfaceSoft
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 28, weight: .regular))
                                    .foregroundStyle(ADColor.textLight)
                            )
                    @unknown default:
                        ADColor.surfaceSoft
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width * 10 / 16)
                .clipped()
            }
            .aspectRatio(16/10, contentMode: .fit)

            HStack {
                if property.isFeatured {
                    badgeView(text: "Nuovo")
                } else {
                    Color.clear.frame(width: 1, height: 1)
                }
                Spacer()
                favoriteButton
            }
            .padding(ADSpacing.s3)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(property.formattedPrice)
                .font(ADTypography.priceMedium)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(property.title)
                .font(ADTypography.cardTitle)
                .foregroundStyle(ADColor.primary)
                .lineLimit(1)

            Text(property.locationLine)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .lineLimit(1)

            Text(property.metadataLine)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.top, ADSpacing.s1)

            if let agencyName, !agencyName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.system(size: 9, weight: .medium))
                    Text(agencyName)
                        .font(ADTypography.metadata.weight(.medium))
                        .lineLimit(1)
                }
                .foregroundStyle(ADColor.primarySoft)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingSmall)
    }

    private func badgeView(text: String) -> some View {
        Text(text)
            .font(ADTypography.metadata.weight(.medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, ADSpacing.s3)
            .padding(.vertical, ADSpacing.s1)
            .background(
                Capsule().fill(ADColor.primarySoft)
            )
    }

    private var favoriteButton: some View {
        Button(action: onTapFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isFavorite ? ADColor.primarySoft : ADColor.primary)
                .padding(ADSpacing.s2)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(0..<1, id: \.self) { _ in
                PropertyCard(
                    property: Property(
                        id: UUID(),
                        agencyID: UUID(),
                        title: "Attico in Brera",
                        descriptionShort: nil, descriptionLong: nil,
                        propertyType: .attico, contractType: .vendita,
                        price: 780_000, city: "Milano", area: "Brera",
                        addressPublic: nil, latitude: nil, longitude: nil,
                        surfaceCommercial: 120, surfaceInternal: nil,
                        rooms: 3, bedrooms: 2, bathrooms: 2,
                        floor: nil, totalFloors: nil,
                        hasElevator: true, hasBalcony: false, hasTerrace: true,
                        hasGarden: false, hasGarage: false, hasParking: false, hasCellar: true,
                        conditionStatus: "Ristrutturato", energyClass: .a2,
                        publishedStatus: .online, isFeatured: true,
                        coverImageURL: URL(string: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200")
                    ),
                    isFavorite: false,
                    onTapFavorite: {}
                )
                .padding()
            }
        }
    }
    .background(ADColor.background)
}
