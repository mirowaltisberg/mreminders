import Foundation

enum ReminderInputValidator {

    static func validateText(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func parseMinutes(_ text: String, current: Int) -> Int {
        guard let value = Int(text), value >= 1, value <= 999 else {
            return current
        }
        return value
    }

    static func clampMinutes(_ value: Int) -> Int {
        min(999, max(1, value))
    }
}
