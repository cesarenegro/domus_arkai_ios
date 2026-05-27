//
//  RoomScanFlowView.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — Sprint 1 + 2.
//  Flow utente:
//   1. RoomCaptureRepresentable → scansiona la stanza (RoomPlan LiDAR)
//   2. Summary con metriche geometria + JSON debug
//   3. (Sprint 2) Bottone "Carica su immobile" → upload `scan_json` a Supabase
//   4. Polling status finché `.ready` (USDZ pronto) o `.error`
//

import SwiftUI
import RoomPlan
import Auth

@MainActor
struct RoomScanFlowView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var capturedRoom: CapturedRoom?
    @State private var captureError: String?
    @State private var jsonPreview: String = ""

    // MARK: - Upload state (Sprint 2)
    @State private var showUploadSheet: Bool = false
    @State private var propertyIDInput: String = ""
    @State private var uploadPhase: UploadPhase = .idle
    @State private var uploadedScan: PropertyScan?
    @State private var uploadError: String?
    @State private var pollTask: Task<Void, Never>? = nil

    enum UploadPhase: Equatable {
        case idle
        case uploading
        case waiting     // status pending/processing — in attesa pipeline server
        case ready       // status ready
        case errored(String)
    }

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
                        Button("Chiudi") {
                            pollTask?.cancel()
                            dismiss()
                        }
                        .foregroundStyle(ADColor.primary)
                    }
                }
            }
            .sheet(isPresented: $showUploadSheet) {
                uploadSheet
            }
        }
    }

    // MARK: - Capture callbacks

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
                    uploadStateCard
                    uploadButton(room)
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
        let area = computeArea(from: room)
        let metrics: [(String, String)] = [
            ("Pareti", "\(room.walls.count)"),
            ("Porte", "\(room.doors.count)"),
            ("Finestre", "\(room.windows.count)"),
            ("Aperture", "\(room.openings.count)"),
            ("Oggetti", "\(room.objects.count)"),
            ("Area m²", String(format: "%.1f", area))
        ]

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: ADSpacing.s3
        ) {
            ForEach(metrics, id: \.0) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.1)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
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

    // MARK: - Sprint 2: upload UI

    @ViewBuilder
    private var uploadStateCard: some View {
        switch uploadPhase {
        case .idle:
            EmptyView()
        case .uploading:
            uploadStatusRow(icon: "arrow.up.circle.fill", text: "Caricamento scansione…", tint: ADColor.primarySoft, showSpinner: true)
        case .waiting:
            uploadStatusRow(icon: "hourglass", text: "In elaborazione lato server. Riceverai una notifica push quando l'USDZ sarà pronto.", tint: ADColor.accentWarm, showSpinner: true)
        case .ready:
            uploadStatusRow(icon: "checkmark.seal.fill", text: "Scansione pronta! USDZ disponibile su Storage.", tint: ADColor.success, showSpinner: false)
        case .errored(let msg):
            uploadStatusRow(icon: "exclamationmark.triangle.fill", text: msg, tint: ADColor.warning, showSpinner: false)
        }
    }

    private func uploadStatusRow(icon: String, text: String, tint: Color, showSpinner: Bool) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            if showSpinner {
                ProgressView().tint(tint)
                    .padding(.top, 2)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(tint)
                    .padding(.top, 2)
            }
            Text(text)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.text.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s4)
        .background(tint.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func uploadButton(_ room: CapturedRoom) -> some View {
        if case .idle = uploadPhase {
            Button {
                showUploadSheet = true
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Carica su immobile")
                        .font(ADTypography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ADColor.primary)
                .foregroundStyle(ADColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var uploadSheet: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s4) {
                        Text("INSERIMENTO TEMPORANEO")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(ADColor.accentWarm)
                        Text("Associa la scansione a un immobile")
                            .font(ADTypography.sectionTitle)
                            .foregroundStyle(ADColor.primary)
                        Text("Per ora inserisci manualmente l'UUID della property. Nella v2.0 finale ci sarà un picker delle property dell'agenzia.")
                            .font(ADTypography.small)
                            .foregroundStyle(ADColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        TextField("UUID property (es. A5598C7A-…)", text: $propertyIDInput)
                            .font(.system(size: 14, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, ADSpacing.s4)
                            .frame(height: 50)
                            .background(ADColor.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ADColor.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            startUpload()
                        } label: {
                            HStack(spacing: ADSpacing.s2) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Conferma e carica")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canSubmit ? ADColor.primary : ADColor.textLight)
                            .foregroundStyle(ADColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit)
                    }
                    .padding(ADSpacing.s5)
                }
            }
            .navigationTitle("Carica scansione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { showUploadSheet = false }
                        .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    private var canSubmit: Bool {
        UUID(uuidString: propertyIDInput.trimmingCharacters(in: .whitespaces)) != nil
    }

    private func startUpload() {
        guard let room = capturedRoom else { return }
        guard let propertyID = UUID(uuidString: propertyIDInput.trimmingCharacters(in: .whitespaces)) else { return }
        guard let userID = AuthService.shared.currentUser?.id else {
            uploadPhase = .errored("Non sei autenticato.")
            return
        }
        showUploadSheet = false
        uploadPhase = .uploading
        Task {
            do {
                // Codifica blob CapturedRoom
                let blob = try AnyCodable(room)
                let area = computeArea(from: room)
                let count = max(1, room.sections.count)
                let draft = PropertyScanDraft(
                    propertyID: propertyID,
                    scannedBy: userID,
                    scanJSON: blob,
                    totalAreaM2: area,
                    roomCount: count
                )
                let created = try await PropertyScanService.shared.createScan(draft)
                uploadedScan = created
                uploadPhase = .waiting
                startPolling(scanID: created.id)
            } catch {
                uploadPhase = .errored(error.localizedDescription)
                print("🔴 [RoomScan][Flow] upload failed — \(error.localizedDescription)")
            }
        }
    }

    private func startPolling(scanID: UUID) {
        pollTask?.cancel()
        pollTask = Task { @MainActor in
            // Polling ogni 5s. La pipeline server normalmente impiega 10-60s.
            // Stop al primo .ready o .error o se la view viene chiusa.
            for _ in 0..<60 { // max ~5 minuti
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if Task.isCancelled { return }
                do {
                    guard let updated = try await PropertyScanService.shared.fetchScan(id: scanID) else { continue }
                    switch updated.status {
                    case .ready:
                        uploadedScan = updated
                        uploadPhase = .ready
                        return
                    case .error:
                        uploadPhase = .errored("La pipeline server ha segnalato un errore. Riprova o contatta supporto.")
                        return
                    case .pending, .processing:
                        continue
                    }
                } catch {
                    print("🟡 [RoomScan][Flow] poll error: \(error.localizedDescription)")
                }
            }
            // Timeout: lascia in waiting, lo user può chiudere e ricevere la push notification quando pronta
            print("🟡 [RoomScan][Flow] poll timeout after 5min — relying on push notification")
        }
    }

    // MARK: - JSON debug card

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

    // MARK: - Helpers

    /// Area totale approssimativa sommando l'area dei pavimenti rilevati.
    /// Apple usa SI: dimensions x/z sono in metri.
    private func computeArea(from room: CapturedRoom) -> Double {
        room.floors.reduce(0.0) { sum, floor in
            let w = Double(floor.dimensions.x)
            let d = Double(floor.dimensions.z)
            return sum + (w * d)
        }
    }

    private func renderJSON(from room: CapturedRoom) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(room),
              let raw = String(data: data, encoding: .utf8) else {
            return "(JSON encoding failed)"
        }
        if raw.count > 4000 {
            return String(raw.prefix(4000)) + "\n\n… (troncato, \(raw.count) bytes totali)"
        }
        return raw
    }
}

#Preview {
    RoomScanFlowView()
}
