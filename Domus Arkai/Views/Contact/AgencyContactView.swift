//
//  AgencyContactView.swift
//  Domus Arkai
//
//  Spec: `13_ios_agency_contact.json`. Rating rimosso (scope lock).
//

import SwiftUI

struct AgencyContactView: View {
    @State private var agency: Agency?

    // Coordinata mappa Contatti — default Brera Milano, override se Agency ha coordinate.
    private let defaultLatitude: Double = 45.4716
    private let defaultLongitude: Double = 9.1879

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: ADSpacing.s5) {
                        agencyCard
                        contactButtonsRow
                        addressCard
                        mapCard
                        openingHoursCard
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
            }
            .navigationTitle("Contatti")
            .navigationBarTitleDisplayMode(.large)
            .task {
                agency = await MockDataService.shared.currentAgency()
            }
        }
    }

    private var agencyCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            ZStack {
                Circle()
                    .fill(ADColor.primaryLight)
                    .frame(width: 56, height: 56)
                Image(systemName: "building.2")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(ADColor.primary)
            }
            .padding(.bottom, ADSpacing.s2)

            Text(agency?.name ?? "Studio Casa Milano")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            Text("powered by Arkai Domus")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var contactButtonsRow: some View {
        HStack(spacing: ADSpacing.s3) {
            contactButton(icon: "phone.fill", label: "Chiama") {
                if let phone = agency?.phone, let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                    UIApplication.shared.open(url)
                }
            }
            contactButton(icon: "message.fill", label: "WhatsApp") {
                if let wa = agency?.whatsapp,
                   let url = URL(string: "https://wa.me/\(wa.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: ""))") {
                    UIApplication.shared.open(url)
                }
            }
            contactButton(icon: "envelope.fill", label: "Email") {
                if let email = agency?.email, let url = URL(string: "mailto:\(email)") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private func contactButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: ADSpacing.s2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ADColor.primary)
                Text(label)
                    .font(ADTypography.smallMedium)
                    .foregroundStyle(ADColor.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
        .buttonStyle(.plain)
    }

    private var addressCard: some View {
        sectionCard(title: "Indirizzo") {
            HStack(alignment: .top, spacing: ADSpacing.s3) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(ADColor.primarySoft)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(agency?.address ?? "—")
                        .font(ADTypography.body)
                        .foregroundStyle(ADColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    if let city = agency?.city {
                        Text(city)
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textMuted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var mapCard: some View {
        // Static Mapbox brand-coloured (light-v11 + pin sand c5a977)
        // Coerente col PDF Dossier e col frontend web.
        let url = MapboxConfig.staticMapURL(
            latitude: defaultLatitude,
            longitude: defaultLongitude,
            width: 600,
            height: 220,
            zoom: 15
        )
        return AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty:
                ADColor.surfaceSoft.overlay(ProgressView().tint(ADColor.primarySoft))
            default:
                ADColor.surfaceSoft.overlay(
                    Image(systemName: "map")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(ADColor.textLight)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var openingHoursCard: some View {
        sectionCard(title: "Orari") {
            VStack(spacing: ADSpacing.s2) {
                hourRow("Lunedì – Venerdì", "9:00 — 13:00 · 14:30 — 19:00")
                hourRow("Sabato", "9:30 — 12:30")
                hourRow("Domenica", "Chiuso")
            }
        }
    }

    private func hourRow(_ day: String, _ hours: String) -> some View {
        HStack(spacing: ADSpacing.s2) {
            Text(day)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .lineLimit(1)
            Spacer(minLength: ADSpacing.s2)
            Text(hours)
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text(title)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }
}
