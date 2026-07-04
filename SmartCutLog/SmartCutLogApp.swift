//
//  SmartCutLogApp.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import SwiftUI
import SwiftData

// MARK: - App entry point
//
// @main marks where the app starts. An App describes its UI as Scenes.
// WindowGroup is the normal scene for a windowed app.
//
// The important line is .modelContainer(AppModelContainer.shared). It puts our
// one shared SwiftData database into the SwiftUI environment, so:
//   views can use @Query and @Environment(\.modelContext), and
//   it is the same database the background LogNoteIntent writes to, which is why
//   a note added by Siri shows up here with no manual refresh.

@main
struct SmartCutLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
