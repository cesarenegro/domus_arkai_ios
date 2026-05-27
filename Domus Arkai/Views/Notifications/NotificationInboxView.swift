//
//  NotificationInboxView.swift
//  Domus Arkai
//
//  Inbox in-app delle notifiche utente (push persistite server-side).
//  Aperta come sheet dalla campanella in HomeView.
//

import SwiftUI

struct NotificationInboxView: View {
    @Bindable var model: NotificationInboxViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                contentSection
            }
            .navigationTitle("Notifiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if model.unreadCount > 0 {
                        Button {
                            Task { await model.markAllAsRead() }
                        } label: {
                            Text("Segna tutte")
                                .font(ADTypography.small.weight(.semibold))
                                .foregroundStyle(ADColor.primary)
                        }
                    }
                }
            }
            .refreshable {
                await model.load()
            }
            .task {
                if model.phase == .idle {
                    await model.load()
                }
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch model.phase {
        case .idle, .loading:
            ProgressView()
                .tint(ADColor.primary)

        case .loaded:
            if model.notifications.isEmpty {
                ADEmptyState(
                    icon: "bell.slash",
                    title: "Nessuna notifica",
                    message: "Quando riceverai aggiornamenti su visite, immobili o messaggi dell'agenzia, li troverai qui."
                )
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
            } else {
                notificationsList
            }

        case .error(let message):
            VStack(spacing: ADSpacing.s3) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(ADColor.textLight)
                Text(message)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.textMuted)
                    .multilineTextAlignment(.center)
                Button("Riprova") {
                    Task { await model.load() }
                }
                .buttonStyle(.borderedProminent)
                .tint(ADColor.primary)
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        }
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: ADSpacing.s3) {
                ForEach(model.notifications) { notification in
                    NotificationRow(notification: notification)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await model.markAsRead(notification) }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await model.delete(notification) }
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
            .padding(.top, ADSpacing.s3)
            .padding(.bottom, ADSpacing.s6)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Row

private struct NotificationRow: View {
    let notification: UserNotification

    var body: some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            ZStack {
                Circle()
                    .fill(ADColor.surfaceSoft)
                    .frame(width: 40, height: 40)
                Image(systemName: notification.iconName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ADColor.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: ADSpacing.s2) {
                    Text(notification.title)
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.text)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if notification.isUnread {
                        Circle()
                            .fill(ADColor.primary)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.body)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !notification.relativeTimeLabel.isEmpty {
                    Text(notification.relativeTimeLabel)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                        .padding(.top, 2)
                }
            }
        }
        .padding(ADSpacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }
}

#Preview {
    NotificationInboxView(model: NotificationInboxViewModel())
}
