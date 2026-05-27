//
//  AgenciesListView.swift
//  Domus Arkai
//
//  Tab "Contatti": lista delle agenzie partner Arkai Domus
//  + card finale "Sviluppato da Arkai Domus" (contatto team).
//

import SwiftUI

@MainActor
@Observable
final class AgenciesListViewModel {
    enum Phase: Equatable {
        case idle, loading, loaded, error(String)
    }

    var agencies: [Agency] = []
    var phase: Phase = .idle

    func load() async {
        phase = .loading
        do {
            agencies = try await AgencyService.shared.fetchAllAgencies(activeOnly: true)
            phase = .loaded
            print("📦 [AgenciesList] loaded \(agencies.count) agencies")
        } catch {
            phase = .error(error.localizedDescription)
            print("🔴 [AgenciesList] load failed — \(error)")
        }
    }
}

struct AgenciesListView: View {
    @State private var model = AgenciesListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s4) {
                        intro
                        agenciesSection
                        developerCard
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
                .scrollIndicators(.hidden)
                .refreshable { await model.load() }
            }
            .navigationTitle("Agenzie Partner")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Agency.self) { agency in
                AgencyDetailView(agency: agency)
            }
            .task {
                if case .idle = model.phase {
                    await model.load()
                }
            }
        }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Le agenzie partner Arkai Domus")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
            Text("Una selezione curata di agenzie immobiliari italiane di pregio.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Agencies

    @ViewBuilder
    private var agenciesSection: some View {
        switch model.phase {
        case .idle, .loading:
            VStack(spacing: ADSpacing.s3) {
                ForEach(0..<2, id: \.self) { _ in agencyCardSkeleton }
            }
        case .loaded:
            if model.agencies.isEmpty {
                emptyView
            } else {
                VStack(spacing: ADSpacing.s3) {
                    ForEach(model.agencies) { agency in
                        NavigationLink(value: agency) {
                            agencyCard(agency)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case .error(let msg):
            ADErrorState(message: msg) {
                Task { await model.load() }
            }
        }
    }

    private func agencyCard(_ agency: Agency) -> some View {
        HStack(spacing: ADSpacing.s3) {
            if let logoURL = agency.logoURL {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: ADColor.surfaceSoft
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .stroke(ADColor.border, lineWidth: 1)
                )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .fill(ADColor.primaryLight)
                        .frame(width: 56, height: 56)
                    Image(systemName: "building.2")
                        .font(.system(size: 22))
                        .foregroundStyle(ADColor.primary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(agency.name)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(2)
                if let city = agency.city {
                    Text(city)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(1)
                }
                if let desc = agency.description, !desc.isEmpty {
                    Text(desc)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ADColor.textLight)
        }
        .padding(ADSpacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var agencyCardSkeleton: some View {
        HStack(spacing: ADSpacing.s3) {
            RoundedRectangle(cornerRadius: ADRadius.md)
                .fill(ADColor.surfaceSoft)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(ADColor.surfaceSoft).frame(height: 12)
                RoundedRectangle(cornerRadius: 4).fill(ADColor.surfaceSoft).frame(height: 10).frame(maxWidth: 120)
            }
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s3)
        .background(ADColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var emptyView: some View {
        ADEmptyState(
            icon: "building.2",
            title: "Nessuna agenzia partner",
            message: "Al momento non ci sono agenzie partner attive."
        )
    }

    // MARK: - Developer card (Arkai Domus team)

    private var developerCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Sviluppato da")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            HStack(spacing: ADSpacing.s3) {
                ZStack {
                    Circle()
                        .fill(ADColor.primary)
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(ADColor.accentWarm)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Arkai Domus")
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                    Text("Piattaforma editoriale per immobili italiani di pregio.")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(ADSpacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))

            Button {
                if let url = URL(string: "https://arkai.dev") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 13, weight: .medium))
                    Text("arkai.dev")
                        .font(ADTypography.metadata.weight(.semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 11))
                }
                .foregroundStyle(ADColor.primary)
                .padding(.horizontal, ADSpacing.s3)
                .padding(.vertical, ADSpacing.s2)
                .background(ADColor.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
            }
            .buttonStyle(.plain)
        }
    }
}
