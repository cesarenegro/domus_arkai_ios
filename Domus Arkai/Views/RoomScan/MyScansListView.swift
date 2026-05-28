//
//  MyScansListView.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — lista delle scansioni effettuate dall'agente loggato.
//  Mostra status (pending/processing/ready/error) + label + area + property associata.
//

import SwiftUI
import Auth

@MainActor
@Observable
final class MyScansListModel {
    enum Phase: Equatable {
        case idle, loading, loaded, error(String)
    }

    var phase: Phase = .idle
    var scans: [PropertyScan] = []

    func load() async {
        guard let uid = AuthService.shared.currentUser?.id else {
            phase = .idle
            return
        }
        phase = .loading
        do {
            let rows = try await PropertyScanService.shared.listMyScans(userID: uid)
            scans = rows
            phase = .loaded
            print("✅ [MyScans] loaded \(rows.count) scans")
        } catch {
            phase = .error(error.localizedDescription)
            print("🔴 [MyScans] load failed — \(error.localizedDescription)")
        }
    }
}

struct MyScansListView: View {
    @State private var listModel = MyScansListModel()

    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Le mie scansioni")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if listModel.phase == .idle {
                await listModel.load()
            }
        }
        .refreshable {
            await listModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch listModel.phase {
        case .idle, .loading:
            ProgressView()
                .tint(ADColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            if listModel.scans.isEmpty {
                emptyState
            } else {
                scansList
            }

        case .error(let msg):
            errorState(msg)
        }
    }

    private var scansList: some View {
        ScrollView {
            LazyVStack(spacing: ADSpacing.s2) {
                ForEach(listModel.scans) { scan in
                    scanRow(scan)
                }
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
            .padding(.top, ADSpacing.s3)
            .padding(.bottom, ADSpacing.s8)
        }
        .scrollIndicators(.hidden)
    }

    private func scanRow(_ scan: PropertyScan) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            statusIcon(scan.status)
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(scan.label ?? "Scansione senza nome")
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                HStack(spacing: ADSpacing.s2) {
                    Text(scan.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor(scan.status))
                    if let area = scan.totalAreaM2 {
                        Text("· \(String(format: "%.1f", area)) m²")
                            .font(.system(size: 11))
                            .foregroundStyle(ADColor.textMuted)
                    }
                    if let rooms = scan.roomCount, rooms > 0 {
                        Text("· \(rooms) \(rooms == 1 ? "ambiente" : "ambienti")")
                            .font(.system(size: 11))
                            .foregroundStyle(ADColor.textMuted)
                    }
                }
                if let created = scan.createdAt {
                    Text(created.formatted(date: .abbreviated, time: .shortened))
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                }
            }
            Spacer(minLength: 0)
            if scan.status == .ready {
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(ADColor.accentWarm)
            }
        }
        .padding(ADSpacing.s3)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func statusIcon(_ status: PropertyScanStatus) -> some View {
        ZStack {
            Circle()
                .fill(statusColor(status).opacity(0.18))
            Image(systemName: statusSymbol(status))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(statusColor(status))
        }
    }

    private func statusSymbol(_ status: PropertyScanStatus) -> String {
        switch status {
        case .pending: "hourglass"
        case .processing: "gearshape"
        case .ready: "checkmark.seal.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private func statusColor(_ status: PropertyScanStatus) -> Color {
        switch status {
        case .pending, .processing: ADColor.accentWarm
        case .ready: ADColor.success
        case .error: ADColor.warning
        }
    }

    private var emptyState: some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(ADColor.textLight)
            Text("Nessuna scansione")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text("Lancia la tua prima scansione 3D dalla voce \"Nuova scansione\" nel menu professionale.")
                .font(ADTypography.body)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ADSpacing.s5)
        }
        .padding(ADSpacing.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(ADColor.warning)
            Text("Errore di caricamento")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text(message)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ADSpacing.s5)
            Button("Riprova") {
                Task { await listModel.load() }
            }
            .foregroundStyle(ADColor.primary)
            .padding(.top, ADSpacing.s2)
        }
        .padding(ADSpacing.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        MyScansListView()
    }
}
