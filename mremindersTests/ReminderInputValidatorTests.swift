import Testing
import Foundation
@testable import mreminders

@Suite("ReminderInputValidator Tests")
struct ReminderInputValidatorTests {

    // MARK: - validateText

    @Test("validateText returns trimmed text for valid input")
    func validateTextValid() {
        #expect(ReminderInputValidator.validateText("  buy milk  ") == "buy milk")
    }

    @Test("validateText returns nil for whitespace-only input")
    func validateTextWhitespace() {
        #expect(ReminderInputValidator.validateText("   ") == nil)
    }

    @Test("validateText returns nil for empty string")
    func validateTextEmpty() {
        #expect(ReminderInputValidator.validateText("") == nil)
    }

    @Test("validateText returns nil for newlines-only input")
    func validateTextNewlines() {
        #expect(ReminderInputValidator.validateText("\n\t\n") == nil)
    }

    @Test("validateText preserves inner whitespace")
    func validateTextInnerSpaces() {
        #expect(ReminderInputValidator.validateText("  check  CI  build  ") == "check  CI  build")
    }

    // MARK: - parseMinutes

    @Test("parseMinutes accepts lower bound")
    func parseMinutesLowerBound() {
        #expect(ReminderInputValidator.parseMinutes("1", current: 10) == 1)
    }

    @Test("parseMinutes accepts upper bound")
    func parseMinutesUpperBound() {
        #expect(ReminderInputValidator.parseMinutes("999", current: 10) == 999)
    }

    @Test("parseMinutes rejects zero")
    func parseMinutesZero() {
        #expect(ReminderInputValidator.parseMinutes("0", current: 10) == 10)
    }

    @Test("parseMinutes rejects negative")
    func parseMinutesNegative() {
        #expect(ReminderInputValidator.parseMinutes("-5", current: 10) == 10)
    }

    @Test("parseMinutes rejects 1000")
    func parseMinutesTooHigh() {
        #expect(ReminderInputValidator.parseMinutes("1000", current: 10) == 10)
    }

    @Test("parseMinutes rejects non-numeric")
    func parseMinutesNonNumeric() {
        #expect(ReminderInputValidator.parseMinutes("abc", current: 10) == 10)
    }

    @Test("parseMinutes rejects empty string")
    func parseMinutesEmpty() {
        #expect(ReminderInputValidator.parseMinutes("", current: 5) == 5)
    }

    // MARK: - clampMinutes

    @Test("clampMinutes caps at upper bound")
    func clampMinutesUpper() {
        #expect(ReminderInputValidator.clampMinutes(1000) == 999)
    }

    @Test("clampMinutes caps at lower bound")
    func clampMinutesLower() {
        #expect(ReminderInputValidator.clampMinutes(0) == 1)
    }

    @Test("clampMinutes passes through valid value")
    func clampMinutesValid() {
        #expect(ReminderInputValidator.clampMinutes(50) == 50)
    }

    @Test("clampMinutes handles negative")
    func clampMinutesNegative() {
        #expect(ReminderInputValidator.clampMinutes(-10) == 1)
    }
}
