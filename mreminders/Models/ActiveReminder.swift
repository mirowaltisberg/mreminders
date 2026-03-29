import Foundation

struct ActiveReminder: Identifiable, Equatable {
    let id: UUID
    let text: String
    let endDate: Date
    let ekReminderID: String

    func remainingSeconds(from now: Date = Date()) -> Int {
        max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
    }

    func isUrgent(from now: Date = Date()) -> Bool {
        let remaining = remainingSeconds(from: now)
        return remaining > 0 && remaining < 60
    }

    func isExpired(from now: Date = Date()) -> Bool {
        remainingSeconds(from: now) <= 0
    }

    func displayTime(from now: Date = Date()) -> String {
        let total = remainingSeconds(from: now)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
