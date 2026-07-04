//
//  AppModelContainer.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import Foundation
import SwiftData

// MARK: - One shared database
//
// SwiftData has two parts:
//   ModelContainer - the database itself (its schema and where it is stored).
//   ModelContext   - the object you read and write through.
//
// We need one shared container because the App Intent (LogNoteIntent) can run in
// the background without opening the app. The app and the intent must use the
// same database, or a note added by Siri would not show up in the app.
//
// So we make one container here and share it:
//   the app injects it with .modelContainer(AppModelContainer.shared)
//   the intent makes a context with ModelContext(AppModelContainer.shared)
//
// The intent lives in the app's own target, so an in-process shared container is
// enough. If it were a separate extension, we would need an App Group instead.

enum AppModelContainer {

    /// The one database for the whole app.
    static let shared: ModelContainer = {
        // The schema lists every @Model type SwiftData should manage.
        let schema = Schema([LogEntry.self])

        // Store on disk so notes survive app restarts.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // If the store can't be created, the app can't work. We stop with a
            // clear message instead of running in a broken state. This should not
            // happen in normal use.
            fatalError("Could not create the SmartCut Log database: \(error)")
        }
    }()
}
