//
//  SmartCutShortcuts.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import AppIntents

// MARK: - Siri phrases (no setup needed)
//
// The AppIntent on its own has no spoken trigger. AppShortcutsProvider adds one.
// The system reads it when the app installs and registers these phrases with
// Siri and Spotlight, so the user does not have to build a shortcut first.
//
// One rule: every phrase must contain \(.applicationName). That token tells Siri
// which app the phrase belongs to (many apps could say "log a note"). It is
// replaced with the app's display name at runtime.

struct SmartCutShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            // Which action to run.
            intent: LogNoteIntent(),

            // Natural ways to say it. The first phrase is the one the system
            // suggests. A few variations help.
            phrases: [
                "Log a note in \(.applicationName)",
                "Log to \(.applicationName)",
                "Capture a note with \(.applicationName)",
                "Add a note to \(.applicationName)"
            ],

            // How it appears in the Shortcuts app / Spotlight.
            shortTitle: "Log a Note",
            systemImageName: "square.and.pencil"
        )
    }
}
