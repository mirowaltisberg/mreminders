import Testing
import Foundation
@testable import mreminders

@Suite("ReminderManager State Tests")
@MainActor
struct ReminderManagerStateTests {

    private func makeManager() -> ReminderManager {
        ReminderManager()
    }

    private func makeReminder(
        secondsFromNow: TimeInterval,
        text: String = "Test"
    ) -> ActiveReminder {
        ActiveReminder(
            id: UUID(),
            text: text,
            endDate: Date().addingTimeInterval(secondsFromNow),
            ekReminderID: "test-\(UUID().uuidString)"
        )
    }

    // MARK: - checkExpired

    @Test("checkExpired fires callback once per expired reminder")
    func checkExpiredFiresOnce() {
        let manager = makeManager()
        let expired = makeReminder(secondsFromNow: -10)
        manager.activeReminders = [expired]
        manager.currentDate = Date()

        var firedCount = 0
        manager.onReminderExpired = { _ in firedCount += 1 }

        manager.checkExpired()
        manager.checkExpired()

        #expect(firedCount == 1)
    }

    @Test("checkExpired does not fire for future reminder")
    func checkExpiredIgnoresFuture() {
        let manager = makeManager()
        let future = makeReminder(secondsFromNow: 60)
        manager.activeReminders = [future]
        manager.currentDate = Date()

        var fired = false
        manager.onReminderExpired = { _ in fired = true }

        manager.checkExpired()

        #expect(fired == false)
    }

    @Test("checkExpired fires for multiple expired reminders")
    func checkExpiredMultiple() {
        let manager = makeManager()
        let expired1 = makeReminder(secondsFromNow: -10, text: "A")
        let expired2 = makeReminder(secondsFromNow: -5, text: "B")
        manager.activeReminders = [expired1, expired2]
        manager.currentDate = Date()

        var firedTexts: [String] = []
        manager.onReminderExpired = { reminder in firedTexts.append(reminder.text) }

        manager.checkExpired()

        #expect(firedTexts.count == 2)
        #expect(firedTexts.contains("A"))
        #expect(firedTexts.contains("B"))
    }

    // MARK: - deleteReminder

    @Test("deleteReminder removes from activeReminders")
    func deleteRemovesFromList() {
        let manager = makeManager()
        let reminder = makeReminder(secondsFromNow: 60)
        manager.activeReminders = [reminder]

        manager.deleteReminder(reminder)

        #expect(manager.activeReminders.isEmpty)
    }

    @Test("deleteReminder clears notifiedReminderID")
    func deleteClearsNotifiedID() {
        let manager = makeManager()
        let expired = makeReminder(secondsFromNow: -10)
        manager.activeReminders = [expired]
        manager.currentDate = Date()

        manager.onReminderExpired = { _ in }
        manager.checkExpired()

        #expect(manager.notifiedReminderIDs.contains(expired.id))

        manager.deleteReminder(expired)

        #expect(!manager.notifiedReminderIDs.contains(expired.id))
    }

    // MARK: - notifiedReminderIDs pruning

    @Test("checkExpired prunes orphaned notification IDs")
    func prunesOrphanedIDs() {
        let manager = makeManager()
        let expired = makeReminder(secondsFromNow: -10)
        manager.activeReminders = [expired]
        manager.currentDate = Date()

        manager.onReminderExpired = { _ in }
        manager.checkExpired()

        #expect(manager.notifiedReminderIDs.count == 1)

        // Remove the reminder without using deleteReminder (simulates notification-dismiss)
        manager.activeReminders = []
        manager.checkExpired()

        #expect(manager.notifiedReminderIDs.isEmpty)
    }
}
