import Testing
import Foundation
@testable import mreminders

@Suite("ActiveReminder Tests")
struct ActiveReminderTests {

    @Test("remainingSeconds returns positive when timer active")
    func remainingSecondsActive() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(120),
            ekReminderID: "test-id"
        )
        let remaining = reminder.remainingSeconds(from: Date())
        #expect(remaining > 115 && remaining <= 120)
    }

    @Test("remainingSeconds returns 0 when expired")
    func remainingSecondsExpired() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-10),
            ekReminderID: "test-id"
        )
        #expect(reminder.remainingSeconds(from: Date()) == 0)
    }

    @Test("isUrgent true when under 60 seconds")
    func urgentUnder60() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(30),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: Date()) == true)
    }

    @Test("isUrgent false when over 60 seconds")
    func notUrgentOver60() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(90),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: Date()) == false)
    }

    @Test("isUrgent false when expired (0 seconds)")
    func notUrgentWhenExpired() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-5),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: Date()) == false)
    }

    @Test("isExpired true when past end date")
    func expiredPastEndDate() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-1),
            ekReminderID: "test-id"
        )
        #expect(reminder.isExpired(from: Date()) == true)
    }

    @Test("displayTime formats correctly")
    func displayTimeFormat() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now.addingTimeInterval(754), // 12 min 34 sec
            ekReminderID: "test-id"
        )
        let display = reminder.displayTime(from: now)
        #expect(display == "12:34")
    }

    @Test("displayTime shows 0:00 when expired")
    func displayTimeExpired() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-60),
            ekReminderID: "test-id"
        )
        #expect(reminder.displayTime(from: Date()) == "0:00")
    }

    // MARK: - Boundary Cases

    @Test("isUrgent false at exactly 60 seconds")
    func isUrgentAtExactly60() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now.addingTimeInterval(60),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: now) == false)
    }

    @Test("isUrgent true at exactly 1 second")
    func isUrgentAt1Second() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now.addingTimeInterval(1),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: now) == true)
    }

    @Test("isExpired true when endDate equals now")
    func isExpiredAtExactlyZero() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now,
            ekReminderID: "test-id"
        )
        #expect(reminder.isExpired(from: now) == true)
    }

    @Test("displayTime zero-pads single digit seconds")
    func displayTimeZeroPads() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now.addingTimeInterval(65),
            ekReminderID: "test-id"
        )
        #expect(reminder.displayTime(from: now) == "1:05")
    }

    @Test("remainingSeconds rounds up fractional seconds")
    func remainingSecondsRoundsUp() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now.addingTimeInterval(0.4),
            ekReminderID: "test-id"
        )
        #expect(reminder.remainingSeconds(from: now) == 1)
    }
}
