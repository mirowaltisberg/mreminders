import Foundation
import EventKit
import Combine
import AppKit

@Observable
@MainActor
final class ReminderManager {

    // MARK: - Published State

    var activeReminders: [ActiveReminder] = []
    var currentDate: Date = Date()
    var permissionGranted: Bool = false

    // MARK: - Private

    private let store = EKEventStore()
    private var timerCancellable: AnyCancellable?
    private var wakeCancellable: AnyCancellable?
    private var deskMinderCalendar: EKCalendar?
    private(set) var notifiedReminderIDs: Set<UUID> = []

    var onReminderExpired: (@MainActor (ActiveReminder) -> Void)?

    // MARK: - Permissions

    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToReminders()
            permissionGranted = granted
            if granted {
                setupCalendar()
            }
        } catch {
            permissionGranted = false
        }
    }

    // MARK: - Calendar Setup

    private func setupCalendar() {
        let calendars = store.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == "mreminders" }) {
            deskMinderCalendar = existing
            loadActiveReminders()
            return
        }

        let calendar = EKCalendar(for: .reminder, eventStore: store)
        calendar.title = "mreminders"

        if let defaultSource = store.defaultCalendarForNewReminders()?.source {
            calendar.source = defaultSource
        } else if let localSource = store.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else {
            return
        }

        do {
            try store.saveCalendar(calendar, commit: true)
            deskMinderCalendar = calendar
        } catch {
            deskMinderCalendar = store.defaultCalendarForNewReminders()
        }
    }

    private func loadActiveReminders() {
        guard let calendar = deskMinderCalendar else { return }
        let predicate = store.predicateForReminders(in: [calendar])
        store.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self, let reminders else { return }
            let now = Date()
            let loaded: [ActiveReminder] = reminders.compactMap { ek in
                guard !ek.isCompleted,
                      let alarm = ek.alarms?.first,
                      let endDate = alarm.absoluteDate,
                      endDate > now
                else { return nil }
                return ActiveReminder(
                    id: UUID(),
                    text: ek.title ?? "",
                    endDate: endDate,
                    ekReminderID: ek.calendarItemIdentifier
                )
            }
            Task { @MainActor in
                self.activeReminders = loaded
            }
        }
    }

    // MARK: - Timer Engine

    func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.currentDate = date
                    self.checkExpired()
                }
            }

        wakeCancellable = NotificationCenter.default
            .publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.currentDate = Date()
                    self.checkExpired()
                }
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        wakeCancellable?.cancel()
        wakeCancellable = nil
    }

    func checkExpired() {
        let activeIDs = Set(activeReminders.map(\.id))
        notifiedReminderIDs.formIntersection(activeIDs)

        for reminder in activeReminders {
            if reminder.isExpired(from: currentDate) && !notifiedReminderIDs.contains(reminder.id) {
                notifiedReminderIDs.insert(reminder.id)
                onReminderExpired?(reminder)
            }
        }
    }

    // MARK: - CRUD

    func createReminder(text: String, minutes: Int) {
        guard let calendar = deskMinderCalendar else { return }

        let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.title = text
        ekReminder.calendar = calendar
        ekReminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: endDate
        )
        ekReminder.addAlarm(EKAlarm(absoluteDate: endDate))

        do {
            try store.save(ekReminder, commit: true)
        } catch {
            return
        }

        let active = ActiveReminder(
            id: UUID(),
            text: text,
            endDate: endDate,
            ekReminderID: ekReminder.calendarItemIdentifier
        )
        activeReminders.append(active)
    }

    func deleteReminder(_ reminder: ActiveReminder) {
        if let ekReminder = store.calendarItem(withIdentifier: reminder.ekReminderID) as? EKReminder {
            do {
                try store.remove(ekReminder, commit: true)
            } catch {
                // Continue with local removal
            }
        }

        activeReminders.removeAll { $0.id == reminder.id }
        notifiedReminderIDs.remove(reminder.id)
    }
}
