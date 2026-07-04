//
//  LogNoteIntent.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import AppIntents
import SwiftData

// MARK: - The headless entry point
//
// An AppIntent is a small action the system can run from Siri, the Shortcuts
// app, Spotlight, or a widget, often without opening the app. This is the
// "invisible intelligence" idea: the OS can run your feature for the user.
//
// This intent connects the two parts of the app. The system calls it, and inside
// it we call the model (through CaptureService) and save the result.

struct LogNoteIntent: AppIntent {

    /// Name shown in the Shortcuts app and Siri. LocalizedStringResource makes it
    /// translatable. static let keeps it concurrency-safe in Swift 6.
    static let title: LocalizedStringResource = "Log a Note"

    static let description = IntentDescription(
        "Capture a quick note. SmartCut Log turns it into a structured item on-device."
    )

    /// Do not open the app when this runs. The model call and save happen in the
    /// background, and we only speak a short reply. Set true if you want it to
    /// open the UI instead.
    static let openAppWhenRun = false

    /// The note text. Optional on purpose.
    ///
    /// If this is a required parameter, an App Shortcut started by voice fails
    /// with "hasn't added support for that with Siri", because Siri cannot get
    /// the free text before running. So we make it optional and ask for the value
    /// inside perform() with requestValue (see below). Shortcuts and Spotlight
    /// still pass the value directly.
    @Parameter(title: "Note", description: "The note to capture.")
    var rawText: String?

    /// The system calls this to run the action.
    ///
    /// @MainActor keeps our SwiftData writes on one actor, which is the simple
    /// correct choice under Swift 6 concurrency. The return type
    /// "some IntentResult & ProvidesDialog" means it finishes the action and also
    /// speaks a line back to the user.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {

        // 0) Get the text. If Siri started us by voice with no value, ask for it
        // now with requestValue. The framework prompts the user and then resumes
        // this method with the answer. This is what makes the Siri voice path work.
        let note: String
        if let rawText, !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            note = rawText
        } else {
            note = try await $rawText.requestValue("What should I log?")
        }

        // 1) Run the on-device model. This is the only awaited step.
        let item = try await CaptureService.shared.extract(from: note)

        // 2) Convert the model output into a LogEntry we can store.
        let entry = CaptureService.shared.makeLogEntry(from: item, rawText: note)

        // 3) Save into the shared database. The note then shows in the app's list,
        // even though we never opened the app.
        let context = ModelContext(AppModelContainer.shared)
        context.insert(entry)
        try context.save()

        // 4) Reply with a short line. Siri speaks it, Shortcuts shows it.
        return .result(
            dialog: "Logged \"\(entry.title)\" as a \(entry.category.rawValue)."
        )
    }
}
