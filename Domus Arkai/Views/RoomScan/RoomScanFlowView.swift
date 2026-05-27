//
//  RoomScanFlowView.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — POC standalone Sprint 1.
//  Apre `RoomCaptureRepresentable` per scansionare una stanza.
//  Al termine mostra una sintesi della geometria + JSON debug.
//  NIENTE upload Supabase in questa fase: è solo verifica RoomPlan end-to-end.
//

import SwiftUI
import RoomPlan

struct RoomScanFlowView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var capturedRoom: CapturedRoom?
    @State private var captureError: String?
    @State private var jsonPreview: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                if RoomCaptureSession.isSupported == false {
                    unsupportedDeviceView
                } else if let capturedRoom {
                    summaryView(capturedRoom)
                } else if let captureError {
                    errorView(captureError)
                } else {
                    RoomCaptureRepresentable(
                        onComplete: handleComplete,
                        onCancel: { dismiss() },
                        onError: handleError
                    )
                    .ignoresSafeArea()
                }
            }
            .navigationTitle("Scansione 3D · POC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if capturedRoom != nil || captureError != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Chiudi") { dismiss() }
                            .foregroundStyle(ADColor.primary)
                    }
                }
            }
        }
    }

    // MARK: - Callbacks

    private func handleComplete(_ room: CapturedRoom) {
        capturedRoom = room
        jsonPreview = renderJSON(from: room)
    }

    private func handleError(_ error: Error) {
        captureError = error.localizedDescription
        print("🔴 [RoomScan][Flow] error — \(error.localizedDescription)")
    }

    // MARK: - Summary view

    private func summaryView(_ room: CapturedRoom) -> some View {
        ZStack {
            ADColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: ADSpacing.s4) {
                    headerCard(room)
                    metricsGrid(room)
                    jsonDebugCard
                    Color.clear.frame(height: ADSpacing.s6)
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.top, ADSpacing.s3)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func headerCard(_ room: CapturedRoom) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("SCANSIONE COMPLETATA")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text("Geometria rilevata")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text("ID scansione: \(room.identifier.uuidString.prefix(8))…")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.s4)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func metricsGrid(_ room: CapturedRoom) -> some View {
        let metrics: [(String, Int)] = [
            ("Pareti", room.walls.count),
            ("Porte", room.doors.count),
            ("Finestre", room.windows.count),
            ("Aperture", room.openings.count),
            ("Pavimenti", room.floors.count),
            ("Oggetti", room.objects.count)
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: ADSpacing.s3) {
            ForEach(metrics, id: \.0) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(metric.1)")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(ADColor.primary)
                        .monospacedDigit()
                    Text(metric.0)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ADSpacing.s3)
                .background(ADColor.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var jsonDebugCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("JSON DEBUG (CapturedRoom encoded)")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(ADColor.textMuted)
            Text(jsonPreview)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(ADColor.text.opacity(0.8))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ADSpacing.s4)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Error / unsupported states

    private func errorView(_ message: String) -> some View {
        ZStack {
            ADColor.background.ignoresSafeArea()
            VStack(spacing: ADSpacing.s3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(ADColor.warning)
                Text("Scansione fallita")
                    .font(ADTypography.sectionTitle)
                    .foregroundStyle(ADColor.primary)
                Text(message)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ADSpacing.s5)
        }
    }

    private var unsupportedDeviceView: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()
            VStack(spacing: ADSpacing.s3) {
                Image(systemName: "iphone.gen3.slash")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(ADColor.textLight)
                Text("Hardware non supportato")
                    .font(ADTypography.sectionTitle)
                    .foregroundStyle(ADColor.primary)
                Text("La scansione 3D richiede un iPhone Pro o iPad Pro con sensore LiDAR.")
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Chiudi") { dismiss() }
                    .padding(.top, ADSpacing.s3)
                    .foregroundStyle(ADColor.primary)
            }
            .padding(ADSpacing.s5)
        }
    }

    // MARK: - JSON serializer

    private func renderJSON(from room: CapturedRoom) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(room),
              let raw = String(data: data, encoding: .utf8) else {
            return "(JSON encoding failed)"
        }
        // Tronca per anteprima debug: i CapturedRoom serializzati sono molto lunghi
        if raw.count > 4000 {
            return String(raw.prefix(4000)) + "\n\n… (troncato, \(raw.count) bytes totali)"
        }
        return raw
    }
}

#Preview {
    RoomScanFlowView()
}
