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
import simd

@MainActor
struct RoomScanFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenRoomScanOnboarding") private var hasSeenOnboarding: Bool = false

    @State private var capturedRoom: CapturedRoom?
    @State private var captureError: String?
    @State private var jsonPreview: String = ""
    @State private var showOnboarding: Bool = false
    @State private var scanController = RoomScanController()

    // MARK: - Upload state (Sprint 2)
    @State private var showUploadSheet: Bool = false
    @State private var scanLabel: String = ""
    @State private var selectedProperty: Property?
    @State private var availableProperties: [Property] = []
    @State private var loadingProperties: Bool = false
    @State private var propertiesLoadError: String?
    @State private var uploadPhase: UploadPhase = .idle
    @State private var uploadedScan: PropertyScan?
    @State private var uploadError: String?
    @State private var pollTask: Task<Void, Never>? = nil

    // MARK: - New property creation state (v2.0 — Cesare requirement, msg e91b208a)
    @State private var targetMode: TargetMode = .existing
    @State private var newPropertyCity: String = ""
    @State private var userGeneratedCount: Int? = nil // nil = non ancora caricato
    @State private var newPropertyError: String?

    enum TargetMode: String, CaseIterable {
        case existing  // associa a property esistente (picker)
        case new       // crea nuovo immobile user-generated (max 1 per user)

        var label: String {
            switch self {
            case .existing: "Immobile esistente"
            case .new: "Nuovo immobile"
            }
        }
    }

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
                    ZStack(alignment: .top) {
                        RoomCaptureRepresentable(
                            controller: scanController,
                            onComplete: handleComplete,
                            onCancel: { dismiss() },
                            onError: handleError
                        )
                        .ignoresSafeArea()

                        captureOverlayBar
                    }
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
            .sheet(isPresented: $showOnboarding) {
                RoomScanOnboardingView()
                    .interactiveDismissDisabled()
            }
            .task {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
            }
        }
    }

    // MARK: - Capture overlay (Annulla / Termina)

    private var captureOverlayBar: some View {
        HStack(spacing: ADSpacing.s3) {
            Button {
                scanController.requestCancel()
            } label: {
                HStack(spacing: ADSpacing.s1) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Annulla")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, ADSpacing.s4)
                .padding(.vertical, ADSpacing.s2)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(.white.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                scanController.requestStop()
            } label: {
                HStack(spacing: ADSpacing.s1) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Termina")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(ADColor.background)
                .padding(.horizontal, ADSpacing.s4)
                .padding(.vertical, ADSpacing.s2)
                .background(ADColor.primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(.white.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.top, ADSpacing.s5)
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
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        Text("SALVA SCANSIONE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(ADColor.accentWarm)
                        Text("Associa la scansione a un immobile")
                            .font(ADTypography.sectionTitle)
                            .foregroundStyle(ADColor.primary)

                        // Toggle Esistente / Nuovo
                        targetModeToggle

                        // Nome scansione
                        VStack(alignment: .leading, spacing: ADSpacing.s2) {
                            Text("NOME SCANSIONE")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(2)
                                .foregroundStyle(ADColor.textMuted)
                            TextField("Es. Bagno principale", text: $scanLabel)
                                .font(ADTypography.body)
                                .padding(.horizontal, ADSpacing.s4)
                                .frame(height: 48)
                                .background(ADColor.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ADColor.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Sezione condizionale: picker o form nuovo
                        if targetMode == .existing {
                            existingPropertySection
                        } else {
                            newPropertySection
                        }

                        if let newPropertyError {
                            errorBanner(newPropertyError)
                        }

                        Button {
                            startUpload()
                        } label: {
                            HStack(spacing: ADSpacing.s2) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Conferma e carica")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(canSubmit ? ADColor.primary : ADColor.textLight)
                            .foregroundStyle(ADColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit)
                    }
                    .padding(.horizontal, ADSpacing.s5)
                    .padding(.vertical, ADSpacing.s5)
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
            .task {
                if availableProperties.isEmpty && !loadingProperties {
                    await loadProperties()
                }
                if userGeneratedCount == nil {
                    await loadUserGeneratedCount()
                }
            }
        }
    }

    private var targetModeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TargetMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { targetMode = mode }
                } label: {
                    Text(mode.label)
                        .font(ADTypography.smallMedium.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .foregroundStyle(targetMode == mode ? ADColor.background : ADColor.primary)
                        .background(targetMode == mode ? ADColor.primary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var existingPropertySection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("IMMOBILE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.textMuted)
            propertyPickerContent
        }
    }

    @ViewBuilder
    private var newPropertySection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                Text("CITTÀ")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(ADColor.textMuted)
                TextField("Es. Milano", text: $newPropertyCity)
                    .font(ADTypography.body)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, ADSpacing.s4)
                    .frame(height: 48)
                    .background(ADColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ADColor.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let count = userGeneratedCount, count >= 1 {
                HStack(alignment: .top, spacing: ADSpacing.s2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(ADColor.warning)
                    Text("Hai già 1 immobile creato da scansione. Per crearne un altro, contatta l'amministratore dell'agenzia.")
                        .font(ADTypography.small)
                        .foregroundStyle(ADColor.warning)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(ADSpacing.s3)
                .background(ADColor.warning.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ADColor.warning.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Il nome scansione diventa il titolo del nuovo immobile. Sarà salvato come bozza (`draft`) finché l'amministratore dell'agenzia non lo pubblica.")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(ADColor.warning)
            Text(message)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.warning)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s3)
        .background(ADColor.warning.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ADColor.warning.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadUserGeneratedCount() async {
        guard let uid = AuthService.shared.currentUser?.id else { return }
        do {
            userGeneratedCount = try await PropertyService.shared.countMyUserGeneratedProperties(userID: uid)
            print("✅ [RoomScan][Flow] user-generated count = \(userGeneratedCount ?? 0)")
        } catch {
            print("🟡 [RoomScan][Flow] countMyUserGenerated failed — \(error.localizedDescription)")
            userGeneratedCount = 0 // assume safe
        }
    }

    @ViewBuilder
    private var propertyPickerContent: some View {
        if loadingProperties {
            HStack(spacing: ADSpacing.s2) {
                ProgressView().tint(ADColor.primary)
                Text("Carico immobili…")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                Spacer()
            }
            .padding(ADSpacing.s4)
            .background(ADColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let propertiesLoadError {
            Text(propertiesLoadError)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.warning)
                .padding(ADSpacing.s4)
        } else if availableProperties.isEmpty {
            Text("Nessun immobile disponibile.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .padding(ADSpacing.s4)
        } else {
            VStack(spacing: ADSpacing.s2) {
                ForEach(availableProperties) { property in
                    Button {
                        selectedProperty = property
                    } label: {
                        propertyRow(property, selected: selectedProperty?.id == property.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func propertyRow(_ property: Property, selected: Bool) -> some View {
        HStack(spacing: ADSpacing.s3) {
            AsyncImage(url: property.coverImageURL) { phase in
                switch phase {
                case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                default: ADColor.surfaceSoft
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(property.title)
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                Text(property.locationLine)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundStyle(selected ? ADColor.primary : ADColor.textLight)
        }
        .padding(ADSpacing.s3)
        .background(selected ? ADColor.primaryLight.opacity(0.4) : ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadProperties() async {
        loadingProperties = true
        propertiesLoadError = nil
        defer { loadingProperties = false }
        do {
            let props = try await PropertyService.shared.fetchPublishedProperties()
            availableProperties = props
            print("✅ [RoomScan][Flow] loaded \(props.count) properties for picker")
        } catch {
            propertiesLoadError = "Impossibile caricare gli immobili: \(error.localizedDescription)"
            print("🔴 [RoomScan][Flow] loadProperties failed — \(error.localizedDescription)")
        }
    }

    private var canSubmit: Bool {
        guard !scanLabel.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch targetMode {
        case .existing:
            return selectedProperty != nil
        case .new:
            let quotaOK = (userGeneratedCount ?? 0) < 1
            return quotaOK && !newPropertyCity.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func startUpload() {
        guard let room = capturedRoom else { return }
        guard let userID = AuthService.shared.currentUser?.id else {
            uploadPhase = .errored("Non sei autenticato.")
            return
        }
        let trimmedLabel = scanLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else { return }
        showUploadSheet = false
        uploadPhase = .uploading
        Task {
            do {
                // 1. Risolvi propertyID: esistente o crea nuovo
                let propertyID: UUID
                switch targetMode {
                case .existing:
                    guard let property = selectedProperty else {
                        uploadPhase = .errored("Nessun immobile selezionato.")
                        return
                    }
                    propertyID = property.id

                case .new:
                    // Recupera agency_id dell'utente (null per super_admin)
                    let agencyID = await AgencyAccessService.shared.fetchMyAgencyID()
                    let trimmedCity = newPropertyCity.trimmingCharacters(in: .whitespacesAndNewlines)
                    let draftProperty = UserGeneratedPropertyDraft(
                        title: trimmedLabel,
                        city: trimmedCity.isEmpty ? nil : trimmedCity,
                        agencyID: agencyID,
                        createdBy: userID
                    )
                    let createdProperty = try await PropertyService.shared.createUserGeneratedProperty(draft: draftProperty)
                    propertyID = createdProperty.id
                    print("✅ [RoomScan][Flow] new property created → id=\(propertyID)")
                }

                // 2. Encode CapturedRoom blob + crea PropertyScanDraft
                let blob = try AnyCodable(room)
                let area = computeArea(from: room)
                let count = max(1, room.sections.count)
                let draft = PropertyScanDraft(
                    propertyID: propertyID,
                    scannedBy: userID,
                    scanJSON: blob,
                    label: trimmedLabel,
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
        DisclosureGroup {
            Text(jsonPreview)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(ADColor.text.opacity(0.8))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, ADSpacing.s2)
        } label: {
            Text("JSON debug · \(jsonPreview.count / 1024) KB")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(ADColor.textMuted)
        }
        .tint(ADColor.textMuted)
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

    /// Area totale approssimativa.
    /// Strategia:
    ///   1. Se RoomPlan ha popolato `floors`, somma w*d delle dimensions
    ///   2. Fallback su bounding-box delle posizioni delle walls nel piano xz
    /// Apple usa SI: dimensions/translation in metri.
    private func computeArea(from room: CapturedRoom) -> Double {
        // 1. Primary: sum floors area
        let floorArea = room.floors.reduce(0.0) { sum, floor in
            let w = Double(floor.dimensions.x)
            let d = Double(floor.dimensions.z)
            return sum + (w * d)
        }
        if floorArea > 0.5 { // sanity check: una stanza minima è > 0.5 m²
            return floorArea
        }
        // 2. Fallback: bounding box delle walls nel piano xz
        let walls = room.walls
        guard !walls.isEmpty else { return 0 }
        let positions = walls.map { $0.transform.columns.3 }
        let xs = positions.map { $0.x }
        let zs = positions.map { $0.z }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minZ = zs.min(), let maxZ = zs.max() else { return 0 }
        let area = Double((maxX - minX) * (maxZ - minZ))
        return max(0, area)
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
