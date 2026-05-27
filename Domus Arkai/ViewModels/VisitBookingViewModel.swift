//
//  VisitBookingViewModel.swift
//  Domus Arkai
//

import Foundation

@MainActor
@Observable
final class VisitBookingViewModel {
    let property: Property

    var preferredDate: Date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    var timeSlot: VisitRequest.TimeSlot = .afternoon
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var notes: String = ""

    var isSubmitting: Bool = false
    var submissionResult: VisitRequest?
    var errorMessage: String?

    init(property: Property) {
        self.property = property
    }

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (!phone.trimmingCharacters(in: .whitespaces).isEmpty
                || isValidEmail(email))
    }

    func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        print("🟢 [Visit][VM] submit() — property=\(property.id), name=\(name)")

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        do {
            // 1. Crea lead per qualificare il contatto
            let lead = try await LeadService.shared.createLead(
                agencyID: property.agencyID,
                propertyID: property.id,
                name: name.trimmingCharacters(in: .whitespaces),
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
                message: trimmedNotes.isEmpty ? nil : trimmedNotes,
                source: .visitRequest
            )
            print("✅ [Visit][VM] lead created — id=\(lead.id)")

            // 2. Crea visit request collegata al lead
            let visit = try await VisitRequestService.shared.createVisitRequest(
                agencyID: property.agencyID,
                propertyID: property.id,
                leadID: lead.id,
                preferredDate: preferredDate,
                preferredTimeSlot: timeSlot,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            print("✅ [Visit][VM] visit request created — id=\(visit.id)")

            submissionResult = visit
            errorMessage = nil

            // Schedule local reminders 24h + 1h prima della visita.
            // (orario default mid-slot in base al timeSlot scelto.)
            let visitDateTime = composeVisitDateTime(date: preferredDate, slot: timeSlot)
            await NotificationService.shared.scheduleVisitReminder(
                visitDate: visitDateTime,
                propertyTitle: property.title,
                visitID: visit.id
            )
        } catch {
            print("🔴 [Visit][VM] submit failed — \(error)")
            errorMessage = "Invio non riuscito. Riprova tra qualche istante."
        }
    }

    private func isValidEmail(_ string: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return string.range(of: pattern, options: .regularExpression) != nil
    }

    /// Compone data + ora indicativa centrale della slot scelta (utile per i reminder locali).
    private func composeVisitDateTime(date: Date, slot: VisitRequest.TimeSlot) -> Date {
        let calendar = Calendar.current
        let hour: Int
        switch slot {
        case .morning: hour = 10      // 9–12 → 10:00
        case .afternoon: hour = 15    // 14–17 → 15:00
        case .evening: hour = 18      // 17–20 → 18:00
        }
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }
}
