//
//  HubInboxView.swift
//  Domus Arkai
//

import SwiftUI

@MainActor
@Observable
final class HubInboxModel {
    var messages: [HubMessage] = []
    var isLoading: Bool = false
    var lastError: String?
    var lastRefresh: Date?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await HubService.shared.fetchPendingFromPeer()
            lastRefresh = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func markCompleted(_ message: HubMessage) async {
        do {
            _ = try await HubService.shared.markCompleted(id: message.id)
            messages.removeAll { $0.id == message.id }
        } catch {
            lastError = error.localizedDescription
        }
    }
}

struct HubInboxView: View {
    @State private var model = HubInboxModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusRow
                }

                if model.messages.isEmpty && !model.isLoading {
                    ContentUnavailableView(
                        "Nessun messaggio pendente",
                        systemImage: "tray",
                        description: Text("Inbox da \(HubConfig.peerSender) vuota.")
                    )
                } else {
                    ForEach(model.messages) { message in
                        NavigationLink(value: message) {
                            HubMessageRow(message: message)
                        }
                    }
                }
            }
            .navigationTitle("HUB Arkai")
            .navigationDestination(for: HubMessage.self) { message in
                HubMessageDetailView(message: message) {
                    await model.markCompleted(message)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.refresh() }
                    } label: {
                        if model.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(model.isLoading)
                }
            }
            .refreshable {
                await model.refresh()
            }
            .task {
                await model.refresh()
            }
        }
    }

    private var statusRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(model.lastError == nil ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(model.lastError == nil ? "Connesso a Supabase" : "Errore di connessione")
                    .font(.subheadline)
                Spacer()
                if let lastRefresh = model.lastRefresh {
                    Text(lastRefresh, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if let error = model.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct HubMessageRow: View {
    let message: HubMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.title)
                .font(.headline)
                .lineLimit(2)
            Text(message.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 6) {
                Text(message.sender)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
                Text(message.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct HubMessageDetailView: View {
    let message: HubMessage
    let onMarkCompleted: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isMarking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(message.title)
                    .font(.title2.bold())
                HStack {
                    Label(message.sender, systemImage: "person.circle")
                    Spacer()
                    Text(message.createdAt, style: .date)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Divider()
                Text(message.body)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                Button {
                    Task {
                        isMarking = true
                        await onMarkCompleted()
                        isMarking = false
                        dismiss()
                    }
                } label: {
                    if isMarking {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Marca come completed", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isMarking)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Messaggio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HubInboxView()
}
