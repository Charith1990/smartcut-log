//
//  CaptureService.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import Foundation
import FoundationModels

// MARK: - The engine
//
// CaptureService does the AI work only:
//   1. check the on-device model is available,
//   2. run it with guided generation to get a typed CapturedItem,
//   3. turn that into a LogEntry (map strings to enums, parse the date).
//
// It does not touch SwiftData. extract() returns a plain value, and the caller
// (the view or the intent) saves it into its own ModelContext. Keeping the model
// call away from the database also keeps Swift 6 concurrency simple: we only
// await around the model call, and the database writes happen after that on the
// caller's own actor.

struct CaptureService {

    /// A single shared instance to call from anywhere.
    static let shared = CaptureService()

    // MARK: Errors

    enum CaptureError: LocalizedError {
        case modelUnavailable(String)

        var errorDescription: String? {
            switch self {
            case .modelUnavailable(let reason):
                return "The on-device model isn't available: \(reason)"
            }
        }
    }

    // MARK: Step 1 + 2 — run the model

    /// Runs the on-device model over rawText and returns the structured result.
    /// async because the model call takes time. throws because it can fail (model
    /// not available, or a generation error).
    func extract(from rawText: String) async throws -> CapturedItem {

        // 1) Check the model is available. It only runs on an Apple Intelligence
        // device with the feature on, and it can be busy downloading. Always
        // check before you use it.
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw CaptureError.modelUnavailable(String(describing: reason))
        @unknown default:
            throw CaptureError.modelUnavailable("unknown")
        }

        // 2) Make a session with instructions. Instructions are the model's fixed
        // job description for the whole session. The user's note is the prompt we
        // pass to respond() below. Rules go here, the data goes in the prompt.
        let session = LanguageModelSession(instructions: Self.instructions)

        // 3) Guided generation. Passing generating: CapturedItem.self makes the
        // framework fill in our struct. response.content is the typed
        // CapturedItem. No JSON parsing.
        let response = try await session.respond(to: rawText, generating: CapturedItem.self)
        return response.content
    }

    // MARK: Step 3 — map to a storable record (pure, synchronous)

    /// Converts the model's CapturedItem into a LogEntry (strings to enums, and
    /// the date string to a real Date). No await and no database here. The caller
    /// inserts the returned entry into its own context.
    func makeLogEntry(from item: CapturedItem, rawText: String) -> LogEntry {
        LogEntry(
            rawText: rawText,
            title: item.title,
            category: ItemCategory(rawValue: item.category) ?? .idea,
            priority: ItemPriority(rawValue: item.priority) ?? .normal,
            dueDate: Self.parseDate(item.dueDate),
            amount: item.amount
        )
    }

    // MARK: - Private helpers

    /// Fixed instructions the model follows for every capture.
    private static let instructions = """
        You convert a short, messy personal note into structured data.
        - Pick the single best category and priority.
        - Write a concise, clean title (do not just copy the raw text).
        - Only include a due date if the note clearly implies one.
        - Only include an amount for expenses.
        Never invent details that are not in the note.
        """

    /// Parses the model's "yyyy-MM-dd" string into a Date, or nil if it is empty
    /// or wrong. en_US_POSIX with a fixed format is the safe way to parse fixed
    /// dates, whatever the user's region is.
    private static func parseDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
